#!/usr/bin/perl
# Simple CGI Captcha

use strict;
use warnings;
use Captcha::reCAPTCHA;
use CGI::Simple;

# Your reCAPTCHA keys from
#  https://www.google.com/recaptcha/admin/create
# Googles Test signature
use constant PUBLIC_KEY  => '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI';
use constant PRIVATE_KEY => '6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe';

$| = 1;

my $q = CGI::Simple->new;
my $c = Captcha::reCAPTCHA->new;

my $error = undef;

print "Content-type: text/html\n\n";
print <<EOT;
<html>
  <body>
    <form action="" method="post">
EOT

# Check response
if ( $q->param( 'recaptcha_response_field' ) ) {
  my $result = $c->check_answer(
    PRIVATE_KEY, $ENV{'REMOTE_ADDR'},
    $q->param( 'recaptcha_challenge_field' ),
    $q->param( 'recaptcha_response_field' )
  );

  if ( $result->{is_valid} ) {
    print "Yes!";
  }
  else {
    $error = $result->{error};
  }
}


if ( $q->param( 'g-recaptcha-response' ) ) {
   my $result = $c->check_answer(
     PRIVATE_KEY, $ENV{'REMOTE_ADDR'},
     $q->param( 'recaptcha_challenge_field' ),
     $q->param( 'recaptcha_response_field' )
   );

   if ( $result->{is_valid} ) {
     print "Yes!";
   }
   else {
     $error = $result->{error};
   }
 }

# Generate the form
print $c->get_html( PUBLIC_KEY, $error );

print "<h3>Version 2</h3>";

print $c->get_html_v2( PUBLIC_KEY );


print <<EOT;
    <br/>
    <input type="submit" value="submit" />
    </form>
  </body>
</html>
EOT
