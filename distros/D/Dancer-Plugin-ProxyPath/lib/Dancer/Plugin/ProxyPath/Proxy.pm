package Dancer::Plugin::ProxyPath::Proxy;

use warnings;
use strict;
use Carp;
use URI;

=head1 NAME

Dancer::Plugin::ProxyPath::Proxy - Provides user-perspective paths

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This object provides the method uri_for to provide
user perspective paths. See L<Dancer::Plugin::ProxyPath>

    use Dancer::Plugin::ProxyPath;

    my $external_path = proxy->uri_for("/path/to/elsewhere");
    # http://public.server.com/dancer-app/path/to/elsewhere
    ...

    # and in your templates: (assuming a passed variable $background)

    <body style="background-image: url('<% proxy.uri_for(background) %>')">
    </body>

If no proxy information is found, proxy->path and proxy->uri for will 
return the same paths as request->path an request->uri_for, making it work
in development as well.

=head1 METHODS

=head2 uri_for( path, parameters )

Returns a fully qualified url for a path, as seen by the user.

=cut

my $base_header = "request-base";

sub uri_for {
    my $self = shift;
    my $destination = shift || Dancer::request->path;
    my $parameters = shift || {};
    ref $parameters eq 'HASH' or croak q/Usage: proxy->uri_for($path, \%parameters)/;
    my $base = Dancer::request->header($self->{base_header});
    my $host = Dancer::request->header("x-forwarded-host");
    my $scheme = Dancer::request->env->{"psgi.url_scheme"};
    if ($host) {
        my $uri = URI->new;
        $uri->scheme($scheme);
        $uri->authority($host);
        my $path = '';
        $path .= $base if ($base);
        unless ($self->is_absolute($destination)) {
            $path .= Dancer::request->path;
            $path .= '/' unless ($path =~ m{/$});
        }
        $path .= $destination;
        $uri->path($path || '/');
        if (%$parameters) {
            $uri->query_form($parameters);
        }
        return $uri->canonical;
    } else {
        return Dancer::request->uri_for($destination, $parameters);
    }
}

=head2 secure_uri_for( path, parameters )

Returns a fully qualified url for a path, as seen by the user, 
with the scheme set to https.

=cut

sub secure_uri_for {
    my $self = shift;
    my $uri = $self->uri_for(@_);
    $uri->scheme("https");
    return $uri;
}

=head2 instance

Returns a singleton instance of this class

=cut

my $instance;
sub instance {
    my $class = shift;
    my $header = shift || $base_header;
    unless ($instance) {
        $instance = bless {base_header => $header}, $class;
    }
    return $instance;
}

=head2 is_absolute 

Determines whether the path passed to it is absolute by 
whether or not it has a leading slash

=cut

sub is_absolute {
    my $self = shift;
    my $path = shift;
    
    if ($path =~ m{^/}) {
        return 1;
    };
    return 0;
}

=head1 AUTHOR

Alex Kalderimis, C<< <alex kalderimis at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-proxypath at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-ProxyPath>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::ProxyPath::Proxy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-ProxyPath>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-ProxyPath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-ProxyPath>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-ProxyPath/>

=back

=head1 ACKNOWLEDGEMENTS

Dancer obviously, for being a great way to write a web-app.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alex Kalderimis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer::Plugin::ProxyPath::Proxy
