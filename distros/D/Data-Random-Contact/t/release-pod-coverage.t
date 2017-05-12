#!/usr/bin/perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::More;

use Test::Requires {
    'Test::Pod::Coverage' => '1.04',
};

my @modules = qw(
    Data::Random::Contact
    Data::Random::Contact::Country::US
    Data::Random::Contact::Language::EN
);


for my $module (@modules) {
    pod_coverage_ok(
        $module,
        "Pod coverage for $module",
    );
}

done_testing();
