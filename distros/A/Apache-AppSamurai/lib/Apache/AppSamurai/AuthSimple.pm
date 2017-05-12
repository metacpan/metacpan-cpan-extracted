# Apache::AppSamurai::AuthSimple - AppSamurai "Simple" authentication framework
#                                  plugin

# $Id: AuthSimple.pm,v 1.2 2008/05/01 22:36:10 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

package Apache::AppSamurai::AuthSimple;
use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = substr(q$Revision: 1.2 $, 10, -1);

use Carp;
use Apache::AppSamurai::AuthBase;
use Authen::Simple;

@ISA = qw( Apache::AppSamurai::AuthBase );

sub Configure {
    my $self = shift;

    # Pull defaults from AuthBase and save.
    $self->SUPER::Configure();
    my $conft = $self->{conf};
    
    # Initial configuration.  Put defaults here before the @_ args are
    # pulled in.
    $self->{conf} = { %{$conft},
		      # Send log messages to Apache::AppSamurai::AuthSimple
		      # itself (see debug, error, info, and warn methods below)
		      log => $self,
		      @_,
		  };

    return 1;
}

sub Initialize {
    my $self = shift;

   # A submodule MUST be selected at this point
    unless ($self->{conf}{SubModule}) {
	$self->AddError("Please specify a submodule for Authen::Simple to use!");
	return 0;
    }
    
    my $fullsub = 'Authen::Simple::' . $self->{conf}{SubModule};

    # Attempt to load the submodule
    unless (eval "require $fullsub") {
	$self->AddError("Unable to load Authen::Simple submodule, $fullsub: $@");
	return 0;
    }

    # Create a limited config hash with only the keys supported by the
    # adaptor submodule
    my %simpleconf;
    
    if ($fullsub->can('options')) {
	# Pull in only supported values
	foreach (keys %{$fullsub->options}) {
	    exists $self->{conf}{$_} and $simpleconf{$_} = $self->{conf}{$_};
	}
    } else {
	# Params::Validate appears not to be used for this adaptor, so
	# just copy in the full conf
	%simpleconf = %{$self->{conf}};
    }

    # Prepare an eval to create our Authen::Simple instance with our
    # chosen auth adaptor
    my $asconf = '$self->{authen} = Authen::Simple->new(' .
	$fullsub . '->new(%simpleconf))';

    unless (eval $asconf && $self->{authen}) {
	$self->AddError("Initialization of Authen::Simple failed: $@");
	return 0;
    }

    $self->{init} = 1;
    return 1;
}


# Authenticate using Authen::Simple (which in turn calls the configured
# adaptor submodule)
sub Authenticator {
    my $self = shift;
    my $user = shift;
    my $pass = shift;

    # Multiple layers of abstraction rock!  (We are passing authentication
    # information to Authen::Simple which is passing it to its adaptor
    # submodule...)
    ($self->{authen}->authenticate($user, $pass)) && (return 1);

    $self->AddError('warn', "Authentication failure with $self->{conf}{SubModule} for user: \"$user\"");

    # DEFAULT DENY # 
    return 0;
}


# Logging methods for the Authen:Simple submodules to callback to
sub debug {
    shift->_simplelog('debug', @_);
}

sub error {
    shift->_simplelog('error', @_);
}

sub info {
    shift->_simplelog('info', @_);
}

sub warn {
    shift->_simplelog('warn', @_);
}

sub _simplelog {
    my $self = shift;
    my $severity = shift;

    # For now, squeezing multiple log lines into one seems more reasonable
    # for auth submodules.  This can be changed if submodules are shown
    # to send a lot of multiline log messages
    my $msg = join(", ", @_);

    $msg =~ s/\n/ /gs;

    $self->AddError($severity, $msg);
}

1; # End of Apache::AppSamurai::AuthSimple

__END__

=head1 NAME

Apache::AppSamurai::AuthSimple - Check credentials with Authen::Simple framework

=head1 SYNOPSIS

The module is selected and configured inside the Apache configuration.

 # Example with an authname of "fred" for use as part of an Apache config.

 # Configure as an authentication method (Authen::Simple::Passwd shown)
 PerlSetVar fredAuthMethods "AuthSimplePasswd"

 # Set auth method options (Authen::Simple::Passwd "path" option shown)
 PerlSetVar fredAuthSimplePasswdpath "/var/www/conf/passwordfile"

=head1 DESCRIPTION

This L<Apache::AppSamurai|Apache::AppSamurai> authentication module checks a
username and password using the Authen::Simple auth framework and a supported
Authen::Simple::XXX adaptor module. If this sounds confusing, read on and
examine the examples.

This module opens up authentication access to a wide array of options including
PAM, LDAP, Kerberos, and even SSH.

=head1 USAGE

Basic L<Apache::AppSamurai::AuthBase|Apache::AppSamurai::AuthBase>
configuration options are supported.  Additional options are described
below.  The following must be preceded by the auth name and the auth
module name, I<AuthSimple>, followed by the adaptor submodule for
L<Authen::Simple|Authen::Simple> to use, and finally the name of the
parameter to set. (This will end up being passed directly to the adaptor
submodule.)

For example, if you wish to set the
L<Authen::Simple::Kerberos|Authen::Simple::Kerberos> C<realm> value for
the authname "Jerry", you would use:

 PerlSetVar JerryAuthSimpleKerberosrealm "REALM.REALMY.COM"

Note that the configuration key, "realm", is in all lower case to match
the key L<Authen::Simple::Kerberos|Authen::Simple::Kerberos> expects.

Here is another example, this time setting the
L<Authen::Simple::LDAP|Authen::Simple::LDAP> and the authname "GRAVY":

 PerlSetVar GRAVYAuthSimpleLDAPhost "dir.lovemesomeldap.org"
 PerlSetVar GRAVYAuthSimpleLDAPbasedn "ou=People,dc=lovemesomeldap,dc=org"

Check the documentation for the specific L<Authen::Simple|Authen::Simple>
adaptor you wish to use for a list of configuration parameters.  All
parameters that can be passed to the I<new> constructor of the adaptor
module can be set, with the exception of the I<log> parameter which is
handled by L<Apache::AppSamurai::AuthSimple|Apache::AppSamurai::AuthSimple>
directly.

See L<Apache::AppSamurai|Apache::AppSamurai> for more general configuration
information, or the F<examples/conf/> directory in the Apache::AppSamurai
distribution for examples.

=head1 METHODS

=head2 Configure()

Primarily a wrapper for the AuthBase C<Configure()> method, with the addition
of code to point all adaptor submodule logging back to
L<Apache::AppSamurai::AuthSimple|Apache::AppSamurai::AuthSimple> for handling.
This overrides the default logging behaviour for
L<Authen::Simple|Authen::Simple> adaptors, which is to send log messages
to STDERR.

=head2 Initialize()

Performs the following additional actions:

=over 4

=item *

Attempts to load the configured L<Authen::Simple|Authen::Simple> adaptor
submodule

=item *

Creates a new L<Authen::Simple|Authen::Simple> instance with the
configured adaptor submodule

=back

=head2 Authenticator()

Sends the authentication request to the L<Authen::Simple|Authen::Simple>
instance, which in turn sends the request to the configured adaptor submodule.
It logs error(s) and/or warnings and returns 0 if the authentication
fails for any reason.

=head2 debug(), info(), warn(), error()

Logging callback methods used by L<Authen::Simple|Authen::Simple> to log
to.  All methods use I<Apache::AppSamurai::AuthBase::AddError()> to push
messages onto the log stack.

=head1 EXAMPLES

See L</USAGE> for basic examples, or configuration examples in
F<examples/conf/> inside the Apache::AppSamurai distribution.

=head1 SEE ALSO

L<Apache::AppSamurai>, L<Apache::AppSamurai::AuthBase>, L<Authen::Simple>

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
