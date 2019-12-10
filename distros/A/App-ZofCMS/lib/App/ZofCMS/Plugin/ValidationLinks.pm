package App::ZofCMS::Plugin::ValidationLinks;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

sub new { bless {}, }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    my %conf = (
        html_text   => 'Valid HTML 4.01 Strict',
        css_text    => 'Valid CSS',
        xhtml       => 0,
        %{ delete $config->conf->{plug_val_links} || {} },
        %{ delete $template->{plug_val_links}     || {} },
    );

    my $code = $conf{xhtml} ? 'XHTML' : 'HTML';

    $template->{t}{val_link_html} = qq|<a href="http://validator.w3.org/check?uri=referer"|
        . qq| title="Validate $code code on this page">$conf{html_text}</a>|;

    $template->{t}{val_link_css} =
        qq|<a href="http://jigsaw.w3.org/css-validator/check/referer"|
        . qq| title="Validate CSS code on this page">$conf{css_text}</a>|;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::ValidationLinks - plugin for people with bad memory to include Valid HTML/Valid CSS links pointing to validators

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template file:

    plugins => [ qw/ValidationLinks/ ]

In your L<HTML::Template> template:

    <tmpl_var name="val_link_html">
    <tmpl_var name="val_link_css">

Produced HTML code:

    <a href="http://validator.w3.org/check?uri=referer" title="Validate HTML code on this page">Valid HTML 4.01 Strict</a>
    <a href="http://jigsaw.w3.org/css-validator/check/referer" title="Validate CSS code on this page">Valid CSS</a>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It's pretty useless unless you are like me: have
a really bad memory on URIs and sick and tired of looking up all those links. The links are
L<http://validator.w3.org/check?uri=referer> for (X)HTML and
L<http://jigsaw.w3.org/css-validator/check/referer> for CSS.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plug_val_links>

    plug_val_links => {
        html_text   => 'Valid HTML 4.01 Strict',
        css_text    => 'Valid CSS',
        xhtml       => 0,
    },

B<Optional>. The plugin takes its configuration via a hashref assigned to a
C<plug_val_links> first-level key in either Main Config File or ZofCMS Template. As opposed
to many other plugins, this plugin will still execute even if the C<plug_val_links> key
is not present; as long as you include the plugin in the list of plugins to execute.
Possible keys/values of C<plug_val_links> hashref are as follows:

=head3 C<html_text>

    plug_val_links => {
        html_text   => 'Valid HTML 4.01 Strict',
    }

B<Optional>. Specifies the text for the "validate (X)HTML" link. B<Defaults to:>
C<Valid HTML 4.01 Strict>

=head3 C<css_text>

    plug_val_links => {
        css_text    => 'Valid CSS',
    },

B<Optional>. Specifies the text for the "validate CSS" link. B<Defaults to:> C<Valid CSS>

=head3 C<xhtml>

    plug_val_links => {
        xhtml       => 0,
    },

B<Optional>. Pretty much the only purpose of this argument is for the C<title="">
attribute of the "validate (X)HTML" link. Takes either true or false values.
When set to a true value the link will have
C<title="Validate XHTML code on this page">, when set to a false value
the link will have C<title="Validate HTML code on this page">. B<Defaults to:> C<0> (false)

=head1 HTML::Template VARIABLES

    <tmpl_var name="val_link_html">
    <tmpl_var name="val_link_css">

The plugin will set two keys in C<{t}> special keys, thus you'll have two
L<HTML::Template> variables to use:

=head2 C<val_link_html>

    <tmpl_var name="val_link_html">

Will contain the link to HTML validator to validate the current page.

=head2 C<val_link_css>

    <tmpl_var name="val_link_css">

Will contain the link to CSS validator to validate the current page.

=head1 NOTES ON TESTING

The W3C validator cannot validate pages that are not publicly accessible, i.e. (possibly) your
development server; thus clicking the links from your local version of site will make
the validator error out.

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