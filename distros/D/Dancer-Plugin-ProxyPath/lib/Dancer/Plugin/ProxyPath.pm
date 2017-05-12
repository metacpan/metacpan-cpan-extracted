package Dancer::Plugin::ProxyPath;

use warnings;
use strict;
use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::ProxyPath::Proxy;

=head1 NAME

Dancer::Plugin::ProxyPath - Provides user-perspective paths

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module provides an alternative to using request->uri_for, which provides
server perspective paths. The paths produced by this module are made using
headers provided by Apache to determine what the path should be from the requester's
perspective. This is useful when you have deployed your Dancer app using the 
ReverseProxy method: L<http://search.cpan.org/~sukria/Dancer-1.3002/lib/Dancer/Deployment.pod#Using_Apache's_mod_proxy>

Supposing a Dancer app hosted on http://private.server.com:5000 but
reachable at http://public.server.com/dancer-app, the following should apply:

    use Dancer::Plugin::ProxyPath;

    my $internal_path = request->uri_for("/path/to/elsewhere");
    # http://private.server.com:5000/path/to/elsewhere

    my $external_path = proxy->uri_for("/path/to/elsewhere");
    # http://public.server.com/dancer-app/path/to/elsewhere
    ...

    # and in your templates: (assuming a passed variable $background)

    <body style="background-image: url('<% proxy.uri_for(background) %>')">
    </body>

If no proxy information is found, proxy->uri_for will 
return the same paths as request->uri_for, making it work
in development as well.

If the proxy is not mounted at the root level, you will 
need to pass along the mounted location, using a header (See README).
You can set the name of the header you have chosen with the 
plugin setting "base_header"


=head1 EXPORT

One function is exported by default: proxy

=head1 SUBROUTINES

=head2 proxy

Returns the proxy object, which has two methods: path and uri_for.

See L<Dancer::Plugin::ProxyPath::Proxy>

=cut

sub _get_base_header {
    return plugin_setting->{"base_header"};
}

register proxy => sub {
    return Dancer::Plugin::ProxyPath::Proxy->instance(_get_base_header);
};

before_template sub {
    my $tokens = shift;
    $tokens->{proxy} = Dancer::Plugin::ProxyPath::Proxy->instance;
};

register_plugin;

=head1 AUTHOR

Alex Kalderimis, C<< <alex kalderimis at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-proxypath at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-ProxyPath>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::ProxyPath


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

1; # End of Dancer::Plugin::ProxyPath
