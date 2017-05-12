package App::ZofCMS::Plugin::Doctypes;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my %conf = (
        %{ delete $config->conf->{plugin_doctype} || {} },
        %{ delete $template->{plugin_doctype}     || {} },
    );

    my $t = $template->{t};

    $t->{'doctype HTML 4.01 Strict'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" |
        . q|"http://www.w3.org/TR/html4/strict.dtd">|;

    $t->{'doctype HTML 4.01 Transitional'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" |
        . q|"http://www.w3.org/TR/html4/loose.dtd">|;

    $t->{'doctype HTML 4.01 Frameset'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" |
        . q|"http://www.w3.org/TR/html4/frameset.dtd">|;

    $t->{'doctype XHTML 1.0 Strict'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" |
        . q|"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">|;

    $t->{'doctype XHTML 1.0 Transitional'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" |
        . q|"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">|;

    $t->{'doctype XHTML 1.0 Frameset'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" |
        . q|"http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">|;

    $t->{'doctype XHTML 1.1'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" |
        . q|"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">|;

    $t->{'doctype HTML5'}
    = q|<!DOCTYPE html>|;

    return 1
        unless $conf{extra};

    $t->{'doctype XHTML Basic 1.0'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.0//EN" |
        . q|"http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd">|;

    $t->{'doctype XHTML Basic 1.1'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" |
        . q|"http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">|;

    $t->{'doctype HTML 2.0'}
    = q|<!DOCTYPE html PUBLIC "-//IETF//DTD HTML 2.0//EN">|;

    $t->{'doctype HTML 3.2'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">|;

    $t->{'doctype MathML 1.01'}
    = q|<!DOCTYPE math SYSTEM "http://www.w3.org/Math/DTD/mathml1/mathml.dtd">|;

    $t->{'doctype MathML 2.0'}
    = q|<!DOCTYPE math PUBLIC "-//W3C//DTD MathML 2.0//EN" |
        . q|"http://www.w3.org/TR/MathML2/dtd/mathml2.dtd">|;

    $t->{'doctype XHTML + MathML + SVG'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN" |
        . q|"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">|;

    $t->{'doctype SVG 1.0'}
    = q|<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" |
        . q|"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">|;

    $t->{'doctype SVG 1.1 Full'}
    = q|<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" |
        . q|"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">|;

    $t->{'doctype SVG 1.1 Basic'}
    = q|<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" |
        . q|"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">|;

    $t->{'doctype SVG 1.1 Tiny'}
    = q|<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Tiny//EN" |
        . q|"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-tiny.dtd">|;

    $t->{'doctype XHTML + MathML + SVG Profile (XHTML as the host language)'}
    = q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN" |
        . q|"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">|;

    $t->{'doctype XHTML + MathML + SVG Profile (Using SVG as the host)'}
    = q|<!DOCTYPE svg:svg PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN" |
        . q|"http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg.dtd">|;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::Doctypes - include DOCTYPEs in your pages without remembering how to spell them

=head1 SYNOPSIS

In your Main Config file:

    template_defaults => {
        plugins => [ qw/Doctypes/ ],
    },

In your L<HTML::Template> files

    <tmpl_var name="doctype HTML 4.01 Strict">

=head1 DESCRIPTION

If you are like me you definitely don't remember how to properly spell out the DOCTYPE (DOCument TYPE definition) in your pages and always rely on your editor or look it up. Well,
fear no more! This little module contains all the common DTDs and will stuff them into C<{t}>
ZofCMS template's special key for you to use.

=head1 AVAILABLE DTDs

Below are examples of C<< <tmpl_var name=""> >> that will be substituted into the actual
doctypes. The names of the doctypes correspoding to each of those examples are self
explanatory. B<Note:> the plugin has two modes (for now). The I<basic> mode is the default
one, it will make only DTDs available under C<BASIC> section. The I<extra> mode will include
more doctypes.

=head1 ENABLING 'EXTRA' MODE

B<To enable the extra mode>: in your ZofCMS template, but most likely you'd want that in your
main config file:

    plugin_doctype => { extra => 1 },

This would be the first-level key in ZofCMS template as well as main config file.

=head1 'BASIC' MODE DTDs

    <tmpl_var name="doctype HTML 4.01 Strict">
    <tmpl_var name="doctype HTML 4.01 Transitional">
    <tmpl_var name="doctype HTML 4.01 Frameset">
    <tmpl_var name="doctype XHTML 1.0 Strict">
    <tmpl_var name="doctype XHTML 1.0 Transitional">
    <tmpl_var name="doctype XHTML 1.0 Frameset">
    <tmpl_var name="doctype XHTML 1.1">
    <tmpl_var name="doctype HTML5">

=head1 'EXTRA' MODE DTDs

    <tmpl_var name="doctype XHTML Basic 1.0">
    <tmpl_var name="doctype XHTML Basic 1.1">
    <tmpl_var name="doctype HTML 2.0">
    <tmpl_var name="doctype HTML 3.2">
    <tmpl_var name="doctype MathML 1.01">
    <tmpl_var name="doctype MathML 2.0">
    <tmpl_var name="doctype XHTML + MathML + SVG">
    <tmpl_var name="doctype SVG 1.0">
    <tmpl_var name="doctype SVG 1.1 Full">
    <tmpl_var name="doctype SVG 1.1 Basic">
    <tmpl_var name="doctype SVG 1.1 Tiny">
    <tmpl_var name="doctype XHTML + MathML + SVG Profile (XHTML as the host language)">
    <tmpl_var name="doctype XHTML + MathML + SVG Profile (Using SVG as the host)">

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