#!/usr/bin/perl

use strict;
use warnings;

my $RUNS = $ENV{AUTOMATED_TESTING} || $ENV{AUTHOR_TESTING} ? 500 : 50;    # Number of random documents to create
my $DEEP = 2;      # Max depth level of embedded hashes
my $KEYS = 20;     # Number of keys per hash

use Config;
use Test::More 0.86;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

plan tests => $RUNS;

use BSON qw/encode decode/;

srand;

my $level = 0;
my @codex = (
    \&int32, \&doub, \&str, \&hash, \&arr,  \&dt,   \&bin,
    \&re,    \&oid,   \&min,  \&max, \&ts,   \&null, \&bool, \&code
);

# If Perl is 64-bit then add 64 integers
if ( $Config{'use64bitint'} ) {
    push @codex, \&int64;
}

for my $count ( 1 .. $RUNS ) {
    my $ar   = hash($KEYS);
    my $bson = eval { encode($ar) };
    if ( my $err = $@ ) {
        chomp $err;
        fail("Encoding error: $err");
    }
    else {
        my $ar1  = decode($bson);
        is_deeply( $ar, $ar1 ) or diag explain $ar1;
    }
}

sub int32 {
    return int( rand( 2**31-1 ) ) * ( int( rand(2) ) ? -1 : 1 );
}

sub int64 {
    return int( rand( 2**63-1 ) ) * ( int( rand(2) ) ? -1 : 1 );
}

sub doub {
    return rand() * 2**63-1 * ( int( rand(2) ) ? -1 : 1 );
}

sub str {
    my $len = int( rand(255) ) + 1;
    my @a   = map {
        ( 'A' .. 'Z', 'a' .. 'z', ' ', '0' .. '9' )[ rand( 26 + 26 + 11 ) ]
    } 1 .. $len;
    return BSON::String->new( join( '', @a ) );
}

sub dt  { BSON::Time->new( abs( int32() ) ) }
sub bin { BSON::Bytes->new( str(), int( rand(5) ) ) }
sub re  { BSON::Regex->new( pattern => '\w\a+\s$', flags => 'i') }

sub oid { BSON::ObjectId->new }
sub min { BSON::MinKey->new }
sub max { BSON::MaxKey->new }

sub ts { BSON::Timestamp->new( abs( int32() ), abs( int32() ) ) }

sub null { undef }
sub bool { BSON::Bool->new( int( rand(2) ) ) }
sub code { BSON::Code->new( str(), hash() ) }

sub rnd {
    my $sub = $codex[ int( rand(@codex) ) ];
    return $sub->($level);
}

sub arr {
    return [] if $level > $DEEP;
    $level++;
    my $len = int( rand(20) ) + 1;
    my @a   = ();
    for ( 1 .. $len ) {
        push @a, rnd( $level + 1 );
    }
    $level--;
    return \@a;
}

sub hash {
    return {} if $level > $DEEP;
    $level++;
    my $hash = {};
    for my $idx ( 1 .. $KEYS ) {
        $hash->{"key_$idx"} = rnd( $level + 1 );
    }
    $level--;
    return $hash;
}

