package Apache::AutoLogin;

use 5.006;
use strict;
use warnings;

use Apache::Constants qw(OK DECLINED SERVER_ERROR);
use Crypt::Rijndael;
use MIME::Base64;
use Digest::MD5 qw(md5_hex md5);
use Apache::Cookie;
use Apache::Request;
use Apache::Log;

our $VERSION = '0.1';


## This is the handler that gets called by mod_perl

sub handler {
    
    my $r=shift;
    
    ## We do not want any caching of the pages. Not sure if this does help, but anyways...
    
    $r->no_cache(1);
    
    ## Get some information on the client as the IP, the User-Agent and the host name.
    my $conn=$r->connection;
    my $client_identifier=$conn->remote_ip;
    $client_identifier=$client_identifier."-".md5_hex($r->headers_in->get('User-Agent')).
                "-".md5_hex($r->headers_in->get('Host'));
    
    ## Now read the configuration variable from the httpd.conf
    
    my $cookie_lifetime=$r->dir_config('AutoLoginCookieLifetimeInDays');
    my $encryption_key=$r->dir_config('AutoLoginEncryptionKey');
    my $logout_uri=$r->dir_config('AutoLoginLogoutPage');
    my $auth_name=$r->dir_config('AutoLoginAuthName');
    
    ## lets make an md5 hash out of the encryption key.
    ## This should make things more secure
    
    $encryption_key=md5($encryption_key).md5($encryption_key.md5($encryption_key));
    
    ## enable logging to apache's error log
    my $log=$r->server->log;

    
    # Test the length of the key. I wonder if this is really necessary,
    # perhaps using md5 keys generated from this one would be better
    
    if (length($encryption_key) % 32 != 0) {
        $log->error("Encryption key must by 256 bits long (32 characters)");
        return SERVER_ERROR;
    }    
    
    # Let's get the authorization headers out of the client's request
    my $credentials='';
    my $user='';
    my $password='';
    
    my $auth_header=$r->headers_in->get('Authorization');
    if (defined $auth_header)
    {
        $credentials =(split / /, $auth_header)[-1];
        ($user, $password) = split /:/, MIME::Base64::decode($credentials),2;
    }
    
    $log->info("header $user from $client_identifier");
    
    # Look for any cookies
    
    my %cookiejar = Apache::Cookie->new($r)->parse;
    
    
    ## If the user has called the predefined logout page,
    ## invalidate the cookie
    if ($r->uri() eq $logout_uri)
    {
        $log->info("User from $client_identifier logged out (".$r->uri().")");
        
        my $i=0;
        my $temp_key="";
        my $temp_key2="";
        my $temp_key3="";
        
        while ($i<32)
        {
            $temp_key.=int(rand(10));
            $temp_key2.=int(rand(10));
            $temp_key3.=int(rand(10));
            ++$i;
        }
        
        setCookie($r,$temp_key2,$temp_key3,0,1,$temp_key);
       
        $r->uri($logout_uri);
        return OK;
    }
    
    # If there is no cookie at all, generate one
    
    unless ($cookiejar{$auth_name}) {
        
        $log->info("Client $client_identifier has no cookie");
    
        setCookie($r,$user,$password,$client_identifier,$cookie_lifetime,$encryption_key);
        
        # DECLINED zur?ckgeben, damit Apache weitermacht.
        return DECLINED;
    }
    
        
    # Get the credentials out of the cookie
    
    my %auth_cookie=$cookiejar{$auth_name}->value;
    my $decrypted_string=decrypt_aes(decode_base64($auth_cookie{Basic}),$encryption_key);
    my ($c_user,$c_password,$c_client_ip,$c_date)=split (/:/, $decrypted_string , 4);
    
    # Check if the client has furnished any valid information
    
    if ($decrypted_string ne '')
    {
        $log->info("Data from cookie $c_user, $c_date, $c_client_ip");
        
        ## Some checks on the validity of the cookie
        
        # Check if the cookie hasn't expired
        
        if (time()>$c_date)
        {
            $log->info("Cookie has expired");
            setCookie($r,$user,$password,$client_identifier,$cookie_lifetime,$encryption_key);
            return DECLINED;
        }
        
        # Check if the cookie comes from the host it was issued to
        
        if ($client_identifier ne $c_client_ip)
        {
            $log->info("Cookie for $c_user has not been set for $client_identifier but for $c_client_ip");
            setCookie($r,$user,$password,$client_identifier,$cookie_lifetime,$encryption_key);
            return DECLINED;
        }
    }
    else
    {
        $log->info("Client $client_identifier has furnished an invalid cookie.");
    }
    
    # If the client sent any http authentication credentials lets write them to a cookie
    
    if ($user ne '' && $password ne '') {
        setCookie($r,$user,$password,$client_identifier,$cookie_lifetime,$encryption_key);
    }
    
    # Else write the credentials within the cookie into the http header
    else {
        # But only if there IS something in the cookie!
        if ($decrypted_string ne '' and $c_user ne '' and $c_password ne '')    {
            my $credentials=MIME::Base64::encode(join(":",$c_user,$c_password));
            $r->headers_in->set(Authorization => "Basic $credentials");
        }
    }
    
    # Return DECLINED
    return DECLINED;
}

## sets the cookie
sub setCookie {
    
    my ($r,$user,$password,$client_identifier,$cookie_lifetime,$encryption_key)=@_;
    my $auth_name=$r->dir_config('AutoLoginAuthName');
    my $log=$r->server->log;

    my $auth_cookie = Apache::Cookie->new ($r,
                                       -name => $auth_name,
                                       -value => {Basic => encode_base64(encrypt_aes(join (":",$user,$password,$client_identifier,(time()+60*60*24*$cookie_lifetime)),$encryption_key))},
                                       -path => "/",
                                       -expires => "+".$cookie_lifetime."d"
                                      );
    $auth_cookie->bake;
       
}

sub encrypt_aes {

    my ($string, $key)=@_;
    
    # keysize() is 32, but 24 and 16 are also possible
    # blocksize() is 16
    # So we fill the string with some random data to the next 16 byte boundary.
    # Like this we have a valid block size AND oracle attacks get very difficult.
    
    my $fillup=16-(length($string) % 16);
    
    if ($fillup==0)
    {
        $fillup=16;
    }
    
    # The : is the boundary of the random data.
    $string=$string . ":";
    --$fillup;
    
    while ($fillup>0)
    {
        $string.=int(rand(10));
        --$fillup;
    }
    
    ## a a md5_hex checksum to the string.
    $string.=md5_hex($string);
    
    my $cipher = new Crypt::Rijndael $key, Crypt::Rijndael::MODE_CBC;
    
    # encrypt the string.
    $string=$cipher->encrypt($string);
   
    return $string;
}

sub decrypt_aes {

    my ($string, $key)=@_;
    
    # keysize() is 32, but 24 and 16 are also possible
    # blocksize() is 16
    ## The string must have 16 bytes blocks.
    if (length($string) % 16 !=0)
    {
        return "";
    }
    
    my $cipher = new Crypt::Rijndael $key, Crypt::Rijndael::MODE_CBC;
    # decrypt it
    my $decrypted=$cipher->decrypt($string);
    
    
    # Chop of the last 32 bytes (this is the md5 checksum)
    # and calculate checksum
    
    ## Check if the string is longer than 32 bytes
    if (length ($decrypted)<32)
    {
        return "";
    }
    
    ## Alter the string (chop of the last 32 bytes
    my $checksum=substr($decrypted,-32);
    $decrypted=substr($decrypted,0,(length($decrypted)-32));
    
    ## If the checksum is invalid return this
    if ($checksum ne md5_hex($decrypted))
    {
        return "";
    }
    ## chop of the random data
    my $char=" ";
    while($char ne ':' and $char ne '')
    {
        $char=chop($decrypted);
    }
    
    ## If char is eq to '' then there were no credentials, etc. in the string...
    if ($char eq '')
    {
        return '';
    }
    
     
    return $decrypted;

}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Apache::AutoLogin - Automatic login module based on encrypted cookies for sites using basic authentication.

=head1 SYNOPSIS

  # In httpd.conf or .htaccess put it just
  # before your basic authentication module
  
  # It has the be invoked as a PerlAccessHandler,
  # because this is just the phase
  # before authentication!
  
  <Location />
        PerlModule Apache::AutoLogin
        PerlAccessHandler Apache::AutoLogin
        
        # Set the lifetime of the cookie in days
        
        PerlSetVar AutoLoginCookieLifetimeInDays "3"
        
        # The encryption key can have any length, but the longer the better
        
        PerlSetVar AutoLoginEncryptionKey "abcdefghijklmnopqrstuvwxyz123456"
        
        # set the logout page: Important, make
        # sure that you specify something
        # that gets not cached by proxies, or
        # else the cookie won't be invalidated.
        
        PerlSetVar AutoLoginLogoutPage "/logout.php"
        
        # The name of the cookie
        
        PerlSetVar AutoLoginAuthName "AutoLogin rulez"
        

        # Here comes the basic authentication
        # module of any flavour. Apache::AutoLogin
        # has been tested with AuthPAM and AuthLDAP
        
        AuthType Basic
        AuthName "Apache_AutoLogin example"
        AuthPAM_Enabled on
        require valid-user

  </Location>
  
  # In this example make sure logout.php
  # can be viewed by the client without authentication!
  
  <Location /logout.php>
        PerlModule Apache::AutoLogin
        PerlAccessHandler Apache::AutoLogin
        PerlSetVar AutoLoginCookieLifetimeInDays "3"
        ## Anything as a key, is not important, cause it will by a random key
        PerlSetVar AutoLoginEncryptionKey "abcdefghijklmnopqrstuvwxyz123456"
        PerlSetVar AutoLoginLogoutPage "/logout.php"
        PerlSetVar AutoLoginAuthName "AutoLogin rulez"

        Order allow,deny
        allow from all
        satisfy any
  </Location>



=head1 DESCRIPTION

Apache::AutoLogin is a mod_perl module for convenience of the users. It is NO authentication module so far, authentication is up to other auth basic modules of any flavour.

Apache::AutoLogin does basically the following:

If a client connects for the first time, grab it's request and look for an Apache::AutoLogin cookie. If there is such a cookie, extract the credentials, add them to the http headers for later use by the authentication module. During such a session, the client does not send any basic authentication credentials over the net.

If the client sends an authorization header, then one of two things happened: There was no cookie for supplying the credentials or the cookie or the credentials were invalid. Then we basically take the credentials from the client's header and store them into a cookie for later use. During such a session the client sents as usual basic credentials over the net.

If a client wants to log out, he / she has to invoke a predefined page of any flavour and we will set in invalid cookie to erase the credentials.

=head2 Who should use it?

Anyone who relies on basic authentication and does not want the users to authenticate everytime they point their browser to the restricted website. Especially useful for company intranets.

=head2 Security aspects

The cookie itself is AES256 encrypted using Crypt::Rjindael and features a md5 checksum of the data. Furthermore, some information about the client the cookie was issued for is stored as well (IP address, user-agent, hostname), which should make it more difficult to steal a cookie from someone. The cookie expires after a given time. This expiration date is stored in the encrypted part of the cookie as well. Each time one accesses the page, the cookie gets renewed.

Anyways, although cracking of the cookie is almost unfeasable with todays computing powers, be aware that this module is for convenience only. It does not give you any additional security (well a bit perhaps) over traditional basic authentication, where credentials are sent in plaintext over the net, because if there is no valid cookie, the client sents these credentials anyways. So for security's sake use ssl! The encryption of the cookie is done only for avoiding offline password sneaking on the client itself.

Although the cookie can be regarded as secure, the security of it's use stands and falls with the security of the computer it is stored on. If your users do not have personal accounts on their computers, forget about using it.


=head1 Apache configuration directives

All directives are passed in PerlSetVar.
        
=head2 AutoLoginCookieLifetimeInDays "3"

    Lifetime of the cookie in days.

=head2 AutoLoginEncryptionKey "abcdefghijklmnopqrstuvwxyz123456"

    The encryption key to use. Based on this key via md5 some fairly random 256 bit key will be generated. You may change it regularly.

=head2 AutoLoginLogoutPage "/logout.php"

    The logout URI. Make sure, that it does not get cached by any proxies or else the cookie cannot be invalidated and that this URI can be accessed without authentication!

=head2 AutoLoginAuthName "AutoLogin rulez"
    
    The name of the cookie.
    

=head1 License

Perl artistic license.


=head1 AUTHOR

Marcel M. Weber <lt>mmweber@ncpro.com<gt>

=head1 SEE ALSO

L<perl>.

=cut
