package Apache::AuthenMSAD;

use mod_perl;
use Apache::Access::Headers;
use Apache::Log ;
use Apache::Request;
use Apache::Constants qw(HTTP_UNAUTHORIZED HTTP_INTERNAL_SERVER_ERROR DECLINED HTTP_FORBIDDEN OK) ;
use Net::LDAP;
use strict;

$Apache::AuthenMSAD::VERSION = '0.02';

# $Id: AuthenMSAD.pm,v 1.7 2005/11/29 13:46:04 reggers Exp $

sub handler
{
   my $r = shift;
   # Continue only if the first request.

   # return OK unless $r->is_initial_req;

   # Grab the password, or return in HTTP_UNAUTHORIZED

   my ($res, $pass) = $r->get_basic_auth_pw;
   return $res if $res;

   my $user = $r->user;

   my $domain = $r->dir_config('MSADDomain') || "no-domain";
   my $server = $r->dir_config('MSADServer') || $domain;

   if ($pass eq "") {
      $r->note_basic_auth_failure;
      $r->log_reason("user - no password supplied",$r->uri);
      return Apache::Constants::HTTP_UNAUTHORIZED;
   }

   if ($user eq "") {
      $r->note_basic_auth_failure;
      $r->log_reason("user - no userid supplied",$r->uri);
      return Apache::Constants::HTTP_UNAUTHORIZED;
   }

   my $ldap = Net::LDAP->new($server, version=>3);
   unless ($ldap) {
      $r->note_basic_auth_failure;
      $r->log_reason("user - MSAD LDAP Connect Failed",$r->uri);
      return Apache::Constants::HTTP_UNAUTHORIZED;
   }

   my $result= $ldap->bind (dn => "$user\@$domain", password => $pass);
   if (!$result || ($result && $result->code)) {
      $r->note_basic_auth_failure;
      $r->log_reason("user - Active Directory Authen Failed",$r->uri);
      return Apache::Constants::HTTP_UNAUTHORIZED;
   }

   return Apache::Constants::OK;
}


1;


__END__


=head1 NAME

Apache::AuthenMSAD - Microsoft Active Directory authentication for Apache

=head1 SYNOPSIS

    <Directory /foo/bar>
    # Authentication Realm and Type (only Basic supported)

    AuthName "Microsoft Active Directory Authentication"
    AuthType Basic

    # Authentication  method/handler

    PerlAuthenHandler Apache::AuthenMSAD

    # The Microsoft Active Directory Domain Name must be set
    # The Active Directory Server Name will default to the domain.

    PerlSetVar MSADDomain ads.foo.com
    PerlSetVar MSADServer dc.ads.foo.com

    # Require lines can be any of the following -- any user, one of a list

    require valid-user
    require user joe mary tom
    </Directory>

    These directives can also be used in a .htaccess file.

=head1 DESCRIPTION

This module is a backport of Apache2::AuthenMSAD v.0.02.  The rest of
this description is from the orginal authors of that module.

This perl module is designed to work with mod_perl and Net::LDAP. It
will authenticate users in a Windows 2000 or later Microsoft Active
Directory -- hence the acronym MSAD. Configuration parameters give the
DNS name used for the cluster of Microsoft Domain Controllers and the
Microsoft Domain name used within the Active Directory.

This relies on a surprising feature first brought to our attention by
Yvan Rodrigues here at the University of Waterloo. You can
authenticate with a Distinguished Name like "reggers@ads.foo.com"
(ie. the userPrincipalName in the Active Directory) and you don't need
to resort to the X509 Distinguished Name. Most LDAP authentication
methods require a guest account where you can login to find the user's
Distinguished Name and then login again as that name. Active Directory
has this extra feature which makes life much simpler.

At our site the domain mentioned in the userPrincipalName is
"ads.uwaterloo.ca" -- that is also the name we use for our collection
of Domain Controllers. You might not implement that convention. If you
do the MSADServer parameter is optional -- it defaults to the
MSADDomain. This version is patched to use mod_per2 (>=2.0x) and apache2.
It was tested in an production environment to work perfectly.

=head1 BEWARE

This builds on the Net::LDAP interface and as such passes the userid
and password in the clear. We've not been able to get Net::LDAPS to
work with Microsoft Active Directory. If anyone else has we'd dearly
love to hear from them.

=head1 AUTHOR

Yvan Rodrigues <yrodrigu@uwaterloo.ca>
Reg Quinton <reggers@ist.uwaterloo.ca>
Franz Skale <franz.skale@cubit.at>

Ported to mod_perl1 by Andrew McGregor C<< <andy@txm.mobi> >>, <L<http://www.txm.net>>

=head1 COPYRIGHT

Copyright (c) 2005-2007 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

