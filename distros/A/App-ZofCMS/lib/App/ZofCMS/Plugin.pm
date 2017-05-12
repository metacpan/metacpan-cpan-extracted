package App::ZofCMS::Plugin;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin - documentation for ZofCMS plugin authors

=head1 SYNOPSIS

    package App::ZofCMS::Plugins::QueryToTemplate;

    use strict;
    use warnings;

    sub new { bless {}, shift; }

    sub process {
        my ( $self, $template, $query, $config ) = @_;

        keys %$query;
        while ( my ( $key, $value ) = each %$query ) {
            $template->{t}{"query_$key"} = $value;
        }

        return;
    }

    1;
    __END__

    PLEASE INCLUDE DECENT PLUGIN DOCUMENTATION

=head1 DESCRIPTION

This documentation is intended for ZofCMS plugin authors, whether you are
coding a plugin for personal use or planning to upload to CPAN. Uploads
are more than welcome.

First of all, the plugin must be located in App::ZofCMS::Plugin:: namespace.

At the very least the plugin must contain to subs:

    sub new { bless {}, shift }

This is a constructor, you don't have to use a hashref for the object but
it's recommended. Currently no arguments (except a class name) are passed
to C<new()> but that may be changed in the future.

Second required sub is C<sub process {}> the C<@_> will contain the
following (in this order):

    $self     -- object of your plugin
    $template -- hashref which is ZofCMS template, go nuts
    $query    -- hashref containing query parameters as keys/values
    $config   -- App::ZofCMS::Config object, from here you can obtain
                 a CGI object via C<cgi()> method.

Return value is discarded.

Normally a plugin would take user input from ZofCMS template hashref.
If you are using anything outside the C<d> key (as described in
L<App::ZofCMS::Template> please C<delete()> the key from ZofCMS template.

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