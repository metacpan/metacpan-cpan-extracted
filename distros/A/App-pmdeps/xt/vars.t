#!perl

use strict;
use warnings;
use utf8;

use Test::More;

eval "use Test::Vars";
plan skip_all => "Test::Vars required for testing variables" if $@;

eval "use Compiler::Lexer";
if ($@) {
    # Ignore Test::LocalFunctions::Fast
    vars_ok('lib/Test/LocalFunctions.pm');
}
else {
    all_vars_ok();
}

done_testing;
