#!/usr/bin/perl -w

# Test with assert off.


use strict;
use Test::More tests => 25;


use Carp::Assert qw(:NDEBUG);


my $tests = <<'END_OF_TESTS';
eval { assert(1==0) if DEBUG; };
is $@, '';


eval { assert(1==0); };
is $@, '';


eval { should('this', 'moofer') if DEBUG };
is $@, '';


eval { shouldnt('this', 'this') };
is $@, '';
END_OF_TESTS


my @disable_code = (
    "use Carp::Assert qw(:NDEBUG);",
    "no Carp::Assert;",
    'BEGIN { $ENV{NDEBUG} = 1; }  use Carp::Assert;',
    'BEGIN { $ENV{PERL_NDEBUG} = 1; }  use Carp::Assert;',
    'BEGIN { $ENV{NDEBUG} = 0;  $ENV{PERL_NDEBUG} = 1; } use Carp::Assert;'
);

for my $code (@disable_code) {
    local %ENV = %ENV;
    delete @ENV{qw(PERL_NDEBUG NDEBUG)};
    eval $code . "\n" . $tests;
    is $@, '';
}