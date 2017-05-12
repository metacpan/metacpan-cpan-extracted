#===============================================================================

=head1 NAME

Apache2::AuthCookieDBImg

=head1 PURPOSE

An AuthCookie module backed by a DBI database with second level
authentication via image matching.  This is very simple image
authentication scheme that is only meant to prevent robotic
logins to a web page by adding a 2nd level of authentication.

=head1 SYNOPSIS

    # In httpd.conf or .htaccess
        
    PerlModule Apache2::AuthCookieDBImg
    PerlSetVar WhatEverPath /
    PerlSetVar WhatEverLoginScript /login.pl

    # Optional, to share tickets between servers.
    PerlSetVar WhatEverDomain .domain.com
    
    # These must be set
    PerlSetVar WhatEverDBI_DSN "DBI:mysql:database=test"
    PerlSetVar WhatEverDBI_SecretKey "489e5eaad8b3208f9ad8792ef4afca73598ae666b0206a9c92ac877e73ce835c"

    # These are optional, the module sets sensible defaults.
    PerlSetVar WhatEverDBI_User "nobody"
    PerlSetVar WhatEverDBI_Password "password"

    PerlSetVar WhatEverDBI_UsersTable "users"
    PerlSetVar WhatEverDBI_UserField "user"
    PerlSetVar WhatEverDBI_PasswordField "password"
    PerlSetVar WhatEverDBI_CryptType "none"

    PerlSetVar WhatEverDBI_GroupsTable "groups"
    PerlSetVar WhatEverDBI_GroupField "grp"
    PerlSetVar WhatEverDBI_GroupUserField "user"

	 # These are optional, if all 3 are set
    # Image verification is performed
	 # The word is passed in via credential_2
	 # The key is passed in via credential_3
	 #
    PerlSetVar WhatEverDBI_ImgTable 		"images"
    PerlSetVar WhatEverDBI_ImgWordField 	"imageword"
    PerlSetVar WhatEverDBI_ImgKeyField 	"imagekey"

    PerlSetVar WhatEverDBI_EncryptionType "none"
    PerlSetVar WhatEverDBI_SessionLifetime 00-24-00-00

    # Protected by AuthCookieDBImg.
    <Directory /www/domain.com/authcookiedbimg>
        AuthType Apache2::AuthCookieDBImg
        AuthName WhatEver
        PerlAuthenHandler Apache2::AuthCookieDBImg->authenticate
        PerlAuthzHandler Apache2::AuthCookieDBImg->authorize
        require valid-user
        # or you can require users:
        require user jacob
        # You can optionally require groups.
        require group system
    </Directory>

    # Login location.
    <Files LOGIN>
        AuthType Apache2::AuthCookieDBImg
        AuthName WhatEver
        SetHandler perl-script
        PerlHandler Apache2::AuthCookieDBImg->login
    </Files>

=head1 DESCRIPTION

This module is an authentication handler that uses the basic mechanism provided
by Apache2::AuthCookie with a DBI database for ticket-based protection.  It
is based on two tokens being provided, a username and password, which can
be any strings (there are no illegal characters for either).  The username is
used to set the remote user as if Basic Authentication was used.

On an attempt to access a protected location without a valid cookie being
provided, the module prints an HTML login form (produced by a CGI or any
other handler; this can be a static file if you want to always send people
to the same entry page when they log in).  This login form has fields for
username and password.  On submitting it, the username and password are looked
up in the DBI database.  The supplied password is checked against the password
in the database; the password in the database can be plaintext, or a crypt()
or md5_hex() checksum of the password.  If this succeeds, the user is issued
a ticket.  This ticket contains the username, an issue time, an expire time,
and an MD5 checksum of those and a secret key for the server.  It can
optionally be encrypted before returning it to the client in the cookie;
encryption is only useful for preventing the client from seeing the expire
time.  If you wish to protect passwords in transport, use an SSL-encrypted
connection.  The ticket is given in a cookie that the browser stores.

After a login the user is redirected to the location they originally wished
to view (or to a fixed page if the login "script" was really a static file).

On this access and any subsequent attempt to access a protected document, the
browser returns the ticket to the server.  The server unencrypts it if
encrypted tickets are enabled, then extracts the username, issue time, expire
time and checksum.  A new checksum is calculated of the username, issue time,
expire time and the secret key again; if it agrees with the checksum that
the client supplied, we know that the data has not been tampered with.  We
next check that the expire time has not passed.  If not, the ticket is still
good, so we set the username.

Authorization checks then check that any "require valid-user" or "require
user jacob" settings are passed.  Finally, if a "require group foo" directive
was given, the module will look up the username in a groups database and
check that the user is a member of one of the groups listed.  If all these
checks pass, the document requested is displayed.

If a ticket has expired or is otherwise invalid it is cleared in the browser
and the login form is shown again.

IMAGE MATCHING

The image matching only occurs if all 3 of the following directives appear
in the Apache configuration file:
    PerlSetVar WhatEverDBI_ImgTable 		"images"
    PerlSetVar WhatEverDBI_ImgWordField 	"imageword"
    PerlSetVar WhatEverDBI_ImgKeyField 	"imagekey"

The first ImgTable var is the DBI table that we will use to store our
image key + word pairs.   The key field is set by the second var, the word
is the third var.

Your login form should set the 2  required fields for ALL AuthCookieDBI
login forms:
Your login ID: <input type="text" name="credential_0" value="">
Your password: <input type="password" name="credential_1" value="">

PLUS two additional fields for image processing:
The image says: <input type="text" name="credential_2" value="">
<input type="hidden" name="credential_3" value="a_random_key">

The login form should also have an image displayed that shows the word
that we are expecting to receive via credential_2 as semi-obscured text.
Typically the image that is displayed is selected at random (provide
your own image randomizer here) with the hidden credential_3 field
also being set via the same random selector so that we can lookup
the word in the images table via the key we get in credential_3.

For example, my randomizer (written in perl and called via a perl 
page template processor similar to Template::Toolkit) will spit out
my image coding and hidden field coding into my HTML page selecting
a random image + key from the images table.  For example, the output
from my perl randomizer spits out:
<img src="/images/dbimg/junk.png"><input type="hidden" name="credential_3" value="1">

To make the work of the randomizer easier I create my images table
like this:
create table images ( imagekey serial, imageurl char(128), imageword char(20));

And load it up like this:
inssert into images (imageurl,imageword) values ('/images/dbimg/junk.png','saywhat?');

Then create an image named junk.png and put it in my web server /images/dbimg folder.
The text on the image has a background picture plus the word "saywhat?" across the front.

The randomizer just looks up the imageurl and imagekey in the database and spits out
the appropriate HTML code.   ApacheCookieDBImg then does a reverse operation, looking
up the imageword based on the key.

=head1 CAVEATS

This is not a truly random image, so it is not overly secure.  The initial idea is just
to thwart stupid bots.   Someone could easily visit the site and build a map of image
sources and the matching words.  i.e. when credential_3 == 1 the word is always "saywhat?".

Not fool-proof, just and extra level of bot protection.

=cut

#===============================================================================
#===============================================================================

package Apache2::AuthCookieDBImg;

use strict;
use 5.004;
use vars qw( $VERSION );
$VERSION = '2.2';

use Apache2::AuthCookie;
use vars qw( @ISA );
@ISA = qw( Apache2::AuthCookie );

use Apache2::RequestRec;
use Apache::DBI;
use Apache2::Const -compile => qw( OK HTTP_FORBIDDEN );
use Apache2::ServerUtil;
use Digest::MD5 qw( md5_hex );
use Date::Calc qw( Today_and_Now Add_Delta_DHMS );
# Also uses Crypt::CBC if you're using encrypted cookies.
# Also uses Apache2::Session if you're using sessions.

#===============================================================================
# F U N C T I O N   D E C L A R A T I O N S
#===============================================================================

sub _log_not_set($$);
sub _dir_config_var($$);
sub _dbi_config_vars($);
sub _now_year_month_day_hour_minute_second();
sub _percent_encode($);
sub _percent_decode($);

sub extra_session_info($$\@);
sub authen_cred($$\@);
sub authen_ses_key($$$);
sub group($$\@);

#===============================================================================
# P A C K A G E   G L O B A L S
#===============================================================================

use vars qw( %CIPHERS );
# Stores Cipher::CBC objects in $CIPHERS{ idea:AuthName },
# $CIPHERS{ des:AuthName } etc.
our @Extra_Data;		# CSA Patch - needed for keeping cookie active


#===============================================================================
# P R I V A T E   F U N C T I O N S
#===============================================================================

#-------------------------------------------------------------------------------
# _log_not_set -- Log that a particular authentication variable was not set.

sub _log_not_set($$) {
    my( $r, $variable ) = @_;
    my $auth_name = $r->auth_name;
    $r->log_error( "Apache2::AuthCookieDBImg: $variable not set for auth realm $auth_name", $r->uri );
}

#-------------------------------------------------------------------------------
# _dir_config_var -- Get a particular authentication variable.

sub _dir_config_var($$) {
    my( $r, $variable ) = @_;
    my $auth_name = $r->auth_name;
    return $r->dir_config( "$auth_name$variable" );
}

#-------------------------------------------------------------------------------
# _dbi_config_vars -- Gets the config variables from the dir_config and logs
# errors if required fields were not set, returns undef if any of the fields
# had errors or a hash of the values if they were all OK.  Takes a request
# object.

=head1 APACHE CONFIGURATION DIRECTIVES

All configuration directives for this module are passed in PerlSetVars.  These
PerlSetVars must begin with the AuthName that you are describing, so if your
AuthName is PrivateBankingSystem they will look like:

    PerlSetVar PrivateBankingSystemDBI_DSN "DBI:mysql:database=banking"

See also L<Apache2::Authcookie> for the directives required for any kind
of Apache2::AuthCookie-based authentication system.

In the following descriptions, replace "WhatEver" with your particular
AuthName.  The available configuration directives are as follows:

=over 4

=item C<WhatEverDBI_DSN>

Specifies the DSN for DBI for the database you wish to connect to retrieve
user information.  This is required and has no default value.

=item C<WhateverDBI_SecretKey>

Specifies the secret key for this auth scheme.  This should be a long
random string.  This should be secret; either make the httpd.conf file
only readable by root, or put the PerlSetVar in a file only readable by
root and include it.

This is required and has no default value.
(NOTE: In AuthCookieDBImg versions 1.22 and earlier the secret key either could be
or was required to be in a seperate file with the path configured with
PerlSetVar WhateverDBI_SecretKeyFile, as of version 2.0 this is not possible, you
must put the secret key in the Apache configuration directly, either in the main
httpd.conf file or in an included file.  You might wish to make the file not
world-readable. Also, make sure that the Perl environment variables are
not publically available, for example via the /perl-status handler.)
See also L</"COMPATIBILITY"> in this man page.

=item C<WhatEverDBI_User>

The user to log into the database as.  This is not required and
defaults to undef.

=item C<WhatEverDBI_Password>

The password to use to access the database.  This is not required
and defaults to undef.

Make sure that the Perl environment variables are
not publically available, for example via the /perl-status handler since the
password could be exposed.

=item C<WhatEverDBI_UsersTable>

The table that user names and passwords are stored in.  This is not
required and defaults to 'users'.

=item C<WhatEverDBI_UserField>

The field in the above table that has the user name.  This is not
required and defaults to 'user'.

=item C<WhatEverDBI_PasswordField>

The field in the above table that has the password.  This is not
required and defaults to 'password'.

=item C<WhatEverDBI_CryptType>

What kind of hashing is used on the password field in the database.  This can
be 'none', 'crypt', or 'md5'.  This is not required and defaults to 'none'.

=item C<WhatEverDBI_GroupsTable>

The table that has the user / group information.  This is not required and
defaults to 'groups'.

=item C<WhatEverDBI_GroupField>

The field in the above table that has the group name.  This is not required
and defaults to 'grp' (to prevent conflicts with the SQL reserved word 'group').

=item C<WhatEverDBI_GroupUserField>

The field in the above table that has the user name.  This is not required
and defaults to 'user'.

=item C<WhatEverDBI_ImgTable>

The table that has the image to word mapping information.  This is not required and
defaults to 'groups'.

=item C<WhatEverDBI_GroupField>

The field in the above table that has the group name.  This is not required
and defaults to 'grp' (to prevent conflicts with the SQL reserved word 'group').

=item C<WhatEverDBI_GroupUserField>

The field in the above table that has the user name.  This is not required
and defaults to 'user'.

=item C<WhatEverDBI_EncryptionType>

What kind of encryption to use to prevent the user from looking at the fields
in the ticket we give them.  This is almost completely useless, so don''t
switch it on unless you really know you need it.  It does not provide any
protection of the password in transport; use SSL for that.  It can be 'none',
'des', 'idea', 'blowfish', or 'blowfish_pp'.

This is not required and defaults to 'none'.

=item C<WhatEverDBI_SessionLifetime>

How long tickets are good for after being issued.  Note that presently
Apache2::AuthCookie does not set a client-side expire time, which means that
most clients will only keep the cookie until the user quits the browser.
However, if you wish to force people to log in again sooner than that, set
this value.  This can be 'forever' or a life time specified as:

    DD-hh-mm-ss -- Days, hours, minute and seconds to live.

This is not required and defaults to '00-24-00-00' or 24 hours.

=item C<WhatEverDBI_SessionModule>

Which Apache2::Session module to use for persistent sessions.
For example, a value could be "Apache2::Session::MySQL".  The DSN will
be the same as used for authentication.  The session created will be
stored in $r->pnotes( WhatEver ).

If you use this, you should put:

    PerlModule Apache2::Session::MySQL

(or whatever the name of your session module is) in your httpd.conf file,
so it is loaded.

If you are using this directive, you can timeout a session on the server side
by deleting the user''s session.  Authentication will then fail for them.

This is not required and defaults to none, meaning no session objects will
be created.

=item C<WhatEverDBI_SessionActiveReset>

Force the session cookie expiration to reset whenever user activity is
detected (new page loaded, etc.).  This allows a low expiration time (5 minutes)
that logs off when a session is inactive.  Active sessions will be granted
more time each time they perform an action.

This is not required and defaults to 0 (Expire X minutes after initial logon).

=cut

sub _dbi_config_vars($) {
    my( $r ) = @_;
    my %c; # config variables hash

    unless ( $c{ DBI_DSN } = _dir_config_var $r, 'DBI_DSN' ) {
        _log_not_set $r, 'DBI_DSN';
        return undef;
    }

    unless ( $c{ DBI_secretkey } = _dir_config_var $r, 'DBI_SecretKey' ) {
        _log_not_set $r, 'DBI_SecretKey';
        return undef;
    }

    $c{ DBI_user           } = _dir_config_var( $r, 'DBI_User'           )                || undef;
    $c{ DBI_password       } = _dir_config_var( $r, 'DBI_Password'       )                || undef;
    $c{ DBI_userstable     } = _dir_config_var( $r, 'DBI_UsersTable'     )                || 'users';
    $c{ DBI_userfield      } = _dir_config_var( $r, 'DBI_UserField'      )                || 'user';
    $c{ DBI_passwordfield  } = _dir_config_var( $r, 'DBI_PasswordField'  )                || 'password';
    $c{ DBI_crypttype      } = _dir_config_var( $r, 'DBI_CryptType'      )                || 'none';
    $c{ DBI_groupstable    } = _dir_config_var( $r, 'DBI_GroupsTable'    ) 					|| 'groups';
    $c{ DBI_groupfield     } = _dir_config_var( $r, 'DBI_GroupField'     ) 					|| 'grp';
    $c{ DBI_groupuserfield } = _dir_config_var( $r, 'DBI_GroupUserField' )						|| 'user';
    $c{ DBI_imgtable    	} = _dir_config_var( $r, 'DBI_ImgTable'		 ) 					|| '';
    $c{ DBI_imgkeyfield   	} = _dir_config_var( $r, 'DBI_ImgKeyField'	 )						|| '';
    $c{ DBI_imgwordfield   } = _dir_config_var( $r, 'DBI_ImgWordField'	 )						|| '';
    $c{ DBI_encryptiontype } = _dir_config_var( $r, 'DBI_EncryptionType' )    	         || 'none';
    $c{ DBI_sessionlifetime} = _dir_config_var( $r, 'DBI_SessionLifetime') 					|| '00-24-00-00';
    $c{ DBI_sessionmodule 	} = _dir_config_var( $r, 'DBI_SessionModule'  );
    $c{ DBI_SessionActiveReset } = _dir_config_var( $r, 'DBI_SessionActiveReset' ) 			|| 0;

    return %c;

    # If we used encryption we need to pull in Crypt::CBC.
    require Crypt::CBC if ( $c{ DBI_encryptiontype } ne 'none' );

    return %c;
}

#-------------------------------------------------------------------------------
# _now_year_month_day_hour_minute_second -- Return a string with the time in
# this order separated by dashes.

sub _now_year_month_day_hour_minute_second()
{
    return sprintf '%04d-%02d-%02d-%02d-%02d-%02d', Today_and_Now;
}

#-------------------------------------------------------------------------------
# _percent_encode -- Percent-encode (like URI encoding) any non-alphanumberics
# in the supplied string.

sub _percent_encode($)
{
    my( $str ) = @_;
    $str =~ s/([^\w])/ uc sprintf '%%%02x', ord $1 /eg;
    return $str;
}

#-------------------------------------------------------------------------------
# _percent_decode -- Percent-decode (like URI decoding) any %XX sequences in
# the supplied string.

sub _percent_decode($)
{
    my( $str ) = @_;
    $str =~ s/%([0-9a-fA-F]{2})/ pack( "c",hex( $1 ) ) /ge;
    return $str;
}

#===============================================================================
# P U B L I C   F U N C T I O N S
#===============================================================================

=head1 SUBCLASSING

You can subclass this module to override public functions and change
their behaviour.

=over 4

=item C<extra_session_info()>

This method returns extra fields to add to the session key.
It should return a string consisting of ":field1:field2:field3"
(where each field is preceded by a colon).

The default implementation does nothing.

=back

=cut

sub extra_session_info ($$\@) {
    my ($self, $r, @credentials) = @_;
    return '';
}

#-------------------------------------------------------------------------------
# Take the credentials for a user and check that they match; if so, return
# a new session key for this user that can be stored in the cookie.
# If there is a problem, return a bogus session key.

sub authen_cred($$\@)
{
    my( $self, $r, @credentials ) = @_;

    my $auth_name = $r->auth_name;

    # Username goes in credential_0
    my $user = shift @credentials;
    unless ( $user =~ /^.+$/ ) {
        $r->log_error( "Apache2::AuthCookieDBI: no username supplied for auth realm $auth_name", $r->uri );
        return undef;
    }
    # Password goes in credential_1
    my $password = shift @credentials;
    unless ( $password =~ /^.+$/ ) {
        $r->log_error( "Apache2::AuthCookieDBI: no password supplied for auth realm $auth_name", $r->uri );
        return undef;
    }

	 # CSA Patch - Use global var
	 # needed later for authen_sess_key
	 # to keep cookie alive
	 #
    # Extra data can be put in credential_2, _3, etc.
    # my @extra_data = @credentials;
	 @Extra_Data = @credentials;

    # get the configuration information.
    my %c = _dbi_config_vars $r;

    # get the crypted password from the users database for this user.
    my $dbh = DBI->connect( $c{ DBI_DSN },
                            $c{ DBI_user }, $c{ DBI_password } );
    unless ( defined $dbh ) {
        $r->log_error( "Apache2::AuthCookieDBI: couldn't connect to $c{ DBI_DSN } for auth realm $auth_name", $r->uri );
        return undef;
    }
    my $sth = $dbh->prepare( <<"EOS" );
SELECT $c{ DBI_passwordfield }
FROM $c{ DBI_userstable }
WHERE $c{ DBI_userfield } = ?
EOS
    $sth->execute( $user );

    # CSA Patch - No need to add array overhead when fetching a single field
    # my( $crypted_password ) = $sth->fetchrow_array;
    my $crypted_password = $sth->fetchrow;
    unless ( defined $crypted_password ) {
        $r->log_error( "Apache2::AuthCookieDBI: couldn't select password from $c{ DBI_DSN }, $c{ DBI_userstable }, $c{ DBI_userfield } for user $user for auth realm $auth_name", $r->uri );
        return undef;
    }
   
    # now return unless the passwords match.
    if ( lc $c{ DBI_crypttype } eq 'none' ) {
        unless ( $password eq $crypted_password ) {
            $r->log_error( "Apache2::AuthCookieDBI: plaintext passwords didn't match for user $user for auth realm $auth_name", $r->uri );
            return undef;
        }
    } elsif ( lc $c{ DBI_crypttype } eq 'crypt' ) {
        my $salt = substr $crypted_password, 0, 2;
        unless ( crypt( $password, $salt ) eq $crypted_password ) {
            $r->log_error( "Apache2::AuthCookieDBI: crypted passwords didn't match for user $user for auth realm $auth_name", $r->uri );
            return undef;
        }
    } elsif ( lc $c{ DBI_crypttype } eq 'md5' ) {
        unless ( md5_hex( $password ) eq $crypted_password ) {
            $r->log_error( "Apache2::AuthCookieDBI: MD5 passwords didn't match for user $user for auth realm $auth_name", $r->uri );
            return undef;
        }
    }

    # CSA Patch - New gen_key function for activity reset
	 # on cookies
    #
    return $self->gen_key($r, $user, \@Extra_Data);
}

#-------------------------------------------------------------------------------
# Take a session key and check that it is still valid; if so, return the user.

sub authen_ses_key($$$)
{
    my( $self, $r, $encrypted_session_key ) = @_;

    my $auth_name = $r->auth_name;

	 # Enable Debugging In Here
    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    # Get the configuration information.
    my %c = _dbi_config_vars $r;


    # Get the secret key.
    my $secretkey = $c{ DBI_secretkey };
    unless ( defined $secretkey ) {
        $r->log_error( "Apache2::AuthCookieDBImg: didn't have the secret key from for auth realm $auth_name", $r->uri );
        return undef;
    }
    
    # Decrypt the session key.
    my $session_key;
    if ( $c{ DBI_encryptiontype } eq 'none' ) {
        $session_key = $encrypted_session_key;
    } else {
        # Check that this looks like an encrypted hex-encoded string.
        unless ( $encrypted_session_key =~ /^[0-9a-fA-F]+$/ ) {
            $r->log_error( "Apache2::AuthCookieDBImg: encrypted session key $encrypted_session_key doesn't look like it's properly hex-encoded for auth realm $auth_name", $r->uri );
            return undef;
        }

        # Get the cipher from the cache, or create a new one if the
        # cached cipher hasn't been created, & decrypt the session key.
        my $cipher;
        if ( lc $c{ DBI_encryptiontype } eq 'des' ) {
            $cipher = $CIPHERS{ "des:$auth_name" }
               ||= Crypt::CBC->new( $secretkey, 'DES' );
        } elsif ( lc $c{ DBI_encryptiontype } eq 'idea' ) {
            $cipher = $CIPHERS{ "idea:$auth_name" }
               ||= Crypt::CBC->new( $secretkey, 'IDEA' );
        } elsif ( lc $c{ DBI_encryptiontype } eq 'blowfish' ) {
            $cipher = $CIPHERS{ "blowfish:$auth_name" }
               ||= Crypt::CBC->new( $secretkey, 'Blowfish' );
        } elsif ( lc $c{ DBI_encryptiontype } eq 'blowfish_pp' ) {
            $cipher = $CIPHERS{ "blowfish_pp:$auth_name" }
               ||= Crypt::CBC->new( $secretkey, 'Blowfish_PP' );
        } else {
            $r->log_error( "Apache2::AuthCookieDBImg: unknown encryption type $c{ DBI_encryptiontype } for auth realm $auth_name", $r->uri );
            return undef;
        }
        $session_key = $cipher->decrypt_hex( $encrypted_session_key );
    }
    
    # Break up the session key.
    my( $enc_user, $issue_time, $expire_time, $session_id,
      $supplied_hash, @rest ) = split /:/, $session_key;

    # Let's check that we got passed sensible values in the cookie.
    unless ( $enc_user =~ /^[a-zA-Z0-9_\%]+$/ ) {
        $r->log_error( "Apache2::AuthCookieDBImg: bad percent-encoded user $enc_user recovered from session ticket for auth_realm $auth_name", $r->uri );
        return undef;
    }
    # decode the user
    my $user = _percent_decode $enc_user;
    unless ( $issue_time =~ /^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/ ) {
        $r->log_error( "Apache2::AuthCookieDBImg: bad issue time $issue_time recovered from ticket for user $user for auth_realm $auth_name", $r->uri );
        return undef;
    }
    unless ( $expire_time =~ /^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/ ) {
        $r->log_error( "Apache2::AuthCookieDBImg: bad expire time $expire_time recovered from ticket for user $user for auth_realm $auth_name", $r->uri );
        return undef;
    }
    unless ( $supplied_hash =~ /^[0-9a-fA-F]{32}$/ ) {
        $r->log_error( "Apache2::AuthCookieDBImg: bad hash $supplied_hash recovered from ticket for user $user for auth_realm $auth_name", $r->uri );
        return undef;
    }

    # If we're using a session module, check that their session exist.
    if ( defined $c{ DBI_sessionmodule } ) {
        my %session;
        my $dbh = DBI->connect( $c{ DBI_DSN },
                                $c{ DBI_user }, $c{ DBI_password } );
        unless ( defined $dbh ) {
            $r->log_error( "Apache2::AuthCookieDBImg: couldn't connect to $c{ DBI_DSN } for auth realm $auth_name", $r->uri );
            return undef;
        }
        eval {
            tie %session, $c{ DBI_sessionmodule }, $session_id, +{
              Handle => $dbh,
              LockHandle => $dbh,
            };
        };
        if ( $@ ) {
            $r->log_error( "Apache2::AuthCookieDBImg: failed to tie session hash using session id $session_id for user $user for auth_realm $auth_name, error was $@", $r->uri );
            return undef;
        }
        # Update a timestamp at the top level to make sure we sync.
        $session{ timestamp } = _now_year_month_day_hour_minute_second;
        $r->pnotes( $auth_name, \%session );
    }

    # Calculate the hash of the user, issue time, expire_time and
    # the secret key  and the session_id and then the hash of that
    # and the secret key again.
    my $hash = md5_hex( join ':', $secretkey, md5_hex( join ':',
      $enc_user, $issue_time, $expire_time, $session_id, @rest, $secretkey
    ) );

    # Compare it to the hash they gave us.
    unless ( $hash eq $supplied_hash ) {
        $r->log_error( "Apache2::AuthCookieDBImg: hash in cookie did not match calculated hash of contents for user $user for auth realm $auth_name", $r->uri );
        return undef;
    }

    # Check that their session hasn't timed out.
    if ( _now_year_month_day_hour_minute_second gt $expire_time ) {
        $r->log_error( "Apache:AuthCookieDBImg: expire time $expire_time has passed for user $user for auth realm $auth_name", $r->uri );
        return undef;
    }

    # If we're being paranoid about timing-out long-lived sessions,
    # check that the issue time + the current (server-set) session lifetime
    # hasn't passed too (in case we issued long-lived session tickets
    # in the past that we want to get rid of). *** TODO ***
    # if ( lc $c{ DBI_AlwaysUseCurrentSessionLifetime } eq 'on' ) {


	 # Expire Time Update (Inactivity Timer vs. Hard Time)
	 # If SessionActiveReset Flag Is On
	 #
	 if ($c{ DBI_SessionActiveReset}) {
	  	my $ses_key = $self->gen_key($r, $user, \@Extra_Data);
 		$self->send_cookie($r, $ses_key);
	   $r->server->warn('Apache2:AuthCookieDBI: extended() '.$ses_key) if $debug >= 3;
 	 }


    # They must be okay, so return the user.
    return $user;
}

#-------------------------------------------------------------------------------
# 
# Separated gen_key from authen_cred
#
sub gen_key($$$)
{
	my( $self, $r, $user, $refExtraData ) = @_;

	my %c 			= _dbi_config_vars $r;
	my $auth_name 	= $r->auth_name;

	#----- Generate The Key Stuff...

    # Create the expire time for the ticket.
    my $expire_time;
    # expire time in a zillion years if it's forever.
    if ( lc $c{ DBI_sessionlifetime } eq 'forever' ) {
        $expire_time = '9999-01-01-01-01-01';
    } else {
        my( $deltaday, $deltahour, $deltaminute, $deltasecond )
           = split /-/, $c{ DBI_sessionlifetime };
        # Figure out the expire time.
        $expire_time = sprintf(
            '%04d-%02d-%02d-%02d-%02d-%02d',
            Add_Delta_DHMS( Today_and_Now,
                            $deltaday, $deltahour,
                    $deltaminute, $deltasecond )
        );
    }

    # Now we need to %-encode non-alphanumberics in the username so we
    # can stick it in the cookie safely.
    my $enc_user = _percent_encode $user;

	#---- CSA :: NEW 2.03 Session Stuff
	# If we are using sessions, we create a new session for this login.
	my $session_id = '';
	if ( defined $c{ DBI_sessionmodule } ) {
	    my $dbh = DBI->connect( $c{ DBI_DSN },
	                            $c{ DBI_user }, $c{ DBI_password } );
	    unless ( defined $dbh ) {
	        $r->log_error( "Apache2::AuthCookieDBI: couldn't connect to $c{ DBI_DSN } for auth realm $auth_name", $r->uri );
	        return undef;
	    }

	  my %session;
	  tie %session, $c{ DBI_sessionmodule }, undef, +{
	    Handle => $dbh,
	    LockHandle => $dbh,
	  };
	  $session_id = $session{ _session_id };
	  $r->pnotes( $auth_name, \%session );
	  $session{ user } = $user;
	  $session{ extra_data } = $refExtraData;
	}
	
	# OK, now we stick the username and the current time and the expire
	# time and the session id (if any) together to make the public part
	# of the session key:
	my $current_time = _now_year_month_day_hour_minute_second;
	my $public_part = "$enc_user:$current_time:$expire_time:$session_id";
	$public_part .= $self->extra_session_info($r,@Extra_Data);

	#----- CSA :: End New 2.03 Session Stuff
	#	my $current_time = _now_year_month_day_hour_minute_second;
	#	my $public_part = "$enc_user:$current_time:$expire_time";

    # OK, now we stick the username and the current time and the expire
    # time and the session id (if any) together to make the public part
    # of the session key:
    my $current_time = _now_year_month_day_hour_minute_second;
    my $public_part = "$enc_user:$current_time:$expire_time:$session_id";
    $public_part .= $self->extra_session_info($r,@Extra_Data);

    # Now we calculate the hash of this and the secret key and then
    # calculate the hash of *that* and the secret key again.
    my $secretkey = $c{DBI_secretkey};
    unless ( defined $secretkey ) {
        $r->log_error( "Apache2::AuthCookieDBI: didn't have the secret key for auth realm $auth_name", $r->uri );
        return undef;
    }
    my $hash = md5_hex( join ':', $secretkey, md5_hex(
        join ':', $public_part, $secretkey
    ) );

    # Now we add this hash to the end of the public part.
    my $session_key = "$public_part:$hash";

    # Now we encrypt this and return it.
    my $encrypted_session_key;
    if ( $c{ DBI_encryptiontype } eq 'none' ) {
        $encrypted_session_key = $session_key;
    } elsif ( lc $c{ DBI_encryptiontype } eq 'des'      ) {
        $CIPHERS{ "des:$auth_name"      }
           ||= Crypt::CBC->new( $secretkey, 'DES'      );
        $encrypted_session_key = $CIPHERS{
            "des:$auth_name"
        }->encrypt_hex( $session_key );
    } elsif ( lc $c{ DBI_encryptiontype } eq 'idea'     ) {
        $CIPHERS{ "idea:$auth_name"      }
           ||= Crypt::CBC->new( $secretkey, 'IDEA'     );
        $encrypted_session_key = $CIPHERS{
            "idea:$auth_name"
        }->encrypt_hex( $session_key );
    } elsif ( lc $c{ DBI_encryptiontype } eq 'blowfish' ) {
        $CIPHERS{ "blowfish:$auth_name" }
           ||= Crypt::CBC->new( $secretkey, 'Blowfish' );
        $encrypted_session_key = $CIPHERS{
            "blowfish:$auth_name"
        }->encrypt_hex( $session_key );
    }

    return $encrypted_session_key;
}


#-------------------------------------------------------------------------------
# Take a list of groups and make sure that the current remote user is a member
# of one of them.

sub group($$\@)
{
    my( $self, $r, $groups ) = @_;
    my @groups = split(/\s+/o, $groups);

    my $auth_name = $r->auth_name;

    # Get the configuration information.
    my %c = _dbi_config_vars $r;

    my $user = $r->user;

    # See if we have a row in the groups table for this user/group.
    my $dbh = DBI->connect( $c{ DBI_DSN },
                            $c{ DBI_user }, $c{ DBI_password } );
    unless ( defined $dbh ) {
        $r->log_error( "Apache2::AuthCookieDBImg: couldn't connect to $c{ DBI_DSN } for auth realm $auth_name", $r->uri );
        return undef;
    }

    # Now loop through all the groups to see if we're a member of any:
    my $sth = $dbh->prepare( <<"EOS" );
SELECT $c{ DBI_groupuserfield }
FROM $c{ DBI_groupstable }
WHERE $c{ DBI_groupfield } = ?
AND $c{ DBI_groupuserfield } = ?
EOS
    foreach my $group ( @groups ) {
        $sth->execute( $group, $user );
        return Apache2::Const::OK if ( $sth->fetchrow_array );
    }
    $r->log_error( "Apache2::AuthCookieDBImg: user $user was not a member of any of the required groups @groups for auth realm $auth_name", $r->uri );
    return Apache2::Const::HTTP_FORBIDDEN;
}

1;
__END__

=back

=head1 DATABASE SCHEMAS

For this module to work, the database tables must be laid out at least somewhat
according to the following rules:  the user field must be a primary key
so there is only one row per user; the password field must be NOT NULL.  If
you're using MD5 passwords the password field must be 32 characters long to
allow enough space for the output of md5_hex().  If you're using crypt()
passwords you need to allow 13 characters.

An minimal CREATE TABLE statement might look like:

    CREATE TABLE users (
        user VARCHAR(16) PRIMARY KEY,
        password VARCHAR(32) NOT NULL
    )

For the groups table, the access table is actually going to be a join table
between the users table and a table in which there is one row per group
if you have more per-group data to store; if all you care about is group
membership though, you only need this one table.  The only constraints on
this table are that the user and group fields be NOT NULL.

A minimal CREATE TABLE statement might look like:

    CREATE TABLE groups (
        grp VARCHAR(16) NOT NULL,
        user VARCHAR(16) NOT NULL
    )

=head1 COPYRIGHT

 Copyright (C) 2006 Charleston Software Associates (www.CharlestonSW.com)

=head1 LICENSE

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHOR

Lance Cleveland, Charleston Software Associates <info@charlestonsw.com>

=head1 HISTORY

v2.1 - February 2006
       Significant portions based on AuthCookieDBI v2.03
		 
v2.2 - April 2006
       Added SessionActiveReset configuration variable (reset logout timer)

=head1 REQUIRES

Apache::DBI
Apache2::AuthCookie
Apache2::Const
Apache2::ServerUtil
Date::Calc
Digest::MD5

Apache2::Session (if using sessions)
Cipher::CBC (if using CBC Ciphers)


=head1 SEE ALSO

Latest version: http://search.cpan.org/search?query=Apache%3A%3AAuthCookieDBImg&mode=all

Apache2::AuthCookieDBI(1)
Apache2::AuthCookie(1)
Apache2::Session(1)

=cut
