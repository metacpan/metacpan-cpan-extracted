#!/usr/bin/env perl

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";
use App::OS::Detect::MachineCores;

use_ok( 'App::OS::Detect::MachineCores' );

ok (
    (App::OS::Detect::MachineCores->new_with_options->cores + 1) ==
    (App::OS::Detect::MachineCores->new(add_one => 1)->cores), "add_one works"
);

done_testing();