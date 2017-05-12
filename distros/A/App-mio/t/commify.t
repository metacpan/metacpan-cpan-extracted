#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

BEGIN { use_ok( 'App::mio' ); }
require_ok( 'App::mio' );


my $input    = "Some text 100\nwith 10000000 thousands\nand -123491823412";
my $expected = "Some text 100\nwith 10,000,000 thousands\nand -123,491,823,412";

ok(App::mio->commify($input) eq $expected => "the right output is returned");

done_testing();