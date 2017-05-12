package Apache2::reCaptcha;
use Apache2::AuthTicket;
@ISA = ("Apache2::AuthTicket");
use vars qw(%DEFAULTS %CONFIG);


use Captcha::reCAPTCHA;
use CGI;
use strict;
use warnings;
use Apache2::Const qw(REDIRECT OK);
use constant DEBUGGING => 0;

our $VERSION = '0.02';

my $_SESS_NAME='reCaptchaID';

sub make_login_screen {
    my ($self, $r, $action, $destination) = @_;

    if (DEBUGGING) {
        # log what we think is wrong.
        my $reason = $r->prev->subprocess_env("AuthCookieReason");
        $r->log_error("REASON FOR AUTH NEEDED: $reason");
        $reason = $r->prev->subprocess_env("AuthTicketReason");
        $r->log_error("AUTHTICKET REASON: $reason");
    }

    $r->content_type('text/html');

    my $c = Captcha::reCAPTCHA->new;
    my $recaptcha_public_key = $self->get_conf($r, 'PublicKey');
    my $header_template = $self->read_file($r, $self->get_conf($r, 'HeaderTemplate'));
    my $footer_template = $self->read_file($r, $self->get_conf($r, 'FooterTemplate'));


    my $cap_str =  $c->get_html( $recaptcha_public_key );
    my $bdy = <<END;
	<form method="post" action="$action">
	<input type="hidden" name="destination" value="$destination">
	$cap_str
	<input type="submit" value="Verify Me">
	<p>
	</form>
	<EM>Note: </EM>
	Set your browser to accept cookies in order for login to succeed.
	You will be asked to do this again after some period of time.
END

    $r->print($header_template . $bdy . $footer_template);

    return OK;
}

# check credentials and return a session key if valid
# return undef if invalid
sub authen_cred {
    my ($class, $r, @cred) = @_;

    my $this = $class->new($r);
    my $query = new CGI;

    my $response = $query->param('recaptcha_response_field');
    my $challenge = $query->param('recaptcha_challenge_field');

    my $c = Captcha::reCAPTCHA->new;
    my $privatekey = $this->get_conf($r, 'PrivateKey');
    my $result = $c->check_answer( $privatekey, $ENV{'REMOTE_ADDR'}, $challenge, $response);
    
    if ($result->{is_valid}) {
         $r->log_error("reCaptcha Is good");
        return $this->make_ticket($r, 'recaptcha');
    }
    else {
         $r->log_error("reCaptcha is Bad");
        return undef;
    }
}

sub get_conf{
    my ($self, $r, $f ) = @_;
    my $auth_name = $r->auth_name;
    return($r->dir_config("${auth_name}$f") ||
                          $CONFIG{$auth_name}->{$f} ||
                          $DEFAULTS{$f});
}


sub read_file{
    my ($self, $r, $f ) = @_;
    my $cnts;
    open F, "< $f" or $r->log_error("Can't open $f : $!");
    while(<F>){
       $cnts .= $_;
    }
    close F;
    return $cnts;
}

1;

__END__

=head1 NAME

Apache2::reCaptcha - reCaptcha based auth system using cookies.

=head1 SYNOPSIS

 # reCaptcha.conf
 PerlModule Apache2::reCaptcha
 PerlSetVar reCaptchaTicketDB DBI:mysql:database=sessions;host=mysql.example.com
 PerlSetVar reCaptchaTicketDBUser session
 PerlSetVar reCaptchaTicketDBPassword supersecret password
 PerlSetVar reCaptchaTicketTable tickets:ticket_hash:ts
 PerlSetVar reCaptchaTicketLoginHandler /reCaptchalogin
 #This is the path for the cookie
 PerlSetVar reCaptchaPath /
 PerlSetVar reCaptchaDomain www.example.com
 #only use if you want to force your URL to be SSL
 #PerlSetVar reCaptchaSecure 1
 PerlSetVar reCaptchaPublicKey biglongrandompublicstringfromrecaptchaproject
 PerlSetVar reCaptchaPrivateKey biglongandomprivatesringfromrecaptchaproject
 PerlSetVar reCaptchaHeaderTemplate /etc/apache2/recaptcha.header.inc
 PerlSetVar reCaptchaFooterTemplate /etc/apache2/recaptcha.footer.inc
 PerlSetVar reCaptchaLoginScript /reCaptchaloginform
 PerlSetVar reCaptchaCookieName reCaptcha
 #Having problems, tun on debugging
 #PerlSetVar AuthCookieDebug	5

 <Location /reCaptcha>
     AuthType Apache2::reCaptcha
     AuthName reCaptcha
     PerlAuthenHandler Apache2::reCaptcha->authenticate
     require valid-user
 </Location>
 
 <Location /reCaptchaloginform>
     AuthType Apache2::reCaptcha
     AuthName reCaptcha
     SetHandler perl-script
     PerlResponseHandler Apache2::reCaptcha->login_screen
 </Location>
 
 <Location /reCaptchalogin>
     AuthType Apache2::reCaptcha
     AuthName reCaptcha
     SetHandler perl-script
     PerlResponseHandler Apache2::reCaptcha->login
 </Location>
 
 <Location /reCaptcha/logout>
     AuthType Apache2::reCaptcha
     AuthName reCaptcha
     SetHandler perl-script
     PerlResponseHandler Apache2::reCaptcha->logout
 </Location>


=head1 DESCRIPTION

This Module uses the reCaptcha projects service to protect webresources from automated scripts that try to screen 
scrape your data. Often times adding a captcha check to a webapp requires recoding your app.  This module puts the 
verifcation work into apache and makes it easy to use in multiple places on your website.Often times having to do 
captchas over and over will discourage people from wanting to use the app. This module will asign a cookie based 
ticket the first time you complete a captcha for a protected resource and expire after fifteen minutes requiring 
you to do another captcha.  Since this is done using apache you can also white list IPs via Apaches 
'Allow from/Deny From' syntax.  This is helpful if your services need to be called from other resources.

This module has support for HTML templates to make it have the same look and feel as the rest of your website.
Define reCaptchaHeaderTemplate and reCaptchaFooterTemplate. These template files will be prepended and appended 
to the reCaptcha code.  Infact the reCaptcha interface look and feel can also be conigured.  See the reCaptcha project
page to figure out how to do this.

=head3 Why reCaptcha?

The reCaptcha project is more than just a great serice with accessability support.  By using it you are helping the 
=head3 L<<a href="http://archive.org">Internet Archive</a>> 
to digitize books that OCR software can't seem to figure out.   

=head1 CONFIGURATION

This module requires the following modules

 * Apache2::AuthTicet
 * Captcha::reCAPTCHA
 * CGI
 * DBD
 * DBI

You will also need to create the following tables in a database. 

	CREATE TABLE IF NOT EXISTS `tickets` (
	  `ticket_hash` char(32) NOT NULL,
	  `ts` int(11) NOT NULL,
	  PRIMARY KEY  (`ticket_hash`)
	) ENGINE=MyISAM DEFAULT CHARSET=latin1;
	
	CREATE TABLE IF NOT EXISTS `ticketsecrets` (
	  `sec_version` bigint(20) unsigned NOT NULL auto_increment,
	  `sec_data` text NOT NULL,
	  UNIQUE KEY `sec_version` (`sec_version`)
	) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
	
=head3 B<reCaptchaTicketDB>

This is a standard perl DBI dsn see the DBI for a complete reference on how to set this up. 

=head3 B<reCaptchaTicketDBUser>

The Database username to login

=head3 B<reCaptchaTicketDBPassword>

The database password

=head3 B<reCaptchaTicketTable>

This is the path to where to store tickets the fomat is table:column1:column2
 
=head3 B<reCaptchaTicketLoginHandler> 

This is the 
(See the above example to define these settings).

=head3 B<reCaptchaPrivatKey> 

You will recieve a public key from the reCaptcha project once you sign up

=head3 B<reCaptchaPublicKey> 

You will recieve a public key from the reCaptcha project once you sign up

It's easier to place the main config (Like the above config) into a conf file and use Include to include it into your httpd.conf or virtual 
host config. This defines all the basic setup

=head1 BUGS

If you are using this with proxypass, you may have troubles getting it to work past the first level of the uri

=head1 CREDITS

Thanks to Michael Shout for is development of AuthTicket which did all the heavy lifting in this module and 
Perrin Harkins from the mod_perl mailing list for his help. Last but not least Andy Armstrong for his development of the recaptcha api.

=head1 AUTHOR

Aaron Collins <analogrithems@gmail.com>

=head1 SEE ALSO

L<Apache::AuthTicket>

=cut
