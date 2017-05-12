# Apache::AppSamurai::AuthRadius - AppSamurai Radius authentication plugin

# $Id: AuthRadius.pm,v 1.15 2008/04/30 21:40:06 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

package Apache::AppSamurai::AuthRadius;
use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = substr(q$Revision: 1.15 $, 10, -1);

use Carp;
use Apache::AppSamurai::AuthBase;
use Authen::Radius;

@ISA = qw( Apache::AppSamurai::AuthBase );

sub Configure {
    my $self = shift;

    # Pull defaults from AuthBase and save.
    $self->SUPER::Configure();
    my $conft = $self->{conf};
    
    # Initial configuration.  Put defaults here before the @_ args are
    # pulled in.
    $self->{conf} = { %{$conft},
	              Connect => '127.0.0.1:1812', # IP:port of RADIUS server
		      Secret => 'defaultisstupid', # RADIUS secret for this
                                                   # client
		      Timeout => 5, # Timeout for RADIUS auth to return
		      @_,
		  };
    return 1;
}

sub Initialize {
    my $self = shift;
    # Create our Authen::Radius instance
    $self->{radius} = new Authen::Radius(Host => $self->{conf}{Connect},
					 Secret => $self->{conf}{Secret},
					 TimeOut => $self->{conf}{Timeout}
					 );
    ($self->{radius}) || ($self->AddError("Initialization of Authen::Radius failed: $!") && return 0);

    $self->{init} = 1;
    return 1;
}


# Query the Radius server
sub Authenticator {
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $error;

    # Amazingly enough, this actually sends the authentication request to the
    # RADIUS server.  Bet you couldn't figure THAT one out.
    ($self->{radius}->check_pwd($user, $pass)) && (return 1);

    # Save an error message if there is one, else assume a normal login failure
    $error = $self->{radius}->get_error();
    if ($error ne 'ENONE') {
	$self->AddError('error', "Special authentication failure: \"$user\": $error, " . $self->{radius}->strerror());
    } else {
	$self->AddError('warn', "Authentication failure: \"$user\": " . $self->{radius}->strerror());
    }

    # DEFAULT DENY # 
    return 0;
}
    
1; # End of Apache::AppSamurai::AuthRadius

__END__

=head1 NAME

Apache::AppSamurai::AuthRadius - Check credentials against RADIUS service

=head1 SYNOPSIS

The module is selected and configured inside the Apache configuration.

 # Example with an authname of "fred" for use as part of an Apache config.

 # Configure as an authentication method
 PerlSetVar fredAuthMethods "AuthRadius"

 # Set the IP and port to send Radius requests to
 PerlSetVar fredAuthRadiusConnect "10.10.10.10:1812"

 # Set the RADIUS key to use
 PerlSetVar fredAuthRadiusSecret "ThePasswordJustBetterNotBePASSWORD"

 # Set the timeout for the RADIUS connection
 PerlSetVar fredAuthRadiusTimeout 5

=head1 DESCRIPTION

This L<Apache::AppSamurai|Apache::AppSamurai> authentication module checks a
username and password against a backend RADIUS service.

This module is one way to access strong authentication systems, like RSA
SecurID.  Note that features like "Next Tokencode" are not supported by
this module at this time, so Apache::AppSamurai can not help users
re-synchronize their tokens.

=head1 USAGE

The basic L<Apache::AppSamurai::AuthBase|Apache::AppSamurai::AuthBase>
configuration options are supported.  Additional options are described
below.  The following must be preceded by the auth name and the auth
module name, I<AuthRadius>.  For example, if you wish to set the
C<Connect> value for the auth name "Jerry", you would use:

 PerlSetVar JerryAuthRadiusConnect "thisistheservername:1234"

The auth name and "AuthRadius" have been removed for clarity.
See L<Apache::AppSamurai|Apache::AppSamurai> for more general configuration
information, or the F<examples/conf/> directory in the Apache::AppSamurai
distribution for examples.

=head2 I<Connect> C<SERVER:PORT>

(Default: C<127.0.0.1:1812>)
Set to the IP address or FQDN (fully qualified domain name) of the RADIUS
server, a C<:>, and then the port RADIUS is listening on.

=head2 I<Secret> C<PASSWORD>

(Default: C<defaultisstupid>)
Set the RADIUS secret (password) used for communication between the
Apache::AppSamurai server and the RADIUS server.  If possible, use a
unique RADIUS secret for different devices to reduce the risk of
attack from other devices, and the risk of capturing authentication
information in transit.

Oh, and B<don't use I<defaultisstupid> as your RADIUS secret!>

=head2 I<Timeout> C<SECONDS>

(Default: 5)
The number of seconds to wait for a response from the RADIUS server.
The default should usually be fine.

=head2 OTHERS

All other configuration items are inherited from
L<Apache::AppSamurai::AuthBase|Apache::AppSamurai::AuthBase>.  Consult
its documentation for more information.

=head1 METHODS

=head2 Configure()

Other than the AuthRadius specific configuration options, (described in
L</USAGE>), this is just a wrapper for the AuthBase C<Configure()>.

=head2 Initialize()

Performs the following additional actions:

=over 4

=item *

Creates and initializes an L<Authen::Radius|Authen::Radius> instance and
saves it in C<< $self->{radius} >>.

=back

=head2 Authenticator()

Sends the authentication request to the RADIUS server.  It logs error(s),
including specific RADIUS errors, and returns 0 if the authentication
fails for any reason.

=head1 EXAMPLES

See L</SYNOPSIS> for a basic example, or configuration examples in
F<examples/conf/> inside the Apache::AppSamurai distribution.

=head1 SEE ALSO

L<Apache::AppSamurai>, L<Apache::AppSamurai::AuthBase>, L<Authen::Radius>

=head1 AUTHOR

Paul M. Hirsch, C<< <paul at voltagenoir.org> >>

=head1 BUGS

See L<Apache::AppSamurai> for information on bug submission and tracking.

=head1 SUPPORT

See L<Apache::AppSamurai> for support information.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul M. Hirsch, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
