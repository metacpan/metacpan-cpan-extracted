package App::Zapzi::Publishers::MOBI;
# ABSTRACT: publishes articles to a MOBI eBook file


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Moo;
use App::Zapzi;
use EBook::MOBI 0.69;           # required to drop GD dependency

with 'App::Zapzi::Roles::Publisher';


has mobi => (is => 'rwp');


sub name
{
    return 'MOBI';
}


sub start_publication
{
    my $self = shift;

    # Default encoding is ISO-8859-1 as early Kindles have issues with
    # UTF-8. Characters that cannot be encoded will be replaced with
    # their HTML entity equivalents.
    $self->_set_encoding('ISO-8859-1') unless $self->encoding;

    my $book = EBook::MOBI->new();
    $book->set_filename($self->filename);
    $book->set_title($self->collection_title);
    $book->set_author('Zapzi');
    $book->set_encoding(':encoding(' . $self->encoding . ')');
    $book->add_toc_once();
    $book->add_mhtml_content("<hr>\n");

    $self->_set_mobi($book);
}


sub add_article
{
    my $self = shift;
    my ($article, $index) = @_;

    $self->mobi->add_pagebreak() unless $index == 0;
    $self->mobi->add_mhtml_content($article->{encoded_title});
    $self->mobi->add_mhtml_content($article->{encoded_text});
}


sub finish_publication
{
    my $self = shift;

    $self->mobi->make();
    $self->_set_collection_data($self->mobi->print_mhtml('noprint'));

    $self->mobi->save();
    return $self->filename;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Publishers::MOBI - publishes articles to a MOBI eBook file

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class creates a MOBI file from a collection of articles.

=head1 ATTRIBUTES

=head2 mobi

Returns the EBook::MOBI object created.

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
