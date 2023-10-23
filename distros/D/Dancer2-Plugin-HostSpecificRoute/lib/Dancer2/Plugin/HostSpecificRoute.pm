package Dancer2::Plugin::HostSpecificRoute;
use strict;
use warnings;
our $VERSION = '1.0000'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY
# ABSTRACT: Allow designating routes to respond only on hostname match
use Dancer2::Plugin;

plugin_keywords qw/host/;

sub host {
    my ($plugin, $hostname, $coderef) = @_;

    return sub {
        if (!$coderef || ref $coderef ne 'CODE') {
            $plugin->app->log(
                warning => 'Invalid host usage, please see docs');
        }
        my $request_host = $plugin->app->request->base->host;
        if (ref $hostname eq 'Regexp') {
            return $coderef->($plugin) if $request_host =~ $hostname;
        }
        else {
            return $coderef->($plugin) if $request_host eq $hostname;
        }
        $plugin->app->pass;
    };
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::HostSpecificRoute - Allow designating routes to respond only on hostname match

=head1 VERSION

version 1.0000

=head1 SYNOPSIS

   package MyApp;
   use Dancer2 appname => 'MyApp';
   use Dancer2::Plugin::HostSpecificRoute;

   get '/special_route' => host 'special.host.example' => sub {
      # route code to run only when special.host.example is
      # the request host
   };

   get '/special_route' => sub {
      # default code to run /special_route when host is not 
      # special.host.example
   };

   get '/special_route_2' => host qr/\.funkyhost.example$/ => sub {
      # route code to run only when funkyhost.example is
      # the request host is *.funkyhost.example
   };

   # There is no default route for /special_route_2; it will 404, if you
   # don't address your request to *.funkyhost.example.

=head1 DESCRIPTION

It is not difficult to have your L<Dancer2> application answer to more
than one URL or even IP address; just adding C<server_name> directives in
your nginx config, or C<ServerName> in Apache, will do the trick nicely.

It may be that you want to have different route code for a given path,
depending on which host URL is requested. If that's the case, this plugin
will make it trivially easy to do so, without having to add a C<before>
hook to adjust the behavior of B<all> your routes.

=head1 SUBROUTINES/METHODS

This plugin introduces one new keyword, C<host>, to be used as a 
predicate for your routes. It will work with any of L<Dancer2>'s 
method/route declaratives (C<get>, C<put>, C<post>, C<patch>, C<del> or 
C<any>), and can be chained with other predicates, like
authorization-plugin directives (e.g. L<Dancer2::Plugin::Auth::Extensible>).

The C<host> predicate takes one parameter, which must be either:

=over

=item * A scalar string, the FQDN of a host.

=item * A quoted regex that will match the desired FQDNs to which the route should respond.

=back

If you wish to have a second route that can serve as a default, be sure
to list it B<after> any matching routes with the predicate.  Routes without
a C<host> predicate are handled normally.

=head1 DEPENDENCIES

=over

=item * L<Dancer2>

=back

=head1 BUGS AND LIMITATIONS

None found so far; if you find any, please post an issue on the bug tracker
for this module.

=head1 ACKNOWLEDGEMENTS

L<GitHub|https://github.com> user L<xoid|https://github.com/xoid> suggested
this functionality in L<this discussion|https://github.com/PerlDancer/Dancer2/discussions/1699>.
The idea intrigued me, and I'm doing something similar using a hook (which fires
on Every Single Request), so here we are.

A small bit of blame goes to L<Jason Crome|https://metacpan.org/author/CROMEDOME> for
his constant encouragement in this sort of madness.

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT:

