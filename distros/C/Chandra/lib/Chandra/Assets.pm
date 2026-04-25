package Chandra::Assets;

use strict;
use warnings;

# Load XS functions from Chandra bootstrap
use Chandra ();

our $VERSION = '0.24';

1;

__END__

=head1 NAME

Chandra::Assets - Asset bundling and resource loading for Chandra apps

=head1 SYNOPSIS

    use Chandra::Assets;

    my $assets = Chandra::Assets->new(
        root   => 'assets/',       # Base directory
        prefix => 'app',           # URL prefix: app://asset/path
    );

    # Register with app (sets up protocol handler)
    $assets->mount($app);

    # Now in HTML — use data-href / data-src to avoid console
    # "unsupported URL" warnings from the native resource loader:
    # <link rel="stylesheet" data-href="app://css/style.css">
    # <script data-src="app://js/main.js"></script>
    # <img data-src="app://images/logo.png">
    #
    # Plain href/src also work but the browser logs a harmless error
    # before the JS interception replaces the element.

    # Inline assets directly
    my $css_tag = $assets->inline_css('css/style.css');
    # Returns: <style>...contents...</style>

    my $js_tag = $assets->inline_js('js/main.js');
    # Returns: <script>...contents...</script>

    my $img_tag = $assets->inline_image('images/logo.png');
    # Returns: <img src="data:image/png;base64,...">

    # Bundle multiple files
    my $bundle = $assets->bundle(
        css => ['css/reset.css', 'css/style.css'],
        js  => ['js/utils.js', 'js/main.js'],
    );
    # $bundle->{css} => '<style>...combined...</style>'
    # $bundle->{js}  => '<script>...combined...</script>'

    # List available assets
    my @files = $assets->list;
    my @css   = $assets->list('*.css');

    # Read asset content
    my $content = $assets->read('css/style.css');

    # Check existence
    if ($assets->exists('images/logo.png')) { ... }

=head1 DESCRIPTION

Serve local CSS, JS, images, and fonts from a directory via custom protocol.
Uses L<Chandra::Protocol> internally to register the asset scheme. Path
traversal attacks are blocked.

=head1 METHODS

=head2 new

    my $assets = Chandra::Assets->new(
        root   => 'assets/',    # required
        prefix => 'app',        # default: 'asset'
        app    => $app,         # optional, can pass to mount() instead
    );

=head2 root

Returns the asset root directory.

=head2 prefix

Returns the URL prefix (scheme name).

=head2 mount

    $assets->mount($app);

Register the asset protocol with a Chandra app. After mounting,
C<< prefix://path >> URLs in the webview will serve files from the
root directory.  The injected JavaScript transparently intercepts
C<< <link> >>, C<< <script> >>, C<< <img> >>, and C<fetch()> calls
for the registered scheme.

Use C<data-href> / C<data-src> attributes instead of plain C<href> /
C<src> to prevent the browser's native loader from logging a
C<"Failed to load resource: unsupported URL"> warning:

    <link rel="stylesheet" data-href="app://css/style.css">
    <script data-src="app://js/main.js"></script>
    <img data-src="app://images/logo.png">

=head2 read

    my $content = $assets->read('css/style.css');

Read an asset file's content. Croak on path traversal attempts.

=head2 exists

    if ($assets->exists('images/logo.png')) { ... }

Check if an asset file exists.

=head2 list

    my @all = $assets->list;
    my @css = $assets->list('*.css');

List asset files, optionally filtered by a simple glob pattern.

=head2 mime_type

    my $mime = $assets->mime_type('style.css');  # 'text/css'

Returns the MIME type for a given filename.

=head2 inline_css

    my $tag = $assets->inline_css('css/style.css');
    # <style>...contents...</style>

=head2 inline_js

    my $tag = $assets->inline_js('js/main.js');
    # <script>...contents...</script>

=head2 inline_image

    my $tag = $assets->inline_image('images/logo.png');
    # <img src="data:image/png;base64,...">

=head2 bundle

    my $result = $assets->bundle(
        css => ['reset.css', 'style.css'],
        js  => ['utils.js', 'main.js'],
    );
    # $result->{css} => '<style>...combined...</style>'
    # $result->{js}  => '<script>...combined...</script>'

=head1 SECURITY

Path traversal is prevented: C<..>, absolute paths, backslashes, and
null bytes are all rejected.

=head1 DEPENDENCIES

L<File::Raw>, L<MIME::Base64> (core), L<Chandra::Protocol>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
