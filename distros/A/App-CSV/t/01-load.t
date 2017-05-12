#!perl -T

use Test::More qw(no_plan);

BEGIN { use_ok('App::CSV') }
diag("Testing App-CSV $App::CSV::VERSION, Perl $], $^X");

