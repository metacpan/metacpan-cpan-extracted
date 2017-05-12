package Captcha::reCAPTCHA::Mailhide;

use warnings;
use strict;
use Carp;
use Crypt::Rijndael;
use MIME::Base64;
use HTML::Tiny;

our $VERSION = '0.94';

use constant API_MAILHIDE_SERVER =>
 'http://www.google.com/recaptcha/mailhide';

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  croak "new takes no parameters" if @_;
  return $self;
}

sub _aes_encrypt {
  my ( $val, $ky ) = @_;

  my $val_len = length( $val );
  my $pad_len = int( ( $val_len + 15 ) / 16 ) * 16;

  # Pad value
  $val .= chr( 16 - $val_len % 16 ) x ( $pad_len - $val_len )
   if $val_len < $pad_len;

  my $cipher = Crypt::Rijndael->new( $ky, Crypt::Rijndael::MODE_CBC );
  $cipher->set_iv( "\0" x 16 );

  return $cipher->encrypt( $val );
}

sub _urlbase64 {
  my $str = shift;
  chomp( my $enc = encode_base64( $str ) );
  $enc =~ tr{+/}{-_};
  return $enc;
}

sub mailhide_url {
  my $self = shift;
  my ( $pubkey, $privkey, $email ) = @_;

  croak
   "To use reCAPTCHA::Mailhide, you have to sign up for a public and "
   . "private key. You can do so at http://www.google.com/recaptcha/mailhide/apikey."
   unless $pubkey && $privkey;

  croak "You must supply an email address"
   unless $email;

  my $h = HTML::Tiny->new();

  return
   API_MAILHIDE_SERVER . '/d?'
   . $h->query_encode(
    {
      k => $pubkey,
      c => _urlbase64( _aes_encrypt( $email, pack( 'H*', $privkey ) ) )
    }
   );
}

sub _email_parts {
  my ( $user, $dom ) = split( /\@/, shift, 2 );
  my $ul = length( $user );
  return ( substr( $user, 0, $ul <= 4 ? 1 : $ul <= 6 ? 3 : 4 ),
    '...', '@', $dom );
}

sub mailhide_html {
  my $self = shift;
  my ( $pubkey, $privkey, $email ) = @_;

  my $h = HTML::Tiny->new();

  my $url = $self->mailhide_url( $pubkey, $privkey, $email );
  my ( $user, $dots, $at, $dom ) = _email_parts( $email );

  my %window_options = (
    toolbar    => 0,
    scrollbars => 0,
    location   => 0,
    statusbar  => 0,
    menubar    => 0,
    resizable  => 0,
    width      => 500,
    height     => 300
  );

  my $options = join ',',
   map { "$_=$window_options{$_}" } sort keys %window_options;

  return join(
    '',
    $h->entity_encode( $user ),
    $h->a(
      {
        href    => $url,
        onclick => "window.open('$url', '', '$options'); return false;",
        title   => 'Reveal this e-mail address'
      },
      $dots
    ),
    $at,
    $h->entity_encode( $dom )
  );
}

1;
__END__

=head1 NAME

Captcha::reCAPTCHA::Mailhide - A Perl implementation of the reCAPTCHA Mailhide API

=head1 VERSION

This document describes Captcha::reCAPTCHA::Mailhide version 0.94

=head1 SYNOPSIS

    use Captcha::reCAPTCHA::Mailhide;
    
    my $m = Captcha::reCAPTCHA::Mailhide->new;

    # Get the URL that reveals the email
    my $url = $m->mailhide_url( MAIL_PUBLIC_KEY, MAIL_PRIVATE_KEY, 'someone@example.com' );

    # Or - even easier - get the formatted HTML for an email link
    print $m->mailhide_html( MAIL_PUBLIC_KEY, MAIL_PRIVATE_KEY, 'someone@example.com' );

For complete examples see the /examples subdirectory

=head1 DESCRIPTION

reCAPTCHA is a hybrid mechanical turk and captcha that allows visitors
who complete the captcha to assist in the digitization of books.

From L<http://recaptcha.net/learnmore.html>:

    reCAPTCHA improves the process of digitizing books by sending words that
    cannot be read by computers to the Web in the form of CAPTCHAs for
    humans to decipher. More specifically, each word that cannot be read
    correctly by OCR is placed on an image and used as a CAPTCHA. This is
    possible because most OCR programs alert you when a word cannot be read
    correctly.

This Perl implementation is modelled on the PHP interface that can be
found here:

L<http://recaptcha.net/plugins/php/>

=head1 INTERFACE

To use reCAPTCHA Mailhide you need to get a public, private key pair
from this page:

L<http://www.google.com/recaptcha/mailhide/apikey>

The Mailhide API consists of two methods C<< mailhide_html >>
and C<< mailhide_url >>. The methods have the same parameters.

The _html version returns HTML that can be directly put on your web
page. The username portion of the email that is passed in is
truncated and replaced with a link that calls Mailhide. The _url
version gives you the url to decode the email and leaves it up to you
to place the email in HTML.

=over

=item C<< new >>

Create a new C<< Captcha::reCAPTCHA::Mailhide >>.

=item C<< mailhide_url( $pubkey, $privkey, $email ) >>

Generate a link that will decode the specified email address.

=over

=item C<< $pubkey >>

The Mailhide public key from the signup page

=item C<< $privkey >>

The Mailhide private key from the signup page

=item C<< $email >>

The email address you want to hide.

=back

Returns a URL that when clicked will allow the user to decode the hidden
email address.

=item C<< mailhide_html( $pubkey, $privkey, $email ) >>

Generates HTML markup to embed a Mailhide protected email address
on a page.

The arguments are the same as for C<mailhide_url>.

Returns a string containing HTML that may be embedded directly in
a web page.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Captcha::reCAPTCHA::Mailhide requires no configuration files or environment
variables.

To use Mailhide get a public/private key pair here:

L<http://www.google.com/recaptcha/mailhide/apikey>

=head1 DEPENDENCIES

Crypt::Rijndael,
MIME::Base64,
HTML::Tiny

=head1 INCOMPATIBILITIES

None reported .

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-captcha-recaptcha@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
