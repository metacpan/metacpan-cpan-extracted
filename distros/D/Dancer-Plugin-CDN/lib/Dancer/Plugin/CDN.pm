package Dancer::Plugin::CDN;
$Dancer::Plugin::CDN::VERSION = '1.002';
use warnings;
use strict;

use Dancer ':syntax';
use Dancer::Plugin;
use HTTP::CDN;
use HTTP::Date;


use constant EXPIRES => 315_576_000;  # approx 10 years


my $cdn;


register cdn_url => sub {
    my($path) = @_;

    $cdn ||= _init_cdn();
    return $cdn->resolve($path);
};


sub _send_cdn_content {
    $cdn ||= _init_cdn();
    my ($uri, $hash) = $cdn->unhash_uri(splat);

    my $info = eval { $cdn->fileinfo($uri) };

    unless ( $info and $info->{hash} eq $hash ) {
        status 'not_found';
        return 'Not Found';
    }

    status( 200 );
    content_type( $info->{mime}->type );
    header('Last-Modified'  => HTTP::Date::time2str($info->{stat}->mtime));
    header('Expires'        => HTTP::Date::time2str(time + EXPIRES));
    header('Cache-Control'  => 'max-age=' . EXPIRES . ', public');
    return $cdn->filedata($uri);

}


sub _init_cdn {
    my $setting = plugin_setting();

    my $base = $setting->{base} || '/cdn/';
    my $root = $setting->{root} || setting('public') || 'public';

    die "CDN root directory does not exist: '$root'\n" unless -d $root;

    my %args = (
        root => $root,
        base => $base,
    );

    if( my $plugins = $setting->{plugins} ) {
        $args{plugins} = $plugins;
    }

    return HTTP::CDN->new( %args );
}


{   # Set up route handler to serve responses to rewritten URLS

    my $base = plugin_setting->{base} || '/cdn/';
    my($prefix) = $base =~ m{^(?:https?://[^/]+)?(.*)$};
    my $route = qr/${prefix}(.*)$/;

    get $route => \&_send_cdn_content;
}


hook 'before_template_render' => sub {
    my $tokens = shift;
    $tokens->{'cdn_url'}  = \&cdn_url;
};


register_plugin;

1;


=head1 NAME

Dancer::Plugin::CDN - Serve static files with unique URLs and far-future expiry


=head1 SYNOPSIS

  use Dancer::Plugin::CDN;

  # Generate a CDN URL for a static file

  my $style_sheet = cdn_url('css/style.css'); #  e.g.: "/cdn/css/style.B97EA317759D.css"

  # Or, in a TT2 template:

  <link rel="stylesheet" href="[% cdn_url('css/style.css') %]" >

=head1 DESCRIPTION

This plugin generates URLs for your static files that include a content hash so
that the URLs will change when the content changes.  The plugin also arranges
for the files to be served with cache-control and expiry headers to enable the
content to be cached by the browser.

The real work is performed by the L<HTTP::CDN> module which can also be
configured with plugins to minify CSS/JS on-the-fly and also to render LESS to
CSS.


=head1 FUNCTIONS

A single helper function is exported into the caller's namespace.  This
function is also made available to be called from within your TT2 templates
(probably won't work with other template engines).

=head2 cdn_url

Takes a pathname to a static file (e.g.: C<css/style.css>) and returns a URL
with content-hash and configurable CDN prefix added (e.g.:
C</cdn/css/style.B97EA317759D.css>);


=head1 CONFIGURATION

You do not need to configure this module although you may choose to add a
section like this to your Dancer config file:

  plugins:
    CDN:
      root: "static"
      base: "/cdn/"
      plugins:
        - "CSS"
        - "CSS::Minifier::XS"

The C<root> setting defines where the static source files can be found.  By
default this points to Dancer's standard C<public> directory.

The C<base> setting is the prefix which will be added to each URL.  The default
value is C</cdn/>.  The plugin will also use this prefix to set up a route
handler for serving the static content.  This setting can include a hostname
e.g.:

    base: "http://static.example.com/cdn/"

The C<plugins> setting should be an array of HTTP::CDN plugin names.  The
default setting is to enable only the HTTP::CDN::CSS plugin which rewrites
URLs (e.g.: for image files) to the CDN scheme.


=head1 SUPPORT

=over 4

=item * Bug reports and feature requests

L<https://github.com/grantm/Dancer-Plugin-CDN/issues>

=item * Source Code Repository

L<http://github.com/grantm/Dancer-Plugin-CDN/>

=back


=head1 COPYRIGHT AND LICENSE

Copyright 2012 Grant McLean C<< <grantm@cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;

