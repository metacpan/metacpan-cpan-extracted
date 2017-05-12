package Catalyst::Plugin::SecureCookies;
use strict;

use CGI::Cookie;
use Symbol;
use Class::Accessor::Fast;
use Digest::SHA1;
use Crypt::CBC;
use MIME::Base64;

our $VERSION = 0.01;
our $CIPHER;

=head1 NAME

Catalyst::Plugin::SecureCookies - Tamper-resistant, encrypted HTTP Cookies

=head1 SYNOPSIS

 use Catalyst qw/SecureCookies/;
 MyApp->config->{SecureCookies} = {
     key       => $blowfish_key,
     ssl       => 1       # send the checksum over ssl
 };
 MyApp->setup;

 # later, in another part of MyApp...

 $c->request->exp_secure_cookies( $expiration );
 $c->request->set_secure_cookie( 'my_cookie_name', $value );
 my $secure_data = $c->request->get_secure_cookie('my_cookie_name');

=head1 DESCRIPTION

=head2 Overview

When HTTP cookies are used to store a user's state or identity it's
important that your application is able to distinguish legitimate
cookies from those that have been edited or created by a malicious
user.

This module creates a pair of cookies which encrypt a form so the
user cannot modify cookie contents.

=head2 Implementation

SecureCookies is implemented using Crypt::CBC and MIME::Base64
to encrypt and encode a urlencoded string representing a perl
hash.  The encoded string is then hashed using Digest::SHA1 to
prepare a sort of "checksum" or hash to make sure the user did
not modify the cookie.

=head1 CONFIGURATION

=over 4

=item key

 MyApp->config->{SecureCookies}->{key} = $secret_key;

This parameter is B<required>, and sets the secret key that is used to
encrypt the cookies with Crypt::CBC Blowfish.  This needs to be a
16 hex character string.


=item ssl

 MyApp->config->{SecureCookies}->{ssl} = 0;
   # or
 MyApp->config->{SecureCookies}->{ssl} = 1;

This parameter is optional, and will default to C<1> if not set.

If C<1>, the checksum or hash cookie will be sent over SSL for
added security.  This will prevent replay attacks from being
used against the server.

If C<0>, the checksum will be sent as a normal, non-secure cookie.

=back

=head1 DIAGNOSTICS

=over 4

=back

=cut

=head1 METHODS

=head2 Catalyst Request Object Methods

=over 4

=cut

*{Symbol::qualify_to_ref('SecureCookies', 'Catalyst::Request')} =
  Class::Accessor::Fast::make_accessor('Catalyst::Request', 'SecureCookies');


=item C<< $c->request->get_secure_cookie($cookie_name) >>

If a cookie was successfully authenticated then this method will
return the value of the cookie.

=cut

*{Symbol::qualify_to_ref('get_secure_cookie', 'Catalyst::Request')} = sub {
    my $self = shift;
    my $name = shift;

    return $self->SecureCookies->{$name};
};

# add a secure cookie to the output
*{Symbol::qualify_to_ref('set_secure_cookie', 'Catalyst::Response')} = sub {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    $self->{SecureCookies}->{$name} = $value;
};


## set the cookie exp time
*{Symbol::qualify_to_ref('exp_secure_cookies', 'Catalyst::Response')} =
  Class::Accessor::Fast::make_accessor('Catalyst::Request', 'exp_secure_cookies');

sub setup {
    my $self = shift;

    $self->config->{SecureCookies}->{ssl} ||= 1;


    return $self->NEXT::setup(@_);
}

# remove and check hash in Cookie Values
sub prepare_cookies {
    my $c = shift;
    $c->NEXT::prepare_cookies(@_);

    ## pull out our secure dudes
    $c->request->{SecureCookies} = {};
    my $rJ = $c->request->cookie( 'rJ' );
    my $rC = $c->request->cookie( 'rC' );

    ## decrypt them
    if( $rJ && $rC ) {
	## decode it
	my $secret_form = &_decrypt( $c,
				     $rJ->value,   # encoded cookie
				     $rC->value ); # it's checksum
	if( $secret_form ) {
	    foreach my $key (keys %$secret_form) {
		$c->request->{SecureCookies}->{$key} = $secret_form->{$key};
	    }
	}
    }
    
    return $c;
}

# alter all Cookie Values to include a hash
sub finalize_cookies {
    my $c = shift;

    my $sc = $c->response->{SecureCookies};

    if( $sc ) {
	## pull in the existing secure cookies
	my $sco = $c->req->SecureCookies;
	if( $sco ) {
	    foreach my $key (keys %$sco) {
		if( ! defined($sc->{$key}) ) {
		    $sc->{$key} = $sco->{$key};
		}
	    }
	}

	## first encode the form
	my ($encoded, $csum) = &_encrypt( $c, $sc );

	## ssl, yes or no?
	my $ssl = $c->config->{SecureCookies}->{ssl};
	my $ssl_val = $ssl ? 1 : 0;

	## expiration?
	my $exp = $c->response->exp_secure_cookies();

	## make the two cookies
	$c->response->cookies->{rJ} = { value => $encoded,
				        expires => $exp };
	$c->response->cookies->{rC} = { value => $csum,
				        expires => $exp };

	my $domain = $c->config->{SecureCookies}->{cookie_domain};
	if( $domain ) {
		$c->response->cookies->{rJ}->{domain} = ".$domain";
		$c->response->cookies->{rJ}->{path} = '/';
		$c->response->cookies->{rC}->{domain} = ".$domain";
		$c->response->cookies->{rC}->{path} = '/';
	}
    }

    $c->NEXT::finalize_cookies(@_);
    return $c;
}

=item B<_encrypt>

Description:
  Takes a hashref representing web form elements, encrypts the components, creates a base64 safe url string

Args:
  $form_hasref - hashref of vars

Return:
  $encoded     - the encoded form
  $csum        - the checksum

=cut

sub _encrypt {
    my ( $c, $form_hashref ) = @_;

    my $cipher = &_get_cipher( $c->config->{SecureCookies}->{key} );

    ## first url encode it
    my $encoded = &_url_encode_hashref( $form_hashref );

    ## now we encrypt and mime encode it
    my $encrypted = $cipher->encrypt( $encoded );
#    $encrypted =~ s/^RandomIV//;
    my $mimed = &_base64_encode_url( $encrypted );

    ## checksum it
    my $ctx = new Digest::SHA1;
    $ctx->add( $mimed );
    my $csum = substr( &_base64_encode_url( $ctx->digest ), 3, 4 );

    ## give em what they want
    return ($mimed, $csum);
}

=item B<_decrypt>

Description:
  Takes a base64 safe url string representing form elements, decrypts the components, creates a hashref
m
Args:
  $encoded      - encoded form
  $csum         - csum for the form

Return:
  $form_hashref - hashref of the variables

=cut

sub _decrypt {
    my ( $c, $encoded, $csum ) = @_;

    my $cipher = &_get_cipher( $c->config->{SecureCookies}->{key} );

    ## calc a csum for the encrypted block
    my $ctx = new Digest::SHA1;
    $ctx->add( $encoded );

    my $this_csum = substr( &_base64_encode_url( $ctx->digest ), 3, 4 );

    ## compare it
    if( $csum ne $this_csum ) { return undef; }

    ## ok, the csum is good, decrypt
    my $encrypted = &_base64_decode_url( $encoded );
#    $encrypted = "RandomIV".$encrypted;
    my $dec = $cipher->decrypt( $encrypted );

    ## get the form
    my $form_hashref = &_url_decode_hashref( $dec );

    return $form_hashref;

}

=item B<_base64_encode_url>

Description:
 - safely encode using base64 to be used in urls

=cut

sub _base64_encode_url {
    my ($data, $separator) = @_;

    my $mimed = encode_base64( $data, $separator );

    ## convert to web friendlies
    $mimed =~ s/\s//g;
    $mimed =~ tr/[\+\/\=]/[\_\-.]/;
    return $mimed;
}

=item B<_base64_decode_url>

Description:
 - safely decode base64 from urls

=cut

sub _base64_decode_url {
    my ($mimed) = @_;

    ## convert from web friendlies
    $mimed =~ tr/[\_\-.]/[\+\/\=]/;

    return decode_base64( $mimed );
}

sub _get_cipher {
    my $key = shift;
    if ( !$CIPHER ) {
	$CIPHER = new Crypt::CBC( -key => pack("H16", $key), 
				  -cipher => 'Blowfish' );
    }
    return $CIPHER;
}

sub _url_encode_hashref {
    my ($form_hashref) = @_;

    ## bail if it's not a form
    if( !defined($form_hashref) ) { return ''; }

    ## run through the data, convert
    my @pairs;
    foreach my $key (keys %{$form_hashref}) {
	## grab the value
	my $val = $form_hashref->{$key};

	## support for array
	my @vals;
	if( ref($val) eq 'ARRAY' ) {
	    @vals = @$val;
	}
	else {
	    push( @vals, $val );
	}


	## encode the key and val
	foreach my $val1 (@vals) {
	    my $keye = &_urlencode_string( defined ( $key )  ? $key  : '' );
	    my $vale = &_urlencode_string( defined ( $val1 ) ? $val1 : '' );

	    ## save
	    push( @pairs, "$keye=$vale" );
	}
    }

    ## return the string
    return join( "&", @pairs );
}


=item B<decode_url_hashref>

Description:

convert a get string ( key1=val1&key2=val2 ) to a hash representing a
web form. If you are really using a get string, you must be sure to
only pass in the text after the question mark.

Args:
  $url_encoded   - parse this text

Return:
  $form       - hashref of the variables

=cut

sub _url_decode_hashref {
    my ($url_encoded) = @_;

    my %form;
    foreach (split(/&/,$url_encoded)) {

	## convert plus's to spaces
	s/\+/ /g;

	## split into key and value.
	my ($key, $val) = split(/\=/,$_,2 );

	## convert %XX from hex numbers to alphanumeric
	$key =~ s/%(..)/pack("c",hex($1))/ge if $key;
	$val =~ s/%(..)/pack("c",hex($1))/ge if $val;

	## associate key and value, multiple vars get tab delimination
	$form{$key} .= "\t" if ( defined($form{$key}) );
	$form{$key} .= $val if ( defined($val) );
    }

    return \%form;
}


=item B<_urlencode_string>

Description:
  convert $string into a url safe format

=cut

sub _urlencode_string {
    my ($string) = @_;

    ## standard urlencode
    $string =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    $string =~ s/ /\+/g;

    return $string;
}

=back

=head1 SEE ALSO

L<Catalyst>, L<Digest::SHA1>, L<Crypt::CBC>, L<MIME::Base64>

L<http://www.schneier.com/blog/archives/2005/08/new_cryptanalyt.html>

=head1 AUTHOR

Rob Johnson L<rob@giant-rock.com>

=head1 ACKNOWLEDGEMENTS

 * Karim A. Nassar for converting this into a self-contained Catalyst Plugin.

 * All the helpful people in #catalyst.

=head1 COPYRIGHT

Copyright (c) 2007 Karim A. Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

1;
