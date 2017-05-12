package Apache::AuthLDAP;

use strict;
use Apache::Constants ':common';
use Net::LDAPapi;

$Apache::AuthLDAP::VERSION = '0.21';

sub handler
{
   my $r = shift;
   my ($res, $sent_pwd) = $r->get_basic_auth_pw;
   return $res if $res;

   my $name = $r->connection->user;

   my $basedn = $r->dir_config('BaseDN') || "";
   my $ldapserver = $r->dir_config('LDAPServer') || "localhost";
   my $ldapport = $r->dir_config('LDAPPort') || 389;
   my $uidattr = $r->dir_config('UIDAttr') || "uid";

   if ($sent_pwd eq "")
   {
      $r->note_basic_auth_failure;
      $r->log_reason("user $name: no password supplied",$r->uri);
      return AUTH_REQUIRED;
   }

   my $ld = new Net::LDAPapi($ldapserver,$ldapport);
   if ($ld <= 0)
   {
      $r->note_basic_auth_failure;
      $r->log_reason("user $name: LDAP Connection Failed",$r->uri);
      return AUTH_REQUIRED;
   }

   if ($ld->bind_s != LDAP_SUCCESS)
   {
      $r->note_basic_auth_failure;
      $r->log_reason("user $name: LDAP Initial Bind Failed",$r->uri);
      return AUTH_REQUIRED;
   }

   my $filter = "$uidattr=$name";
   my $status = $ld->search_s($basedn,LDAP_SCOPE_SUBTREE,$filter,["c"],1);
   if ($status != LDAP_SUCCESS)
   {
      $r->note_basic_auth_failure;
      $r->log_reason("user $name: ldap search failed",$r->uri);
      $ld->unbind;
      return AUTH_REQUIRED;
   }

   if ($ld->count_entries != 1)
   {
      $r->note_basic_auth_failure;
      $r->log_reason("user $name: username not found",$r->uri);
      $ld->unbind;
      return AUTH_REQUIRED;
   }

   $ld->first_entry;

   my $dn = $ld->get_dn;

   $status = $ld->bind_s($dn,$sent_pwd);
   if ($status == LDAP_SUCCESS)
   {
      $r->push_handlers(PerlAuthzHandler => \&authz);
      $ld->unbind;
      return OK;
   }

   $ld->unbind;
   $r->note_basic_auth_failure;
   $r->log_reason("user $name: password mismatch", $r->uri);
   return AUTH_REQUIRED;
}

sub authz
{
   my $r = shift;
   my $requires = $r->requires;
   return OK unless $requires;

   my $name = $r->connection->user;

   my $basedn = $r->dir_config('BaseDN') || "";
   my $ldapserver = $r->dir_config('LDAPServer') || "localhost";
   my $ldapport = $r->dir_config('LDAPPort') || 389;
   my $uidattr = $r->dir_config('UIDAttr') || "uid";

   for my $req (@$requires)
   {
      my ($require, @rest) = split /\s+/, $req->{requirement};

      if ($require eq "user")
      {
         return OK if grep $name eq $_, @rest;
      } elsif ($require eq "valid-user")
      {
         return OK;
      } else {
         my $ld = new Net::LDAPapi($ldapserver,$ldapport);
         $ld->bind_s;
         my $filter = "(&(|($require=" . join(")($require=",@rest) .
               "))($uidattr=$name))";
         my $status = $ld->search_s($basedn,LDAP_SCOPE_SUBTREE,$filter,["c"],1);
         if ($status != LDAP_SUCCESS)
         {
            $r->note_basic_auth_failure;
            $r->log_reason("LDAP Lookup Failed",$r->uri);
            $ld->unbind;
            return AUTH_REQUIRED;
         }
         if ($ld->count_entries == 1)
         {
            $ld->unbind;
            return OK;
         }
         $ld->unbind;
      }
   }

   $r->note_basic_auth_failure;
   $r->log_reason("user $name: not authorized", $r->uri);
   return AUTH_REQUIRED;
}

1;
__END__

=head1 NAME

Apache::AuthLDAP - mod_perl LDAP Access Control and Authentication Module

=head1 SYNOPSIS

    <Directory /foo/bar>
    # Authentication Realm and Type (only Basic supported)
    AuthName "Foo Bar Authentication"
    AuthType Basic

    # Any of the following variables can be set.  Defaults are listed
    # to the right.
    PerlSetVar BaseDN o=Foo,c=Bar        # Default:  Empty String ("")
    PerlSetVar LDAPServer ldap.foo.com   # Default: localhost
    PerlSetVar LDAPPort 389              # Default: 389 (standard LDAP port)
    PerlSetVar UIDAttr uid               # Default: uid

    PerlAuthenHandler Apache::AuthLDAP

    # Require lines can be any of the following:
    #
    require valid-user             # Any Valid LDAP User
    require user uid1 uid2 uid2    # Allow Any User in List
    require ldapattrib val1 val2   # Allow Any User w/ Entry Containing
                                   # Matching Attribute and Value
    </Directory>

    These directives can also be used in a .htaccess file.

= head1 DESCRIPTION

This perl module is designed to work with mod_perl and my Net::LDAPapi
module (http://www.wwa.com/~donley/).

This version of the module does not support access control based on
LDAP groups, but the next release will.  It does support a handy access
control based on attribute and value pairs.  This can be used to restrict
access to people whose LDAP entries contain a given department number, etc...

I welcome feedback on this module and the Net::LDAPapi module.

=head1 AUTHOR

Clayton Donley <donley@wwa.com>

=head1 COPYRIGHT

Copyright (c) 1998 Clayton Donley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

