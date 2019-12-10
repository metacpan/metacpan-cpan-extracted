package App::ZofCMS::Plugin::TOC;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use HTML::Template;

sub new { return bless {}, shift; }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    return
        unless $template->{page_toc};

    my $html = <<"END_HTML";
   <ul class="page_toc">
    <tmpl_loop name="toc">\t<li<tmpl_if name="class"> class="<tmpl_var name="class">"</tmpl_if>><a href="<tmpl_var name="url">"><tmpl_var name="name"></a></li>
    </tmpl_loop></ul>
END_HTML

    my $t = HTML::Template->new_scalar_ref( \$html );
    $t->param(
        toc => [
            map +{
                url     => $_->[0],
                name    => $_->[1],
                class   => $_->[2],
            }, map $self->_make_entry, @{ delete $template->{page_toc} },
        ],
    );

    $template->{t}{page_toc} = $t->output;

    return;
}

sub _make_entry {
    if ( not ref or @$_ == 1 ) {
        $_ = [ $_ ] unless ref;

        my $name = $_->[0];
        $name =~ s/^#//;
        $name = ucfirst $name;
        $name =~ s/[-_](.)/ \u$1/g;
        $_->[1] = $name;
    }
    return $_;
}


1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::TOC - Table of Contents building plugin for ZofCMS

=head1 SYNOPSIS

In your ZofCMS template, or in your main config file (under
C<template_defaults> or C<dir_defaults>):

    page_toc    => [
        qw/
            #overview
            #beginning
            #something_else
            #conclusion
        /,
    ],
    plugins     => [ qw/TOC/ ],

    # OR

    page_toc    => [
        [ qw/#overview Overview class_overview/ ],
        [ qw/#beginning Beginning/ ],
        qw/
            #something_else
            #conclusion
        /,
    ],
    plugins     => [ qw/TOC/ ],

In your L<HTML::Template> template:

    <tmpl_var name="page_toc">

=head1 DESCRIPTION

This plugin provides means to generate "table of contents" lists. For
example, the second example in the SYNOPSIS would replace
C<< <tmpl_var name="page_toc"> >> with this:

    <ul class="page_toc">
        <li class="class_overview"><a href="#overview">Overview</a></li>
        <li><a href="#beginning">Beginning</a></li>
        <li><a href="#something_else">Something Else</a></li>
        <li><a href="#conclusion">Conclusion</a></li>
    </ul>

=head1 HOW TO USE

Aside from sticking C<TOC> in your arrayref of plugins in your
ZofCMS template (C<< plugins => [ qw/TOC/ ] >>) and placing
C<< <tmpl_var name="page_toc"> >> in your L<HTML::Template> template
you also need to create
a C<page_toc> first level key in ZofCMS template. That key's value is an
arrayref each element of which can be either an arrayref or a scalar.
B<If the element is a scalar it is the same as it being an arrayref with one
element>. The element which is an arrayref can contain either one, two or
three elements itself. Which represent the following:

=head2 arrayref which contains only one element

    page_toc => [
        '#foo',
        '#bar-baz',
    ],

    # OR

    page_toc => [
        [ '#foo' ],
        [ '#bar-baz' ],
    ],

The first (and only) element will be used in C<href=""> attribute
of the generated link. The text of the link will be determined
automatically, in particular the C<'#'> will be removed, first letter
will be capitalized and any dashes C<'-'> or underscores C<'_'> will
be replaced by a space with the letter following them capitalized. The
example above will place the following code in
C<< <tmpl_var name="page_toc"> >>:

    <ul class="page_toc">
        <li><a href="#foo">Foo</a></li>
        <li><a href="#bar-baz">Bar Baz</a></li>
    </ul>

=head2 arrayref which contains two elements

    page_toc => [
        [ '#foo', 'Foos Lots of Foos!' ],
        [ '#bar-baz', 'Bar-baz' ],
    ],

The first element will be used in C<href=""> attribute
of the generated link. The second element will be used as text for the
link. The example above will generate the following code:

    <ul class="page_toc">
        <li><a href="#foo">Foos Lots of Foos!</a></li>
        <li><a href="#bar-baz">Bar-baz</a></li>
    </ul>

=head2 arrayref which contains three elements

    page_toc => [
        [ '#foo', 'Foos Lots of Foos!', 'foos' ],
        [ '#bar-baz', 'Bar-baz', 'bars' ],
    ],

The first element will be used in C<href=""> attribute
of the generated link. The second element will be used as text for the
link. The third elemenet will be used to create a C<class=""> attribute
on the C<< <li> >> element for the corresponding entry.
The example above will generate the following code:

    <ul class="page_toc">
        <li class="foos"><a href="#foo">Foos Lots of Foos!</a></li>
        <li class="bars"><a href="#bar-baz">Bar-baz</a></li>
    </ul>

Note: the class of the C<< <ul> >> element is always C<page_toc>

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