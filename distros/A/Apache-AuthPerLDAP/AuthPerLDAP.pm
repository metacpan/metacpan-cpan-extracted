package Apache::AuthPerLDAP;

use mod_perl;
use Apache::Constants qw(OK AUTH_REQUIRED);
use Mozilla::LDAP::Conn;

use strict;

$Apache::AuthPerLDAP::VERSION = '0.5';

sub handler {
    my $r = shift;
    my ($result, $password) = $r->get_basic_auth_pw;
    return $result if $result;

    my $username = $r->connection->user;

    my $basedn = $r->dir_config('BaseDN') || "";
    my $ldapserver = $r->dir_config('LDAPServer') || "localhost";
    my $ldapport = $r->dir_config('LDAPPort') || 389;
    my $uidattr = $r->dir_config('UIDAttr') || "uid";

    if ($password eq "") {
        $r->note_basic_auth_failure;
        $r->log_reason("user $username: no password supplied",$r->uri);
        return AUTH_REQUIRED;
    }

    my $conn = new Mozilla::LDAP::Conn({ "host" => $ldapserver, 
                                         "port" => $ldapport} );
    unless($conn) {
        $r->note_basic_auth_failure;
        $r->log_reason("user $username: LDAP Connection Failed",$r->uri);
        return AUTH_REQUIRED;
    }
#
# Attempt to find the user using as user attribute the value of UIDAttr
#
    my $entry = $conn->search($basedn, "SUB", "($uidattr=$username)", 0, ($uidattr));

    unless ($entry) {
        $r->note_basic_auth_failure;
        $r->log_reason("user $username: username not found",$r->uri);
        return AUTH_REQUIRED;
    }

# Found username in LDAP database, get its DN

    my $dn = $entry->getDN();

#
# Try to rebind with the users DN and password.
#

    unless (($dn ne "") && ($conn->simpleAuth($dn, $password))) {
        $r->note_basic_auth_failure;
        $r->log_reason("user $username: invalid password", $r->uri);
        return AUTH_REQUIRED;
    }

return OK;

} # End of handler()

1;

__END__

=head1 NAME

Apache::AuthPerLDAP - mod_perl PerLDAP Authentication Module

=head1 SYNOPSIS

    <Directory /foo/bar>
    # Authentication Realm and Type (only Basic supported)
    AuthName "Foo Bar Authentication"
    AuthType Basic

    # Any of the following variables can be set.  
    # Defaults are listed to the right.
    PerlSetVar BaseDN o=Foo,c=Bar        # Default: ""  (empty String)
    PerlSetVar LDAPServer ldap.foo.com   # Default: localhost
    PerlSetVar LDAPPort 389              # Default: 389 (standard LDAP port)
    PerlSetVar UIDAttr uid               # Default: uid
    require valid-user

    PerlAuthenHandler Apache::AuthPerLDAP

    </Directory>

    These directives can also be used in a .htaccess file.

=head1 DESCRIPTION

AuthPerLDAP provides Basic Authentication, with username/password 
lookups against an LDAP server, using Netscape's PerLDAP kit.

It is heavily based on Clayton Donley's Apache::AuthLDAP module, 
but uses the newer Netscape PerLDAP (Mozilla::LDAP), which in turn
uses the Netscape Directory SDK for C. Thus Donley's original 
Net::LDAPapi module and library is no longer required. 

It requires mod_perl and PerLDAP (v1.2 or later). 
Building mod_perl with: 

perl Makefile.PL PERL_AUTHEN=1 PERL_STACKED_HANDLERS=1 PERL_GET_SET_HANDLERS

works for me. If this module is the only Apache/Perl module you are going to use,
you probably don't need anything but the PERL_AUTHEN hook enabled.

Unlike Donley's Apache::AuthLDAP module, AuthPerLDAP is only used for
authentication, and thus only supports the require-user directive.
If a user enters the correct username and password, the authentication 
is considered to be OK. 

=head1 TODO

=over 4

=item *

Find out more about these messages in the error_log:
"child pid 5244 exit signal Segmentation Fault (11)"

=item * 

Further testing.

=item * 

More detailed documentation.

=item * 

Some examples of how to setup and use this module.

=back

=head1 CREDITS

Apache::AuthPerLDAP is greatly inspired by the original Apache::AuthLDAP 
written by Clayton Donley. 

Adoption to PerLDAP was done by reading the PerLDAP source and documentation 
provided by Netscape Corp. and Leif Hedstrom, found at www.perldap.org.

The new book published by O'Reilly & Associates, and authored by Lincoln Stein
and Doug MacEachern helped clarify many mod_perl issues I previously had 
problems with: "Writing Apache Modules with Perl and C" (www.modperl.com).

Andreas K. Sorensen provided usefull Perl wisdom during debugging.

=head1 AUTHOR

Henrik Strom <henrik@computer.org>

=head1 COPYRIGHT

Copyright (c) 1999 Henrik Strom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

mod_perl(1), I<Mozilla::LDAP::Conn>, I<Apache::AuthenCache>.

=cut

