package Apache2::AuthZLDAP;

use warnings;
use strict;
use mod_perl2;
BEGIN {
		require Apache2::Const;
		require Apache2::Access;
		require Apache2::SubRequest;
		require Apache2::RequestRec;
		require Apache2::RequestUtil;
		require Apache2::Response;
		require APR::Table;
		Apache2::Const->import(-compile => 'HTTP_UNAUTHORIZED','OK', 'HTTP_INTERNAL_SERVER_ERROR');
		require Apache2::Log;
		require Apache2::Directive;
		require Net::LDAP;
} 
=head1 NAME

Apache2::AuthZLDAP - Authorization module based on LDAP filters or LDAP groups

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module is an authorization handler for Apache 2. Its authorization method relies on openLDAP filters.

=head1 CONFIGURATION

This module can work with all authentification module that provides a valid REMOTE_USER env var. For example :

=over

=item *
Basic Apache auth

=item *
CAS authentication (mod_cas, Apache2::AuthCAS)

=back 

Example with CAS authentication :

    <VirtualHost 192.168.0.1:80>
    ## these vars can be initialized outside of directory 
    PerlSetVar LDAPURI             ldap://myldaphost/
    PerlSetVar LDAPbaseDN          ou=groups,dc=organization,dc=domain

 
    <Directory "/var/www/somewhere">
    AuthName CAS
    AuthType CAS
    ## define a filter. [uid] will be replaced by user value on runtime 
    PerlSetVar LDAPfilter          &(member=uid=[uid],ou=people,dc=organization,dc=domain)(cn=admins)
    ## charging of the module for authZ
    PerlAuthzHandler Apache2::AuthZLDAP
    require valid-user
    </Directory>

    </VirtualHost>

=head2 Configuration Options

    # Set to the LDAP URI
    # Multiple URIs can be set for failover LDAP servers
    # Note: ldaps Defaults to port 636
    PerlSetVar LDAPURI          ldap://ldaphost1
    PerlSetVar LDAPURI          ldaps://ldaphost2
    PerlSetVar LDAPURI          ldap://ldaphost3:1001

    # How to handle the certificate verification for ldaps:// URIs
    # See start_tls in Net::LDAP for more information
    # If you set any of the LDAPSSL* variables, be sure to include only
    # ldaps:// URIs. Otherwise the connection will fail.
    # (none|optional|require)
    PerlSetVar LDAPSSLverify    none

    # Set to a directory that contains the CA certs
    PerlSetVar LDAPSSLcapath    /path/to/cadir

    # Set to a file that contains the CA cert
    PerlSetVar LDAPSSLcafile    /path/to/cafile.pem

    # Turn on TLS to encrypt a connection
    # Note: This is different from ldaps:// connections. ldaps:// specifies
    # an LDAP connection totally encapsulated by SSL usually running on a 
    # different port. TLS tells the LDAP server to encrypt a cleartext ldap://
    # connection from the time the start_tls command is issued.
    # (yes|no)
    PerlSetVar LDAPTLS          yes

    # How to handle the certificate verification
    # See start_tls in Net::LDAP for more information
    # (none|optional|require)
    PerlSetVar LDAPTLSverify    none

    # Set to a directory that contains the CA certs
    PerlSetVar LDAPTLScapath    /path/to/cadir

    # Set to a file that contains the CA cert
    PerlSetVar LDAPTLScafile    /path/to/cafile.pem

    # Specifies a user/password to use for the bind
    # If LDAPuser is not specified, AuthZLDAP will attempt an anonymous bind
    PerlSetVar LDAPuser         cn=user,o=org
    PerlSetVar LDAPpassword     secret

    # Sets the LDAP search scope
    # (base|one|sub)
    # Defaults to sub
    PerlSetVar LDAPscope        sub

    # Defines the search filter
    # [uid] will be replaced by the username passed in to AuthZLDAP
    PerlSetVar LDAPfilter       &(member=uid=[uid],ou=people,dc=organization,dc=domain)(cn=admins)

=cut

sub handler{
    my $r= shift;
    return Apache2::Const::OK unless $r->is_initial_req;

    ## Location Variables to connect to the good server
    my @LDAPURI = $r->dir_config->get('LDAPURI');

    my $LDAPSSLverify = lc($r->dir_config('LDAPSSLverify'));
    my $LDAPSSLcapath = $r->dir_config('LDAPSSLcapath');
    my $LDAPSSLcafile = $r->dir_config('LDAPSSLcafile');
    
    my $LDAPTLS =  lc($r->dir_config('LDAPTLS')) || "no";
    my $LDAPTLSverify = lc($r->dir_config('LDAPTLSverify'));
    my $LDAPTLScapath = $r->dir_config('LDAPTLScapath');
    my $LDAPTLScafile = $r->dir_config('LDAPTLScafile');

    if($LDAPTLS ne "yes" && $LDAPTLS ne "no"){
	$LDAPTLS="no";
    }

    ## bind
    my $LDAPuser = $r->dir_config('LDAPuser'); 
    my $LDAPpassword = $r->dir_config('LDAPpassword');

    ## baseDN and Filters
    my $LDAPbaseDN = $r->dir_config('LDAPbaseDN');
    my $LDAPscope =  lc($r->dir_config('LDAPscope'));
    my $LDAPfilter = $r->dir_config('LDAPfilter');

    if($LDAPscope ne 'base' && $LDAPscope ne 'one' && $LDAPscope ne 'sub'){
        $LDAPscope = 'sub';
    }
    
    my $location = $r->location;
    
    ## Some error checking
    if (not @LDAPURI) {
        $r->log_error("Apache2::AuthZLDAP : $location, did not specify a LDAPURI");
	return Apache2::Const::HTTP_UNAUTHORIZED; 
    }

    if (not defined $LDAPfilter) {
        $r->log_error("Apache2::AuthZLDAP : $location, did not specify a LDAPfilter");
	return Apache2::Const::HTTP_UNAUTHORIZED; 
    }

    ## did user authentified ?
    ## retrieval of user id
    my $user = $r->user;
    if (not defined $user){
	$r->log_error("Apache2::AuthZLDAP : $location, user didn't authentify uid empty");
	return Apache2::Const::HTTP_UNAUTHORIZED; 
    }else{
	$LDAPfilter =~ s/\[uid\]/$user/;
    }

    ## port initialisation
    my $session; ## TODO make this come from a pool maybe?
    my $mesg;

    unless ($session = Net::LDAP->new(\@LDAPURI, capath=>$LDAPSSLcapath, cafile=>$LDAPSSLcafile, verify=>$LDAPSSLverify)) {
        $r->log_error("Apache2::AuthZLDAP : $location, LDAP error cannot create session");
        return Apache2::Const::HTTP_UNAUTHORIZED;
    }
    
    if ($LDAPTLS eq 'yes') {
        $mesg = $session->start_tls(capath=>$LDAPTLScapath, cafile=>$LDAPTLScafile, verify=>$LDAPTLSverify);
	if ($mesg->code) {
             $r->log_error("Apache2::AuthZLDAP : $location, LDAP error could not start TLS : ".$mesg->error);
	}
        return Apache2::Const::HTTP_UNAUTHORIZED;
    }
    
    ## user password bind if configured else anonymous
    if (defined $LDAPuser and defined $LDAPpassword){
        $mesg = $session->bind($LDAPuser,password=>$LDAPpassword);
    }else{
        $mesg = $session->bind();
    }

    if($mesg->code){
	my $err_msg = 'LDAP error cannot bind ';
        if (defined $LDAPuser){
             $err_msg .= "as $LDAPuser";
        }else{
             $err_msg .= 'anonymously';
        }
        $r->log_error("Apache2::AuthZLDAP : $location, $err_msg : ".$mesg->error);
        return Apache2::Const::HTTP_UNAUTHORIZED; 
    }
    
    ## search performing, if there is a result, OK
    $mesg = $session->search( # perform a search
			   base   => $LDAPbaseDN,
			   scope => $LDAPscope,
			   filter => $LDAPfilter,
			   );
    if ($mesg->code) {
         $r->log_error("Apache2::AuthZLDAP : $location, LDAP error could not search : ".$mesg->error);
	return Apache2::Const::HTTP_UNAUTHORIZED;
    }
    if ($mesg->count != 0){
	$r->log->notice("Apache2::AuthZLDAP : $user authorized to access $location");  
	$session->unbind;
	return Apache2::Const::OK;
    }else{
	$session->unbind;
	$r->log_error("Apache2::AuthZLDAP : $user not allowed to access $location");
	return Apache2::Const::HTTP_UNAUTHORIZED;
    }
}

=head1 AUTHOR

Dominique Launay, C<< <dominique.launay AT cru.fr> >>
Thanks to David Lowry, C<< <dlowry AT bju.edu> >>  for making the code more readable and improving it.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://sourcesup.cru.fr/tracker/?func=add&group_id=354&atid=1506>
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache2::AuthZLDAP


=over 4


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dominique Launay, all rights reserved.

This program is released under the following license: GPL

=cut

1; # End of Apache2::AuthZLDAP
