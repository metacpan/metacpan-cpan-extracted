package App::ZofCMS::PluginBundle::Naughty;

use strict;
use warnings;

our $VERSION = '1.001002'; # VERSION

q|
Programming is 10% science, 20% ingenuity, and 70% getting the
ingenuity to work with the science
|;

__END__

=encoding utf8

=for stopwords captchas

=head1 NAME

App::ZofCMS::PluginBundle::Naughty - a collection of ZofCMS plugins that are troublesome to install

=head1 DESCRIPTION

This distribution contains L<App::ZofCMS> plugins that are difficult to
install, because they required C libraries to be installed, or
need some extra resources to be downloaded during the install.
These are the plugins available in this bundle:

=over 4

=item * L<App::ZofCMS::Plugin::Captcha> utilize security images (captchas)

=item * L<App::ZofCMS::Plugin::ImageGallery> CRUD-like plugin for managing images

=item * L<App::ZofCMS::Plugin::ImageResize> Plugin to resize images

=item * L<App::ZofCMS::Plugin::RandomPasswordGenerator> easily generate random passwords with an option to use md5_hex from Digest::MD5 on them

=item * L<App::ZofCMS::Plugin::Search::Indexer> plugin that incorporates L<Search::Indexer> module's functionality

=back

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS-PluginBundle-Naughty at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut