#!/usr/bin/perl -w

use strict;
use warnings;
use Carp;
$SIG{__WARN__} = $SIG{__DIE__} = \&Carp::croak;

BEGIN
{ 
   use Test::More tests => 3;
   use_ok("CAM::EmailTemplate");
}


SKIP: {
   if (!$ENV{RECIPIENT})
   {
      skip('Use "setenv RECIPIENT user@somehost.foo.com" to enable this test', 2);
   }

   my $t = CAM::EmailTemplate->new();
   ok($t, "Constructor");

   $t->setString(<<'EOF'
To: ::RECIPIENT::, "Joe Smith" <::RECIPIENT::>
From: "EmailTemplate test" <justatest@clotho.com>
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
