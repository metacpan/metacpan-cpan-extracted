#!perl
use strict;
use warnings;
use Test::More tests => 7;
use Test::Expect;
use lib 't/lib';
use TestHelpers qw(e_value e_defined);

expect_run
(
    command => "$^X -Ilib t/scripts/11-warn.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/2/);

e_value('$a',4);

e_defined('$b',0);

