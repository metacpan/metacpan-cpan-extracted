# $Id: Auth.pm,v 1.9 2002/07/31 16:44:14 Administrator Exp $

package Apache::AuthenSecurID::Auth;

use strict;
use Apache;
use Apache::Registry;
use Apache::Constants qw(:common);
use IO::Socket::INET;
use Crypt::CBC;
use vars qw($VERSION);

$VERSION = '0.4';


sub handler {

   my $r = shift;

   # seed the random number generator
   srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip -f`);

   #get params
   my %params = ( $r->args, $r->content );
   my $username = $params {'username'};
   my $passcode = $params{'passcode'};
   my $type = $params{'type'};
   my $uri = $params{'a'};

   # get ace_initd config directives
   my $ace_initd_server  = $r->dir_config("ace_initd_server") || "localhost";
   my $ace_initd_port  = $r->dir_config("ace_initd_port") || 1969;

   # grab apache session cookie
   my ( $session_id ) = ( ($r->header_in("Cookie") || "") =~
                /Apache=([^;]+)/);

   my $client = IO::Socket::INET->new ( PeerAddr   =>      $ace_initd_server,
                                        PeerPort   =>      $ace_initd_port,    
                                        Proto      =>      'udp' );

   my %ACE;
   my $request;
   my $message;
   my $extra_input;

   if ( ( ! $username && ! $passcode ) || ( $type ne "pin"  && ! $passcode ) ||
         	( $passcode =~ /\:/ ) ) {
	$message = qq{
		Please enter your username and passcode<br>
		Your passcode is your 4 - 8 digit pin plus<br>
		6 digit SecurID code.  If you do not have<br>
		a PIN yet just enter the 6 digit SecurID code.
	};
	$extra_input = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			Passcode :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=passcode>
			<input type=hidden name=type value=check>
			<input type=hidden name=a value=$uri>
		   </td>
		</tr>
	};
   } else {
	if ( $type eq "pin" ) {
		( $passcode, $message,$extra_input) = check_pin ( \%params ) ;
		if ( $passcode )  {
			($message,$extra_input) = Do_ACE($username,$passcode,$type,$session_id,$client,$r,\%params);
		}
	} else {
		($message,$extra_input) = Do_ACE($username,$passcode,$type,$session_id,$client,$r,\%params);
	}

   }


my $head = qq{
<body bgcolor=F0F8FF link=FFFF00 alink=FFFF00 vlink=FFFF00>
<html>
<!-- $session_id  -->
<center>
<form method=post>
<table>
   <tr>
	<td colspan=2>
<table bgcolor=cccccc >
   <tr>
	<td>
	   <table cellspacing=2 bgcolor=dddddd width=100%>
		<tr>
		   <td align=center>
			<font size=+2 color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			SecurID Authorization
			</b>
			</font>
		   </td>
		</tr>
		<tr>
		   <td>
			<font color=000000 face="Arial, Helvetica, sans-serif">
			$message
			</font>
		   </td>
		</tr>
	   </table>
	</td>
   </tr>
   <tr>
	<td align=right>
	   <table cellspacing=0 cellpadding=0 bgcolor=dddddd width=100%>
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			Username :
			</b>
			</font>
		   </td>
		   <td>
			<input type=text name=username value=$username>
		   </td>
		</tr>
		$extra_input
	   </table>
	</td>
   </tr>
</table>
	</td>
   </tr>
   <tr>
	<td>
		<input type=submit name=Submit value="Enter">
	</td>
	<td>
		<input type=reset name=reset>
	</td>
   </tr>
</table>
</form>
</center>
</html>
};

$r->content_type ('text/html');
$r->send_http_header; 
$r->print ($head);

}

sub check_pin {

	my ( $params ) = @_;

	my $pin1 = $$params{'pin1'};
	my $pin2 = $$params{'pin2'};
	my $alphanumeric = $$params{'alphanumeric'};
	my $min_pin_len = $$params{'min_pin_len'};
	my $max_pin_len = $$params{'max_pin_len'};
	my $uri = $$params{'a'};
        my $message;

	my $extra_info = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			PIN :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=pin1>
			<input type=hidden name=type value=pin>
			<input type=hidden name=alphanumeric value=$alphanumeric>
			<input type=hidden name=min_pin_len value=$min_pin_len>
			<input type=hidden name=max_pin_len value=$max_pin_len>
			<input type=hidden name=a value=$uri>
		   </td>
		</tr>
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			PIN ( Again ) :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=pin2>
		   </td>
		</tr>
	   };

	if ( $pin1 != $pin2 ) {
	   $message = qq{
		<b>New Pin Required</b><p>
		Pins do not match!!<p>
		Please enter a $min_pin_len to $max_pin_len digit pin.
	   };
		return ( 0, $message, $extra_info );
	}

	if ( $alphanumeric ) {
           if ( $pin1 =~ /[^0-9a-zA-Z]/ ) {
	      $message = qq{
		<b>New Pin Required</b><p>
		Pin must be alphanumeric!!<p>
		Please enter a $min_pin_len to $max_pin_len digit pin.
	      };
		return ( 0, $message, $extra_info );
           }
        } else {
           if ( $pin1 =~ /[^0-9]/ ) {
	      $message = qq{
		<b>New Pin Required</b><p>
		Pin must be numeric!!<p>
		Please enter a $min_pin_len to $max_pin_len digit pin.
	      };
		return ( 0, $message, $extra_info );
           }
        }

	my $pin_length = length ( $pin1 );

	if ( $pin_length < $min_pin_len || $pin_length > $max_pin_len ) {
	      $message = qq{
		<b>New Pin Required</b><p>
		Pin must be the correct length!!<p>
		Please enter a $min_pin_len to $max_pin_len digit pin.
	      };
		return ( 0, $message, $extra_info );
	}

	return ( $pin1, 0, 0 );
	
}

sub Do_ACE {

	my ( $username,$passcode,$type,$session_id,$client,$r,$params ) = @_;	

	$ENV{'VAR_ACE'} = "/opt/ace/data";
	my $message;
	my $extra_input;
	my $result;
	my %info;
	my $ace;
	my $mesg;
	my $my_rand = rand();
	my $return_rand;

	my $crypt_key = $r->dir_config("AuthCryptKey");
	my $crypt = new Crypt::CBC ( $crypt_key, "Blowfish" );
	
	$mesg = $crypt->encrypt_hex ("$my_rand:$session_id:$type:$username:$passcode"); 
	$client->send($mesg);

	$client->recv($mesg, 1024);
	$mesg = $crypt->decrypt_hex ( $mesg );


	( $return_rand, $result, $info{system_pin}, $info{min_pin_len}, $info{max_pin_len}, 
	$info{alphanumeric}, $info{user_selectable} )
	   = split /\:/, $mesg;

	if ( $my_rand ne $return_rand ) {
		$result = 100;
	}
	($message,$extra_input)=Ace_Result($result,\%info,$r,$crypt,$params,$username);

	return ( $message, $extra_input );

}

sub Ace_Result {

	my ( $result, $info, $r, $crypt, $params,$username ) = @_;
	my $message;
	my $extra_input;
	my $uri = $$params{'a'};
	my $time = time ();

if ( $result == 0 ) {

	my $auth_cookie = $r->dir_config("AuthCookie") || "SecurID";
	my $auth_user_cookie = $r->dir_config("AuthUserCookie") || "SecurID_User";
	my $crypt_cookie = $crypt->encrypt_hex ( "$time:$username" );
	$r->headers_out->add("Set-Cookie" => $auth_user_cookie . "=" .
		$username . "; path=" . "/");
	$r->headers_out->add("Set-Cookie" => $auth_cookie . "=" .
		$crypt_cookie . "; path=" . "/");

	$uri = $crypt->decrypt_hex ( $uri );

	# success
	$message = qq{
		<b>User Authenticated</b><p>
		<SCRIPT LANGUAGE="JavaScript">
		<!-- Begin
		window.location="$uri";
		// End -->
		</script>
		If you do not have Java Script enabled<br>
		please click <a href="$uri">here</a> to go to<br>
		the protected page.<p>
		Plase enter your username and passcode<br>
		Your passcode is your 4 - 8 digit pin plus<br>
		6 digit SecurID code.  If you do not have<br>
		a PIN yet just enter the 6 digit SecurID code.
	};
	$extra_input = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			Passcode :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=passcode>
			<input type=hidden name=type value=check>
			<input type=hidden name=a value=$uri>
		   </td>
		</tr>
	};
} elsif ( $result == 1 ) {
	# failure
	$message = qq{
		<b>User Authentication Failed</b><p>
		Plase enter your username and passcode<br>
		Your passcode is your 4 - 8 digit pin plus<br>
		6 digit SecurID code.  If you do not have<br>
		a PIN yet just enter the 6 digit SecurID code.
	};
	$extra_input = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			Passcode :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=passcode>
			<input type=hidden name=type value=check>
			<input type=hidden name=a value=$uri>
		   </td>
		</tr>
	};
} elsif ( $result == 100 ) {
	# failure
	$message = qq{
		<b>User Authentication Failed</b><p>
		The ACE server is either down or behaving<br>
		incorrectly.  Please conact your system<br>
		administrator.
	};
	$extra_input = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			Passcode :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=passcode>
			<input type=hidden name=type value=check>
			<input type=hidden name=a value=$uri>
		   </td>
		</tr>
	};
} elsif ( $result == 2 ) {
	# next token code
	$message = qq{
		<b>Next Token Required</b><p>
		Plase wait for you token to change and enter<br>
		the 6 digit SecurID token code.
	};
	$extra_input = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			Next Token Code :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=passcode>
			<input type=hidden name=type value=next>
			<input type=hidden name=a value=$uri>
		   </td>
		</tr>
	};
} elsif ( $result == 5 ) {
	# New PIN required.
	if ( $$info{user_selectable} >= 1 ) {
	   $message = qq{
		<b>New Pin Required</b><p>
		Please enter a $$info{min_pin_len} to $$info{max_pin_len} digit pin.
	   };
	   $extra_input = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			PIN :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=pin1>
			<input type=hidden name=type value=pin>
			<input type=hidden name=a value=$uri>
			<input type=hidden name=alphanumeric value=$$info{alphanumeric}>
			<input type=hidden name=min_pin_len value=$$info{min_pin_len}>
			<input type=hidden name=max_pin_len value=$$info{max_pin_len}>
		   </td>
		</tr>
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			PIN ( Again ) :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=pin2>
		   </td>
		</tr>
	   };
		
	} else {
	$message = qq{
		<b>You have been assignes a new PIN.</b><p>
		Your PIN is: <b>$$info{system_pin}</b><p>
		Please remember your PIN.  Do not share it<br>
		with anyone else.<p>
		Please enter your username and passcode<br>
		Your passcode is your 4 - 8 digit pin plus<br>
		6 digit SecurID code.
	};
	$extra_input = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			Passcode :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=passcode>
			<input type=hidden name=type value=check>
			<input type=hidden name=a value=$uri>
		   </td>
		</tr>
	};
	}
} elsif ( $result == 6 ) {
	$message = qq{
		<b>PIN Accepted</b><p>
		Please remember you PIN.  Do not share it<br> 
		with anyone else.<p>
		Please enter your username and passcode<br>
		Your passcode is your 4 - 8 digit pin plus<br>
		6 digit SecurID code.
	};
	$extra_input = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			Passcode :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=passcode>
			<input type=hidden name=type value=check>
			<input type=hidden name=a value=$uri>
		   </td>
		</tr>
	};

} elsif ( $result == 7 ) {
	$message = qq{
		<b>PIN Rejected</b><p>
		Please contact the system administrator.<p>
		Please enter your username and passcode<br>
		Your passcode is your 4 - 8 digit pin plus<br>
		6 digit SecurID code.
	};
	$extra_input = qq{
		<tr>
		   <td>
			<font  color=000000 face="Arial, Helvetica, sans-serif">
			<b>
			Passcode :
			</b>
			</font>
		   </td>
		   <td>
			<input type=password name=passcode>
			<input type=hidden name=type value=check>
			<input type=hidden name=a value=$uri>
		   </td>
		</tr>
	};

}
	return ( $message, $extra_input );
}


1;

__END__

=head1 NAME

Apache::AuthenSecurID::Auth - Authentication handler for Apache::AuthenSecurID 

=head1 SYNOPSIS

 # Configuration in httpd.conf  

<Location /path/of/authentication/handler>
   SetHandler perl-script
   PerlHandler Apache::AuthenSecurID::Auth

   PerlSetVar AuthCryptKey Encryption_Key
   PerlSetVar AuthCookie Name_of_Authentication_Cookie
   PerlSetVar AuthUserCookie Name_of_Username_Authentication_Cookie
   PerlSetVar AuthCookiePath /path/of/authentication/cookie
   PerlSetVar AuthApacheCookie Apache_Cookie
   PerlSetVar ace_initd_server name.of.ace.handler.server.com
   PerlSetVar ace_initd_port 1969
</Location>

=head1 DESCRIPTION

This module allows authentication against a SecurID server.  A request
is redirected to this handler if the authentication cookie does not
exist or is no longer valid.  The handler will prompt for username and 
passcode.  It will then construct and encrypt a UDP packet and send it to 
the Ace request daemon.  This is necessary since libsdiclient.a needs to 
persist for NEXT TOKEN MODE and SET PIN MODE.  If the authentication is 
valid an encrypted Authentication Cookie is set and the request is redirected 
to the originating URI.  If the user needs to enter NEXT TOKEN or set their 
PIN they will be prompted to do so and if valid the request is then redirected 
to the originating URI.


=head1 LIST OF TOKENS


=item *
AuthCryptKey

The Blowfish key used to encrypt and decrypt the authentication cookie. 
It defaults to F<my secret> if this variable is not set.

=item *
AuthCookie

The name of the of cookie to be set for the authentication token.  
It defaults to F<SecurID> if this variable is not set.

=item *
AuthUserCookie

The name of the of cookie that contains the value of the persons username
in plain text.  This is checked against the contents of the encrypted cookie
to verify user.  The cookie is set of other applications can identify 
authorized users.  It defaults to F<SecurID_User> if this variable is not set.

=item *
AuthCookiePath

The path of the of cookie to be set for the authentication token.  
It defaults to F</> if this variable is not set.

=item *
AuthApacheCookie

The name of the mod_usertrack cookie.  The mod_usertrack module must be
compile and enabled in order to track user sessions.  This is set by the
CookieName directive in httpd.conf.  It defaults to F<Apache> if this variable 
is not set.

=item *
ace_initd_server

The name of the server running the ACE request daemon.  This daemon is the
actual process that communicates with the ACE Server.  If the user is in
NEXT TOKEN MODE due to repeated failures or SET PIN MODE the Authen::ACE 
object must persist beyond the initial request.  A request packet is 
constructed with a random number, type of transaction, username, passcode
and session identifier.  The request packet is then encrypted using Blowfish
and sent to the ACE request daemon.  The ACE request daemon decrypts and
parses the packet.  The request if forwarded to the ACE server and the 
response is sent back to the handler.  The random number originally sent is
returned to prevent attacks.  It defaults to F<localhost> if this variable 
is not set.

=item *
ace_initd_port

The port the that the Ace request daemon listens on.  It defaults to F<1969> 
if this variable is not set.


=head1 CONFIGURATION

The module should be loaded upon startup of the Apache daemon.
Add the following line to your httpd.conf:

 PerlModule Apache::AuthenSecurID::Auth

=head1 PREREQUISITES

For AuthenSecurID::Auth you need to enable the appropriate call-back hook 
when making mod_perl: 

  perl Makefile.PL PERL_AUTHEN=1

AuthenSecurID::Auth requires Crypt::Blowfish and Crypt::CBC.

For AuthenSecurID::Auth to properly track users mod_usertrack must be
compiled and enabled.


=head1 SEE ALSO

L<Apache>, L<mod_perl>, L<Authen::ACE> L<Apache::AuthenSecurID::Auth>

=head1 AUTHORS

=item *
mod_perl by Doug MacEachern <dougm@osf.org>

=item *
Authen::ACE by Dave Carrigan <Dave.Carrigan@iplenergy.com>

=item *
Apache::AuthenSecurID by David Berk <dberk@lump.org>

=item *
Apache::AuthenSecurID::Auth by David Berk <dberk@lump.org>

=head1 COPYRIGHT

The Apache::AuthenSecurID::Auth module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

