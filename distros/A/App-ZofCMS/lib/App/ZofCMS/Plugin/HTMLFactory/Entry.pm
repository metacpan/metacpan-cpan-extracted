package App::ZofCMS::Plugin::HTMLFactory::Entry;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

sub new { bless {}, shift }

sub process {
    my ( $self, $template ) = @_;
    $template->{t}{entry_start} = <<"END";
<div class="entry">
    <div class="entry_top">
        <div class="entry_bottom">
END
    $template->{t}{entry_end} = <<"END";
        </div>
    </div>
</div>
END
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::HTMLFactory::Entry - plugin to wrap content in three divs used for styling boxes

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template file:

    plugins => [ qw/HTMLFactory::Entry/ ],

In your L<HTML::Template> template:

    <tmpl_var name='entry_start'>
        <p>Some content</p>
    <tmpl_var name='entry_end'>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. The module resides in
C<App::ZofCMS::Plugin::HTMLFactory::> namespace thus only provides some packed HTML code.

I use the HTML code provided by the plugin virtually on every site, and am sick and tired of
writing it! Hence the plugin.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/HTMLFactory::Entry/ ],

To run the plugin all you have to do is include it in the list of plugins to execute.

=head1 HTML::Template VARIABLES

    <tmpl_var name='entry_start'>
    <tmpl_var name='entry_end'>

The plugins creates two keys in C<{t}> ZofCMS Template special keys.

=head2 C<entry_start>

    <tmpl_var name='entry_start'>

The C<entry_start> will be replaced with the following HTML code:

    <div class="entry">
        <div class="entry_top">
            <div class="entry_bottom">

=head2 C<entry_end>

    <tmpl_var name='entry_end'>

The C<entry_end> will be replaced with the following HTML code:

            </div>
        </div>
    </div>

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