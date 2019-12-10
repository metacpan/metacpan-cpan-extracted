package App::ZofCMS::Plugin::LinksToSpecs::CSS;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

sub new { bless {}, shift }

sub process {
    my ( $self, $template ) = @_;

    my %pseudo_classes = (
        ':focus'
        => q|http://www.w3.org/TR/CSS21/selector.html#dynamic-pseudo-classes|,
        ':hover'
        => q|http://www.w3.org/TR/CSS21/selector.html#dynamic-pseudo-classes|,
        ':visited'
        => q|http://www.w3.org/TR/CSS21/selector.html#dynamic-pseudo-classes|,
        ':active'
        => q|http://www.w3.org/TR/CSS21/selector.html#dynamic-pseudo-classes|,
        ':link'
        => q|http://www.w3.org/TR/CSS21/selector.html#dynamic-pseudo-classes|,
        ':lang'
        => q|http://www.w3.org/TR/CSS21/selector.html#lang|,
        ':first-child'
        => q|http://www.w3.org/TR/CSS21/selector.html#first-child|,
    );

    my %pseudo_elements = (
        ':before'
        => q|http://www.w3.org/TR/CSS21/selector.html#before-and-after|,
        ':after'
        => q|http://www.w3.org/TR/CSS21/selector.html#before-and-after|,
        ':first-line'
        => q|http://www.w3.org/TR/CSS21/selector.html#first-line-pseudo|,
        ':first-letter'
        => q|http://www.w3.org/TR/CSS21/selector.html#first-letter|,
    );

    my %props = (
        'background'
        => q|http://w3.org/TR/CSS21/colors.html#propdef-background|,

        'border-left-color'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-left-color|,

        'border-left-style'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-left-style|,

        'border-spacing'
        => q|http://w3.org/TR/CSS21/tables.html#propdef-border-spacing|,

        'list-style-image'
        => q|http://w3.org/TR/CSS21/generate.html#propdef-list-style-image|,

        'content'
        => q|http://w3.org/TR/CSS21/generate.html#propdef-content|,

        'vertical-align'
        => q|http://w3.org/TR/CSS21/visudet.html#propdef-vertical-align|,

        'page-break-before'
        => q|http://w3.org/TR/CSS21/page.html#propdef-page-break-before|,

        'font-size'
        => q|http://w3.org/TR/CSS21/fonts.html#propdef-font-size|,

        'border-width'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-width|,

        'counter-increment'
        => q|http://w3.org/TR/CSS21/generate.html#propdef-counter-increment|,

        'max-height'
        => q|http://w3.org/TR/CSS21/visudet.html#propdef-max-height|,

        'outline-color'
        => q|http://w3.org/TR/CSS21/ui.html#propdef-outline-color|,

        'background-color'
        => q|http://w3.org/TR/CSS21/colors.html#propdef-background-color|,

        'padding-bottom'
        => q|http://w3.org/TR/CSS21/box.html#propdef-padding-bottom|,

        'caption-side'
        => q|http://w3.org/TR/CSS21/tables.html#propdef-caption-side|,

        'height'
        => q|http://w3.org/TR/CSS21/visudet.html#propdef-height|,

        'border-top'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-top|,

        'background-attachment'
        => q|http://w3.org/TR/CSS21/colors.html#propdef-background-attachment|,

        'font-variant'
        => q|http://w3.org/TR/CSS21/fonts.html#propdef-font-variant|,

        'visibility'
        => q|http://w3.org/TR/CSS21/visufx.html#propdef-visibility|,

        'quotes'
        => q|http://w3.org/TR/CSS21/generate.html#propdef-quotes|,

        'border-collapse'
        => q|http://w3.org/TR/CSS21/tables.html#propdef-border-collapse|,

        'letter-spacing'
        => q|http://w3.org/TR/CSS21/text.html#propdef-letter-spacing|,

        'orphans'
        => q|http://w3.org/TR/CSS21/page.html#propdef-orphans|,

        'margin-bottom'
        => q|http://w3.org/TR/CSS21/box.html#propdef-margin-bottom|,

        'position'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-position|,

        'widows'
        => q|http://w3.org/TR/CSS21/page.html#propdef-widows|,

        'border-left'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-left|,

        'margin-right'
        => q|http://w3.org/TR/CSS21/box.html#propdef-margin-right|,

        'table-layout'
        => q|http://w3.org/TR/CSS21/tables.html#propdef-table-layout|,

        'border-bottom-width'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-bottom-width|,

        'font-family'
        => q|http://w3.org/TR/CSS21/fonts.html#propdef-font-family|,

        'border'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border|,

        'background-image'
        => q|http://w3.org/TR/CSS21/colors.html#propdef-background-image|,

        'font'
        => q|http://w3.org/TR/CSS21/fonts.html#propdef-font|,

        'border-bottom-style'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-bottom-style|,

        'bottom'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-bottom|,

        'border-style'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-style|,

        'counter-reset'
        => q|http://w3.org/TR/CSS21/generate.html#propdef-counter-reset|,

        'empty-cells'
        => q|http://w3.org/TR/CSS21/tables.html#propdef-empty-cells|,

        'border-left-width'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-left-width|,

        'border-top-color'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-top-color|,

        'white-space'
        => q|http://w3.org/TR/CSS21/text.html#propdef-white-space|,

        'background-position'
        => q|http://w3.org/TR/CSS21/colors.html#propdef-background-position|,

        'word-spacing'
        => q|http://w3.org/TR/CSS21/text.html#propdef-word-spacing|,

        'page-break-after'
        => q|http://w3.org/TR/CSS21/page.html#propdef-page-break-after|,

        'border-color'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-color|,

        'line-height'
        => q|http://w3.org/TR/CSS21/visudet.html#propdef-line-height|,

        'speak-header'
        => q|http://w3.org/TR/CSS21/tables.html#propdef-speak-header|,

        'width'
        => q|http://w3.org/TR/CSS21/visudet.html#propdef-width|,

        'clear'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-clear|,

        'padding'
        => q|http://w3.org/TR/CSS21/box.html#propdef-padding|,

        'cursor'
        => q|http://w3.org/TR/CSS21/ui.html#propdef-cursor|,

        'float'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-float|,

        'border-right-color'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-right-color|,

        'padding-left'
        => q|http://w3.org/TR/CSS21/box.html#propdef-padding-left|,

        'max-width'
        => q|http://w3.org/TR/CSS21/visudet.html#propdef-max-width|,

        'top'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-top|,

        'padding-right'
        => q|http://w3.org/TR/CSS21/box.html#propdef-padding-right|,

        'font-style'
        => q|http://w3.org/TR/CSS21/fonts.html#propdef-font-style|,

        'outline'
        => q|http://w3.org/TR/CSS21/ui.html#propdef-outline|,

        'border-right-style'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-right-style|,

        'font-weight'
        => q|http://w3.org/TR/CSS21/fonts.html#propdef-font-weight|,

        'min-width'
        => q|http://w3.org/TR/CSS21/visudet.html#propdef-min-width|,

        'border-top-width'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-top-width|,

        'text-align'
        => q|http://w3.org/TR/CSS21/text.html#propdef-text-align|,

        'outline-style'
        => q|http://w3.org/TR/CSS21/ui.html#propdef-outline-style|,

        'border-top-style'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-top-style|,

        'color'
        => q|http://w3.org/TR/CSS21/colors.html#propdef-color|,

        'margin'
        => q|http://w3.org/TR/CSS21/box.html#propdef-margin|,

        'left'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-left|,

        'direction'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-direction|,

        'text-decoration'
        => q|http://w3.org/TR/CSS21/text.html#propdef-text-decoration|,

        'unicode-bidi'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-unicode-bidi|,

        'background-repeat'
        => q|http://w3.org/TR/CSS21/colors.html#propdef-background-repeat|,

        'right'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-right|,

        'border-bottom-color'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-bottom-color|,

        'overflow'
        => q|http://w3.org/TR/CSS21/visufx.html#propdef-overflow|,

        'page-break-inside'
        => q|http://w3.org/TR/CSS21/page.html#propdef-page-break-inside|,

        'margin-top'
        => q|http://w3.org/TR/CSS21/box.html#propdef-margin-top|,

        'outline-width'
        => q|http://w3.org/TR/CSS21/ui.html#propdef-outline-width|,

        'margin-left'
        => q|http://w3.org/TR/CSS21/box.html#propdef-margin-left|,

        'border-right-width'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-right-width|,

        'min-height'
        => q|http://w3.org/TR/CSS21/visudet.html#propdef-min-height|,

        'text-transform'
        => q|http://w3.org/TR/CSS21/text.html#propdef-text-transform|,

        'text-indent'
        => q|http://w3.org/TR/CSS21/text.html#propdef-text-indent|,

        'list-style'
        => q|http://w3.org/TR/CSS21/generate.html#propdef-list-style|,

        'padding-top'
        => q|http://w3.org/TR/CSS21/box.html#propdef-padding-top|,

        'border-bottom'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-bottom|,

        'z-index'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-z-index|,

        'border-right'
        => q|http://w3.org/TR/CSS21/box.html#propdef-border-right|,

        'display'
        => q|http://w3.org/TR/CSS21/visuren.html#propdef-display|,
    );

    keys %props;
    while ( my ($name, $link ) = each %props ) {
        my $link_start
        = qq|<a href="$link" title="CSS Specification: '$name\' property">|;

        @{ $template->{t} }{
            "css_$name",
            "css_${name}_p",
            "css_${name}_c",
            "css_${name}_cp",
        } = (
            $link_start . "<code>$name</code></a>",
            $link_start . "<code>$name</code> property</a>",
            $link_start . "$name</a>",
            $link_start . "$name property</a>",
        );
    }

    keys %pseudo_elements;
    while ( my ($name, $link ) = each %pseudo_elements ) {
        my $link_start
        = qq|<a href="$link" title="CSS Specification: '$name\' pseudo-element">|;

        @{ $template->{t} }{
            "css_$name",
            "css_${name}_p",
            "css_${name}_c",
            "css_${name}_cp",
        } = (
            $link_start . "<code>$name</code></a>",
            $link_start . "<code>$name</code> pseudo-element</a>",
            $link_start . "$name</a>",
            $link_start . "$name pseudo-element</a>",
        );
    }

    keys %pseudo_classes;
    while ( my ($name, $link ) = each %pseudo_classes ) {
        my $link_start
        = qq|<a href="$link" title="CSS Specification: '$name\' pseudo-class">|;

        @{ $template->{t} }{
            "css_$name",
            "css_${name}_p",
            "css_${name}_c",
            "css_${name}_cp",
        } = (
            $link_start . "<code>$name</code></a>",
            $link_start . "<code>$name</code> pseudo-class</a>",
            $link_start . "$name</a>",
            $link_start . "$name pseudo-class</a>",
        );
    }
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::LinksToSpecs::CSS - easily include links to properties in CSS2.1 specification

=head1 SYNOPSIS

In your ZofCMS template:

    plugins => [ qw/LinksToSpecs::CSS/ ],

In your L<HTML::Template> template:

    See: <tmpl_var name="css_text-align"> for text-align property<br>
    See: <tmpl_var name="css_display"> for display propery<br>
    <tmpl_var name="css_float_p"> is quite neat

=head1 DESCRIPTION

The module is a plugin for ZofCMS which allows you to easily link to
CSS properties in CSS2.1 specification. Personally, I use it when writing
my tutorials, hopefully it will be useful to someone else as well.

=head1 ZofCMS TEMPLATE

    plugins => [ qw/LinksToSpecs::CSS/ ],

The only thing you'd need in your ZofCMS template is to add the plugin
into the list of plugins to execute.

=head1 HTML::Template TEMPLATE

    See: <tmpl_var name="css_text-align"> for text-align property<br>
    See: <tmpl_var name="css_display"> for display propery<br>
    <tmpl_var name="css_float_p"> is quite neat

To include links to CSS properties in your HTML code you'd use
C<< <tmpl_var name=""> >>. The plugin provides four "styles" of links which
are presented below. The C<PROP> stands for any CSS property specified in
CSS2.1 specification, C<LINK> stands for the link pointing to the
explaination of the given property in CSS specification. B<Note:>
everything needs to be lowercased:

    <tmpl_var name="css_PROP">
    <a href="LINK" title="CSS Specification: 'PROP' property"><code>PROP</code></a>

    <tmpl_var name="css_PROP_p">
    <a href="LINK" title="CSS Specification: 'PROP' property"><code>PROP</code> property</a>

    <tmpl_var name="css_PROP_c">
    <a href="LINK" title="CSS Specification: 'PROP' property">PROP</a>

    <tmpl_var name="css_PROP_cp">
    <a href="LINK" title="CSS Specification: 'PROP' property">PROP property</a>

The plugin also has links for C<:after>, C<:hover>, etc. pseudo-classes and pseudo-elements;
in this case, the rules are the same except in the output word "property" would say
"pseudo-class" or "pseudo-element".

=head1 SEE ALSO

L<http://w3.org/Style/CSS/>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut