package App::Zapzi::Transformers::HTMLExtractMain;
# ABSTRACT: transform text using HTMLExtractMain


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use HTML::ExtractMain 0.63;
use Moo;

extends "App::Zapzi::Transformers::HTML";


sub name
{
    return 'HTMLExtractMain';
}


sub handles
{
    my $self = shift;
    my $content_type = shift;

    return 1 if $content_type =~ m|text/html|;
}

# transform and _extract_title inherited from parent

sub _extract_html
{
    my $self = shift;
    my ($raw_html) = @_;

    my $tree = HTML::ExtractMain::extract_main_html($raw_html,
                                                    output_type => 'tree' );

    if ($tree)
    {
        $self->_remove_fonts($tree);
        $self->_optionally_deactivate_links($tree);
    }

    return $tree;
}

sub _remove_fonts
{
    my ($self, $tree) = @_;

    # Remove any font attributes as they rarely work as expected on
    # eReaders - eg colours do not make sense on monochrome displays,
    # font families will probably not exist.
    for my $font ($tree->look_down(_tag => "font"))
    {
        $font->attr($_, undef) for $font->all_external_attr_names;
    }
}

sub _optionally_deactivate_links
{
    my ($self, $tree) = @_;

    # Turn links into text if option was requested.

    my $option = App::Zapzi::UserConfig::get('deactivate_links');

    if ($option && $option =~ /^Y/i)
    {
        for my $a ($tree->find_by_tag_name('a'))
        {
            my $href = $a->attr('href');
            if ($href && $href !~ /^#/)
            {
                $a->replace_with_content($a->as_text);
            }
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Transformers::HTMLExtractMain - transform text using HTMLExtractMain

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This class takes HTML and returns readable HTML using
HTML::ExtractMain. It attempts to remove text that is not part of the
main article body, eg menus or headers.

=head1 METHODS

=head2 name

Name of transformer visible to user.

=head2 handles($content_type)

Returns true if this module handles the given content-type

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
