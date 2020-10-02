use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use Data::Fake::Text;

subtest 'fake_words' => sub {
    for my $i ( undef, 0 .. 5 ) {
        my @args = defined $i ? $i : ();
        my $got = fake_words(@args)->();
        ok( defined($got), "word is defined" );

        my $n = defined $i ? $i : 1;
        my $msg = "word list of length $n";
        $msg .= " (default)" unless defined $i;

        is( scalar split( / /, $got ), $n, $msg );
    }
};

subtest 'fake_sentences' => sub {
    for my $i ( undef, 0 .. 5 ) {
        my @args = defined $i ? $i : ();
        my $got = fake_sentences(@args)->();
        ok( defined($got), "sentence is defined" );

        my $n = defined $i ? $i : 1;
        my $msg = "sentence list of length $n";
        $msg .= " (default)" unless defined $i;

        my $count =()= ( $got =~ /\./g );
        is( $count, $n, $msg ) or diag $got;
    }
};

subtest 'fake_paragraphs' => sub {
    for my $i ( undef, 0 .. 5 ) {
        my @args = defined $i ? $i : ();
        my $got = fake_paragraphs(@args)->();
        ok( defined($got), "paragraph is defined" );

        my $n = defined $i ? ( $i == 0 ? 0 : 2 * $i - 1 ) : 1;
        my $msg = "paragraph list of length $n";
        $msg .= " (default)" unless defined $i;

        my $count = scalar split /^/, $got;
        is( $count, $n, $msg ) or diag $got;
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
