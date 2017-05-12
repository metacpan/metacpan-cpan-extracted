package Apache2::AuthLLDAPSympa;

use strict;
use warnings;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);
use MIME::Base64;

my $logMode='ERROR';
my $fileLog='LemonSympaPlu.log';

=head1 NAME

Apache2::AuthLLDAPSympa - Authz module to authorize access asking sympa server if the user is subscribing a list. Usefull for working groups!!

=head1 VERSION

Version 1.0

=cut

our $VERSION = '0.4.0';

=head1 SYNOPSIS

This module authorize a LemonLDAP account to connect to sympa lists server.


Sample httpd.conf example:
<VirtualHost *:80>
    ServerAdmin webmaster@dummy-host.example.com
    DocumentRoot /www/docs/dummy-host.example.com
    ServerName dummy-host.example.com
    ErrorLog logs/dummy-host.example.com-error_log
    CustomLog logs/dummy-host.example.com-access_log common
    
    AddHandler cgi-script .cgi .pl
    PerlModule Apache2::compat

    #the repertory of the libs of sympa
    PerlSwitches -I/repertory/to/sympa/sympa/bin/
    #For loading the handler
    PerlPostReadRequestHandler Apache2::AuthLLDAPSympa
    #The LDAP host 
    PerlSetVar LemonLDAPSympaHost            ldpcentraledev.alize:10389
    #The LDAP Filter
    PerlSetVar LemonLDAPSympaFilter   	    (objectclass=*)
    #The LDAP attribute for email
    PerlSetVar LemonLDAPSympaEmailAttribute  mail
    #The choice of the email
    PerlSetVar LemonLDAPSympaEmailSelect  0
    #The configuration file of sympa (important for secret)
    PerlSetVar LemonLDAPSympaConfFile    /repertory/to/sympa/sympa/etc/sympa.conf
    #The configuration file of the cgi wwsympa.pl
    PerlSetVar LemonLDAPSympaWWConfFile    /repertory/to/sympa/sympa/etc/wwsympa.conf
    #the Directory of libs of sympa
    PerlSetVar LemonLDAPSympaDirectory /repertory/to/sympa/sympa/bin/
    #the name with directory where is the tools.pl
    PerlSetVar LemonLDAPSympaToolScript /repertory/to/sympa/sympa/bin/tools.pl
    #The log filename
    PerlSetVar LemonLDAPSympaLogFile /logs/to/sympa/loghandler.log
    #The log mode precision
    PerlSetVar LemonLDAPSympaLogMode INFO
    #The script wwsympa
    ScriptAlias /sympa "/repertory/to/sympa/sympa/bin/wwsympa.fcgi"
</VirtualHost>


=head1 FUNCTIONS

=head2 handler

=cut

sub handler {
	my $r=shift;
	$fileLog=$r->dir_config('LemonLDAPSympaLogFile')||'LemonSympaPlu.log';
        $logMode=$r->dir_config('LemonLDAPSympaLogMode')||'ERROR';
        if ($fileLog eq "") { $fileLog='LemonSympaPlu.log';}
        if ($logMode eq "") { $logMode='ERROR';}
	&logDebug('Start the Handler');
        my $myCookies=$r->headers_in->get('Cookie');
	&logDebug("The cookies are:$myCookies");
	my $auth = $r->header_in("Authorization");
	&logDebug("The Authorization is:$auth");
	my ($user, $pass);
	if ($auth ne "")
	{
	 $auth =~ s/Basic//;
         ($user, $pass)=split(/:/, decode_base64($auth));
	}
	&logDebug("The user is:$user");
	#If Authentification and no cookie sympa user we add a new cookie sympauser
        if ($auth ne "" && $user ne "" && $myCookies !~ /sympauser/)
        {
	 &logDebug("There is no Cookie sympauser");
	 &logDebug("There user is:$user");
	 
	 &logDebug("Read mod_perl parameters");
	 #Read the parameters for the plugin
	 my $LDAPHOST=$r->dir_config('LemonLDAPSympaHost');
       my $LDAPFilter=$r->dir_config('LemonLDAPSympaFilter');
	 my $LDAPEmailAttr=$r->dir_config('LemonLDAPSympaEmailAttribute');
	 my $LDAPEmailSel=$r->dir_config('LemonLDAPSympaEmailSelect');
	 my $LemonConf=$r->dir_config('LemonLDAPSympaConfFile');
	 my $LemonWWConf=$r->dir_config('LemonLDAPSympaWWConfFile');
	 my $SympaDirectory=$r->dir_config('LemonLDAPSympaDirectory'); 
	 my $SympaToolScript=$r->dir_config('LemonLDAPSympaToolScript');
	 $fileLog=$r->dir_config('LemonLDAPSympaLogFile');
	 $logMode=$r->dir_config('LemonLDAPSympaLogMode');
	 if ($fileLog eq "") { $fileLog='LemonSympaPlu.log';}
	 if ($logMode eq "") { $logMode='ERROR';}
	 &logDebug("The parameter LemonLDAPSympaHost=$LDAPHOST");
	 &logDebug("The parameter LemonLDAPSympaFilter=$LDAPFilter");
	 &logDebug("The parameter LemonLDAPSympaEmailAttribute=$LDAPEmailAttr");
	 &logDebug("The parameter LemonLDAPSympaEmailSelect=$LDAPEmailSel");
	 &logDebug("The parameter LemonLDAPSympaConfFile=$LemonConf");
	 &logDebug("The parameter LemonLDAPSympaWWConfFile=$LemonWWConf");
	 &logDebug("The parameter LemonLDAPSympaDirectory=$SympaDirectory");
	 &logDebug("The parameter LemonLDAPSympaToolScript=$SympaToolScript");
	 &logDebug("The parameter LemonLDAPSympaLogFile=$fileLog");
	 &logDebug("The parameter LemonLDAPSympaLogMode=$logMode");
	 
	 #get page uri and host
	 my $document_root = $r->document_root;
         my $uri = $r->uri;
	 local $_ = $uri;
	 if ($LDAPHOST eq "")
	 {
		&logError("The parameter LemonLDAPSympaHost is empty");
	        $r->warn("$uri => The parameter LemonLDAPSympaHost is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
	 }
	 
	 if ($LDAPFilter eq "")
         {
                &logError("The parameter LemonLDAPSympaFilter is empty");
		$r->warn("$uri => The parameter LemonLDAPSympaFilter is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
         }
	 if ($LDAPEmailAttr eq "")
         {
                &logError("The parameter LemonLDAPSympaEmailAttribute is empty");
		$r->warn("$uri => The parameter LemonLDAPSympaEmailAttribute is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
         }
	 if ($LDAPEmailSel eq "")
         {
                &logError("The parameter LemonLDAPSympaEmailSelect is empty");
	 	$r->warn("$uri => The parameter LemonLDAPSympaEmailSelect is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
         }
	 if ($LemonConf eq "")
         {
                &logError("The parameter LemonLDAPSympaConfFile is empty");
		$r->warn("$uri => The parameter LemonLDAPSympaConfFile is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
         }
	 if ($LemonWWConf eq "")
         {
                &logError("The parameter LemonLDAPSympaWWConfFile is empty");
		$r->warn("$uri => The parameter LemonLDAPSympaWWConfFile is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
         }
	 if ($SympaDirectory eq "")
         {
                &logError("The parameter LemonLDAPSympaDirectory is empty");
		$r->warn("$uri => The parameter LemonLDAPSympaDirectory is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
         }
	 if ($SympaToolScript eq "")
         {
                &logError("The parameter LemonLDAPSympaToolScript is empty");
                $r->warn("$uri => The parameter LemonLDAPSympaDirectory is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
         }
	 if ($fileLog eq "")
         {
                &logError("The parameter LemonLDAPSympaLogFile is empty");
		$r->warn("$uri => The parameter LemonLDAPSympaLogFile is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
         }
	 if ($logMode eq "")
         {
                &logError("The parameter LemonLDAPSympaLogMode is empty");
		$r->warn("$uri => The parameter LemonLDAPSympaLogMode is empty at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
         }

	 &logDebug("Load the libraries");
	 &logDebug("Sympa Directory is $SympaDirectory");
	 
	 use wwslib;
         use Log;
         use Conf;
         use Exporter;
	 
	 use List;
	 use mail;
	 use smtp;
	 use Conf;
	 use Commands;
	 use Language;
	 use Log;
	 use Auth;
	 use admin ;
	 use CGI;
	 use CGI::Cookie ;
	 require $SympaToolScript;
         ## Configuration
         my $wwsconf = {};

         ## Change to your wwsympa.conf location
         my $conf_file = $LemonWWConf;
         my $sympa_conf_file = $LemonConf;
         my $robot ;
         my $param;
         my $ip;
	 
	 &logDebug ("Load the configuration of Sympa");
	 ## Load config
	 unless ($wwsconf = &wwslib::load_config($conf_file))
	 {
	 	&logError("Error on loading Config File $conf_file");
                $r->warn("$uri => Error on loading Config File $conf_file at $document_root$_");
                $r->filename("$document_root$_");
                return 0;		
	 }
	 ## Load sympa config
	 unless (&Conf::load( $sympa_conf_file ))
	 {
		&logError("Error on loading Config File $sympa_conf_file");
                $r->warn("$uri => Error on loading Config File $sympa_conf_file at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
	 }
	 
         &logDebug ("Calculate the cookie Domain");
	 #Calculate the cookie_domain
         if (defined $Conf{'robot_by_http_host'}{$ENV{'SERVER_NAME'}}) {
          my ($selected_robot, $selected_path);
          my ($k,$v);
          while (($k, $v) = each %{$Conf{'robot_by_http_host'}{$ENV{'SERVER_NAME'}}}) {
             if ($ENV{'REQUEST_URI'} =~ /^$k/) {
                ## Longer path wins
                 if (length($k) > length($selected_path)) {
                     ($selected_robot, $selected_path) = ($v, $k);
                 }
             }
          }
          $robot = $selected_robot;
         }

         $robot = $Conf{'host'} unless $robot;

         $param->{'cookie_domain'} = $Conf{'robots'}{$robot}{'cookie_domain'} if $Conf{'robots'}{$robot};
         $param->{'cookie_domain'} ||= $wwsconf->{'cookie_domain'};
         $ip = $ENV{'REMOTE_HOST'};
         $ip = $ENV{'REMOTE_ADDR'} unless ($ip);
         $ip = 'undef' unless ($ip);
         ## In case HTTP_HOST does not match cookie_domain
         my $http_host = $ENV{'HTTP_HOST'};
         $http_host =~ s/:\d+$//; ## suppress port
         unless (($http_host =~ /$param->{'cookie_domain'}$/) ||
            ($param->{'cookie_domain'} eq 'localhost')) {
            &wwslog('notice', 'Cookie_domain(%s) does NOT match HTTP_HOST; setting cookie_domain to %s', $param->{'cookie_domain'}, $http_host);
	    my $cookLog=$param->{'cookie_domain'};
	    &logDebug("Cookie_domain($cookLog=) does NOT match HTTP_HOST; setting cookie_domain to $http_host");
            $param->{'cookie_domain'} = $http_host;
         }
	 

	 #The LDAP Traitment
	 &logDebug ("Load LDAP libraries");
         use Net::LDAP;

         #my($ldap) = Net::LDAP->new('ldpcentraledev.alize', port => 10389) or die "Can't bind to ldap: $!\n";
	 &logDebug ("Connect to LDAP");

         my($ldap) = Net::LDAP->new($LDAPHOST) ||"ERROR";
	 if ($ldap eq "ERROR")
	 {
		&logError("Error LDAP on connecting to $LDAPHOST");
                $r->warn("$uri => Error LDAP on connecting to $LDAPHOST at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
	 }
	 &logDebug ("Bind LDAP");
         $ldap->bind;
	 
         #my($mesg) = $ldap->search( base => $user,
         #                                     filter => '(objectclass=*)');
	 &logDebug ("Search on LDAP");
         my($mesg) = $ldap->search( base => $user,
                                          filter => $LDAPFilter);
	 if ($mesg->error ne "Success")
	 {
		my $messageEr=$mesg->error;
	    	&logError("Error LDAP on searching $user with Filter $LDAPFilter and message=$messageEr");
                $r->warn("$uri => Error LDAP on searching $user with Filter $LDAPFilter at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
	 }
         $mesg->code && die $mesg->error;
	 
	 
         my($entryL);
         my @enrtyLi;

         my $emailFinded="";
	 
  	 #List all Entries
	 &logDebug ("List Entries on LDAP");
         foreach $entryL ($mesg->all_entries) {
          #@enrtyLi=$entryL->get('mail');
	  @enrtyLi=$entryL->get($LDAPEmailAttr);
          #$emailFinded=@enrtyLi[0];
	  if ($LDAPEmailSel ge scalar(@enrtyLi)||$LDAPEmailSel lt 0)
          {
                my $NbEntries=scalar(@enrtyLi);
                &logError("The email selection item($LDAPEmailSel) is not good.There is $NbEntries entries.");
                $r->warn("$uri => The email selection item($LDAPEmailSel) is not good.There is $NbEntries entries. at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
          }
	  $emailFinded=$enrtyLi[$LDAPEmailSel];
	  &logDebug ("We Find : $emailFinded");
         }
	 
 	 &logDebug ("We unbind LDAP");
         $ldap->unbind;
	 

	 if ($emailFinded eq "")
	 {
		&logError("We don't find the email adress of the user $user.");
                $r->warn("$uri => We don't find the email adress of the user $user. at $document_root$_");
                $r->filename("$document_root$_");
                return 0;
	 }
	 #Calculate Delay
	 &logDebug ("Calculate the delay");
	 my $delayL;
         $delayL = $param->{'user'}{'cookie_delay'};
         unless (defined $delayL) {
          $delayL = $wwsconf->{'cookie_expire'};
         }
         if ($delayL == 0) {
          $delayL = 'session';
         }

	 #Generate the cookie of Sympa
	 &logDebug ("Generate the cookie");
         my $cookieVal= &set_cookie_ext($emailFinded, $Conf{'cookie'},$param->{'cookie_domain'}, $delayL, 'classic');
	 #my $cookieAltVal= &set_cookie_alte_ext($emailFinded, $Conf{'cookie'},$param->{'cookie_domain'}, $delayL, 'classic');
	 &logDebug ("The cookie is :$cookieVal");
	 #&logDebug ("The cookie Alte is :$cookieAltVal");
	 #$cookieVal="$cookieVal;$cookieAltVal"
         $r->header_in('Cookie',"$myCookies;$cookieVal");
	 &logDebug ("The cookie is added to cookie List");
	 &logInfo ("The user $user is connected on Sympa with the email $emailFinded");
	
         
	}
	return Apache2::Const::OK;
}


## Set user $email cookie, ckecksum use $secret, expire=(now|session|#sec) domain=(localhost|<a domain>)
sub set_cookie_ext {
    my ($email, $secret, $http_domain, $expires, $auth) = @_ ;
    &logDebug("Enter on sub set_cookie_ext with parameters $email, $secret, $http_domain, $expires, $auth");
    unless ($email) {
       return undef;
    }
    my $expiration;
    if ($expires =~ /now/i) {
        ## 10 years ago
        $expiration = '-10y';
    }else{
        $expiration = '+'.$expires.'m';
    }

    if ($http_domain eq 'localhost') {
        $http_domain="";
    }

    my $value = sprintf '%s:%s', $email, &get_mac_extra($email,$secret);
    if ($auth ne 'classic') {
        $value .= ':'.$auth;
    }
    my $cookie;
    if ($expires =~ /session/i) {
        $cookie = new CGI::Cookie (-name    => 'sympauser',
                                  -value   => $value,
                                   -domain  => $http_domain,
                                   -path    => '/'
                                   );
    }else {
        $cookie = new CGI::Cookie (-name    => 'sympauser',
                                   -value   => $value,
                                   -expires => $expiration,
                                   -domain  => $http_domain,
                                   -path    => '/'
                                   );
    }
    ## Send cookie to the client
    return  $cookie->as_string;
}
## Set user $email cookie, ckecksum use $secret, expire=(now|session|#sec) domain=(localhost|<a domain>)
sub set_cookie_alte_ext {
    my ($email, $secret, $http_domain, $expires, $auth) = @_ ;
    &logDebug("Enter on sub set_cookie_ext with parameters $email, $secret, $http_domain, $expires, $auth");
    unless ($email) {
       return undef;
    }
    my $expiration;
    if ($expires =~ /now/i) {
        ## 10 years ago
        $expiration = '-10y';
    }else{
        $expiration = '+'.$expires.'m';
    }

    if ($http_domain eq 'localhost') {
        $http_domain="";
    }

    my $value = sprintf '%s:%s', $email, &get_mac_extra($email,$secret);
    if ($auth ne 'classic') {
        $value .= ':'.$auth;
    }
    my $cookie;
    if ($expires =~ /session/i) {
        $cookie = new CGI::Cookie (-name    => 'sympa_altemails',
                                  -value   => $value,
                                   -domain  => $http_domain,
                                   -path    => '/'
                                   );
    }else {
        $cookie = new CGI::Cookie (-name    => 'sympa_altemails',
                                   -value   => $value,
                                   -expires => $expiration,
                                   -domain  => $http_domain,
                                   -path    => '/'
                                   );
    }
    ## Send cookie to the client
    return  $cookie->as_string;
}
sub get_mac_extra {
        my $email = shift ;
        my $secret = shift ;
	
	&logDebug("Enter on sub get_mac_extra with parameters $email, $secret");
        unless ($secret) {
            &logError( 'get_mac : failure missing server secret for cookie MD5 digest');
            return undef;
        }
        unless ($email) {
            &logError( 'get_mac : failure missing email adresse or cookie MD5 digest');
            return undef;
        }



       my $md5 = new Digest::MD5;

      $md5->reset;
      $md5->add($email.$secret);
      return substr( unpack("H*", $md5->digest) , -8 );
}


sub logInfo {
	my $messageToLog=shift;
	if (uc($logMode) eq 'INFO'||uc($logMode) eq 'DEBUG')
	{
		&logFile("INFO:$messageToLog");
	}
}

sub logError {
        my $messageToLog=shift;
	if (uc($logMode) eq 'ERROR'||uc($logMode) eq 'INFO'||uc($logMode) eq 'DEBUG')
        {
                &logFile("ERROR:$messageToLog");
        }
}

sub logDebug {
        my $messageToLog=shift;
	if (uc($logMode) eq 'DEBUG')
        {
                &logFile("DEBUG:$messageToLog");
        }
}
sub logFile {
	my $messageToLog=shift;
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my $year = 1900 + $yearOffset;
	my $theTime = "$hour:$minute:$second,$weekDays[$dayOfWeek] $months[$month] $dayOfMonth,$year";
	my $definitiveMessage="$theTime: $messageToLog\n";
	open(DAT,">>$fileLog") ;
	#open(DAT,">>/logs/gcp/sympa/logSymp.log") ;
     	print DAT $definitiveMessage;
	close(DAT);	

}
=head1 AUTHOR

Sebastien DIAZ, C<< <sebastien.diaz AT gmail.com> >>


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

AuthLLDAPSympa is distributed under the GNU General Public License http://www.gnu.org/copyleft/gpl.html. 
Copyright (C) 2001, 2003, 2004,2005,2006 Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA 
Verbatim copying and distribution of this entire article are permitted worldwide, without royalty, in any medium, provided this notice, and the copyright notice, are preserved
This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version. 
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. 
You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 


=cut

1;

