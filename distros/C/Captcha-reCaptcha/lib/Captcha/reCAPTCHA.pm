package Captcha::reCAPTCHA;

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTML::Tiny;

our $VERSION = '0.99';

use constant API_SERVER => 'http://www.google.com/recaptcha/api';
use constant API_SECURE_SERVER =>
 'https://www.google.com/recaptcha/api';
use constant API_VERIFY_SERVER => 'http://www.google.com';
use constant API_VERIFY_SERVER_V2 => 'https://www.google.com/recaptcha/api/siteverify';
use constant SERVER_ERROR      => 'recaptcha-not-reachable';
use constant API_V2_SERVER => 'https://www.google.com/recaptcha/api.js';

=head1 NAME

Captcha::reCAPTCHA - A Perl implementation of the reCAPTCHA API

=head1 VERSION

This document describes Captcha::reCAPTCHA version 0.99

=head1 NOTICE

Please note this module now allows the use of v2
there are no changes to version 1.
Version 2 has seperate methds you can call

=cut

=head1 SYNOPSIS

Note this release contains methods that use

    use Captcha::reCAPTCHA;

    my $c = Captcha::reCAPTCHA->new;

    # Output form New Version
    print $c->get_html_v2( 'your public key here' );

    # Version 1 (not recommended)
    print $c->get_html( 'your public key here' );

    # Verify submission
    my $result $c->check_answer_v2($private_key, $response, $ENV{REMOTE_ADDR});

    # Verify submission (Old Version)
    my $result = $c->check_answer(
        'your private key here', $ENV{'REMOTE_ADDR'},
        $challenge, $response
    );

    if ( $result->{is_valid} ) {
        print "Yes!";
    }
    else {
        # Error
        $error = $result->{error};
    }

For complete examples see the /examples subdirectory

=head1 DESCRIPTION

reCAPTCHA version 1 is a hybrid mechanical turk and captcha that allows visitors
who complete the captcha to assist in the digitization of books.

From L<http://recaptcha.net/learnmore.html>:

    reCAPTCHA improves the process of digitizing books by sending words that
    cannot be read by computers to the Web in the form of CAPTCHAs for
    humans to decipher. More specifically, each word that cannot be read
    correctly by OCR is placed on an image and used as a CAPTCHA. This is
    possible because most OCR programs alert you when a word cannot be read
    correctly.

version 1 of Perl implementation is modelled on the PHP interface that can be
found here:

L<http://recaptcha.net/plugins/php/>

To use reCAPTCHA you need to register your site here:

L<https://www.google.com/recaptcha/admin/create>


Version 2 is a new and eaasy to solve captcha that is
"easy for humans to solve, but hard for 'bots' and other malicious software"

=head1 INTERFACE

=over

=item C<< new >>

Create a new C<< Captcha::reCAPTCHA >>.

=cut

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_initialize( @_ );
  return $self;
}

sub _initialize {
  my $self = shift;
  my $args = shift || {};

  croak "new must be called with a reference to a hash of parameters"
   unless 'HASH' eq ref $args;
}

sub _html { shift->{_html} ||= HTML::Tiny->new }

=item C<< get_options_setter( $options ) >>

You can optionally customize the look of the reCAPTCHA widget with some
JavaScript settings. C<get_options_setter> returns a block of Javascript
wrapped in <script> .. </script> tags that will set the options to be used
by the widget.

C<$options> is a reference to a hash that may contain the following keys:

=over

=item C<theme>

Defines which theme to use for reCAPTCHA. Possible values are 'red',
'white' or 'blackglass'. The default is 'red'.

=item C<tabindex>

Sets a tabindex for the reCAPTCHA text box. If other elements in the
form use a tabindex, this should be set so that navigation is easier for
the user. Default: 0.

=back

=cut

sub get_options_setter {
  my $self = shift;
  my $options = shift || return '';

  croak "The argument to get_options_setter must be a hashref"
   unless 'HASH' eq ref $options;

  my $h = $self->_html;

  return $h->script(
    { type => 'text/javascript' },
    "\n//<![CDATA[\n"
     . "var RecaptchaOptions = "
     . $h->json_encode( $options )
     . ";\n//]]>\n"
  ) . "\n";
}

=item C<< get_options_setter_div( $pubkey, $options ) >>

You can optionally customize the look of the reCAPTCHA widget with some
settings. C<get_options_setter_div> returns a div element
wrapped in <div> .. </div> tags that will set the options to be used
by the widget.

C<$options> is a reference to a hash that may contain the following keys:

=over

=item C<data-theme>

Defines which theme to use for reCAPTCHA. Possible values are 'dark',
'light'. The default is 'light'.

=item C<data-type>

Defines the type of captcha to server. Possible values are 'audio' or 'image'.
Default is 'image'

=item C<data-size>

Defines the size of the widget. Possible values are 'compact' or 'normal'.
Default is 'normal'

=item C<data-tabindex>

Defines the tabindex of the widget and challenge. If other elements in your
page use tabindex, it should be set to make user navigation easier.
Default is 0

=item C<data-callback>

Defines the name of your callback function to be executed when the user submits
a successful CAPTCHA response. The user's response, g-recaptcha-response,
will be the input for your callback function.

=item C<data-expired-callback>

Defines the name of your callback function to be executed when the recaptcha
response expires and the user needs to solve a new CAPTCHA

=back
=cut

sub get_options_setter_div {
  my $self = shift;
  my ($pubkey, $options) = @_;

  croak "The argument to get_options_setter_div must be a hashref"
   if $options && ref $options ne 'HASH';

   # Make option in to an empty hash if nothing there
   $options = {} unless $options;

  croak "public key must be supplied" unless $pubkey;

   my $h = $self->_html;

   return $h->div({class => 'g-recaptcha',
        'data-sitekey' => $pubkey,
        %{$options}
      });
}

=item C<< get_html_v2( $pubkey, \%options ) >>

Generates HTML to display the captcha using the new api
pubkey is public key for \%options types the same as get_options_setter

  print $captcha->get_html_v2($pubkey, $options);

This uses ssl by default and does not display custom error messages

=cut

sub get_html_v2 {
  my $self = shift;
  my ($pubkey, $options) = @_;

  croak
   "To use reCAPTCHA you must get an API key from https://www.google.com/recaptcha/admin/create"
   unless $pubkey;

  my $h = $self->_html;

  # Use new version by default
  return join('',
    '<script src="https://www.google.com/recaptcha/api.js" async defer></script>',
    $self->get_options_setter_div( $pubkey, $options )
  );
}

=item C<< get_html( $pubkey, $error, $use_ssl, \%options ) >>

Generates HTML to display the captcha using api version 1.

    print $captcha->get_html( $PUB, $err );

=over

=item C<< $pubkey >>

Your reCAPTCHA public key, from the API Signup Page

=item C<< $error >>

Optional. If set this should be either a string containing a reCAPTCHA
status code or a result hash as returned by C<< check_answer >>.

=item C<< $use_ssl >>

Optional. Should the SSL-based API be used? If you are displaying a page
to the user over SSL, be sure to set this to true so an error dialog
doesn't come up in the user's browser.

=item C<< $options >>

Optional. A reference to a hash of options for the captcha. See
C<< get_options_setter >> for more details.

=back

Returns a string containing the HTML that should be used to display
the captcha.

=cut

sub get_html {
  my $self = shift;
  my ( $pubkey, $error, $use_ssl, $options ) = @_;

  croak
   "To use reCAPTCHA you must get an API key from https://www.google.com/recaptcha/admin/create"
   unless $pubkey;

  my $h = $self->_html;
  my $server = $use_ssl ? API_SECURE_SERVER : API_SERVER;

  my $query = { k => $pubkey };
  if ( $error ) {
    # Handle the case where the result hash from check_answer
    # is passed.
    if ( 'HASH' eq ref $error ) {
      return '' if $error->{is_valid};
      $error = $error->{error};
    }
    $query->{error} = $error;
  }
  my $qs = $h->query_encode( $query );

  return join(
    '',
    $self->get_options_setter( $options ),
    $h->script(
      {
        type => 'text/javascript',
        src  => "$server/challenge?$qs",
      }
    ),
    "\n",
    $h->noscript(
      [
        $h->iframe(
          {
            src         => "$server/noscript?$qs",
            height      => 300,
            width       => 500,
            frameborder => 0
          }
        ),
        $h->textarea(
          {
            name => 'recaptcha_challenge_field',
            rows => 3,
            cols => 40
          }
        ),
        $h->input(
          {
            type  => 'hidden',
            name  => 'recaptcha_response_field',
            value => 'manual_challenge'
          }
        )
      ]
    ),
    "\n"
  );
}

sub _post_request {
  my $self = shift;
  my ( $url, $args ) = @_;

  my $ua = LWP::UserAgent->new();
  $ua->env_proxy();
  return $ua->post( $url, $args );
}

=item C<< check_answer_v2 >>

After the user has filled out the HTML form, including their answer for
the CAPTCHA, use C<< check_answer >> to check their answer when they
submit the form. The user's answer will be in field,
g-recaptcha-response. The reCAPTCHA
library will make an HTTP request to the reCAPTCHA server and verify the
user's answer.

=over

=item C<< $privkey >>

Your reCAPTCHA private key, from the API Signup Page.

=item C<< $remoteip >>

The user's IP address, in the format 192.168.0.1 (optional)

=item C<< $response >>

The value of the form field recaptcha_response_field.

=back

Returns a reference to a hash containing two fields: C<is_valid>
and C<error>.

	# If your site does not use SSL then
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

    my $result = $c->check_answer_v2(
        'your private key here', $response,
        $ENV{'REMOTE_ADDR'}
    );

    my $result = $c->check_answer_v2(
        'your private key here', $response,
        $ENV{'REMOTE_ADDR'}
    );

    if ( $result->{is_valid} ) {
        print "Yes!";
    }
    else {
        # Error
        $error = $result->{error};
    }

See the /examples subdirectory for examples of how to call C<check_answer_v2>.

Note: this method will make an HTTP request to Google to verify the user input.
If this request must be routed via a proxy in your environment, use the
standard environment variable to specify the proxy address, e.g.:

    $ENV{http_proxy} = 'http://myproxy:3128';

=cut

sub check_answer_v2 {
    my $self = shift @_;

    my ($privkey, $response, $remoteip) = @_;

    croak
    "To use reCAPTCHA you must get an API key from https://www.google.com/recaptcha/admin/create"
      unless $privkey;

    croak "To check answer, the user response token must be provided" unless $response;

    my $request = {
      secret => $privkey,
      response => $response,
    };
    $request->{remoteip} = $remoteip if $remoteip;

    my $resp = $self->_post_request(
      API_VERIFY_SERVER_V2,
      $request
    );

    if ( $resp->is_success ) {

      if ($resp->content =~ /success": true/) {
        return { is_valid => 1 }
      } else {
        return { is_valid => 0, error => $resp->content};
      }
    }

    return { is_valid => 0, error => $resp->content }
}

=item C<< check_answer >>

After the user has filled out the HTML form, including their answer for
the CAPTCHA, use C<< check_answer >> to check their answer when they
submit the form. The user's answer will be in two form fields,
recaptcha_challenge_field and recaptcha_response_field. The reCAPTCHA
library will make an HTTP request to the reCAPTCHA server and verify the
user's answer.

=over

=item C<< $privkey >>

Your reCAPTCHA private key, from the API Signup Page.

=item C<< $remoteip >>

The user's IP address, in the format 192.168.0.1.

=item C<< $challenge >>

The value of the form field recaptcha_challenge_field

=item C<< $response >>

The value of the form field recaptcha_response_field.

=back

Returns a reference to a hash containing two fields: C<is_valid>
and C<error>.

    my $result = $c->check_answer(
        'your private key here', $ENV{'REMOTE_ADDR'},
        $challenge, $response
    );

    if ( $result->{is_valid} ) {
        print "Yes!";
    }
    else {
        # Error
        $error = $result->{error};
    }

See the /examples subdirectory for examples of how to call C<check_answer_v1>.

Note: this method will make an HTTP request to Google to verify the user input.
If this request must be routed via a proxy in your environment, use the
standard environment variable to specify the proxy address, e.g.:

    $ENV{http_proxy} = 'http://myproxy:3128';

=back
=cut

sub check_answer {
  my $self = shift;
  my ( $privkey, $remoteip, $challenge, $response ) = @_;

  croak
   "To use reCAPTCHA you must get an API key from https://www.google.com/recaptcha/admin/create"
   unless $privkey;

  croak "For security reasons, you must pass the remote ip to reCAPTCHA"
   unless $remoteip;

  return { is_valid => 0, error => 'incorrect-captcha-sol' }
   unless $challenge && $response;

  my $resp = $self->_post_request(
    API_VERIFY_SERVER . '/recaptcha/api/verify',
    {
      privatekey => $privkey,
      remoteip   => $remoteip,
      challenge  => $challenge,
      response   => $response
    }
  );

  if ( $resp->is_success ) {
    my ( $answer, $message ) = split( /\n/, $resp->content, 2 );
    if ( $answer =~ /true/ ) {
      return { is_valid => 1 };
    }
    else {
      chomp $message;
      return { is_valid => 0, error => $message };
    }
  }
  else {
    return { is_valid => 0, error => SERVER_ERROR };
  }
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT

Captcha::reCAPTCHA requires no configuration files or environment
variables.

To use reCAPTCHA sign up for a key pair here:

L<https://www.google.com/recaptcha/admin/create>

=head1 DEPENDENCIES

LWP::UserAgent,
HTML::Tiny

=head1 INCOMPATIBILITIES

None reported .

=head1 BUGS AND LIMITATIONS

Please see below link

https://rt.cpan.org/Public/Dist/Display.html?Name=Captcha-reCAPTCHA

Please report any bugs or feature requests to
C<bug-captcha-recaptcha@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Mainainted by
Sunny Patel C<< <sunnypatel4141@gmail.com> >>
Please report all bugs to Sunny Patel

Version 0.95-0.97 was maintained by
Fred Moyer C<< <fred@redhotpenguin.com> >>

Original Author
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
