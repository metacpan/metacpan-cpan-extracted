#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Code;

my $code = Airlock::Code->new;

subtest 'user_code' => sub {
  my %seen;
  for ( 1 .. 500 ) {
    my $user_code = $code->user_code;
    like( $user_code, qr/\A[BCDFGHJKLMNPQRSTVWXZ]{8}\z/, 'shape' ) or last;
    $seen{$user_code}++;
  }
  is( scalar keys %seen, 500, 'no repeats in 500 draws' );
  my %letters = map { $_ => 1 } map { split // } keys %seen;
  is( scalar keys %letters, 20, 'every letter of the alphabet is drawn' );
};

subtest 'custom alphabet and length' => sub {
  my $short = Airlock::Code->new( alphabet => 'AB', user_code_length => 3 );
  like( $short->user_code, qr/\A[AB]{3}\z/, 'honours alphabet and length' );
  is( $short->normalize('a-b-a'), 'ABA', 'normalizes against its own alphabet' );
  is( $short->normalize('abc'), undef, 'rejects a foreign letter' );
};

subtest 'secret and hash' => sub {
  my $secret = $code->secret;
  like( $secret, qr/\A[0-9a-f]{64}\z/, '32 bytes as hex' );
  isnt( $code->secret, $secret, 'secrets differ' );
  is(
    $code->hash('abc'),
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    'SHA-256 of abc'
  );
};

subtest 'normalize' => sub {
  is( $code->normalize('BCDF-GHJK'),     'BCDFGHJK', 'dash removed' );
  is( $code->normalize(' bcdf ghjk '),   'BCDFGHJK', 'case and spaces' );
  is( $code->normalize('BCDF_GHJK'),     'BCDFGHJK', 'underscore' );
  is( $code->normalize('BCDF.GHJK'),     'BCDFGHJK', 'dot' );
  is( $code->normalize('BCDFGHJ'),       undef,      'too short' );
  is( $code->normalize('BCDFGHJKL'),     undef,      'too long' );
  is( $code->normalize('BCDFGHJA'),      undef,      'vowel is not in the alphabet' );
  is( $code->normalize('BCDF1HJK'),      undef,      'digit' );
  is( $code->normalize(''),              undef,      'empty' );
  is( $code->normalize(undef),           undef,      'undef' );
  is( $code->normalize("BCDFGHJK\n"),    'BCDFGHJK', 'trailing newline from a pasted code' );
};

subtest 'display' => sub {
  is( $code->display('BCDFGHJK'), 'BCDF-GHJK', 'groups of four' );
  is( $code->normalize( $code->display( $code->user_code ) ) =~ /\A\w{8}\z/ ? 1 : 0, 1, 'display round-trips through normalize' );
};

subtest 'equals' => sub {
  is( $code->equals( 'abc', 'abc' ), 1, 'equal' );
  is( $code->equals( 'abc', 'abd' ), 0, 'differs' );
  is( $code->equals( 'abc', 'abcd' ), 0, 'different length' );
  is( $code->equals( undef, 'abc' ), 0, 'undef left' );
  is( $code->equals( 'abc', undef ), 0, 'undef right' );
  is( $code->equals( '', '' ), 1, 'two empty strings' );
};

subtest 'normalize: what people and programs really send' => sub {
  is( $code->normalize("\x{c4}\x{d6}\x{dc}\x{df}BCDF"), undef, 'non-ASCII letters' );
  is( $code->normalize("\x{ff22}\x{ff23}\x{ff24}\x{ff26}\x{ff27}\x{ff28}\x{ff2a}\x{ff2b}"), undef, 'fullwidth letters are not the alphabet' );
  is( $code->normalize( 'B' x 1_000_000 ), undef, 'a megabyte of input' );
  is( $code->normalize( { a => 1 } ), undef, 'a reference' );
  is( $code->normalize("BCDF\0GHJK"), undef, 'a NUL byte' );
};

done_testing;
