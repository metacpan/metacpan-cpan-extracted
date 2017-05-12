use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use Data::Fake::Names;

subtest 'fake_name' => sub {
    for my $i ( 0 .. 5 ) {
        my $got = fake_name->();
        ok( defined($got), "name is defined" );
        is( scalar split( / /, $got ), 3, "name ($got) has three parts" );
    }
};

subtest 'fake_surname' => sub {
    for my $i ( 0 .. 5 ) {
        my $got = fake_surname->();
        ok( defined($got), "surname ($got) is defined" );
    }
};

subtest 'fake_first_name' => sub {
    for my $i ( 0 .. 5 ) {
        my $got = fake_first_name->();
        ok( defined($got), "first name ($got) is defined" );
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
