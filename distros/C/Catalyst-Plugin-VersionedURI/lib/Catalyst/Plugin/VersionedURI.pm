package Catalyst::Plugin::VersionedURI;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: add version component to uris
$Catalyst::Plugin::VersionedURI::VERSION = '1.2.0';

use 5.10.0;

use strict;
use warnings;

use Moose::Role;
use URI::QueryParam;
use Path::Tiny;

our @uris;

sub initialize_uri_regex {
    my $self = shift;

    if ( not exists $self->config->{'Plugin::VersionedURI'}
         and exists $self->config->{'VersionedURI'} ) {
        warn <<'END_DEPRECATION';
Catalyst::Plugin::VersionedURI configuration set under 'VersionedURI' is deprecated
Please move your configuration to 'Plugin::VersionedURI'
END_DEPRECATION

        $self->config->{'Plugin::VersionedURI'} 
            = $self->config->{'VersionedURI'};
    }


    my $conf = $self->config->{'Plugin::VersionedURI'}{uri} 
        || '/static';

    @uris = ref($conf) ? @$conf : ( $conf );
    s#^/## for @uris;
    s#(?<!/)$#/# for @uris;

    return join '|', @uris;
}

sub versioned_uri_regex {
    my $self = shift;
    state $uris_re = $self->initialize_uri_regex;
    return $uris_re;
}

sub uri_version {
    my ( $self, $uri ) = @_;

    state $app_version = $self->VERSION;

    return $app_version 
        unless state $mtime = $self->config->{'Plugin::VersionedURI'}{mtime};
        
    state %cache;  # Would be nice to make this shared across processes

    # Return the cached value if there is one
    return $cache{$uri} if defined $cache{$uri};

    # Strip off the request base, so we can find the file referenced
    ( my $file = $uri ) =~ s/^\Q@{[ $self->req->base ]}\E//;

    # Search the include_path(s) provided in config or the
    # project root if no include_path was specified
    state $include_paths = 
        $self->config->{'Plugin::VersionedURI'}{include_path} //
        [ $self->config->{root} ];

    # Return/cache the file's mtime
    for my $path ( map { path( $_, $file ) } @$include_paths ) {
        return $cache{$uri} = $path->stat->mtime if -f $path;
    }

    # No file was found. Store and return the application's version as
    # a fallback.
    return $cache{$uri} = $app_version;
}

around uri_for => sub {
    my ( $code, $self, @args ) = @_;

    my $uri = $self->$code(@args);

    my $uris_re = $self->versioned_uri_regex
        or return $uri;

    return $uri unless $uri->path =~ m#^/($uris_re)#;

    my $version = $self->uri_version( $uri, @args );

    if ( state $in_path = $self->config->{'Plugin::VersionedURI'}{in_path} ) {
        my $path = $uri->path;
        $path =~ s#^/($uris_re)#${1}v$version/#;
        $uri->path( $path );
    } 
    else {
        state $version_name = $self->config->{'Plugin::VersionedURI'}{param} || 'v';
        $uri->query_param( $version_name => $version );
    }

    return $uri;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::VersionedURI - add version component to uris

=head1 VERSION

version 1.2.0

=head1 SYNOPSIS

In your config file:

    <Plugin::VersionedURI>
        uri   static/
        mtime 0 
    </Plugin::VersionedURI>

In C<MyApp.pm>:

   package MyApp;

   use Catalyst qw/ VersionedURI /;

In the Apache config:

    <Directory /home/myapp/static>
        ExpiresActive on
        ExpiresDefault "access plus 1 year"
    </Directory>

=head1 DESCRIPTION

C<Catalyst::Plugin::VersionedURI> adds a versioned component
to uris returned by C<uri_for()> matching a given set of regular expressions provided in
the configuration file. E.g.,

    $c->uri_for( '/static/images/foo.png' );

will, with the configuration used in the L<SYNOPSIS> return

    /static/images/foo.png?v=1.2.3

This can be useful, mainly, to have the
static files of a site magically point to a new location upon new
releases of the application, and thus bypass previously set expiration times.

The versioned component of the uri resolves to the version of the application.

=head1 CONFIGURATION

=head2 uri

The plugin's accepts any number of C<uri> configuration elements, which are 
taken as regular expressions to be matched against the uris. The regular
expressions are implicitly anchored at the beginning of the uri, and at the
end by a '/'.  If not given, defaults to C</static>.

=head2 mtime

If set to a true value, the plugin will use the file's modification time for
versioning instead of the application's version. The modification time is
checked only once for each file. If a file is changed after the application is
started, the old version number will continue to be used. Checking the
modification time on each uri, each time it is served, would result in
considerable additional overhead.

=head2 include_path

A list of directories to search for files if you specify the C<mtime> flag.
If no file is found, the application version is used.  Defaults to
C<MyApp->config->{root}>. 

=head2 in_path

If true, add the versioned element as part of the path (right after the
matched uri). If false, the versioned element is added as a query parameter.
For example, if we match on '/static', the base uri '/static/foo.png' will resolve to 
'/static/v1.2.3/foo.png' if 'in_path' is I<true>, and '/static/foo.png?v=1.2.3'
if I<false>.

Defaults to false. 

=head2 param

Name of the parameter to be used for the versioned element. Defaults to 'v'.  

Not used if I<in_path> is set to I<true>.

=head1 WEB SERVER-SIDE CONFIGURATION

Of course, the redirection to a versioned uri is a sham
to fool the browsers into refreshing their cache. If the path is
modified because I<in_path> is set to I<true>, it's typical to 
configure the front-facing web server to point back to 
the same back-end directory.

=head2 Apache

To munge the paths back to the base directory, the Apache 
configuration can look like:

    <Directory /home/myapp/static>
        RewriteEngine on
        RewriteRule ^v[0123456789._]+/(.*)$ /myapp/static/$1 [PT]
 
        ExpiresActive on
        ExpiresDefault "access plus 1 year"
    </Directory>

=head1 YOU BROKE MY DEVELOPMENT SERVER, YOU INSENSITIVE CLOD!

If I<in_path> is set to I<true>, while the plugin is working fine with a web-server front-end, it's going to seriously cramp 
your style if you use, for example, the application's standalone server, as
now all the newly-versioned uris are not going to resolve to anything. 
The obvious solution is, well, fairly obvious: remove the VersionedURI 
configuration stanza from your development configuration file.

If, for whatever reason, you absolutly want your application to deal with the versioned 
paths with or without the web server front-end, you can use
L<Catalyst::Controller::VersionedURI>, which will undo what
C<Catalyst::Plugin::VersionedURI> toiled to shoe-horn in.

=head1 THANKS

Mark Grimes, Alexander Hartmaier. 

=head1 SEE ALSO

=over

=item Blog entry introducing the module: L<http://babyl.dyndns.org/techblog/entry/versioned-uri>.

=item L<Catalyst::Controller::VersionedURI>

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
