#!/usr/bin/perl

use strict;
use warnings;

use constant COVERTEST => ( $ENV{HARNESS_PERL_SWITCHES} || "" ) =~ /Devel::Cover/;

BEGIN {
    use Config;
    use if !COVERTEST && $Config{useithreads}, 'threads';
    use if !COVERTEST && $Config{useithreads}, 'threads::shared';
}

use Config;
use Test::More tests => 45;
use lib 't/lib';
use CleanEnv;

use BSON;

my $o1 = BSON::ObjectId->new();
ok( $o1->is_legal($o1), 'oid generate' );

my $o2 = BSON::ObjectId->new( "$o1" );
is( $o1, $o2, 'oid from string' );

my $o3 = BSON::ObjectId->new('4e2766e6e1b8325d02000028');
is_deeply(
    [ unpack( 'C*', $o3->value ) ],
    [ 0x4e, 0x27, 0x66, 0xe6, 0xe1, 0xb8, 0x32, 0x5d, 0x02, 0x00, 0x00, 0x28 ],
    'oid value'
);

my $o4 = BSON::ObjectId->new( $o3->value );
is( "$o4", "$o3", 'value' );

my $try = eval { my $o5 = BSON::ObjectId->new('abcde'); 1 };
isnt( $try, 1, 'Dies 1' );

$try = eval { my $o5 = BSON::ObjectId->new('12345678901234567890123$'); 1 };
isnt( $try, 1, 'Dies 2' );


SKIP: {
    skip "No threads during coverage testing", 39 if COVERTEST;
    skip "No threads", 39 unless $Config{useithreads};
    skip "Threads not supported before 5.8.5", 39 if $] lt "5.008005";
    my @threads = map {
        threads->create(
            sub {
                [ map { BSON::ObjectId->new } 0 .. 3 ];
            }
        );
    } 0 .. 9;

    my @oids = map { @{ $_->join } } @threads;

    my @inc =
      sort { $a <=> $b }
      map { hex }
      map { substr $_, 18 } @oids; # just counters

    my $prev = shift @inc;
    while (@inc) {
        my $next = shift @inc;
        ok( $next - $prev == 1, "thread counter sequential ($next)" );
        $prev = $next;
    }
};

