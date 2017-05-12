#!/usr/bin/perl -w

use strict;
use warnings;
use Carp;
$SIG{__WARN__} = $SIG{__DIE__} = \&Carp::croak;

BEGIN
{ 
   use Test::More tests => 3;
   use_ok("CAM::EmailTemplate::SMTP");
}


SKIP: {
   if ((!$ENV{RECIPIENT}) || (!$ENV{MAILHOST}))
   {
      skip("\nUse 'setenv RECIPIENT user\@somehost.foo.com' and\n" .
           "    'setenv MAILHOST mail.foo.com' to enable this test.\n" .
           "You might want to do 'setenv SMTPTemplate_Debug 1' too.", 2);
   }

   my $t = CAM::EmailTemplate::SMTP->new();
   ok($t, "Constructor");

   $t->setHost($ENV{MAILHOST});

   $t->setString(<<'EOF'
To: ::RECIPIENT::, "Joe Smith" <::RECIPIENT::>
From: "EmailTemplate SMTP test" <justatest@clotho.com>
Subject: test

This is a test.
Test that bare periods get sent properly:
.
::test::
EOF
              );
   $t->setParams(
                 test => "This is another test, using replacement.",
                 RECIPIENT => $ENV{RECIPIENT},
                 );

   ok($t->send(), "Send to $ENV{RECIPIENT}") or
       diag(">>> ".$t->{sendError}." <<<");
}
