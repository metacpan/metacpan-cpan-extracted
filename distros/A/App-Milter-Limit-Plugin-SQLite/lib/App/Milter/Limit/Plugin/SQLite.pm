#
# This file is part of App-Milter-Limit-Plugin-SQLite
#
# This software is copyright (c) 2010 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package App::Milter::Limit::Plugin::SQLite;
$App::Milter::Limit::Plugin::SQLite::VERSION = '0.52';
# ABSTRACT: SQLite driver for App::Milter::Limit

use strict;
use warnings;
use base qw(App::Milter::Limit::Plugin Class::Accessor);
use DBI;
use File::Spec;
use App::Milter::Limit::Log;
use App::Milter::Limit::Util;

__PACKAGE__->mk_accessors(qw(_dbh table));


sub init {
    my $self = shift;

    $self->_init_defaults;

    App::Milter::Limit::Util::make_path($self->config_get('driver', 'home'));

    $self->table( $self->config_get('driver', 'table') );

    # setup the database
    $self->_init_database;
}

sub _init_defaults {
    my $self = shift;

    $self->config_defaults('driver',
        home  => $self->config_get('global', 'state_dir'),
        file  => 'stats.db',
        table => 'milter');
}


sub db_file {
    my $self = shift;

    my $home = $self->config_get('driver', 'home');
    my $file = $self->config_get('driver', 'file');

    return File::Spec->catfile($home, $file);
}

sub _new_dbh {
    my $self = shift;

    # setup connection to the database.
    my $db_file = $self->db_file;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '', {
        PrintError => 0,
        AutoCommit => 1 })
        or die "failed to initialize SQLite: $!";

    return $dbh;
}

# initialize the database
sub _init_database {
    my $self = shift;

    # setup connection to the database.
    $self->_dbh($self->_new_dbh);

    unless ($self->_table_exists($self->table)) {
        $self->_create_table($self->table);
    }

    # make sure the db file has the right owner.
    my $uid = $self->config_get('global', 'user');
    my $gid = $self->config_get('global', 'group');

    if (defined $uid and defined $gid) {
        my $db_file = $self->db_file;
        chown $uid, $gid, $db_file or die "chown($db_file): $!";
    }
}

sub child_init {
    my $self = shift;

    debug("reopen db handle");

    if (my $dbh = $self->_dbh) {
        $dbh->disconnect;
        $dbh = $self->_new_dbh;
        $self->_dbh($dbh);
    }
}

sub child_exit {
    my $self = shift;

    debug("close db handle");

    if (my $dbh = $self->_dbh) {
        $dbh->disconnect;
    }
}

sub query {
    my ($self, $from) = @_;

    $from = lc $from;

    my $rec = $self->_retrieve($from);

    unless (defined $rec) {
        # initialize new record for sender
        $rec = $self->_create($from)
            or return 0;    # I give up
    }

    my $start  = $$rec{first_seen} || time;
    my $count  = $$rec{messages} || 0;
    my $expire = $self->config_get('global', 'expire');

    # reset counter if it is expired
    if ($start < time - $expire) {
        $self->_reset($from);
        return 1;
    }

    # update database for this sender.
    $self->_update($from);

    return $count + 1;
}

# return true if the given table exists in the db.
sub _table_exists {
    my ($self, $table) = @_;

    $self->_dbh->do("select 1 from $table limit 0")
        or return 0;

    return 1;
}

# create the stats table
sub _create_table {
    my ($self, $table) = @_;

    my $dbh = $self->_dbh;

    $dbh->do(qq{
        create table $table (
            sender varchar (255),
            first_seen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            messages integer NOT NULL DEFAULT 0,
            PRIMARY KEY (sender)
        )
    }) or die "failed to create table $table: $DBI::errstr";

    $dbh->do(qq{
        create index ${table}_first_seen_key on $table (first_seen)
    }) or die "failed to create first_seen index: $DBI::errstr";
}

## CRUD methods
sub _create {
    my ($self, $sender) = @_;

    my $table = $self->table;

    $self->_dbh->do(qq{insert or replace into $table (sender) values (?)},
        undef, $sender)
        or warn "failed to create sender record: $DBI::errstr";

    return $self->_retrieve($sender);
}

sub _retrieve {
    my ($self, $sender) = @_;

    my $table = $self->table;

    my $query = qq{
        select
            sender,
            messages,
            strftime('%s',first_seen) as first_seen
        from
            $table
        where
            sender = ?
    };

    return $self->_dbh->selectrow_hashref($query, undef, $sender);
}

sub _update {
    my ($self, $sender) = @_;

    my $table = $self->table;

    my $query = qq{update $table set messages = messages + 1 where sender = ?};

    return $self->_dbh->do($query, undef, $sender);
}

sub _reset {
    my ($self, $sender) = @_;

    my $table = $self->table;

    $self->_dbh->do(qq{
        update
            $table
        set
            messages   = 1,
            first_seen = CURRENT_TIMESTAMP
        where
            sender = ?
    }, undef, $sender)
        or warn "failed to reset $sender: $DBI::errstr";
}

1;

__END__

=pod

=head1 NAME

App::Milter::Limit::Plugin::SQLite - SQLite driver for App::Milter::Limit

=head1 VERSION

version 0.52

=head1 SYNOPSIS

 my $milter = App::Milter::Limit->instance('SQLite');

=head1 DESCRIPTION

This module implements the L<App::Milter::Limit> backend using a SQLite data
store.

=head1 METHODS

=head2 db_file

return the full path to the SQLite database filename

=for Pod::Coverage child_init
child_exit

=head1 CONFIGURATION

The C<[driver]> section of the configuration file must specify the following items:

=over 4

=item home [optional]

The directory where the database files should be stored.

default: C<state_dir>

=item file [optional]

The database filename.

default: C<stats.db>

=item table [optional]

Table name that will store the statistics.

default: C<milter>

=back

=head1 SEE ALSO

L<App::Milter::Limit::Plugin>,
L<App::Milter::Limit>

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/milter-limit-plugin-sqlite>
and may be cloned from L<git://github.com/mschout/milter-limit-plugin-sqlite.git>

=head1 BUGS

Please report any bugs or feature requests to bug-app-milter-limit-plugin-sqlite@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=App-Milter-Limit-Plugin-SQLite

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
