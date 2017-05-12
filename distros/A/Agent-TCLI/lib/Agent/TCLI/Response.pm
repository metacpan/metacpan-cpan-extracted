package Agent::TCLI::Response;
#
# $Id: Response.pm 59 2007-04-30 11:24:24Z hacker $
#
=head1 NAME

Agent::TCLI::Response - A Response class for Agent::TCLI::Response.

=head1 SYNOPSIS

A simple object for storing TCLI responses. The preferred way to
create a Response object is through the Request->Respond method.

=cut

use warnings;
use strict;
use Carp;

use Object::InsideOut qw(Agent::TCLI::Request);

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Response.pm 59 2007-04-30 11:24:24Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard accessor/mutator
methods and may be set as a parameter to new unless otherwise noted.

=over

=item body

Main body of response.

=cut
my @body			:Field
					:All('body');

=item code

A code for the response, similar to HTTP/SIP.
B<code> will only accept NUMERIC type values.

=cut
my @code			:Field
					:Type('NUMERIC')
					:All('code');

1;
#__END__
=back

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Request. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

The (ab)use of AUTOMETHODS is probably more a bug than a feature.

SHOULDS and MUSTS are currently not always enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
