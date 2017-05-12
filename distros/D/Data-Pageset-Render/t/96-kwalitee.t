use strict;
use warnings;
use Test::More;

plan( skip_all => 'Author test. Set TEST_AUTHOR to a true value to run.' )
    unless $ENV{TEST_AUTHOR};

eval { require Test::Kwalitee; };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

Test::Kwalitee->import();
