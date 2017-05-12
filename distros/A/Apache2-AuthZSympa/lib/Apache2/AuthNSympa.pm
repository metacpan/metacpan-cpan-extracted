package Apache2::AuthNSympa;

use warnings;
use strict;
use mod_perl2; 

BEGIN{
    require Apache2::Const;
    require Apache2::Access;
    require Apache2::SubRequest;
    require Apache2::RequestRec;
    require Apache2::RequestUtil;
    require Apache2::Response;
    require Apache2::Log;
    use APR::Const    -compile => qw(SUCCESS);
    Apache2::Const->import(-compile => 'HTTP_UNAUTHORIZED','OK', 'AUTH_REQUIRED', 'HTTP_INTERNAL_SERVER_ERROR','DECLINED');
    require SOAP::Lite;
    require Cache::Memcached;
    use Digest::MD5  qw(md5_hex);
}
=head1 NAME

Apache2::AuthNSympa - Authen module using sympa mailing lists server to authenticate

=head1 HOMEPAGE

L<http://sourcesup.cru.fr/projects/authsympa/>

=head1 VERSION

Version 0.5.0

=cut

our $VERSION = '0.5.0';

=head1 SYNOPSIS

Because it's difficult to have an up to date authentication backend, this module aims to authenticate against Sympa mailing lists server.

Sympa mailing lists server has got its own authentication system and can be queried over a SOAP interface.

It is based on a basic HTTP authentication (popup on client side). Once the user has authenticated, the REMOTE_USER environnement var contains the user email address. The authentication module implements a SOAP client that validates user credentials against the Sympa SOAP server. Example:
Sample httpd.conf example:

    <Directory "/var/www/somwehere">
    AuthName SympaAuth
    AuthType Basic
    PerlSetVar SympaSoapServer http://mysympa.server/soap
    PerlSetVar MemcachedServer 10.219.213.24:11211
    PerlSetVar CacheExptime 3600 # in seconds, default 1800

    PerlAuthenHandler Apache2::AuthNSympa
    require valid-user

    </Directory>

=cut
sub handler {
    my $r = shift;
    
    ## Location Variables to connect to the good server
    my $SympaSoapServer = $r->dir_config('SympaSoapServer') || "localhost"; ## url of sympa soap server
    my $cacheserver = $r->dir_config('MemcachedServer') || "127.0.0.1:11211"; ## cache server
    my $exptime = $r->dir_config('CacheExptime') || 1800; ## 30 minutes of cache
    my $mail_user;
    my $response;
    my $result;
    my $AuthenType = "";
    my $auth_type = lc($r->auth_type());
    my $requires = $r->requires;
    my $location = $r->location();

    # verify if require valid-user is present, if not, authentication is not for this module
    for my $entry (@$requires){
	my $requirement = $entry->{requirement};
	if ($requirement eq 'valid-user' && $auth_type eq 'basic'){
	    $AuthenType = 'Sympa';
	    $r->log->debug("Apache2::AuthNSympa : require type '$requirement' for $location ","Sympa");
	    last;
	}else{
	    $r->log->debug("Apache2::AuthNSympa : require type '$requirement' for $location ","other");
	    next;
	}
    }

    if ($AuthenType ne "Sympa"){
	return Apache2::Const::OK;
    };
    

    ## instanciation of a new Soap::Lite object
    my $soap;
    my $soap_session;
    my $soap_res;
    my $soap_error=0;
    unless($soap = new SOAP::Lite()){
	$r->log_error("Apache2::AuthNSympa : Unable to create SOAP::Lite object while accessing $location");
	return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    }

    ## if there is an error during soap request. $soap_error will be instanciated
    $soap->uri('urn:sympasoap');
    $soap->proxy($SympaSoapServer);
    $soap->on_fault(sub{
	($soap_session, $soap_res) = @_;
	$soap_error=1;
    });



    unless(defined $soap){
	$r->log_error("Apache2::AuthNSympa : SOAP::Lite undefined");
	return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    }


    
    ## instanciation of cache
    ## preventing from errors, verification of its naming
    unless( $cacheserver =~ /[^\:]+\:\d{1,6}/){
	$r->log_error("Apache2::AuthNSympa configuration ($location) : memcached server ($cacheserver) naming format is incorrect, a port number is required");
	return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    }
    
    my $cache = new Cache::Memcached {
	'servers' => [ $cacheserver ],
	'namespace' => 'AuthNSympa',
    };

    ##collect informations from connection
    my ($status, $password) = $r->get_basic_auth_pw;
    $mail_user = $r->user;
    unless ($status == Apache2::Const::OK){
	$r->note_basic_auth_failure;
	return $status
    }
    unless ($mail_user && $password){
	$r->note_basic_auth_failure;
	return  Apache2::Const::AUTH_REQUIRED;
    }

    ## key generation for cache : md5($mail_user + server name) -> prevents from errors when updating 
    my $user_key = md5_hex($mail_user.$SympaSoapServer);
    my $hash_pass = md5_hex($password);    
    if (defined $cache){
	my $cache_pass = $cache->get($user_key);
	$cache_pass |= "";
	if ($cache_pass eq $hash_pass){
	    return Apache2::Const::OK;
	} 
    }

    ## authentify using SympaSoapServer
    unless($soap->login($mail_user,$password)){
	$r->note_basic_auth_failure;
	return Apache2::Const::DECLINED;
    }else{
	$response=$soap->login($mail_user,$password);
    }

    ## verify if error during soap service request
    if ($soap_error==1){
	my ($type_error,$detail) = &traite_soap_error($soap, $soap_res);
	if ($type_error eq 'ERROR'){
	    	$r->log_error("Apache2::AuthNSympa : SOAP error $detail while accessing $location");
	    }else{
		$r->log->notice("Apache2::AuthNSympa : $detail ","while accessing $location");
	    };

	$r->note_basic_auth_failure;
	return Apache2::Const::HTTP_UNAUTHORIZED;
    }
    $result = $response->result;
    unless($result){
	$r->log_error("Apache2::AuthNSympa : error, result while accessing $location : $result");
	$r->note_basic_auth_failure;
	return Apache2::Const::AUTH_REQUIRED;
    }
    ## everything is good, people has authenticated

    if (defined $cache){
	$cache->set($user_key, $hash_pass,$exptime);
    }
    $r->log->notice("Apache2::AuthNSympa :  authentication via $SympaSoapServer for $location");
    return Apache2::Const::OK;
    
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

=head1 AUTHOR

Dominique Launay, Comite Reseau des Universites, C<< <dominique.launay AT cru.fr> >>



=head1 COPYRIGHT & LICENSE

Copyright 2005 Comite Reseau des Universites, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache2::AuthNSympa
