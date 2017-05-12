package App::Zapzi::Publishers::HTML;
# ABSTRACT: publishes articles to a HTML file


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Path::Tiny;
use Moo;
use App::Zapzi;

with 'App::Zapzi::Roles::Publisher';


has file => (is => 'rwp');


sub name
{
    return 'HTML';
}


sub start_publication
{
    my $self = shift;

    $self->_set_encoding('UTF-8') unless $self->encoding;

    open my $file, '>', $self->filename
            or croak "Can't open output HTML file: $!\n";

    my $html = sprintf("<html><head><meta charset=\"%s\">\n" .
                       "<title>%s</title></head><body>\n",
                       $self->encoding, $self->collection_title);
    print {$file} $html;

    $self->_set_file($file);
}


sub add_article
{
    my $self = shift;
    my ($article, $index) = @_;

    print {$self->file} "\n<hr>\n" unless $index == 0;
    print {$self->file} $article->{encoded_title};
    print {$self->file} $article->{encoded_text};
}


sub finish_publication
{
    my $self = shift;

    print {$self->file} "</body></html>\n";
    close $self->file;

    $self->_set_collection_data(path($self->filename)->slurp);

    return $self->filename;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Publishers::HTML - publishes articles to a HTML file

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class creates a single HTML file from a collection of articles.

=head1 ATTRIBUTES

=head2 file

Returns the output file handle created.

=head1 METHODS

=head2 name

Name of publisher visible to user.

=head2 start_publication($folder, $encoding)

Starts a new publication for the given folder in the given encoding.

=head2 add_article($article, $index)

Adds an article, sequence number index,  to the publication.

=head2 finish_publication()

Finishes publication and returns the filename created.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
