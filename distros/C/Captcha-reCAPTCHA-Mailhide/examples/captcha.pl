#!/usr/bin/perl
# Simple CGI Mailhide Captcha

use strict;
use warnings;
use Captcha::reCAPTCHA::Mailhide;

# Your reCAPTCHA mailhide keys from
#  http://www.google.com/recaptcha/mailhide/apikey
use constant MAIL_PUBLIC_KEY  => '<public mailhide key here>';
use constant MAIL_PRIVATE_KEY => '<private mailhide key here>';

$| = 1;

my $m = Captcha::reCAPTCHA::Mailhide->new;

print "Content-type: text/html\n\n";
print <<EOT;
<html>
  <body>
EOT

# Output a protected email address. Note that this will fail with an error
# until you supply real values for MAIL_PUBLIC_KEY and MAIL_PRIVATE_KEY.

print "<p>Mail ",
  $m->mailhide_html( MAIL_PUBLIC_KEY, MAIL_PRIVATE_KEY,
    'someone@example.com' ),
  "</p>\n";

print <<EOT;
  </body>
</html>
EOT
