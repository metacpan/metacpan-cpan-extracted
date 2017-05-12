package Apache::AuthNetLDAP;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Net::LDAP;
use mod_perl;

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.29';

# setting the constants to help identify which version of mod_perl
# is installed
use constant MP2 => ($mod_perl::VERSION >= 1.99);

# test for the version of mod_perl, and use the appropriate libraries
BEGIN {
	if (MP2) {
		require Apache::Const;
		require Apache::Access;
		require Apache::Connection;
		require Apache::Log;
		require Apache::RequestRec;
		require Apache::RequestUtil;
		Apache::Const->import(-compile => 'HTTP_UNAUTHORIZED','OK','DECLINED');
	} else {
		require Apache::Constants;
		Apache::Constants->import('HTTP_UNAUTHORIZED','OK','DECLINED');
	}
}

# Preloaded methods go here.

#handles Apache requests
sub handler
{
   my $r = shift; 

   my ($result, $password) = $r->get_basic_auth_pw;
    return $result if $result; 
 
   # change based on version of mod_perl 
   my $user = MP2 ? $r->user : $r->connection->user;

   my $binddn = $r->dir_config('BindDN') || "";
   my $bindpwd = $r->dir_config('BindPWD') || "";
   my $basedn = $r->dir_config('BaseDN') || "";
   my $ldapserver = $r->dir_config('LDAPServer') || "localhost";
   my $ldapport = $r->dir_config('LDAPPort') || 389;
   my $uidattr = $r->dir_config('UIDAttr') || "uid";
   my $allowaltauth = $r->dir_config('AllowAlternateAuth') || "no"; 
   my $ldapfilter = $r->dir_config('LDAPFilter') || "";
   my $start_TLS = $r->dir_config('UseStartTLS') || "no";
   my $scope = $r->dir_config('SearchScope') || "sub";
   my $pwattr = $r->dir_config('AlternatePWAttribute') || "";
   my $domain = "";

   # remove the domainname if logging in from winxp
   ## Parse $name's with Domain\Username 
   if ($user =~ m|(\w+)[\\/](.+)|) {
       ($domain,$user) = ($1,$2);
   }
   
   if ($password eq "") {
        $r->note_basic_auth_failure;
	MP2 ? $r->log_error("user $user: no password supplied",$r->uri) : $r->log_reason("user $user: no password supplied",$r->uri); 
        return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
   }
 
  
   my $ldap = new Net::LDAP($ldapserver, port => $ldapport);
   if (lc $start_TLS eq 'yes')
   {
       $ldap->start_tls(verify => 'none')
           or MP2 ? $r->log_error( "Unable to start_tls", $r->uri)
                  : $r->log_reason("Unable to start_tls", $r->uri);
   }

   my $mesg;
   #initial bind as user in Apache config
   if ($bindpwd ne "")
   {
       $mesg = $ldap->bind($binddn, password=>$bindpwd);
   }
   else
   {
       $mesg = $ldap->bind();
   }
  
   #each error message has an LDAP error code
   if (my $error = $mesg->code())
   {
        $r->note_basic_auth_failure;
        MP2 ? $r->log_error("user $user: LDAP Connection Failed: $error",$r->uri) : $r->log_reason("user $user: LDAP Connection Failed: $error",$r->uri);
   }
  
  
  #Look for user based on UIDAttr
   my $attrs = [];
   if ($pwattr ne "")
   {
       $attrs = ['dn',$pwattr];
   }
   else
   {
       $attrs = ['dn'];
   }

   my $filter = $ldapfilter
       ? "(&$ldapfilter($uidattr=$user))"
       : "($uidattr=$user)";
  $mesg = $ldap->search(
                  base => $basedn,
                  scope => $scope,                  
                  filter => $filter,
                  attrs => $attrs
                 );

    if (my $error = $mesg->code())
   {
        $r->note_basic_auth_failure;
        MP2 ? $r->log_error("user $user: LDAP Connection Failed: $error",$r->uri) : $r->log_reason("user $user: LDAP Connection Failed: $error",$r->uri);
        return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
   }

   unless ($mesg->count())
   {
        $r->note_basic_auth_failure;
	MP2 ? $r->log_error("user $user: user entry not found for filter: $uidattr=$user",$r->uri) : $r->log_reason("user $user: user entry not found for filter: $uidattr=$user",$r->uri); 
	# If user is not found in ldap database, check for the next auth handler before failing 
	if (lc($allowaltauth) eq "yes")
	{
           return MP2 ? Apache::DECLINED : Apache::Constants::DECLINED; 
        }
        else
        {
           return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
        }
   }
 
   #now try to authenticate as user
   my $entry = $mesg->shift_entry;

   if ( $pwattr ne "" )
   {
       my $altfieldvalue = $entry->get_value ( $pwattr );
       $altfieldvalue =~ s/^\s+//;
       $altfieldvalue =~ s/\s+$//;
       if ($altfieldvalue eq $password)
       {
	   return MP2 ? Apache::OK : Apache::Constants::OK;
       }
       else
       {
	# If user is not found in ldap database, check for the next auth handler before failing 
	if (lc($allowaltauth) eq "yes")
	{
           return MP2 ? Apache::DECLINED : Apache::Constants::DECLINED; 
        }
        else
        {
           return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
        }
       }
   }
   else
   {
       $mesg = $ldap->bind($entry->dn(),password=>$password);
   }
 
  if (my $error = $mesg->code())
  {
        $r->note_basic_auth_failure;
        MP2 ? $r->log_error("user $user: failed bind: $error",$r->uri) : $r->log_reason("user $user: failed bind: $error",$r->uri);
        return MP2 ? Apache::HTTP_UNAUTHORIZED : Apache::Constants::HTTP_UNAUTHORIZED;
   }
        my $error = $mesg->code();
        my $dn = $entry->dn();
        # MP2 ? $r->log_error("AUTHDEBUG user $dn:$password bind: $error",$r->uri) : $r->log_reason("AUTHDEBUG user $dn:$password bind: $error",$r->uri);

 	return MP2 ? Apache::OK : Apache::Constants::OK;
}
# Autoload methods go after =cut, and are processed by the autosplit program.

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Apache::AuthNetLDAP - mod_perl module that uses the Net::LDAP module for user authentication for Apache 

=head1 SYNOPSIS

 AuthName "LDAP Test Auth"
 AuthType Basic

 #only set the next two if you need to bind as a user for searching
 #PerlSetVar BindDN "uid=user1,ou=people,o=acme.com" #optional
 #PerlSetVar BindPWD "password" #optional
 PerlSetVar BaseDN "ou=people,o=acme.com"
 PerlSetVar LDAPServer ldap.acme.com
 PerlSetVar LDAPPort 389
 #PerlSetVar UIDAttr uid
 PerlSetVar UIDAttr mail
 #PerlSetVar AlternatePWAttribute alternateAttribute
 #PerlSetVar SearchScope base | one | sub # default is sub
 #PerlSetVar LDAPFilter "(&(course=CSA)(class=A))" #optional

 # Set if you want to encrypt communication with LDAP server
 # and avoid sending clear text passwords over the network
 PerlSetVar UseStartTLS yes | no
 
 # Set if you want to allow an alternate method of authentication
 PerlSetVar AllowAlternateAuth yes | no

 require valid-user

 PerlAuthenHandler Apache::AuthNetLDAP

=head1 DESCRIPTION

This module authenticates users via LDAP using the Net::LDAP module. This module is Graham Barr's "pure" Perl LDAP API. 

It also uses all of the same parameters as the Apache::AuthPerLDAP, but I have added four extra parameters. 

The parameters are:

=over 4

=item PerlSetVar BindDN

Used to set initial LDAP user.

=item PerlSetVar BindPWD

Used to set initial LDAP password.

=item PerlSetVar BaseDN

This sets the search base used when looking up a user in an LDAP server.

=item PerlSetVar LDAPServer 

This is the hostname of the LDAP server you wish to use.

=item PerlSetVar LDAPPort 

This is the port the LDAP server is listening on.

=item PerlSetVar UIDAttr

The attribute used to lookup the user.

=item PerlSetVar AlternatePWAttribute

The an alternate attribute with which the $password will be tested.  
This allows you to test with another attribute, instead of just
trying to bind the userdn and password to the ldap server.

If this option is used, then a BindDN and BindPWD must be used for the
initial bind.

=item PerlSetVar AllowAlternateAuth

This attribute allows you to set an alternative method of authentication
(Basically, this allows you to mix authentication methods, if you don't have
 all users in the LDAP database). It does this by returning a DECLINE and checking 
 for the next handler, which could be another authentication, such as 
Apache-AuthenNTLM or basic authentication.

=item PerlSetVar SearchScope

Optional.  Can be base, one or sub.  Default is sub.  Determines the
scope of the LDAP search.

=item PerlSetVar LDAPFilter

This is an LDAP filter, as defined in RFC 2254.  This is optional.  If
provided, it will be ANDed with the filter that verifies the UID.  For
example, if you have these set:

 PerlSetVar UIDAttr uid
 PerlSetVar LDAPFilter "(&(course=41300)(year=3)(classCode=Y))"

and a user authenticates with the username "nicku" then the following
filter will be generated to search for the entry to authenticate against:

 (&(&(course=41300)(year=3)(classCode=Y))(uid=nicku))

This will then allow nicku access only if nicku's LDAP entry has the
attribute course equal to 41300, the attribute year equal to 3, and
attribute classCode equal to Y.  And of course, if the password is
correct.  This may be useful for restricting access to a group of
users in a large directory, e.g., at a university.

=item PerlSetVar UseStartTLS

Optional; can be yes or no.  If yes, will fail unless can start a TLS
encrypted connection to the LDAP server before sending passwords over
the network.  Note that this requires that the optional module
IO::Socket::SSL is installed; this depends on Net::SSLeay, which
depends on openssl.  Of course, the LDAP server must support Start TLS
also.

=back

=head2 Uses for UIDAttr

For example if you set the UIDAttr to uid, and a user enters the UID
nicku, then the LDAP search filter will lookup a user using the search
filter:

 (uid=nicku)

Normally you will use the uid attribute, but you may want (need) to use a different attribute depending on your LDAP server or to synchronize with different applications. For example some versions of Novell's LDAP servers that I've encountered stored the user's login name in the cn attribute (a really bad idea). And the Netscape Address Book uses a user's email address as the login id.

=head1 INSTALLATION 

It's a pretty straightforward install if you already have mod_perl and Net::LDAP already installed.

After you have unpacked the distribution type:

 perl Makefile.PL
 make
 make test 
 make install

Then in your httpd.conf file or .htaccess file, in either a <Directory> or <Location> section put:

 AuthName "LDAP Test Auth"
 AuthType Basic

 #only set the next two if you need to bind as a user for searching
 #PerlSetVar BindDN "uid=user1,ou=people,o=acme.com" #optional
 #PerlSetVar BindPWD "password" #optional
 PerlSetVar BaseDN "ou=people,o=acme.com"
 PerlSetVar LDAPServer ldap.acme.com
 PerlSetVar LDAPPort 389
 PerlSetVar UIDAttr uid
 PerlSetVar UseStartTLS yes # Assuming you installed IO::Socket::SSL, etc.
 
 # Set if you want base or one level scope for search:
 PerlSetVar SearchScope one # default is sub

 # Set if you want to limit access to a subset of users:
 #PerlSetVar LDAPFilter "(&(course=CSA)(class=A))" #optional

 # Set if you want to allow an alternate method of authentication
 PerlSetVar AllowAlternateAuth yes | no

 require valid-user

 PerlAuthenHandler Apache::AuthNetLDAP

If you don't have mod_perl or Net::LDAP installed on your system, then the Makefile will prompt you to 
install each of these modules. At this time, March 8, 2004, you may say yes to Net::LDAP, and yes for 
mod_perl, if you are installing this module on apache 1.3.  (The reason being, that mod_perl 2 is under 
development, and is not ready for download from CPAN at this time.  Therefore, your install of mod_perl,
as initiated with the Makefile.PL, will fail. If you are going to install mod_perl 2, which is needed
to work with Apache2, you will need to download it from:  http://perl.apache.org/download/index.html. 
(Installation is beyond the scope of this document, but you can find documentation at:  
http://perl.apache.org/docs/2.0/user/install/install.html#Installing_mod_perl_from_Source.)  
Otherwise installation is the same.   

You may also notice that the Makefile.PL will ask you to install ExtUtils::AutoInstall.  This is 
necessary for the installation process to automatically install any of the dependencies that you
are prompted for. You may choose to install the module, or not.

=head1 HOMEPAGE

Module Home: http://search.cpan.org/author/SPEEVES/ 

=head1 AUTHOR

 Mark Wilcox mewilcox@unt.edu and
 Shannon Eric Peevey speeves@unt.edu

=head1 SEE ALSO

L<Net::LDAP>

=head1 ACKNOWLEDGMENTS

Graham Barr for writing Net::LDAP module.

Henrik Strom for writing the Apache::AuthPerLDAP module which I derived this from.

The O'Reilly "Programming Modules for Apache with Perl and C" (http://www.modperl.com).

Mark Wilcox for being the "Godfather" of Central Web Support... ;)

Stas Beckman for having the patience to answer my many questions.

Everyone else on the modperl mailing list...  You know who you are :)


=head1 WARRANTY AND LICENSE

You can distribute and modify in accordance to the same license as Perl. Though I would like to know how you are using the module or if you are using the module at all.

Like most of the stuff on the 'net, I got this copy to work for me without destroying mankind, you're mileage may vary.

=cut


1;
__END__
