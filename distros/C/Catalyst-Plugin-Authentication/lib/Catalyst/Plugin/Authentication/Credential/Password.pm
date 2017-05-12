package Catalyst::Plugin::Authentication::Credential::Password;

use strict;
use warnings;

use Catalyst::Authentication::Credential::Password ();

## BACKWARDS COMPATIBILITY - all subs below here are deprecated 
## They are here for compatibility with older modules that use / inherit from C::P::A::Password 
## login()'s existance relies rather heavily on the fact that only Credential::Password
## is being used as a credential.  This may not be the case.  This is only here 
## for backward compatibility.  It will go away in a future version
## login should not be used in new applications.

sub login {
    my ( $c, $user, $password, @rest ) = @_;
    
    unless (
        defined($user)
            or
        $user = $c->request->param("login")
             || $c->request->param("user")
             || $c->request->param("username")
    ) {
        $c->log->debug(
            "Can't login a user without a user object or user ID param")
              if $c->debug;
        return;
    }

    unless (
        defined($password)
            or
        $password = $c->request->param("password")
                 || $c->request->param("passwd")
                 || $c->request->param("pass")
    ) {
        $c->log->debug("Can't login a user without a password")
          if $c->debug;
        return;
    }
    
    unless ( Scalar::Util::blessed($user)
        and $user->isa("Catalyst::Authentication::User") )
    {
        if ( my $user_obj = $c->get_user( $user, $password, @rest ) ) {
            $user = $user_obj;
        }
        else {
            $c->log->debug("User '$user' doesn't exist in the default store")
              if $c->debug;
            return;
        }
    }

    if ( $c->_check_password( $user, $password ) ) {
        $c->set_authenticated($user);
        $c->log->debug("Successfully authenticated user '$user'.")
          if $c->debug;
        return 1;
    }
    else {
        $c->log->debug(
            "Failed to authenticate user '$user'. Reason: 'Incorrect password'")
          if $c->debug;
        return;
    }
    
}

## also deprecated.  Here for compatibility with older credentials which do not inherit from C::P::A::Password
sub _check_password {
    my ( $c, $user, $password ) = @_;
    
    if ( $user->supports(qw/password clear/) ) {
        return $user->password eq $password;
    }
    elsif ( $user->supports(qw/password crypted/) ) {
        my $crypted = $user->crypted_password;
        return $crypted eq crypt( $password, $crypted );
    }
    elsif ( $user->supports(qw/password hashed/) ) {

        my $d = Digest->new( $user->hash_algorithm );
        $d->add( $user->password_pre_salt || '' );
        $d->add($password);
        $d->add( $user->password_post_salt || '' );

        my $stored      = $user->hashed_password;
        my $computed    = $d->clone()->digest;
        my $b64computed = $d->clone()->b64digest;

        return ( ( $computed eq $stored )
              || ( unpack( "H*", $computed ) eq $stored )
              || ( $b64computed eq $stored)
              || ( $b64computed.'=' eq $stored) );
    }
    elsif ( $user->supports(qw/password salted_hash/) ) {
        require Crypt::SaltedHash;

        my $salt_len =
          $user->can("password_salt_len") ? $user->password_salt_len : 0;

        return Crypt::SaltedHash->validate( $user->hashed_password, $password,
            $salt_len );
    }
    elsif ( $user->supports(qw/password self_check/) ) {

        # while somewhat silly, this is to prevent code duplication
        return $user->check_password($password);

    }
    else {
        Catalyst::Exception->throw(
                "The user object $user does not support any "
              . "known password authentication mechanism." );
    }
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Credential::Password - Compatibility shim

=head1 DESCRIPTION

THIS IS A COMPATIBILITY SHIM.  It allows old configurations of Catalyst
Authentication to work without code changes.  

B<DO NOT USE IT IN ANY NEW CODE!>

Please see L<Catalyst::Authentication::Credential::Password> for more information.

=head1 METHODS

=head2 login( )

=cut
