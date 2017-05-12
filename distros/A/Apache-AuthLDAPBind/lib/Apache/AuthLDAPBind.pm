package Apache::AuthLDAPBind;

use warnings;
use strict;
use Net::LDAP;
use Apache::Constants qw(:common);
=head1 NAME

Apache::AuthLDAPBind - Authentcates a user to Apache by binding to an
                       LDAP server as that user.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This is an authentication module for Apache 1.3 (and mod_perl) that
authenticates a user to an LDAP server by binding as that user (with
his supplied password).  If the bind succeeds, the user is
authenticated.  If not, authentication fails.

This is much more secure than the usual method of checking the
password against a hash, since there's no possibility that the hash
will be viewed while in transit (or worse, simply pulled out of the
LDAP database by an attacker), or that the client somehow miscomputes
the hash (since there are a variety of algorithms for password
hashes).  

Since passwords are being sent to the LDAP server over the network,
the server is required to support SSL.  Authentications will fail if
the server doesn't support StartTLS.  Cutting corners is not an option
when dealing with passwords!

Example Apache 1.3 configuration:

    <Directory /foo/bar>
        # Authentication Realm and Type (only Basic supported)
        AuthName "Foo Bar Authentication"
        AuthType Basic  # use SSL, or your passwords will be sent cleartext!!

        # Any of the following variables can be set.  Defaults are listed
        # to the right.
        PerlSetVar ldap_base_dn o=Foo,c=Bar    # Default: Empty String ("")
        PerlSetVar ldap_server ldap.foo.com    # Default: localhost
        PerlSetVar ldap_server_port 389        # Default: (standard port)
        PerlSetVar ldap_uid_attr uid           # Default: uid

        PerlAuthenHandler Apache::AuthLDAPBind

        # Require lines can be any of the following:
        #
        require valid-user             # Any Valid LDAP User

    </Directory>

    These directives can also be used in a .htaccess file.

=head1 SEE ALSO

I'm pretty sure that Apache::AuthLDAP works similarly, but I couldn't
get it working, and the author's e-mail and website are dead.  If
you're the author, please contact me so we can merge these modules
together and avoid duplication. :)

=head1 FUNCTIONS

All of these functions are standard for Apache mod_perl auth modules.

=head2 handler

=cut

sub handler {
    my $r = shift;
    my ($res, $sent_password) = $r->get_basic_auth_pw;
    return $res if $res;
    
    my $username = $r->connection->user;

    my ($ldap_server, $ldap_port, $base_dn, $uid_attr) = _get_ldap_vars($r);

    if (!$sent_password && $sent_password != 0) { # no need to lock out users
	                                          # whose password is 000000
                                                  # or 0e0, or something.
	$r->note_basic_auth_failure;
	$r->log_reason("user $username: no password supplied",$r->uri);
	return AUTH_REQUIRED;
    }

    my $ok;
    eval {
	$ok = _bind_ldap($ldap_server, $ldap_port, $base_dn, $uid_attr,
			 $username, $sent_password);
    };
    $ok = 0 if $@;
    
    if(!$ok){
	$r->note_basic_auth_failure;
	if (!$@) {
	    $r->log_reason("user $username: ".
			   "password incorrect or user not in LDAP",
			   $r->uri);
	}
	  else {
	      r->log_reason("user $username: LDAP error: $@", $r->uri);
	}
	return AUTH_REQUIRED;
    }
    
    # password was acceptable
    $r->push_handlers(PerlAuthzHandler => \&_authz);
    return OK;

}

sub _authz {
   my $r = shift;
   my $requires = $r->requires;
   return OK unless $requires;
   
   my $name = $r->connection->user;
   
   foreach(@$requires){
       my $requirement = $_->{requirement};

       if ($requirement eq "valid-user"){
	   return OK;
       }
       else {
	   $r->note_basic_auth_failure;
	   $r->log_reason("server config error: unknown requirement '$_'");
	   return AUTH_REQUIRED;
       }
   }

   $r->note_basic_auth_failure;
   $r->log_reason("[bug] fallthrough in Apache::AuthLDAPBind");
   return AUTH_REQUIRED;
}

sub _get_ldap_vars {

    my $r = shift;

    my $ldap_server = $r->dir_config('ldap_server')      || "localhost";
    my $ldap_port   = $r->dir_config('ldap_server_port'); 
    my $base_dn     = $r->dir_config('ldap_base_dn')     || "";
    my $uid_attr    = $r->dir_config('ldap_uid_attr')    || "uid";

    die "_get_ldap_vars not correctly invoked: must be invoked in array context"
      unless wantarray;
    
    return ($ldap_server, $ldap_port, $base_dn, $uid_attr);
}

# returns false if login fails, true if login succeeds.  dies on errors.
sub _bind_ldap {
    my $ldap_server = shift;
    my $ldap_port   = shift;
    my $base_dn     = shift;
    my $uid_attr    = shift;
    my $username    = shift;
    my $password    = shift;

    # prevent anonymous binds!
    if(!defined $username || !defined $password){
	die "null username/password passed to _bind_ldap!";
    }
    
    my $ldap = Net::LDAP->new("$ldap_server". 
			      ((defined $ldap_port) ? ":$ldap_port" : ""));
    
    my $mesg = $ldap->start_tls();
    
    $mesg = $ldap->bind("$uid_attr=$username,$base_dn",
                        password=>$password);
    $ldap->unbind;   # take down session
    
    $mesg->code && return 0; # failed
    return 1; # passed
}

=head1 AUTHOR

Jonathan T. Rockway, C<< <jon-cpan@jrock.us> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache-authldapbind@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache-AuthLDAPBind>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jonathan T. Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache::AuthLDAPBind
