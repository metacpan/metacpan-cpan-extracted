use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use Data::Fake::Text;

subtest 'fake_words' => sub {
    for my $i ( 0 .. 5 ) {
        my $got = fake_words($i)->();
        ok( defined($got), "word is defined" );
        is( scalar split( / /, $got ), $i, "word list of length $i" );
    }
};

subtest 'fake_sentences' => sub {
    for my $i ( 0 .. 5 ) {
        my $got = fake_sentences($i)->();
        ok( defined($got), "sentence is defined" );
        my $count =()= ( $got =~ /\./g );
        is( $count, $i, "sentence list of length $i" ) or diag $got;
    }
};

subtest 'fake_paragraphs' => sub {
    for my $i ( 0 .. 5 ) {
        my $got = fake_paragraphs($i)->();
        ok( defined($got), "paragraph is defined" );
        my $count = scalar split /^/, $got;
        is( $count, ( $i == 0 ? 0 : 2 * $i - 1 ), "paragraph list of length $i" )
          or diag $got;
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
