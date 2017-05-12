package Bryar::DataSource::FlatFile;
use Cwd;
use File::Basename;
use Bryar::Document;
use File::Find::Rule;
use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.2';

my %UID_Cache;

=head1 NAME

Bryar::DataSource::FlatFile - Blog entries from flat files, a la blosxom

=head1 SYNOPSIS

	$self->all_documents(...);
	$self->search(...);
    $self->add_comment(...);

=head1 DESCRIPTION

Just like C<blosxom>, this data source pulls blog entries out of flat
files in the file system. 

=head1 METHODS

=head2 all_documents

    $self->all_documents

Returns all documents making up the blog.

=cut

sub all_documents {
    # my ($self, $config) = @_;
    # croak "Must pass in a Bryar::Config object" unless UNIVERSAL::isa($config, "Bryar::Config");
    # my $where = getcwd;
    # chdir($config->datadir); # Damn you, F::F::R.
    # my @docs = map { $self->make_document($_) }
    #             File::Find::Rule->file()
    #                             ->name($self->entry_glob)
    #                             ->maxdepth($config->depth)
    #                             ->in(".");
    # chdir($where);
    # return @docs;
    my ($self, $config) = @_;
    croak "Must pass in a Bryar::Config object" unless UNIVERSAL::isa($config, "Bryar::Config");
    my @docs = sort { $b->epoch() <=> $a->epoch() } $self->search($config);
    return @docs;
}

=head2 all_but_recent

    $self->all_but_recent

Return all documented except recent() ones.

=cut

sub all_but_recent {
    my ($self, $config) = @_;
    croak "Must pass in a Bryar::Config object" unless UNIVERSAL::isa($config, "Bryar::Config");
    my @docs = sort { $b->epoch() <=> $a->epoch() } $self->search($config);
    return @docs[$config->recent() .. $#docs];
}

=head2 entry_glob

Returns a glob pattern which matches blog posts. This defaults to C<*.txt>.

=cut

sub entry_glob { "*.txt" }

=head2 id_to_file

Takes a Bryar ID, converts it to a file name.

=head2 file_to_id

Vice versa.

=cut

sub id_to_file { return $_[1].".txt" }
sub file_to_id { my $file = $_[1]; $file =~ s/.txt$//; $file; }

=head2 search

    $self->search($bryar, $config, %params)

A more advanced search for specific documents

=cut

sub search {
    my ($self, $config, %params) = @_;
    croak "Must pass in a Bryar::Config object" unless UNIVERSAL::isa($config, "Bryar::Config");
    my $was = getcwd;
    my $where = $config->datadir."/";
    if ($params{subblog}) { $where .= $params{subblog}; }
    chdir($where); # Damn you, F::F::R.
    
    my $find = File::Find::Rule->file();
    if ($params{id}) { $find->name($self->id_to_file($params{id})) }
                else { $find->name($self->entry_glob) }
    $find->maxdepth($config->depth);
    if ($params{since})   { $find->mtime(">".$params{since}) }
    if ($params{before})  { $find->mtime("<".$params{before}) }
    my @docs;
    local $/;
    if ($params{content}) { $find->grep(qr/\b\Q$params{content}\E\b/i) }

    @docs = sort { $b->epoch() <=> $a->epoch() } grep { $_->epoch() <= time () } map { $self->make_document($_) } $find->in(".");
    $params{limit} ||= @docs;
    chdir($was);
    return grep { defined } @docs[0..$params{limit}-1];
}

=head2 make_document

Turns a filename into a C<Bryar::Document>, by parsing the file
blosxom-style.

=cut

sub make_document {
    my ($self, $file) = @_;
    return unless $file;
    open(my($in), '<:utf8', $file) or return;
    my $when = (stat $in)[9];
    local $/ = "\n";
    my $fileuid = (stat _)[4];
    my $who;
        if (exists $UID_Cache{$fileuid}) {
        $who = $UID_Cache{$fileuid};
    } else {
        $who = $UID_Cache{$fileuid} = getpwuid($fileuid);
    }
    my $title = <$in>;
    chomp $title;
    local $/;
    my $content = <$in>;
    close $in;
    my $id = $self->file_to_id($file);

    my $comments = [];
    $comments = [_read_comments($id, $id.".comments") ]
        if -e $id.".comments";

    my $dir = dirname($file);
    $dir =~ s{^\./?}{};
    my $category = $dir || "main";
    return Bryar::Document->new(
        title    => $title,
        content  => $content,
        epoch    => $when,
        author   => $who,
        id       => $id,
        category => $category,
        comments => $comments
    );
}

sub _read_comments {
    my ($id, $file) = @_;
    open(COMMENTS, '<:utf8', $file) or die $!;
    local $/;
    # Watch carefully
    my $stuff = <COMMENTS>;
    my @rv;
    for (split /-----\n/, $stuff) {
        push @rv,
            Bryar::Comment->new(
                id => $id,
                map {/^(\w+): (.*)/; $1 => $2 } split /\n/, $_
            )
    }
    return @rv;
}

=head2 add_comment

    Class->add_comment($bryar, 
                       document => $doc,
                         author => $author,
                            url => $url,
                        content => $content );

Records the given comment details.

=cut

sub add_comment {
    my ($self, $config) = (shift, shift);
    my %params = @_;

    s/\n/\r/g for values %params;

    my @links = ("$params{url} $params{content}" =~ m!(http://)!g);
    if(@links > 3) { # more than three links is definitely spam
        $config->frontend->report_error('Comment failure', 'Attempt to spam the journal.');
    } elsif(length($params{content}) < 1) { # real content always has, errm, content
        $config->frontend->report_error('Comment failure', 'Attempt to post with no content.');
    } elsif(@links) {
        my($email, $author) = map { # kill funny chars to avoid remote
            my $foo = $_;           # execution in open(). Yuck.
            $foo =~ s/[^\w @]/_/g;
            $foo;
        } @params{qw(email author)};
        open(MAIL, "| mail -s \"$email $author maybe tried to spam the journal\" ".$config->email())
            or $config->frontend->report_error('Comment failure', "Cannot send mail: $!");
        print MAIL "$_: $params{$_}\n" for keys %params;
        print MAIL "\nEnvironment\n";
        print MAIL "$_: $ENV{$_}\n" for keys %ENV;
        close MAIL
            or $config->frontend->report_error('Comment failure', "Cannot send mail: $!");
        # FIXME: this is not an error
        $config->frontend->report_error("Your comment is being held for approval.");
    } else {
        my $file = $params{document}->id.".comments";
        $params{url} = "http://".$params{url}
            if($params{url} && $params{url} !~ /^http:\/\//);
        # This probably fails with subblogs, but I don't use them.
        chdir $config->datadir."/";
        open(OUT, ">>:utf8", $file)
            or $config->frontend->report_error("Cannot open $file", $!);
        delete $params{document};
        print OUT "$_: $params{$_}\n" for keys %params;
        print OUT "-----\n";
        # Looks a bit like blosxom, doesn't it?
        close OUT;
        # now send mail
        open(MAIL, '| mail -s "Someone commented in the journal" '.$config->email())
            or $config->frontend->report_error('Comment failure', "Cannot send mail: $!");
        print MAIL "$_: $params{$_}\n" for keys %params;
        print MAIL "\nEnvironment\n";
        print MAIL "$_: $ENV{$_}\n" for keys %ENV;
        close MAIL
            or $config->frontend->report_error('Comment failure', "Cannot send mail: $!");
    }
}

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>

some parts Copyright 2007 David Cantrell C<david@cantrell.org.uk>


=cut

1;
