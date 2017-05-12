# Apache::AppSamurai::AuthBase - AppSamurai authentication plugin base
#                                module.

# $Id: AuthBase.pm,v 1.15 2008/04/30 21:40:05 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

# This is a base authentication wrapper for Apache::AppSamurai.
# AppSamurai can use one or more authentication methods to authenticate
# users.  Each method, besides the special AuthServer method, requires
# a module name Apache::AppSamurai::<AUTHNAME>.  All AppSamurai::AuthXXX
# modules should be derived from this base module.

package Apache::AppSamurai::AuthBase;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = substr(q$Revision: 1.15 $, 10, -1);

use Carp;

sub new {
    my $this = shift;
    my $class = (ref($this) || ($this));
    my $me = {};

    bless($me, $class);

    # Call Configure to fill out the $me->{conf} hash
    $me->Configure(@_);
    $me->{init} = 0;
    $me->{errors} = [];

    # If the username and password were passed with the new request,
    # process and return immediately.
    if (defined($me->{conf}{user}) && defined($me->{conf}{pass})) {
	return $me->Authenticate($me->{conf}{user}, $me->{conf}{pass});
    }    
    return $me;
}

#### OVERRIDE Configure(), Initialize(), and Authenticator() FOR NEW ####
#### AuthXXX MODULES                                                 ####

# Configure the conf hash.  If you want to override theses defaults, or
# add new ones, create your own Configure() in your AuthXXX module
sub Configure {
    my $self = shift;
    # Initial configuration.  Put defaults here before the @_ args are
    # pulled in.
    $self->{conf} = { UserMin => 3,
		      UserMax => 256,
		      UserChars => '\w\d_\-\.',
		      UserStripWhite => 1,
		      UserUc => 0,
		      UserLc => 0,
		      PassMin => 4,
		      PassMax => 16384,
		      PassChars => '\w\d !\@\#\$\%\^\&\*:\,\.\?\-_=\+',	      
		      PassStripWhite => 0,
		      DefaultLogLevel => 'error',
		      @_,
		  };

    return 1;
}


# All setup should go here, including configuring authentication modules.
# This will be called by Authenticate() 99% of the time, but for some auth
# types, may be useful to be called in new() as well.
sub Initialize {
    my $self = shift;
    # May only be initialized once
    ($self->{init} == 1) && (return 1);
 
    # Make sure we have config (in case someone tries to call us directly)
    (defined($self->{conf}) && (scalar keys %{$self->{conf}})) || (croak "Could not initialize!  Module not configured!");

    # Make sure to complain if something goes wrong
    (1 == 1) || ($self->AddError("Failed to initialize in " . __PACKAGE__ . "::Initialize") && return 0);

    # Set this after successful initialization
    $self->{init} = 1;
    return 1;
}


# Perform the authentication.  Returns a "yes" value (1, true) on success
# and "no" value (0, false, or undef) on failure.  The function takes
# three arguments.  1) The object itself  2) The username  3) The password
# The username and password at this point have been through ALL checks in
# the module. (Valid chars, valid length, etc,)
sub Authenticator {
    my $self = shift;
    my $user = shift;
    my $pass = shift;

    # Enter stuff here

    # DEFAULT DENY #
    return 0;
}

###########################################################################


# The bulk of the work happens here, calling Initialize(), CheckInput(), and
# Authenticator(), and returning a true (1)/ false (0) status.
sub Authenticate {
    my $self = shift;
    (scalar(@_) == 2) || (croak 'Usage: $a->Authenticate($user, $pass);');
    my ($user, $pass) = @_;
    
    ## DEFAULT DENY ##
    my $authenticated = 0;

    # Check for clean input.
    ($user = $self->CheckInputUser($user)) || ($self->AddError('warn', 'Invalid username') && return 0);
    ($pass = $self->CheckInputPass($pass)) || ($self->AddError('warn', 'Invalid password') && return 0);

    # Initialize if not yet done
    if (!$self->{init}) {
	($self->Initialize()) || (return 0);
    }

    ## This is where the Authentication happens.  Create your own overridden 
    # Authenticator functions today!
    ($self->Authenticator($user, $pass)) && ($authenticated = 1);

    return $authenticated;
}


# Filter or reject the username.  Return the username (with
# modifications, if needed) on success, or nothing on failure.
# CUSTOMIZE THIS TO ONLY ALLOW VALID USERNAMES FOR YOUR AUTH MODULE!
# BE CAREFUL IF YOU RETURN AN ALTERED USERNAME!  Most bases should be covered
# by the various UserXXX config options, but add more as needed here.
sub CheckInputUser {
    my $self = shift;
    my $user = (shift || return undef);

    # Strip surrounding whitespace, if so configured
    if ($self->{conf}{UserStripWhite}) {
	$user =~ s/^\s*(.+?)\s*$/$1/;
    }
    my $ulen = length($user);
   
    # Check username against the list of valid username characters
    unless ($user =~ /^([$self->{conf}{UserChars}]+)$/) {
	$self->AddError('warn', 'Username contains invalid characters');
	return undef;
    }

    # Check for a valid username length.
    if ($ulen < $self->{conf}{UserMin}) {
	$self->AddError('warn', "Username too small ($ulen)");
	return undef;
    } elsif ($ulen > $self->{conf}{UserMax}) {
	$self->AddError('warn', "Username too large ($ulen)");
	return undef;
    }

    # uc() or lc() if so configured.
    if ($self->{conf}{UserUc}) {
	$user = uc($user);
    } elsif ($self->{conf}{UserLc}) {
	$user = lc($user);
    }

    return $user;
}


# Filter or reject the password.  Return the password (with
# modifications, if needed) on success, or nothing on failure.
# CUSTOMIZE THIS TO ONLY ALLOW VALID PASSWORDS FOR YOUR AUTH MODULE!
# BE CAREFUL IF YOU RETURN AN ALTERED PASSWORD!  In almost all cases,
# you should fail out instead of trying to help a user.  No lc($pass)
# unless your backend authentication checker really is case insensitive.
sub CheckInputPass {
    my $self = shift;
    my $pass = (shift || return undef);

    # Strip surrounding whitespace, if so configured
    if ($self->{conf}{PassStripWhite}) {
	$pass =~ s/^\s*(.+?)\s*$/$1/;
    }
    my $plen = length($pass);

    # Check password against the list of valid password characters
    unless ($pass =~ /^([$self->{conf}{PassChars}]+)$/) {
	$self->AddError('warn', 'Password contains invalid characters');
	return undef;
    }

    # Check for a valid password length.
    if ($plen < $self->{conf}{PassMin}) {
	$self->AddError('warn', "Password too small ($plen)");
	return undef;
    } elsif ($plen > $self->{conf}{PassMax}) {
	$self->AddError('warn', "Password too large ($plen)");
	return undef;
    }

    return $pass;
}


# Add error to the list
sub AddError {
    my $self = shift;
    if (scalar(@_) == 2) {
	push(@{$self->{errors}}, [$_[0], ref($self) . ": " . $_[1]]);
    } else {
	push(@{$self->{errors}}, [$self->{conf}{DefaultLogLevel}, ref($self) . ": " . $_[0]]);
    }
    return 1;
}

# Return an array of errors if there are any, or undef if there are not.
sub Errors {
    my $self = shift;
    if (scalar(@{$self->{errors}})) {
	return $self->{errors};
    }
    
    return undef;
}

1; # End of Apache::AppSamurai::AuthBase

__END__

=head1 NAME

Apache::AppSamurai::AuthBase - Base module for all AppSamurai authentication
                               sub modules.

=head1 SYNOPSIS

All L<Apache::AppSamurai|Apache::AppSamurai> authentication modules should
inherit from this base module.  This module is never used directly.
See L<Apache::AppSamurai|Apache::AppSamurai> for details on authentication
module config and use within AppSamurai.                

=head1 DESCRIPTION

All L<Apache::AppSamurai|Apache::AppSamurai> authentication submodules
should inherit from Auth::Base.  This module provides the a standard
framework including config, initialization, basic input validation and
filtering, error checking, and logging needed by all AppSamurai auth modules.

Auth modules must each define at least an L</Authenticator()> method to accept
the username (C<credential_0>) and the mapped credential (password) and return
0 on failure and 1 on success.  Other commonly overridden methods are
L</Configure()> which includes the setup of the C< $self->{conf} >
configuration hash, and L</Initialize()> which performs any needed
pre-authentication setup work.

=head1 METHODS

=head2 new()

Runs I<Configure()>, (passing along any arguments), which creates and
populates the C<< %{$self->{conf}} >> hash.  Then creates and sets
the C<< $self->{init} >> flag to 0, and creates and clears the
C<< @{$self->{errors}} >> array.

The instance is then returned.

Alternately, if a C<< $self->{conf}{user} >> and C<< $self->{conf}{pass} >>
exist, C<< $self->Authenticate() >> is called with those values and the result
is returned.
(Note - This behavior is not currently used by Apache::AppSamurai).

=head2 Configure()

Creates and populates the instance's configuration hash,
C<< %{$self->{conf}} >>.
Each auth module has a basic set of default configuration items from
Auth::Base, plus any additional items added in its own C<Configure()> method,
plus any configuration items passed in when C<Configure()> is called.
Arguments take precedence over defaults in the particular auth module,
and the auth module's defaults take precedence over those in Auth::Base.

See L</EXAMPLES> for an example of overriding C<Configure()> while
preserving the Auth::Base defaults.

The following keys are set in Auth::Base, and are also used by methods
in Auth::Base for input validation, logging, and other purposes.

=head3 I<UserMin>

Minimum characters in username. (Default: 3)

=head3 I<UserMax>

Maximum characters in username. (Default: 256)

=head3 I<UserChars>

Characters allowed in the username.  These are matched with a Perl regex,
and character classes like C<\w> and C<\d> are allowed. (Default:
C<< \w\d_\-\. >>)

=head3 I<UserStripWhite>

If set to 1, strips any whitespace surrounding the username.
(Default: 1)

=head3 I<UserUc>

If set to 1, converts the username to all caps before checking. (Default: 0)

=head3 I<UserLc>

If set to 1, converts the username to all lower case before checking.
(Default: 0)

=head3 I<PassMin>

Minimum characters in password. (Default: 4)

=head3 I<PassMax>

Maximum characters in password. (Default: 16384)

=head3 I<PassChars>

Characters allowed in a password.  These are matched with a Perl regex and
character classes like "\w" and "\d" are allowed.  (Default:
C<< \w\d !\@\#\$\%\^\&\*:\,\.\?\-_=\+ >>)	      

=head3 I<PassStripWhite>

If set to 1, strips any whitespace surrounding the password.
(Default: 0)

=head3 I<DefaultLogLevel>

The L</AddError()> method can take two styles of input when adding log
lines to the object's errors array.  This option sets the logging
severity for log lines passed in without a specific severity set.
The valid values are the same as those allowed in the Apache C<LogLevel>
directive: emerg, alert, crit, error, warn, notice, info, and debug.
(Default: error)

=head2 Initialize()

Performs initial setup of object instance, returning 1 on success or 0
on failure.  Checks the C<< $self->{init} >> flag for a previous run,
and returns 1 of object has already been initialized.  Once completed,
the C<< $self->{init} >> flag is set to 1 before returning.

See L</EXAMPLES> for a sample overridden C<Initialize()> method.

=head2 Authenticator()

C<Apache::AppSamurai::AuthBase::Authenticator()> is just a skeleton and
must be overridden for each authentication module.  It is called with
an object reference and takes the username and password as two scalar
inputs.  It must return 0 on an authentication failure or any other
failure.  1 should only be returned on a clean and successful authentication.

B<Please carefully test this method in any authentication module before
using in production!>  Also, it is recommended that the last command inside
all C<Authenticator()> methods is C<return 0;>.  This helps ensure that
if there is some sort of unanticipated failure, or unanticipated fall through
condition, there is one more obstacle in the way of a potential authentication
bypass.

See L</EXAMPLES> for a simple example of a C<Authenticator()> method.

=head2 Authenticate()

This is called by Apache::AppSamurai to perform the authentication check.
It is called with an object reference and takes the username and password
as scalar arguments.

The username is validated using L</CheckInputUser()>, and then the password
is validated using L</CheckInputPass()>.  (If either of those fail,
an error is added and 0 is returned.)

After validation, L</Initialize()> is called if the C<< $self->{init} >>
flag has not been set.  (Note - Apache::AppSamurai calls C<Initialize()>
separately.  This functionality is added as a fail safe, or for testing.)

Finally, the object's L</Authenticator()> method is called to perform the
actual work of checking the credentials.  It's result is returned by
C<Authenticate()> to the caller.

C<Authenticate()> should not generally need to be overridden.

=head2 CheckInputUser()

Is called with an object ref and expects a scalar username as its only
argument.  If successful, the validated username is returned.  In case of
a failure or violation, C<undef> is returned.

C<CheckInputUser()> uses settings out of C<< $self->{conf} >> as follows:

=over 4

=item *

If I<UserStripWhite> is 1, surrounding whitespace is removed.

=item *

The username is checked against I<UserChars>.

=item *

The length of the username is checked against I<UserMin> and then I<UserMax>.

=item *

If I<UserUc> is 1, the username is converted to all caps.

=item *

If I<UserLc> is 1, the username is converted to all lower case.  (Note - 
I<UserUc> takes precedence if both are set.)

=back

If all conditions are met, the validated and cleaned username is returned.

C<CheckInputUser()> should not generally need to be overridden unless an
authentication module needs more extensive filtering.

=head2 CheckInputPass()

Is called with an object ref and expects a scalar password as its only
argument.  If successful, the validated password is returned.  In case of
a failure or violation, C<undef> is returned.

Note - "password" is used in the descriptions below.  This equates the
whatever data, (password, passphrase, PIN, whatever), will be passed as
an authentication credential to the authentication module.

C<CheckInputPass()> uses settings out of C<< $self->{conf} >> as follows:

=over 4

=item *

If I<PassStripWhite> is 1, surrounding whitespace is removed.  (This is
generally not a good idea unless the specific authentication system does
not support whitespace in the password.)

=item *

The password is checked against I<PassChars>.  Try to allow as many characters
as the underlying authentication system can safely support to avoid reducing
the strength of the passwords or other authentication data that can be used.
(Note - The default I<PassChars> should be decent for most uses, however,
it may be loosened or restricted more in future versions.)

=item *

The length of the password is checked against I<PassMin> and then I<PassMax>.
Once again, avoid limiting the maximum password length as much as safely
possible.

=back

If all conditions are met, the validated and cleaned password is returned.

C<CheckInputPass()> should not generally need to be overridden unless an
authentication module needs more extensive filtering.

=head2 AddError()

Adds a new log message to the C<< @{$self->{errors}} >> array, which is
returned to a then processed by Apache::AppSamurai.

C<AddError()> is called using an object reference and expects one of
two types of calls:

=over 4

=item *

One argument - This should be a single scalar containing the text to be
logged.  It will be added to the errors using the log level defined in
the I<DefaultLogLevel> configuration option.

=item *

Two arguments - This should be scalar containing the log level to use,
followed by a scalar with the message to be logged.

=back

C<AddError()> should not generally need to be overridden.

=head2 Errors()

Called using an object reference and returns an array of anonymous
arrays containing C<loglevel>, C<logmessage> pairs.  If no log messages
exist, undef is returned.

C<Errors()> is called by Apache::AppSamurai after using the authentication
module's C<Authenticate()> method.  It generally does not need to be
overridden.

=head1 EXAMPLES

Here is an example authentication module based on Auth::Base.  Let's call
it Apache::AppSamurai::AuthGarbage and have it use the fictitious module
Junk::Dumpster to check credentials.

 package Apache::AppSamurai::AuthGarbage;

 use Apache::AppSamurai::AuthBase;
 use Junk::Dumpster;  # Kids, don't try this at home 

 # Inherit the AuthBase wind...
 @ISA = qw( Apache::AppSamurai::AuthBase );
 
 # Override the Configure method to add special config options
 sub Configure {
     my $self = shift;

     # Pull defaults from AuthBase and save.
     $self->SUPER::Configure();
     my $conft = $self->{conf};
     
     # Initial configuration.  Put defaults here before the @_ args are
     # pulled in.
     $self->{conf} = { %{$conft},
                       Crud => 1,
                       Dumpster => 'supadumpy',
                       @_,
                     };
     return 1;
 }

 # Set an Initiate function to do any required setup and initialization
 # (Creating object instances, pre-flight checks, etc.)
 sub Initialize {
     my $self = shift;
 
     # Create Junk::Dumpster instance
     $self->{client} = new Junk::Dumpster(crud => $self->{conf}{Crud});
 
     # Set init flag
     $self->{init} = 1;
     return 1;
 }

 # Make authentication check
 sub Authenticator {
     my $self = shift;
     my $user = shift;
     my $pass = shift;
     my ($response, $error, @tmp, $check, $realm);
     
     # This is silly.  There is no Junk::Dumpster....
     $response = $self->{client}->IsItInDere($user,$pass);
     
     if ($response) {
         # You passed the test!
         return 1;
     } elsif ($!) {        
	 # An abnormal failure: Log an error
	 $self->AddError('error', "Failure from Junk:Garbage: $!");
	 return 0;
     }
 
     # Normal failure fall through.  Log the failure and kick back
     $self->AddError('warn', "Junk::Garbage login failure for \"$user\"");
 
     return 0;
 }

=head1 SEE ALSO

L<Apache::AppSamurai>, L<Apache::AppSamurai::AuthBasic>

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
