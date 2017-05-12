package App::Zapzi::Transformers::HTML;
# ABSTRACT: process HTML without doing readability transforms


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Encode;
use HTML::Element;
use HTML::Entities ();
use Moo;

with 'App::Zapzi::Roles::Transformer';


sub name
{
    return 'HTML';
}


sub handles
{
    # By default HTMLExtractMain will handle HTML, not this
    return 0;
}


sub transform
{
    my $self = shift;

    # Use the passed in text if explicity set, else get it from the
    # fetched article object. This is used by derived classes that
    # transform text into HTML then call this method.
    my ($input) = @_;
    $input //= $self->input->text;

    my $encoding = 'utf8';
    if ($self->input->content_type =~ m/charset=([\w-]+)/)
    {
        $encoding = $1;
    }
    my $raw_html = Encode::decode($encoding, $input);

    $self->_extract_title($raw_html);

    my $tree = $self->_extract_html($raw_html);
    return unless $tree;

    # Delete some elements we don't need
    for my $element ($tree->find_by_tag_name(
                         qw{img script noscript object iframe}))
    {
        $element->delete;
    }

    # Set up options to extract the HTML from the tree
    my $entities_to_encode = '<>&\'"';
    my $indent = ' ' x 4;
    my $optional_end_tags = {};

    my $text = $tree->as_HTML($entities_to_encode, $indent,
                              $optional_end_tags);
    $text =~ s|<[/]*body>||sg;
    $self->_set_readable_text($text);
    return 1;
}

sub _extract_title
{
    my $self = shift;
    my ($raw_html) = @_;
    my $title;

    # Try finding the <title> tag first
    my $tree = eval { HTML::TreeBuilder->new_from_content($raw_html) };
    if ($tree)
    {
        my $tag = $tree->find_by_tag_name('title');
        my $content;
        $content = ($tag->content_list)[0] if $tag;

        # Strip surrounding whitespace and decode HTML entities
        $content =~ s/^\s+|\s+$//g if $content;
        $title = HTML::Entities::decode($content) if $content;
    }

    # Use the URL/filename if no title could be found or parsed from
    # the HTML
    if (! $title)
    {
        $title = $self->input->source;
    }

    $self->_set_title($title);
}

sub _extract_html
{
    my $self = shift;
    my ($raw_html) = @_;

    my $tree = eval { HTML::TreeBuilder->new_from_content($raw_html)
                          ->find_by_tag_name('body') };

    return $tree;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Transformers::HTML - process HTML without doing readability transforms

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class takes HTML and returns the body without doing additional
readable transforms - so tags such as script are removed but no text
should be changed. Use this if HTMLExtractMain does not provide the
desired results.

=head1 METHODS

=head2 name

Name of transformer visible to user.

=head2 handles($content_type)

Returns true if this module handles the given content-type

=head2 transform(input)

Converts L<input> to readable text. Returns true if converted OK.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
