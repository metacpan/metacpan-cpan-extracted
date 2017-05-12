package Apache::TransLDAP;
package Apache::TransLDAP;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;
use Apache::Constants ':common';
use Net::LDAPapi;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);
$VERSION = '0.20';

sub handler
{
   my $r = shift @_;

   my $URI = $r->uri;
   my $USERDIR = $r->dir_config("UserDir") || "/users/";
   my $LDAPSERVER = $r->dir_config("LDAPServer");
   my $LDAPPORT = $r->dir_config("LDAPPort") || 389;
   my $LDAPBASE = $r->dir_config("LDAPBase");
   my $UIDATTR = $r->dir_config("UIDAttr") || "uid";
   my $URIATTR = $r->dir_config("URIAttr") || "labeleduri";

   if ($URI =~ /^$USERDIR/)
   {
      $URI =~ s/$USERDIR//;
      my $user;
      if ($URI =~ /\//)
      {
         $URI =~ s/^(.*)\///;
         $user = $1;
      } else {
         $URI =~ s/^(.*)$//;
         $user = $1;
      }

      if (!$user)
      {
         return DECLINED;
      }

      my $ldap = new Net::LDAPapi($LDAPSERVER,$LDAPPORT);
      $ldap->bind_s;

      my $filter = "($UIDATTR=$user)";

      my @attrs = ($URIATTR);

      if ($ldap->search_s($LDAPBASE,LDAP_SCOPE_SUBTREE,$filter,\@attrs,0)
             != LDAP_SUCCESS)
      {
         $r->warn("Search Failed");
         $ldap->unbind;
         return DECLINED;
      }

      if (!$ldap->first_entry)
      {
         $r->warn("No First Entry");
         $ldap->unbind;
         return DECLINED;
      }

      my @uris = $ldap->get_values($URIATTR);

      $ldap->unbind;

      if ($#uris < 0)
      {
         $r->warn("No labeledURIs");
         return DECLINED;
      }

      if ($uris[0] =~ /\/$/)
      {
         $URI = $uris[0] . $URI;
      } else {
         $URI = $uris[0];
      }

      $r->uri($URI);

      if ($r->args)
      {
         $URI .= "?" . $r->args;
      }

      $r->content_type("text/html");
      $r->header_out(Location=>$URI);
      $r->header_out(URI=>$URI);
      $r->status(301);
      return (301);
   }
   return DECLINED;
}
1;
__END__

=head1 NAME

Apache::TransLDAP - An Apache+mod_perl Trans Handler

=head1 SYNOPSIS

  PerlSetVar LDAPServer ldaphost.my.org   # Default: localhost
  PerlSetVar LDAPPort   389               # Default: 389
  PerlSetVar LDAPBase   o=My,c=US         # Default: Empty String
  PerlSetVar UIDAttr    uid               # Default: uid
  PerlSetVar URIAttr    labeledURI        # Default: labeledURI

  PerlTransHandler Apache::TransLDAP

=head1 DESCRIPTION

This module is designed to work with mod_perl and my Net::LDAPapi
module (http://www.wwa.com/~donley/).  Future versions will use
PerLDAP.

This is mostly an example of how a Trans handler can be implemented
in Perl.  Be sure to enable Trans handlers when configuring and
installing mod_perl.

I welcome feedback on this module and any others I've developed.

=head1 AUTHOR

Clayton Donley <donley@wwa.com>
http://www.wwa.com/~donley/

=head1 COPYRIGHT

Copyright (c) 1998 Clayton Donley - All Rights Reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
