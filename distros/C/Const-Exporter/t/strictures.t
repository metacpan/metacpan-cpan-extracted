#!perl

use Test::Most;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use lib 't/lib';

throws_ok {
    require 'Test/Const/Exporter/Strictures.pm';
}
qr/^Global symbol "\$failure" requires explicit package name/,
  "undeclared variable";

done_testing;
