package Bryar::DataSource::FlatFile::Dated;
use base 'Bryar::DataSource::FlatFile';
our $VERSION = '1.0';
use File::Basename;
use Bryar::Document;
use File::Find::Rule;
use strict;
use warnings;
use Carp;

=head1 NAME

Bryar::DataSource::FlatFile - Blog entries from flat files, a la blosxom

=head1 SYNOPSIS

	$self->all_documents(...);
	$self->search(...);
    $self->add_comment(...);
=head1 NAME

Bryar::DataSource::FlatFile::Dated - Blog entries from flat files, a la blosxom

=head1 SYNOPSIS

    1st January 1970, 20:12

    Title

    Stuff

=head1 DESCRIPTION

See L<Bryar::DataSource::FlatFile>

=cut

sub make_document {
    my ($self, $file) = @_;
    return unless $file;
    open(my($in), '<:utf8', $file) or return;
    local $/ = "\n";
    my $who = getpwuid((stat $in)[4]);
    $file =~ s/\.txt$//;
    my $when  = <$in>;
    my $title = <$in>;
    chomp $title;
    local $/;
    my $content = <$in>;
    close $in;

    my $comments = [];
    $comments = [_read_comments($file, $file.".comments") ]
        if -e $file.".comments";

    my $dir = dirname($file);
    $dir =~ s{^\./?}{};
    my $category = $dir || "main";
    return Bryar::Document->new(
        title    => $title,
        content  => $content,
        epoch    => $when,
        author   => $who,
        id       => $file,
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

1;
