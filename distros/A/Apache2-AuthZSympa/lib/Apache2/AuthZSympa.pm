package Apache2::AuthZSympa;

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
		require SOAP::Lite;
		require Apache2::Log;
		require Apache2::Directive;
		require Cache::Memcached;
		use Digest::MD5  qw(md5_hex);
}  

=head1 NAME

Apache2::AuthZSympa - Authorization module based on Sympa mailing list server group definition

=head1 HOMEPAGE

L<http://sourcesup.cru.fr/projects/authsympa/>

=head1 VERSION

Version 0.5.2

=cut

our $VERSION = '0.5.2';
=head1 SYNOPSIS

This module is an authorization handler for Apache 2. Its authorization method relies on mailing lists membership ; it is designed for Sympa mailing list software (http://sympa.org). This authorization handler has been initially designed to work with its peer authentication handler Apache2::AuthNSympa that performs authentication against a Sympa SOAP server. The handler has later been extended to work with third party authentication Apache modules :

=over

=item *
Apache2::AuthNSympa (default)

=item *
SSL authentication (mod_ssl)

=item *
CAS authentication (mod_cas)

=item *
Shibboleth authentication (mod_shib)

=back 

This module needs the associated authentication handler to provide a trusted user email address ; the user email address is later used to query list membership. Because some authentication modules (CAS) don't provide the user email address, the authorization module may be configured to query an LDAP directory. The environment variable name may also be configured (when used with Shibboleth).



=head1 GENERAL CONFIGURATION TIPS

Regardless what authentication module is used, the following rules are  needed in your Apache configuration file :

=over 

=item *
URL of your Sympa SOAP server

=item *
list of mailing lists for which the user has to be a member

=item *
handler calling rule

=item *
optionaly, because SOAP can be slow, you can configure a cache server based on memcached (http://www.danga.com/memcached/).

=back

Of course, your mod_perl2 Apache module has to be correctly configured.

For example, in a location section of your Apache configuration file, you have to put the following rules :

    PerlSetVar SympaSoapServer http://mysympa.server/soap # URL of the sympa SOAP server
    PerlAuthzHandler Apache2::AuthZSympa 
    require SympaLists sympa-users@demo.sympa.org,sympa-test@demo.sympa.org # lists for which the member has to be a member (he needs to be at least a member for one of them)
    PerlSetVar MemcachedServer 10.219.213.24:11211 # URL for cache server (option)
    PerlSetVar CacheExptime 3600 # Cache expiration time in seconds for the cache server (default 1800)

We provide a working example of a web page that has a restricted access for members of test@cru.fr mailing list only. You should subscribe to the test mailing list if you wish to try it : http://listes.cru.fr/sympa/info/test

The following page will request your email address and Sympa password : http://www.cru.fr/demo_authsympa/



=head1 SYMPA AUTHENTICATION MODULE

It is based on a basic  HTTP authentication authentication (popup on client side). Once the user has authenticated, the REMOTE_USER environnement var contains the user email address.  The authentication module implements a SOAP client that validates user credentials against the Sympa SOAP server.
Example: 

    <Directory "/var/www/somewhere">
    AuthName SympaAuth
    AuthType Basic
    PerlSetVar SympaSoapServer http://mysympa.server/soap
    PerlAuthenHandler Apache2::AuthNSympa
    PerlAuthzHandler Apache2::AuthZSympa
    require valid-user
    require SympaLists sympa-users@demo.sympa.org,sympa-test@demo.sympa.org
    </Directory>



=head1 SSL AUTHENTICATION

Mod_ssl can be used to do the user authentication, based on user client certificates. Your mod_ssl configuration should look like this :

=over

=item *
SSLCACertificateFile # or SSLCACertificatePath

=item *
SSLRequireSSL # to prevent from disabling SSL

=item *
SSLVerifyClient require

=item *
AuthType SSL


=back

Because Apache does not consider mod_ssl as an authentication handler, an authentication handler must be  added. So we recommend to call Apache2::AuthNSympa because it is bypassed  if "AuthType" is different from "Sympa" 
The authentication handler will get the expected  user email address extracted from the certificate.

Example :

    <Directory "/var/www/somewhere">
    SSLVerifyClient require 
    SSLRequireSSL 
    SSLOptions +StdEnvVars
    AuthType SSL
    PerlSetVar SympaSoapServer http://mysympa.server/soap
    PerlAuthenHandler Apache2::AuthNSympa
    PerlAuthzHandler Apache2::AuthZSympa
    require SympaLists sympa-users@demo.sympa.org,sympa-test@demo.sympa.org
    </Directory>



=head1 CAS AUTHENTICATION 

CAS is a web single sign-on software, developped by the university of Yale : http://www.ja-sig.org/products/cas/

CAS does not provide any email address . Therefore the authorization module will first query an LDAP directory to get the user email address, given his UID.


Example:

    <Directory "/var/www/somewhere">
    AuthName SympaAuth
    AuthType CAS
    PerlSetVar SympaSoapServer http://mysympa.server/soap
    PerlSetVar MemcachedServer 10.219.213.24:11211
    PerlSetVar CacheExptime 3600 # in seconds, default 1800

    ## here is ldap filters to retrieve user email address
    ## if CAS uid is an email address, no need these directives
    PerlSetVar LDAPHost            ldap.localdomain
    PerlSetVar LDAPSuffix          ou=people
    PerlSetVar LDAPEmailFilter     (uid=[uid])
    PerlSetVar LDAPEmailAttribute  mail
    PerlSetVar LDAPScope           sub

    PerlAuthzHandler Apache2::AuthZSympa
    require valid-user
    require SympaLists sympa-users@demo.sympa.org,sympa-test@demo.sympa.org
    </Directory>



=head1 SHIBBOLETH AUTHENTICATION   

Shibboleth is an open source software developped by Internet2 : http://shibboleth.internet2.edu

The default behavior of mod_shib authentication module is to provide the user email address in the  HTTP_SHIB_INETORGPERSON_MAIL HTTP header. The AuthZSympa module still provides a ShibbolethMailVar parameter to declare which HTTP header contains the user email address, if not the default one.

The following rules are required:

=over

=item *
AuthType shibboleth

=item *    
require valid-user

=item *
ShibbolethMailVar (if not HTTP_SHIB_INETORGPERSON_MAIL)

=back

Example:
 
    <Directory "/var/www/somewhere">

    AuthType shibboleth
    PerlSetVar SympaSoapServer http://mysympa.server/soap
    PerlSetVar MemcachedServer 10.219.213.24:11211
    PerlSetVar CacheExptime 3600 # in seconds, default 1800

    PerlSetVar ShibbolethMailVar            HTTP_SHIB_INETORGPERSON_MAIL 
    PerlAuthzHandler Apache2::AuthZSympa
    require valid-user
    require SympaLists sympa-users@demo.sympa.org,sympa-test@demo.sympa.org
    </Directory>



=head1 COMPLETE MODULE RULES LIST

    # required to identify the good authentication type
    AuthType CAS # can be SSL, Sympa or shibboleth
    
    # URL to query Sympa server SOAP interface, required
    PerlSetEnv SympaSoapServer
    
    # lists to verify membership of user, required
    require SympaLists list1@mydomain,list2@mydomain
    
    # IP address and port of memcached server if necessary
    PerlSetEnv MemcachedServer 192.168.0.1:11211

    # Cache expiration time in seconds if memcached server used, default 1800
    PerlSetEnv CacheExptime 3600
    
    # LDAP Host for CAS backend
    PerlSetEnv LDAPHost ldap.mydomain
    
    # LDAP suffix to query LDAP backend
    PerlSetenv LDAPSuffix o=people
        
    # Filter to query LDAP backend. It has to match uid provided by CAS server
    PerlSetenv LDAPEmailFilter  myIdAttribute=([uid])
    
    # LDAP backend attribute containing email address
    PerlSetenv LDAPEmailAttribute mail
    
    # LDAP scope, default sub
    PerlSetenv LDAPScope sub
    
    # Shibboleth env var to match email address. optional, default HTTP_SHIB_INETORGPERSON_MAIL
    PerlSetenv ShibbolethMailVar HTTP_SHIB_INETORGPERSON_MAIL 
    

=cut

sub handler{
    my $r= shift;
    return Apache2::Const::OK unless $r->is_initial_req;
    ## Location Variables to connect to the good server
    my $SympaSoapServer = $r->dir_config('SympaSoapServer') || "localhost"; ## url of sympa soap server
    my $cacheserver = $r->dir_config('MemcachedServer') || "127.0.0.1:11211"; ## cache server
    my $exptime = $r->dir_config('CacheExptime') || 1800; ## 30 minutes of cache
    my $ShibMailVar = $r->dir_config('ShibbolethMailVar') || 'HTTP_SHIB_INETORGPERSON_MAIL';
    my $SympaList = ""; ## list for which the mail will be checked
    my $mail_user;
    my $response;
    my $result;
    my $auth_type = lc($r->auth_type);
    
    my $requires = $r->requires;
    my $location = $r->location;

    

    # verify if require SympaLists is present
    for my $entry (@$requires){
	my $requirement;
	if ($entry->{requirement} =~ /SympaLists/){
	    ($requirement,$SympaList) = split(/\s+/,$entry->{requirement});
	    $r->log->debug("Apache2::AuthZSympa : require type '$requirement' for $location with lists $SympaList");
	    last;
	}
    }
    
    my @SympaLists = split(/\,/,$SympaList);

 
    ## instanciation of a new Soap::Lite object
    my $soap;
    my $soap_error=0;
    my $soap_session;
    my $soap_res;
    unless($soap = new SOAP::Lite()){
	$r->log_error("Apache2::AuthZSympa : Unable to create SOAP::Lite object while accessing $location");
	return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    }
    ## if there is an error during soap request. $soap_error will be instanciated
    $soap->on_fault(sub {
	($soap_session, $soap_res) = @_;
	$soap_error=1;
    }); 
    $soap->uri('urn:sympasoap');
    $soap->proxy($SympaSoapServer);

    
    unless(defined $soap){
	return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    }

    ## instanciation of cache
    ## preventing from errors, verification of its naming
    unless( $cacheserver =~ /[^\:]+\:\d{1,6}/){
	$r->log_error("Apache2::AuthZSympa configuration ($location) : memcached server ($cacheserver) naming format is incorrect, a port number is required");
	return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    }
    my $cache = new Cache::Memcached {
	'servers' => [ $cacheserver ],
	'namespace' => 'AuthZSympa',
    };



    ## if an email from SSL request is got, then authentication was made via SSL
    $r->subprocess_env;
    my $subr = $r->lookup_uri($r->uri);
    my $ssl_proto = $subr->subprocess_env('SSL_CLIENT_S_DN_Email');
    if ($subr->subprocess_env('SSL_CLIENT_S_DN_Email') && ($auth_type eq "ssl")){
	$mail_user=$subr->subprocess_env('SSL_CLIENT_S_DN_Email');
	$r->user($mail_user);
    }elsif($auth_type eq 'basic' && $r->user){
	## if basic_auth, get remote_user
	$mail_user= $r->user;
    }elsif($auth_type eq 'cas'){
	## if CAS
	my $user = $r->user;
	$mail_user = "";

        ## verification of ldap directives
	my $ldap_host = $r->dir_config('LDAPHost') || "";
	if ($ldap_host eq ""){
	    $r->log->debug("Apache2::AuthZSympa : no LDAPHost, email adress in uid ?");
	    if ($user =~ /@/){
		## if user is emailAddress, don't need ldap to retrieve emailadddress
		$r->log->debug("Apache2::AuthZSympa : no need with LDAP, email adress in uid");
		$mail_user = $user;
	    }else{
		$r->log_error("Apache2::AuthZSympa : no ldap_host defined for $location, can't verify registrations");
		return Apache2::Const::HTTP_UNAUTHORIZED;
	    }
	}
	## key for cache (key for email)
	my $user_key = md5_hex($r->user.$ldap_host);
	
	
	## verification first in cache
	if (defined $cache->get($user_key)){
	    $r->log->debug("Apache2::AuthZSympa : retrieve mail from cache for $user_key");
	    $mail_user = ${$cache->get($user_key)};
	    $r->log->debug("Apache2::AuthZSympa : retrieved mail ($mail_user) from cache") if $mail_user ne "";
	}
	## then retrieve mail from ldap
	if ($mail_user eq ""){
	    $r->log->debug("Apache2::AuthZSympa : retrieve mail from LDAP");
	    $mail_user = &casGetMail($r);
	}
	if ($mail_user ne ""){
	    $r->log->debug("Apache2::AuthZSympa : retrieved mail $mail_user");
	    $cache->set($user_key,\$mail_user,$exptime);
	}else{
	    $r->log_error("Apache2::AuthZSympa : no mail for $user in $ldap_host");
	    return Apache2::Const::HTTP_UNAUTHORIZED;
	}
	
    }elsif($auth_type eq 'shibboleth'){

	$mail_user=$ENV{$ShibMailVar};
	if($mail_user eq ""){
	    $r->log_error("Apache2::AuthZSympa : no mail in var $ShibMailVar");
	    $r->log->debug("Apache2::AuthZSympa : $ShibMailVar value : $mail_user");
	    return Apache2::Const::HTTP_UNAUTHORIZED;   
	}else{
	    $r->log->debug("Apache2::AuthZSympa : $ShibMailVar value : $mail_user");
	}
    
    }else{
	$r->log_error("Apache2::AuthZSympa : no user authenticated for $location, can't verify registrations");
	return Apache2::Const::HTTP_UNAUTHORIZED;
    }
    
    ## key generation for cache : md5($mail_user + server name) -> prevents from errors when updating 
    my $user_key = md5_hex($mail_user.$SympaSoapServer);

    ## verify subscription first in cache
    ## if its in the cache as OK for the list, go, 
    ## if its in all the list as not OK, refuse
    ## else, next step
    my %cache_lists;
    if (defined $cache){
	 if (defined $cache->get($user_key)){
	     %cache_lists = %{$cache->get($user_key)};
	 }
	 my $ok=1;
	 foreach my $list (@SympaLists){
	     if (defined $cache_lists{$list}){
		 if ($cache_lists{$list} == 1){
		     return Apache2::Const::OK;
		 }elsif($cache_lists{$list} == 0){
		     $ok = 0;
		 } 
	     }
	 }
	 if ($ok == 0){
	     my $lists_string = join(", nor in ",@SympaLists);
	     $r->log->notice("Apache2::AuthZSympa : $location. $mail_user is not registred on server $SympaSoapServer in ",$lists_string);  
	     return Apache2::Const::HTTP_UNAUTHORIZED;
	 }
     }
    ## if not in cache, verify soap server
    foreach my $list (@SympaLists){
	$r->log->debug("Apache2::AuthZSympa liste $list");
	$soap_error=0;
	$list =~ s/\s//g;
	$response = $soap->amI($list,'subscriber',$mail_user);
	## verify if error during soap service request
	if ($soap_error==1){
	    my ($type_error,$detail) = &traite_soap_error($soap, $soap_res);
	    if ($type_error eq 'ERROR'){
		$r->log_error("Apache2::AuthZSympa : $location, SOAP error $detail (server $SympaSoapServer)");
	    }else{
		$r->log->notice("Apache2::AuthZSympa : $location, $detail (server $SympaSoapServer)");
	    };
	    $cache_lists{$list} = 0;
	    next;
	}else{
	    $result = $response->result;
	    if ($result == 1){
		if (defined $cache){
		    $cache_lists{$list} = 1;
		    $cache->set($user_key, \%cache_lists,$exptime);
		}
		return Apache2::Const::OK;
	    }else{
		$cache_lists{$list} = 0;
	    }	    
	}
    }
    $cache->set($user_key, \%cache_lists,$exptime);
    my $lists_string = join(", nor in ",@SympaLists);
    $r->log->notice("Apache2::AuthZSympa : $location. $mail_user is not registred on server $SympaSoapServer in ",$lists_string);  
    return Apache2::Const::HTTP_UNAUTHORIZED;	


}

sub traite_soap_error {
    my ($soap, $res) = @_;
    my $detail = "";
    my $type = "";

    if(ref(\$res) eq 'REF'){
	$detail = $res->faultdetail;
	$type = "NOTICE";
    }else{
	$detail = $soap->transport->status;
	$type = "ERROR";
    };
    return ($type, $detail);
}

sub casGetMail(){
    my ($r) = @_;
    my $error="";
    use Net::LDAP;
    my $user = $r->user;
    my $ldap_host = $r->dir_config('LDAPHost');
    my $ldap_suffix = $r->dir_config('LDAPSuffix');
    my $uid_filter = $r->dir_config('LDAPEmailFilter');
    my $attribute = $r->dir_config('LDAPEmailAttribute');
    my $scope = $r->dir_config('LDAPScope') || "sub";
    my $location = $r->location;
    my $ldap;
    unless($ldap = Net::LDAP->new($ldap_host)){
	$r->log_error("Apache2::AuthZSympa : $location, unable to create Net::LDAP object with $ldap_host"); 
	return "";
    }
    my $mesg; 
    unless($mesg = $ldap->bind){
	$r->log_error("Apache2::AuthZSympa : $location, unable to bind $ldap_host");
	return "";
    }
    my $filter = $uid_filter;
    $filter =~ s/\[uid\]/$user/;
    $mesg = $ldap->search( # perform a search
			   base   => $ldap_suffix,
			   scope => $scope,
			   attrs => [$attribute],
			   filter => $filter,
			   );
    my $nb_entries = $mesg->count;
    if(($nb_entries == 0) | ($nb_entries>1)){
	$r->log->notice("Apache2::AuthZSympa : $location, $nb_entries entries returned while querying $ldap_host, maybe wrong parameter ?"); 
	$ldap->unbind;
	return "";
    }
    my $entry = $mesg->entry(0);
    my $mail_user = $entry->get_value($attribute);
    $ldap->unbind;
    return $mail_user;
    
}
=head1 AUTHOR

Dominique Launay,Comite Reseau des Universites, C<< <dominique.launay AT cru.fr> >>


=head1 COPYRIGHT & LICENSE

Copyright 2005 Comite Reseau des Universites L<http://www.cru.fr> All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache2::AuthZSympa
