package CatalystX::UriForStatic;

use warnings;
use strict;

use Moose::Role;

=head1 NAME

CatalystX::UriForStatic - Implements an uri_for_static method for Catalyst applications!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Returns an URI for static files.  It distinguishes between a local and productive environment
so it can return an URI pointing to a different host (eg. to a CDN) for productive environments.

    package MyApp;
    use Moose;
    use namespace::autoclean;
    
    extends 'Catalyst';
    with 'CatalystX::UriForStatic';
    
    __PACKAGE__->config(
        envkey      => 'sysenv',  # optional, this is the default
        local_value => 'local',   # optional, this is the default
        static_host => 'http://static.example.net',
        sysenv      => 'local',
    );


    # In your template
    <% $c->uri_for_static('/static/foo.png') %>

=head1 DESCRIPTION

=head2 uri_for_static

Pass a path like you would do to L<Catalyst/uri_for>.  Doesn't accept Controller paths or blessed references etc.

On a C<local> environment it calls L<Catalyst/uri_for> and returns what it returns.

On any other environment it prepends the C<static_host> to the path while it doesn't care about
SSL or if your passed path is valid.

=cut

sub uri_for_static {
    my ($c, $path) = @_;

    my $envkey =      $c->config->{envkey}      ? $c->config->{envkey}      : 'sysenv';
    my $sysenv =      $c->config->{ $envkey }   ? $c->config->{ $envkey }   : 'local';
    my $local_value = $c->config->{local_value} ? $c->config->{local_value} : 'local';

    if ($sysenv eq $local_value || !$c->config->{static_host}) {
        return $c->uri_for($path);
    }

    $path = '/' . $path unless $path =~ m,^/,;

    return $c->config->{static_host} . $path;
}

=head1 CONFIGURATION

To work properly, CatalystX::UriForStatic needs some small configuration.

=over 4

=item envkey

Specifies the key in the config that is responsible for defining if the environment is a development
or production environment.  The default is B<sysenv>.

=item local_value

Specifies what the value of the L<envkey> is when the environment is a development/local environment.
The default is B<local>.

=item sysenv

This key's name is whatever L<envkey> is set to!  Change this to the value of L<local_value> to tell
C<CatalystX::UriForStatic> if the environment is a development/local environment.  If it differs
from L<local_value> the environment is considered as production.

=item static_host

Contains the URI to the static files and should include the protocol (http or https) and as well the
domain.  Shouldn't contain a trailing slash.

Examples:

=over 8

=item http://static.example.net

=item http://static.example.net/my/static/files

=item https://whatever.example.net

=back

=back

=head1 AUTHOR

Matthias Dietrich, C<< <perl@rainboxx.de> >>

L<http://www.rainboxx.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Matthias Dietrich.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CatalystX::UriForStatic
