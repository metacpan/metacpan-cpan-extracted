package CGI::Application::NetNewsIface::Cache::DBI;

use strict;
use warnings;

use DBI;

=head1 NAME

CGI::Application::NetNewsIface::Cache::DBI - an internally used class to
form a fast cache of the NNTP data.

=head1 SYNOPSIS

    use CGI::Application::NetNewsIface::Cache::DBI;

    my $cache = CGI::Application::NetNewsIface::Cache::DBI->new(
        {
            'nntp' => $nntp,
            'dsn' => "dbi:SQLite:dbname=foo.sqlite",
        },
    );

=head1 FUNCTIONS

=head2 new({ %params })

Constructs a new cache object. Accepts a single argument - a hash ref with
named parameters. Required parameters are:

=over 4

=item 'nntp'

A handle to the Net::NNTP object that will be used for querying the NNTP
server.

=item 'dsn'

The DBI 'dsn' for the DBI initialization.

=back

=cut

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->_initialize(@_);

    return $self;
}

sub _initialize
{
    my $self = shift;
    my $args = shift;

    $self->{'nntp'} = $args->{'nntp'};

    my $dbh = $self->{'dbh'} = DBI->connect($args->{'dsn'}, "", "");

    $self->{'sths'}->{'select_group'} =
        $dbh->prepare_cached(
            "SELECT idx, last_art FROM groups WHERE name = ?"
        );

    $self->{'sths'}->{'insert_group'} =
        $dbh->prepare_cached(
            "INSERT INTO groups (name, idx, last_art) VALUES (?, null, 0)"
        );

    $self->{'sths'}->{'insert_art'} =
        $dbh->prepare_cached(
            "INSERT INTO articles (group_idx, article_idx, msg_id, parent, subject, frm, date)
             VALUES (?, ?, ?, ?, ?, ?, ?)"
        );

    $self->{'sths'}->{'update_last_art'} =
        $dbh->prepare_cached(
            "UPDATE groups SET last_art = ? WHERE idx = ?"
        );

    $self->{'sths'}->{'get_index_of_id'} =
        $dbh->prepare_cached(
            "SELECT article_idx FROM articles WHERE (group_idx = ?) AND (msg_id = ?)"
        );

    $self->{'sths'}->{'get_parent'} =
        $dbh->prepare_cached(
            "SELECT parent FROM articles WHERE (group_idx = ?) AND (article_idx = ?)"
        );

    $self->{'sths'}->{'get_sub_thread'} =
        $dbh->prepare_cached(
            "SELECT article_idx, subject, date, frm" .
            " FROM articles" .
            " WHERE (group_idx = ?) AND (parent = ?)" .
            # We're ordering on (group_idx, article_idx) because that's what
            # the relevant index on the table is wired to.
            " ORDER BY group_idx, article_idx"
        );

    $self->{'sths'}->{'get_art_info'} =
        $dbh->prepare_cached(
            "SELECT subject, date, frm FROM articles WHERE (group_idx = ?) AND (article_idx = ?)"
        );

    return 0;
}

# This is a non-working workaround for the following DBD-SQLite bug:
# http://rt.cpan.org/Public/Bug/Display.html?id=9643
# It can probably be removed afterwards.
sub DESTROY
{
    my $self = shift;
    my @stmts = keys(%{$self->{'sths'}});
    foreach my $s (@stmts)
    {
        my $sth = delete($self->{'sths'}->{$s});
        $sth->finish();
    }
}

=head2 $cache->select( $group )

Selects the newsgroup $group.

=cut

sub select
{
    my ($self, $group) = @_;
    $self->{'group'} = $group;
    return $self->_update_group();
}

sub _update_group
{
    my $self = shift;

    my $group = $self->{'group'};
    my $nntp = $self->{'nntp'};
    my @info = $nntp->group($group);
    if (! @info)
    {
        die "Unknown group \"$group\".";
    }

    my ($num_articles, $first_article, $last_article) = @info;

    # TODO: Add a transaction here
    my $sth = $self->{sths}->{select_group};
    $sth->execute($group);
    my $group_record = $sth->fetchrow_arrayref();
    if (!defined($group_record))
    {
        $self->{sths}->{insert_group}->execute($group);
        $sth = $self->{sths}->{select_group};
        $sth->execute($group);
        $group_record = $sth->fetchrow_arrayref();
    }
    my $last_updated_art;
    my $group_idx;
    my $start_art;
    ($group_idx, $last_updated_art) = @$group_record;
    $self->{group_idx} = $group_idx;
    if ($last_updated_art == 0)
    {
        $start_art = $first_article;
    }
    else
    {
        $start_art = $last_updated_art+1;
    }

    my $ins_sth = $self->{sths}->{insert_art};
    for (my $art_idx=$start_art; $art_idx <= $last_article;$art_idx++)
    {
        my $head = $nntp->head($art_idx);
        if (!defined($head))
        {
            next;
        }

        my ($msg_id,$subject, $from, $date);
        my $parent = 0;
        foreach my $header (@$head)
        {
            chomp($header);
            if ($header =~ m{^Subject: (.*)})
            {
                $subject = $1;
            }
            elsif ($header =~ m{^Message-ID: <(.*?)>$})
            {
                $msg_id = $1;
            }
            elsif ($header =~ m{In-reply-to: <(.*?)>$}i)
            {
                $parent = $self->get_index_of_id($1);
            }
            elsif ($header =~ m{^From: (.*)$})
            {
                $from = $1;
            }
            elsif ($header =~ m{^Date: (.*)$})
            {
                $date = $1;
            }
        }
        $ins_sth->execute(
            $group_idx, $art_idx, $msg_id, $parent,
            $subject, $from, $date,
        );
    }

    if ($start_art <= $last_article)
    {
        $self->{sths}->{update_last_art}
             ->execute($last_article, $group_idx);
    }

    return 0;
}

=head2 $cache->get_index_of_id($id)

Retrieves the index of the message with the id C<$id>.

=cut

sub get_index_of_id
{
    my ($self, $msg_id) = @_;
    my $sth = $self->{sths}->{get_index_of_id};
    $sth->execute($self->{'group_idx'}, $msg_id);
    my $ret = $sth->fetchrow_arrayref();
    return (defined($ret) ? $ret->[0] : 0);
}

sub _get_parent
{
    my ($self, $index) = @_;
    my $sth = $self->{sths}->{get_parent};
    $sth->execute($self->{'group_idx'}, $index);
    my $ret = $sth->fetchrow_arrayref();
    return (defined($ret) ? $ret->[0] : undef);
}

=head2 ($thread, $coords) = $cache->get_thread($index);

Gets the thread for the message indexed C<$index>. Thread is:

C<$thread> looks like this:

    {
        'idx' => $index,
        'subject' => "Problem with Test::More",
        'date' => $date,
        'from' => "Shlomi Fish <shlomif@cpan.org>",
        'subs' =>
        [
            {
                'idx' => $index,
                .
                'subs' =>
                [
                    .
                    .
                    .
                ],
            }
            .
            .
            .
        ],
    }

C<$coords> is the coordinates leading to the current article within the
thread. To access the current article from the coords use:

    $thread->{'subs'}->[$coords[0]]->{'subs'}->[$coords[1]]->...

=cut

sub get_thread
{
    my ($self, $index) = @_;

    # Get the first ancestor of the thread.
    my $thread_head;
    {
        my ($parent, $grandparent);
        $parent = $index;
        while (($grandparent = $self->_get_parent($parent)) != 0)
        {
            $parent = $grandparent;
        }
        $thread_head = $parent;
    }

    # Make sure we retrieve information for the top-most node.
    my $sth = $self->{sths}->{get_art_info};
    $sth->execute($self->{group_idx}, $thread_head);
    my $info = $sth->fetchrow_arrayref();
    my $thread_struct =
    {
        'idx' => $thread_head,
        'subject' => $info->[0],
        'date' => $info->[1],
        'from' => $info->[2],
    };

    my $coords;
    $self->_get_sub_thread($thread_struct, $index, \$coords, []);
    return ($thread_struct, $coords);
}

sub _get_sub_thread
{
    my ($self, $struct_ptr, $requested, $coords_ptr, $coords) = @_;
    my $index = $struct_ptr->{idx};
    if ($index == $requested)
    {
        $$coords_ptr = $coords;
    }
    my $sth = $self->{sths}->{get_sub_thread};
    $sth->execute($self->{group_idx}, $index);
    my @subs;
    while (my $row = $sth->fetchrow_arrayref())
    {
        push @subs,
        {
            'idx' => $row->[0],
            'subject' => $row->[1],
            'date' => $row->[2],
            'from' => $row->[3],
        };
    }
    if (@subs)
    {
        $struct_ptr->{subs} = \@subs;
        foreach my $child_idx (0 .. $#subs)
        {
            $self->_get_sub_thread(
                $subs[$child_idx],
                $requested,
                $coords_ptr,
                [@$coords, $child_idx],
            );
        }
    }
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-netnewsiface@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-NetNewsIface>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

