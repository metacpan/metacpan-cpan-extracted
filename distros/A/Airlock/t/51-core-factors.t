#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Airlock::Factor::Callback;
use Airlock::Factor::TOTP;
use Airlock::Factor::Upstream;
use AirlockTest;

my @pin_calls;

sub fixture {
  my ( %arg ) = @_;
  @pin_calls = ();
  my $t;
  $t = AirlockTest->new(
    policy  => { step_up => { admin => ['pin'] } },
    factors => [
      Airlock::Factor::Callback->new(
        name      => 'pin',
        amr       => 'pin',
        verify    => sub { push @pin_calls, $_[1]; $_[1] eq '4711' },
        available => sub { $_[0]{id} ne 'nopin' }
      ),
      Airlock::Factor::Upstream->new( max_age => 300, now => sub { $t->clock } )
    ],
    %arg
  );
  return $t;
}

my $alice = { id => 'alice', amr => ['pwd'] };

subtest 'a scope without step-up needs no factor' => sub {
  my $t    = fixture();
  my $data = $t->start( scope => 'read' );
  is_deeply( $t->airlock->requirements( $t->airlock->inspect( $data->{user_code} ), $alice ), [], 'requirements' );
  ok( $t->airlock->approve( $data->{user_code}, subject => $alice )->ok, 'approved without proof' );
  is( scalar @pin_calls, 0, 'the factor was never asked' );
};

subtest 'a step-up scope asks for the factor' => sub {
  my $t    = fixture();
  my $data = $t->start( scope => 'read admin' );
  is_deeply( $t->airlock->requirements( $t->airlock->inspect( $data->{user_code} ), $alice ), ['pin'], 'requirements' );

  my $asked = $t->airlock->approve( $data->{user_code}, subject => $alice );
  is( $asked->status, 'factor_required', 'without proof: factor_required' );
  is_deeply( $asked->missing, ['pin'], 'and names the factor' );
  is( scalar @pin_calls, 0, 'a missing proof is not a verification' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 0, 'nor a failure' );

  my $wrong = $t->airlock->approve( $data->{user_code}, subject => $alice, proofs => { pin => '1234' } );
  is( $wrong->status, 'factor_failed', 'wrong proof: factor_failed' );
  is_deeply( $wrong->missing, ['pin'], 'names the factor' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 1, 'counted' );
  is( $t->row( $data->{device_code} )->{state}, 'pending', 'still pending' );

  my $right = $t->airlock->approve( $data->{user_code}, subject => $alice, proofs => { pin => '4711' } );
  ok( $right->ok, 'right proof: approved' );
  my $token = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data->{access_token};
  is_deeply( $t->airlock->verify_token($token)->{amr}, [qw( pwd pin )], 'the grant carries the factor amr after the subject amr' );
  is_deeply( $t->event_names, [qw( opened factor_failed approved redeemed )], 'events' );
  is( $t->events->[1]{factor}, 'pin', 'the failure event names the factor' );
  ok( !grep( { /4711|1234/ } map { values %$_ } @{ $t->events } ), 'and no event carries a proof' );
};

subtest 'too many failures deny the request' => sub {
  my $t    = fixture( max_factor_failures => 3 );
  my $data = $t->start( scope => 'admin' );
  my $try  = sub { $t->airlock->approve( $data->{user_code}, subject => $alice, proofs => { pin => $_[0] } )->status };
  is( $try->('0001'), 'factor_failed',     'first' );
  is( $try->('0002'), 'factor_failed',     'second' );
  is( $try->('0003'), 'too_many_failures', 'third is final' );
  is( $t->row( $data->{device_code} )->{state}, 'denied', 'the request is denied' );
  is( $try->('4711'), 'unknown_code', 'the right proof comes too late' );
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'access_denied', 'the client is told' );
};

subtest 'a factor the subject does not have' => sub {
  my $t      = fixture();
  my $data   = $t->start( scope => 'admin' );
  my $result = $t->airlock->approve( $data->{user_code}, subject => { id => 'nopin' }, proofs => { pin => '4711' } );
  is( $result->status, 'factor_unavailable', 'factor_unavailable' );
  is_deeply( $result->missing, ['pin'], 'names the factor' );
  is( scalar @pin_calls, 0, 'and it is not verified' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 0, 'nor counted as a failure' );
};

subtest 'upstream factor: no proof, no failure count' => sub {
  my $t    = fixture( policy => { always => ['upstream'] } );
  my $data = $t->start;
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', amr => ['pwd'], auth_time => $t->clock } )->status,
    'reauth_required', 'weak login: reauth_required' );
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', amr => ['otp'], auth_time => $t->clock - 301 } )->status,
    'reauth_required', 'old login: reauth_required' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 0, 'neither counts as a failure' );
  ok( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', amr => [qw( pwd otp )], auth_time => $t->clock - 10 } )->ok, 'strong, fresh login: approved' );
  my $token = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data->{access_token};
  is_deeply( $t->airlock->verify_token($token)->{amr}, [qw( pwd otp mfa )], 'amr without duplicates' );
};

subtest 'two factors: upstream and pin' => sub {
  my $t      = fixture( policy => { always => ['upstream'], step_up => { admin => ['pin'] } } );
  my $data   = $t->start( scope => 'admin' );
  my $strong = { id => 'a', amr => ['otp'], auth_time => $t->clock };
  is_deeply( $t->airlock->requirements( $t->airlock->inspect( $data->{user_code} ), $strong ), [qw( upstream pin )], 'requirements' );
  my $asked = $t->airlock->approve( $data->{user_code}, subject => $strong );
  is( $asked->status, 'factor_required', 'upstream holds, pin is still missing' );
  is_deeply( $asked->missing, ['pin'], 'only the pin is asked for' );
  ok( $t->airlock->approve( $data->{user_code}, subject => $strong, proofs => { pin => '4711' } )->ok, 'both: approved' );
};

subtest 'max_auth_age refuses any approval from an old login' => sub {
  my $t    = fixture( policy => { max_auth_age => 60 } );
  my $data = $t->start;
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', auth_time => $t->clock - 61 } )->status, 'reauth_required', 'too old' );
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'a' } )->status, 'reauth_required', 'no auth_time' );
  ok( $t->airlock->approve( $data->{user_code}, subject => { id => 'a', auth_time => $t->clock - 60 } )->ok, 'fresh enough' );
};

subtest 'a policy naming an unknown factor is a programming error' => sub {
  my $t    = fixture( policy => { always => ['fingerprint'] } );
  my $data = $t->start;
  ok( !eval { $t->airlock->approve( $data->{user_code}, subject => $alice ); 1 }, 'croaks' );
  like( $@, qr/unknown factor fingerprint/, 'and names it' );
};

subtest 'an empty proof is a missing proof, not a wrong one' => sub {
  my $t    = fixture( max_factor_failures => 2 );
  my $data = $t->start( scope => 'admin' );
  for ( 1 .. 3 ) {
    my $result = $t->airlock->approve( $data->{user_code}, subject => $alice, proofs => { pin => '' } );
    is( $result->status, 'factor_required', 'a blank field asks again' );
  }
  is( $t->row( $data->{device_code} )->{factor_failures}, 0, 'and burns no attempt' );
  is( scalar @pin_calls, 0, 'the factor is never asked' );
};

subtest 'wrong guesses that all read the row before any of them wrote' => sub {
  my $t     = fixture( max_factor_failures => 3 );
  my $data  = $t->start( scope => 'admin' );
  my $stale = $t->memory->find( 'user_code', $data->{user_code} =~ s/-//r );

  # every guess sees the row as it was at the start: zero failures
  my $racing = Airlock->new(
    clients          => { cli => { scopes => ['admin'] } },
    verification_uri => 'https://example.org/airlock',
    now              => sub { $t->clock },
    policy           => $t->airlock->policy,
    factors          => $t->airlock->factors,
    max_factor_failures => 3,
    store            => { %{ $t->memory->as_subs }, find => sub { $_[0] eq 'user_code' ? { %$stale } : $t->memory->find(@_) } }
  );
  my @status = map { $racing->approve( $data->{user_code}, subject => $alice, proofs => { pin => '000'.$_ } )->status } 1 .. 3;
  is_deeply( \@status, [qw( factor_failed factor_failed too_many_failures )], 'each one counts, the third is final' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 3, 'three failures are in the store' );
  is( $t->row( $data->{device_code} )->{state}, 'denied', 'and the request is denied' );
};

subtest 'TOTP through approve' => sub {
  my ( %secret, %step );
  %secret = ( alice => '12345678901234567890' );
  my $t;
  my $totp = Airlock::Factor::TOTP->new(
    secret      => sub { $secret{ $_[0]{id} } },
    last_step   => sub { $step{ $_[0]{id} } },
    accept_step => sub { $step{ $_[0]{id} } = $_[1] },
    now         => sub { $t->clock }
  );
  $t = fixture( policy => { step_up => { admin => [qw( totp pin )], write => ['totp'] } }, factors => [ $totp, fixture()->airlock->factor('pin') ] );
  my $code = sub { $totp->code_at( $secret{alice}, int( $t->clock / 30 ) ) };

  my $data = $t->start( scope => 'admin' );
  my $half = $t->airlock->approve( $data->{user_code}, subject => $alice, proofs => { totp => $code->(), pin => '1234' } );
  is( $half->status, 'factor_failed', 'right TOTP, wrong PIN' );
  is_deeply( $half->missing, ['pin'], 'the PIN is blamed' );
  is( $step{alice}, undef, 'and the TOTP code is not used up' );
  ok( $t->airlock->approve( $data->{user_code}, subject => $alice, proofs => { totp => $code->(), pin => '4711' } )->ok, 'the same TOTP code with the right PIN approves' );
  is( $step{alice}, int( $t->clock / 30 ), 'now it is used up' );
  is( $t->row( $data->{device_code} )->{factor_failures}, 1, 'one failure counted, not two' );

  my $second = $t->start( scope => 'write' );
  my $replay = $t->airlock->approve( $second->{user_code}, subject => $alice, proofs => { totp => $code->() } );
  is( $replay->status, 'factor_failed', 'the used code does not approve a second request' );
  $t->advance(30);
  ok( $t->airlock->approve( $second->{user_code}, subject => $alice, proofs => { totp => $code->() } )->ok, 'the next code does' );

  my $third = $t->start( scope => 'write' );
  is( $t->airlock->approve( $third->{user_code}, subject => { id => 'bob' }, proofs => { totp => '123456' } )->status, 'factor_unavailable', 'someone without a secret cannot use the factor' );
};

done_testing;
