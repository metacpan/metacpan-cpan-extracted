#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Factor::TOTP;

# RFC 6238 appendix B, SHA-1 rows: 8 digits, secret "12345678901234567890"
my $rfc_secret = '12345678901234567890';
my %vector     = (
  59          => '94287082',
  1111111109  => '07081804',
  1111111111  => '14050471',
  1234567890  => '89005924',
  2000000000  => '69279037',
  20000000000 => '65353130'
);

my $clock = 0;
my %step;

sub totp {
  my ( %arg ) = @_;
  return Airlock::Factor::TOTP->new(
    secret      => sub { $_[0]{id} eq 'nobody' ? undef : $rfc_secret },
    last_step   => sub { $step{ $_[0]{id} } },
    accept_step => sub { $step{ $_[0]{id} } = $_[1] },
    now         => sub { $clock },
    %arg
  );
}

# what Airlock does with a factor: verify, and if that held, commit
sub check {
  my ( $factor, @arg ) = @_;
  return $factor->verify(@arg) && $factor->commit(@arg) ? 1 : 0;
}

subtest 'RFC 6238 test vectors' => sub {
  my $totp = totp( digits => 8 );
  is( $totp->code_at( $rfc_secret, int( $_ / 30 ) ), $vector{$_}, 'time '.$_ ) for sort { $a <=> $b } keys %vector;
};

subtest 'defaults' => sub {
  my $totp = totp();
  is( $totp->name, 'totp', 'name' );
  is( $totp->amr,  'otp',  'amr' );
  is( $totp->needs_proof, 1, 'needs a proof' );
  is( length $totp->code_at( $rfc_secret, 1 ), 6, 'six digits' );
};

subtest 'verify' => sub {
  my $totp  = totp();
  my $alice = { id => 'alice' };
  $clock = 1_700_000_000;
  my $now_step = int( $clock / 30 );
  my $good     = $totp->code_at( $rfc_secret, $now_step );

  is( check( $totp, $alice, 'abcdef' ),  0, 'letters' );
  is( check( $totp, $alice, '12345' ),   0, 'too short' );
  is( check( $totp, $alice, '1234567' ), 0, 'too long' );
  is( check( $totp, $alice, undef ),     0, 'undef' );
  is( check( $totp, $alice, '' ),        0, 'empty' );
  my $wrong = sprintf '%06d', ( $good + 1 ) % 1_000_000;
  is( check( $totp, $alice, $wrong ), 0, 'wrong code' );
  is( $step{alice}, undef, 'a wrong code records no step' );

  is( check( $totp, $alice, substr( $good, 0, 3 ).' '.substr( $good, 3 ) ), 1, 'right code, typed with a space' );
  is( $step{alice}, $now_step, 'the accepted step is recorded' );
  is( check( $totp, $alice, $good ), 0, 'the same code a second time is refused' );
};

subtest 'window and replay' => sub {
  my $totp = totp();
  my $bob  = { id => 'bob' };
  $clock = 1_700_000_000;
  my $now_step = int( $clock / 30 );

  is( check( $totp, $bob, $totp->code_at( $rfc_secret, $now_step - 2 ) ), 0, 'two steps back is outside the window' );
  is( check( $totp, $bob, $totp->code_at( $rfc_secret, $now_step + 2 ) ), 0, 'two steps ahead is outside the window' );
  is( check( $totp, $bob, $totp->code_at( $rfc_secret, $now_step + 1 ) ), 1, 'one step ahead is accepted' );
  is( check( $totp, $bob, $totp->code_at( $rfc_secret, $now_step ) ),     0, 'an older step than the accepted one is refused' );
  is( check( $totp, $bob, $totp->code_at( $rfc_secret, $now_step - 1 ) ), 0, 'and so is the one before' );

  my $strict = totp( window => 0 );
  my $carol  = { id => 'carol' };
  is( check( $strict, $carol, $strict->code_at( $rfc_secret, $now_step - 1 ) ), 0, 'window 0 refuses the previous step' );
  is( check( $strict, $carol, $strict->code_at( $rfc_secret, $now_step ) ),     1, 'window 0 accepts the current step' );
};

subtest 'verify looks, commit uses the code up' => sub {
  my $totp = totp();
  my $dave = { id => 'dave' };
  $clock = 1_700_000_000;
  my $good = $totp->code_at( $rfc_secret, int( $clock / 30 ) );
  is( $totp->verify( $dave, $good ), 1, 'verify holds' );
  is( $step{dave}, undef, 'and records nothing' );
  is( $totp->verify( $dave, $good ), 1, 'so it holds again' );
  is( $totp->commit( $dave, $good ), 1, 'commit records the step' );
  is( $step{dave}, int( $clock / 30 ), 'recorded' );
  is( $totp->verify( $dave, $good ), 0, 'after commit the code is used up' );
  is( $totp->commit( $dave, $good ), 0, 'and cannot be committed again' );
  is( $totp->commit( $dave, '000000' ) + $totp->commit( $dave, undef ), 0, 'commit of a wrong or missing code is false' );

  my $lost = totp( accept_step => sub { 0 } );
  is( $lost->verify( { id => 'erin' }, $good ), 1, 'a host whose store refuses the step: verify holds' );
  is( $lost->commit( { id => 'erin' }, $good ), 0, 'but commit reports the refusal' );
};

subtest 'not enrolled' => sub {
  my $totp = totp();
  is( $totp->available_for( { id => 'nobody' } ), 0, 'not available' );
  is( $totp->available_for( { id => 'alice' } ),  1, 'available' );
  is( check( $totp, { id => 'nobody' }, '123456' ), 0, 'verify is false, not an exception' );

  my $empty = totp( secret => sub { '' } );
  is( $empty->available_for( { id => 'x' } ), 0, 'an empty secret is not an enrolment' );
  is( $empty->verify( { id => 'x' }, $empty->code_at( '', int( $clock / 30 ) ) ), 0, 'and the code for the empty key is refused' );
};

subtest 'enrolment helpers' => sub {
  my $totp = totp();
  is( length $totp->generate_secret, 20, 'twenty bytes' );
  isnt( $totp->generate_secret, $totp->generate_secret, 'random' );
  is( $totp->base32(''),       '',                 'RFC 4648: empty' );
  is( $totp->base32('f'),      'MY',               'RFC 4648: f' );
  is( $totp->base32('fo'),     'MZXQ',             'RFC 4648: fo' );
  is( $totp->base32('foo'),    'MZXW6',            'RFC 4648: foo' );
  is( $totp->base32('foob'),   'MZXW6YQ',          'RFC 4648: foob' );
  is( $totp->base32('fooba'),  'MZXW6YTB',         'RFC 4648: fooba' );
  is( $totp->base32('foobar'), 'MZXW6YTBOI',       'RFC 4648: foobar' );
  is(
    $totp->otpauth_uri( secret => $rfc_secret, account => 'getty@example.org', issuer => 'Mother Ship' ),
    'otpauth://totp/Mother%20Ship:getty%40example.org?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Mother%20Ship&algorithm=SHA1&digits=6&period=30',
    'otpauth URI'
  );
  ok( !eval { $totp->otpauth_uri( secret => $rfc_secret, account => 'a' ); 1 }, 'missing issuer croaks' );
  like( $@, qr/otpauth_uri needs issuer/, 'and says what is missing' );
};

subtest 'construction' => sub {
  ok( !eval { Airlock::Factor::TOTP->new( secret => sub { }, last_step => sub { } ); 1 }, 'accept_step is required' );
  ok( !eval { Airlock::Factor::TOTP->new( secret => sub { }, accept_step => sub { } ); 1 }, 'last_step is required' );
};

done_testing;
