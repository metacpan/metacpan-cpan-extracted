package App::ZofCMS::Plugin::NavMaker;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use HTML::Template;

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my $nav = delete($template->{nav_maker}) || delete $config->conf->{nav_maker};

    return
        unless $nav;

    if ( ref $nav eq 'CODE' ) {
        $nav = $nav->( $template, $query, $config );
    }

    my $html_template
    = HTML::Template->new_scalar_ref( \ $self->_get_html_template );

    for ( @$nav ) {
        next if ref;
        $_ = [ $_ ];
    }

    $html_template->param(
        nav => [
            map +{
                text    => $_->[0],
                title   => (defined $_->[2] ? $_->[2] : "Visit $_->[0]"),
                href    => (
                    defined $_->[1] ? $_->[1] : $self->_make_href( $_->[0] )
                ),
                id      => (
                    defined $_->[3]
                    ? $_->[3]
                    : $self->_make_id( $_->[0] )
                ),
            }, @$nav
        ],
    );

    $template->{t}{nav_maker} = $html_template->output;
    return 1;
}

sub _make_href {
    my ( $self, $text ) = @_;
    $text =~ s/[\W_]/-/g;
    return lc "/$text";
}

sub _make_id {
    my ( $self, $text ) = @_;
    $text =~ s/\W/_/g;
    return lc "nav_$text";
}

sub _get_html_template {
    return <<'END';
<ul id="nav"><tmpl_loop name="nav">
        <li id="<tmpl_var escape="html" name="id">"><a href="<tmpl_var escape="html" name="href">" title="<tmpl_var escape="html" name="title">"><tmpl_var escape="html" name="text"></a></li></tmpl_loop>
</ul>
END
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::NavMaker - ZofCMS plugin for making navigation bars

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template:

    nav_maker => [
        qw/Foo Bar Baz/,
        [ qw(Home /home) ],
        [ qw(Music /music) ],
        [ qw(foo /foo-bar-baz), 'This is the title=""', 'this_is_id' ],
    ],
    plugins => [ qw/NavMaker/ ],

In your L<HTML::Template> template:

    <tmpl_var name="nav_maker">

Produces this code:

    <ul id="nav">
            <li id="nav_foo"><a href="/foo" title="Visit Foo">Foo</a></li>
            <li id="nav_bar"><a href="/bar" title="Visit Bar">Bar</a></li>
            <li id="nav_baz"><a href="/baz" title="Visit Baz">Baz</a></li>
            <li id="nav_home"><a href="/home" title="Visit Home">Home</a></li>
            <li id="nav_music"><a href="/music" title="Visit Music">Music</a></li>
            <li id="this_is_id"><a href="/foo-bar-baz" title="This is the title=&quot;&quot;">foo</a></li>
    </ul>

=head1 DESCRIPTION

The plugin doesn't do much but after writing HTML code for hundreds of
navigation bars I was fed up... and released this tiny plugin.

This documentation assumes you've read L<App::ZofCMS>,
L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/NavMaker/ ],

The obvious one is that you'd want to add C<NavMaker> into the list of
your plugins.

=head2 C<nav_maker>

    nav_maker => [
        qw/Foo Bar Baz/,
        [ qw(Home /home) ],
        [ qw(Music /music) ],
        [ qw(foo /foo-bar-baz), 'This is the title=""', 'this_is_id' ],
    ],

    nav_maker => sub {
        my ( $template, $query, $config ) = @_;

        return [
            qw/Foo Bar Baz/,
            [ qw(Home /home) ],
            [ qw(Music /music) ],
            [ qw(foo /foo-bar-baz), 'This is the title=""', 'this_is_id' ],
        ];
    }

Can be specified in either Main Config File first-level key or ZofCMS template first-level
key. If specified in both, the one in ZofCMS Template will take precedence.
Takes an arrayref or a subref as a value. If the value is a B<subref>, it must return
an arrayref, which will be processed the same way as if the returned arrayref would be
assigned to C<nav_maker> key instead of the subref (see description further). The C<@_> of
the sub will contain the following: C<$template>, C<$query> and C<$config> (in that
order), where C<$template> is the ZofCMS Template hashref, C<$query> is the query parameters
(param names are keys and values are their values) and C<$config> is the
L<App::ZofCMS::Config> object.

The elements of the arrayref (whether directly assigned or returned from the subref)
can either be strings
or arrayrefs, element which is a string is the same as an arrayref with just
that string as an element. Each of those arrayrefs can contain from one
to four elements. They are interpreted as follows:

=head3 first element

    nav_maker => [ qw/Foo Bar Baz/ ],

    # same as

    nav_maker => [
        [ 'Foo' ],
        [ 'Bar' ],
        [ 'Baz' ],
    ],

B<Mandatory>. Specifies the text to use for the link.

=head3 second element

    nav_maker => [
        [ Foo => '/foo' ],
    ],

B<Optional>. Specifies the C<href=""> attribute for the link. If not
specified will be calculated from the first element (the text for the link)
in the following way:

    $text =~ s/[\W_]/-/g;
    return lc "/$text";

=head3 third element

    nav_maker => [
        [ 'Foo', '/foo', 'Title text' ],
    ],

B<Optional>. Specifies the C<title=""> attribute for the link. If not
specified the first element (the text for the link) will be used for the
title with word C<Visit > prepended.

=head3 fourth element

    nav_maker => [
        [ 'Foo', '/foo', 'Title text', 'id_of_the_li' ]
    ],

B<Optional>. Specifies the C<id=""> attribute for the C<< <li> >> element
of this navigation bar item. If not specified will be calculated from the
first element (the text of the link) in the following way:

    $text =~ s/\W/_/g;
    return lc "nav_$text";

=head1 USED HTML::Template VARIABLES

=head2 C<nav_maker>

    <tmpl_var name="nav_maker">

Plugin sets C<nav_maker> key in C<{t}> ZofCMS template special key, to
the generated HTML code, simply stick C<< <tmpl_var name="nav_maker"> >>
whereever you wish to have your navigation.

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