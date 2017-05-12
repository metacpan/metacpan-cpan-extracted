###############################################################################
#
# File:    Simple.pm
#
# Author:  Damien S. Stuart
#
# Purpose: Perl module for basic authenication using Kerberose 5.
#
#
###############################################################################
#
package Authen::Krb5::Simple;

use 5.006;
use strict;
use warnings;
use Carp;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.43';

bootstrap Authen::Krb5::Simple $VERSION;

# Create the Kerberos 5 object.
#
sub new {
    my $class   = shift;
    my (%args)  = @_;

    bless {
        _err_code   => 0,
        _realm  => $args{realm} || ''
    }, $class
}

# Perform the authentication
#
sub authenticate {
    my $self = shift;
    my $user = shift || croak "Missing arg: username\n";
    my $pw   = shift; 

    if(!defined($pw) or $pw eq '') {
        # Codes staring with 'e' are internal to this module.
        #
        $self->{_err_code} = 'e1';

        return 0;
    }

    # If a realm is specified, prepend it to the username (as long as the
    # username does not already have a realm component).
    #
    if($self->{_realm} and $user !~ /@\S+$/) {
        $user .= "\@$self->{_realm}";
    }

    $self->{_err_code} = krb5_auth($user, $pw);

    return(($self->{_err_code} == 0) ? 1 : 0);
}

# Return the error string from the most recent authenticate function.
#
sub errstr {
    # Check for module internal (non-krb) error. If it is return the
    # appropriate error string (there is only one at present).
    #
    if($_[0]->{_err_code} =~ /^e(\d+)/) {
        return('Null or empty password not supported') if($1 == 1);
    }

    # Otherwise, let krb5_errstr tell us...
    #
    return ($_[0]->{_err_code} == 0) ? '' : krb5_errstr($_[0]->{_err_code});
}

# Return the error code from the most recent authenticate function.
#
sub errcode {
    return $_[0]->{_err_code};
}

# Get or set the default realm
#
sub realm {
    my $self = shift;
    my $arg  = shift;

    $self->{_realm} = $arg if(defined($arg));

    return $self->{_realm};
}

1;

__END__

=head1 NAME

Authen::Krb5::Simple - Basic user authentication using Kerberos 5

=head1 SYNOPSIS

  use Authen::Krb5::Simple;

  # Create a new Authen::Krb5::Simple object using
  # the system default realm.
  #
  my $krb = Authen::Krb5::Simple->new();

  # Authenticate a user.
  #
  my $authen = $krb->authenticate($user, $password);

  unless($authen) {
      my $errmsg = $krb->errstr();
      die "User: $user authentication failed: $errmsg\n";
  }

  # Get the current default realm.
  #
  my $realm = $krb->realm();

  # Set the current realm
  #
  $krb->realm('MY.NEW.REALM');

  # Create a new object pointing to another realm.
  #
  my $alt_krb = Authen::Krb5::Simple->new(realm => 'OTHER.REALM');
  ...

=head1 DESCRIPTION

The C<Authen::Krb5::Simple> module provides a means to authenticate a
user/password using Kerberos 5 protocol.  The module's authenticate function
takes a username (or user@kerberos_realm) and a password, and authenticates
that user using the local Kerberos 5 installation.  It was initially created
to allow perl scripts to perform authentication against a Microsoft Active
Directory (AD) server configured to accept Kerberos client requests.

B<It is important to note:> This module only performs simple authentication.
It does not get, grant, use, or retain any kerberos tickets.  It will check
user credentials against the Kerberos server (as configured on the local
system) each time the I<authenticate> method is called.

=head1 CONSTRUCTOR

B<new>

=over

The I<new> method creates the I<Authen::Krb5::Simple> object.  It can take an
optional argument hash.  At present the only recognized argument is C<realm>.

If no realm is specified, the default realm for the local host will be
assumed.  Once set, the specified realm will be used for all subsequent 
authentication calls.  The realm can be changed using the I<realm> function
(see below).

B<Examples:>

Using the default realm:

  my $krb = Authen::Krb5::Simple->new();

specifying a realm:

  my $krb = Authen::Krb5::Simple->new(realm => 'another.realm.net');

=back

=head1 METHODS

B<authenticate($user[@realm], $password)>

=over

the I<authenticate> method takes the user (or user@realm) and a password, and
uses kerberos 5 (the local systems installation) to authenticate the user.

if the user/password is good, I<authenticate> will return a true value.
Otherwise, a false value is returned and the error code is stored in the
object.

  if($krb->authenticate($user, $pw)) {
      print "$user authentication successful\n";
  } else {
      print "$user authentication failed: ", $krb->errstr(), "\n";
  }
        
=back
   
B<realm( )>

B<realm(NEW.REALM)>

=over

The I<realm> method is used to set or get the current default realm.  If an
argument is passed to this method, the default realm is set to that value. If
no argument is supplied, the current realm is returned.

=back

B<errstr>

=over

The I<errstr> method will return the error message from the most recent
I<authentication> call.

=back

B<errcode>

=over

The I<errstr> method will return the krb5 error code from the most recent
I<authentication> call.  This value will not be very useful.  Use the 
I<errstr> method to get a meaningful error message.

=back

=head1 BUGS

This version of I<Authen::Krb5::Simple> does not support null or
empty passwords.  If you pass an undefined value or empty string (C<''>)
as a password, I<authenticate> return false and set the error to indicate
that null or empty passwords are not supported.

=head1 AUTHOR

Damien S. Stuart, E<lt>dstuart@dstuart.orgE<gt>

=head1 SEE ALSO

L<perl>, Kerberos5 documentation.

=cut

###EOF###
