use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

use Data::Fake::Company;

subtest 'fake_title' => sub {
    for my $i ( 0 .. 5 ) {
        my $got = fake_title->();
        ok( defined($got), "title ($got) is defined" );
    }
};

subtest 'fake_company' => sub {
    for my $i ( 0 .. 5 ) {
        my $got = fake_company->();
        ok( defined($got), "company ($got) is defined" );
    }
};

done_testing;
#
# This file is part of Data-Fake
#
# This software is Copyright (c) 2015 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: ts=4 sts=4 sw=4 et tw=75:
