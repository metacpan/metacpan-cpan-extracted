package Apache2::AuthenSmb;

use strict;
use Authen::Smb;
use Apache::Htgroup;

$Apache2::AuthenSmb::VERSION = '0.01';

use mod_perl2 ;

use Apache2::Access;
use Apache2::Connection;
use Apache2::Log;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Const -compile => qw(HTTP_UNAUTHORIZED OK);


sub handler {
    my $r = shift;
    my($res, $sent_pwd) = $r->get_basic_auth_pw;
    return $res if $res; #decline if not Basic

    my $name = $r->user;

    my $pdc = $r->dir_config('myPDC');
    my $bdc = $r->dir_config('myBDC') || $pdc;
    my $domain = $r->dir_config('myDOMAIN') || "WORKGROUP";

    if ($name eq "") {
	$r->note_basic_auth_failure;
        $r->log_error("Apache2::AuthenSmb - No Username Given", $r->uri);
        return Apache2::Const::HTTP_UNAUTHORIZED;
    }

    if (!$pdc) {
	$r->note_basic_auth_failure;
        $r->log_error("Apache2::AuthenSmb - Configuration error, no PDC", $r->uri);
        return Apache2::Const::HTTP_UNAUTHORIZED; 
    }

    ## Parse $name's with Domain\Username 
    if ($name =~ m|(\w+)[\\/](.+)|) {
        ($domain,$name) = ($1,$2);
    }

    my $return = Authen::Smb::authen($name,
			     $sent_pwd,
			     $pdc,
			     $bdc,
			     $domain);

    unless($return == 0) {
	$r->note_basic_auth_failure;
	$r->log_error("user $name: password mismatch", $r->uri);
        return Apache2::Const::HTTP_UNAUTHORIZED; 
    }

    unless (@{ $r->get_handlers("PerlAuthzHandler") || []}) {
	$r->push_handlers(PerlAuthzHandler => \&authz);
    }

    return Apache2::Const::OK;
}

sub authz {
    my $r = shift;
    my $requires = $r->requires;
    return Apache2::Const::OK unless $requires;

    my $name  = $r->user; 
    my $error = ""; # Holds error message
    my $authz_username = $r->dir_config('authzUsername') || 'username';

    # Convert 'domain/username' to 'domain\username'
    $name =~ s|/|\\| if $name =~ m|/|;

    if ($authz_username eq 'domain\username') {
        if ($name !~ m/\\/) {
            #If we authzUsername is set to 'domain\username' and $name
            #is not of the form domain\username, then we prepend the domain 
            $name = $r->dir_config('myDOMAIN') . '\\' . $name;
        }
    }
    else {
       #If authzUsername is set to 'username' and $name has if the
       #form domain\username, then set $name = 'username'
       $name = $1 if $name =~ m/\w+\\(.+)/;
    }

    for my $req (@$requires) {
        my($require, @rest) = split /\s+/, $req->{requirement};

	#ok if user is one of these users
	if ($require eq "user") {
	    return Apache2::Const::OK if grep $name eq $_, @rest;
	}
	#ok if user is simply authenticated
	elsif ($require eq "valid-user") {
	    return Apache2::Const::OK;
	}
        #ok if user is in the 
        elsif ($require eq 'group') {
           unless ($r->dir_config('groupFile')) {
              $error = 'Apache2::AuthenSmb - Configuration error: no groupFile' . $r->uri;

	      $r->note_basic_auth_failure;
              $r->log_error($error);

              return Apache2::Const::HTTP_UNAUTHORIZED;
           }
           unless (-e $r->dir_config('groupFile')) {
              $error = 'Apache2::AuthenSmb - groupFile: ' . $r->dir_config('groupFile') . ' does not exist!';

              $r->log_error($error);

              return Apache2::Const::HTTP_UNAUTHORIZED; 
           }

           if ($@) {
              $error = 'Apache2::AuthenSmb - Unable to load Apache::Htgroup: ' . @$;
              $r->log_error($error);

              return Apache2::Const::HTTP_UNAUTHORIZED;
           }

           my $htgrp = Apache::Htgroup->load($r->dir_config('groupFile'));

           foreach my $group (@rest) {
               return Apache2::Const::OK if $htgrp->ismember($name,$group);
           }
        }
    }
    
    $r->note_basic_auth_failure;
    $r->log_error("user $name: not authorized", $r->uri);
	
    return Apache2::Const::HTTP_UNAUTHORIZED; 
}

1;

__END__

=head1 NAME

Apache2::AuthenSMB - mod_perl NT Authentication module


=head1 SYNOPSIS

    <Directory /foo/bar>
    # This is the standard authentication stuff
    AuthName "Foo Bar Authentication"
    AuthType Basic

    # Variables you need to set, you must set at least
    # the myPDC variable, the DOMAIN defaults to WORKGROUP	
    PerlSetVar myPDC workgroup-pdc
    PerlSetVar myBDC workgroup-bdc
    PerlSetVar myDOMAIN WORKGROUP
   
    # Optional Variables
    PerlSetVar groupFile /path/to/htgroups
    # Set the format of the username to check against
    # defaults to username
    PerlSetVar authzUsername username or domain\username

    PerlAuthenHandler Apache2::AuthenSmb

    # Standard require stuff, only user and 
    # valid-user work currently
    require valid-user

    # Optional, reqires that you have Apache::Htgroup
    # require group groupname
    </Directory>

    These directives can be used in a .htaccess file as well.

    If you wish to use your own PerlAuthzHandler then the require 
    directive should follow whatever handler you use.

=head1 DESCRIPTION

This perl module is designed to work with mod_perl and the Authen::Smb
module by Patrick Michael Kane (See CPAN).  You need to set your PDC,
BDC, and NT domain name for the script to function properly.  You MUST
set a PDC, if no BDC is set it defaults to the PDC, if no DOMAIN is
set it defaults to WORKGROUP.

Users can also specify the Windows Domain name along with the username
when authenticating using the format: C<Domain\Username>. The Domain 
specified will override the domain name set in the myDOMAIN 
configuration setting.

= item PerlSetVar myPDC

Set to the FQDN or IP Address of your Primary Domain Controller

= item PerlSetVar my BDC

Set to the FQDN or IP Address of your Backup Domain Controller

= item PerlSetVar myDOMAIN 

Set this to the Domain Name you want to authenticate against 

= item PerlSetVar groupFile

Set this to the path of the htgroup file you wish this module
to check in.  It allows you to specify your users in groups
found on the web server, as opposed to groups within Active 
Directory, etc. 

= item PerlSetVar authzUsername

Set this to "username" or "domain\username" depending on your preference.
(This simply formats the input username to allowing checking the username 
as "domain\username" or "username".)  For example:

# speeves is a DOMAIN user of DOMAIN
domain\username =>  DOMAIN\speeves 

# speeves is a DOMAIN user of DOMAIN,
# but the server administrator wants to
# check this user against groups in the 
# htgroup file as: 

# groupname: speeves userA userB

username => speeves

If you allow users to use B<Domain\Username> and restrict access
using the C<require user username> or C<require group groupname> make
sure to set the username with the domain included. The authorization 
phase will be looking for C<Domain\Username> string.

Example: require user mydomain\ramirezc

=head2 Note
  
If you are using this module please let me know, I'm curious how many
people there are that need this type of functionality.

=head1 AUTHOR

Michael Parker <parkerm@pobox.com>
Ported by Shannon Eric Peevey <speeves@erikin.com>

=head1 COPYRIGHT

Copyright (c) 1998 Michael Parker, Tandem Computers.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
