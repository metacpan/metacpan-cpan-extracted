#!/usr/bin/perl -w

use strict;
use Test::More tests => 5;
use Test::Exception;

use AE::AdHoc;
$AE::AdHoc::warnings = 0;

my $sub;

ae_recv { $sub = ae_send; ae_send->("stop now"); } 0.01;
lives_ok { $sub->() } "Don't die if event loop MAY exist";
like ($AE::AdHoc::errstr, qr(Leftover.*outside), "Error was catched");
note $AE::AdHoc::errstr;

ae_recv { $sub = ae_goal("foo"); ae_send->("stop now"); } 0.01;
lives_ok { $sub->() } "Don't die if event loop MAY exist";
like ($AE::AdHoc::errstr, qr(Leftover.*outside), "Error was catched");
note $AE::AdHoc::errstr;

is (scalar @AE::AdHoc::errors, 2, "Exactly two errors");
