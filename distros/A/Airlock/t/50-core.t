#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Airlock;
use AirlockTest;

my $alice = { id => 'alice' };

{
  package FixedCode;
  use Moo;
  extends 'Airlock::Code';
  our @QUEUE;
  sub user_code { shift @QUEUE }
}

subtest 'open' => sub {
  my $t      = AirlockTest->new;
  my $result = $t->airlock->open( client_id => 'cli', scope => ' read  write ', origin => { ip => '192.0.2.7', ua => 'curl/8' } );
  ok( $result->ok, 'ok' );
  my $data = $result->data;
  like( $data->{device_code}, qr/\A[0-9a-f]{64}\z/, 'device_code' );
  like( $data->{user_code}, qr/\A[B-DF-HJ-NP-TV-XZ]{4}-[B-DF-HJ-NP-TV-XZ]{4}\z/, 'user_code in display form' );
  is( $data->{verification_uri}, 'https://example.org/airlock', 'verification_uri' );
  is( $data->{verification_uri_complete}, 'https://example.org/airlock?user_code='.$data->{user_code}, 'verification_uri_complete' );
  is( $data->{expires_in}, 600, 'expires_in' );
  is( $data->{interval},   5,   'interval' );
  is_deeply( [ sort keys %$data ], [qw( device_code expires_in interval user_code verification_uri verification_uri_complete )], 'nothing else in the response' );

  my $row = $t->row( $data->{device_code} );
  ok( $row, 'the row is stored under the hash of the device code' );
  is( $t->memory->find( 'hash', $data->{device_code} ), undef, 'and not under the device code itself' );
  is_deeply( [ sort keys %$row ], [ sort Airlock->row_fields ], 'the row has exactly the documented fields' );
  is( $row->{scope}, 'read write', 'scope is normalized' );
  is( $row->{state}, 'pending', 'state' );
  is( $row->{origin_ip}, '192.0.2.7', 'origin ip' );
  is( $row->{origin_ua}, 'curl/8', 'origin ua' );
  is_deeply( $t->event_names, ['opened'], 'event' );
};

subtest 'open: verification_uri that already has a query' => sub {
  my $t    = AirlockTest->new( verification_uri => 'https://example.org/page?view=airlock' );
  my $data = $t->start;
  is( $data->{verification_uri_complete}, 'https://example.org/page?view=airlock&user_code='.$data->{user_code}, 'joined with &' );
};

subtest 'open: refusals' => sub {
  my $t = AirlockTest->new;
  is( $t->airlock->open( client_id => 'nope' )->status,                    'invalid_client', 'unknown client' );
  is( $t->airlock->open( client_id => undef )->status,                     'invalid_client', 'no client' );
  is( $t->airlock->open( client_id => '' )->status,                        'invalid_client', 'empty client' );
  is( $t->airlock->open( client_id => 'cli', scope => 'read root' )->status, 'invalid_scope', 'scope the client may not ask for' );
  is( $t->airlock->open( client_id => 'cli', scope => 're"ad' )->status,     'invalid_scope', 'scope with a forbidden character' );
  ok( $t->airlock->open( client_id => 'cli' )->ok,                         'no scope at all is fine' );
  ok( $t->airlock->open( client_id => 'open', scope => 'anything' )->ok,   'a client without a scope list may ask for any scope' );
  is_deeply( $t->airlock->open( client_id => 'nope' )->oauth, [ 400, { error => 'invalid_client' } ], 'oauth form of a refusal' );
};

subtest 'open: long origin values are clipped' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start( origin => { ip => '1' x 200, ua => 'u' x 1000 } );
  my $row  = $t->row( $data->{device_code} );
  is( length $row->{origin_ip}, 64,  'ip clipped' );
  is( length $row->{origin_ua}, 255, 'ua clipped' );

  my $bare = $t->row( $t->airlock->open( client_id => 'cli' )->data->{device_code} );
  is_deeply( [ sort keys %$bare ], [ sort Airlock->row_fields ], 'without an origin the row still has every field' );
  is( $bare->{origin_ip}, undef, 'and the origin is undef' );
};

subtest 'clients as a coderef' => sub {
  my $t = AirlockTest->new( clients => sub { $_[0] eq 'dyn' ? { name => 'Dynamic' } : undef } );
  ok( $t->airlock->open( client_id => 'dyn' )->ok, 'known to the coderef' );
  is( $t->airlock->open( client_id => 'cli' )->status, 'invalid_client', 'unknown to the coderef' );
  is( $t->airlock->client('dyn')->{name}, 'Dynamic', 'client() goes through the coderef' );
};

subtest 'inspect' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start( scope => 'read admin', origin => { ip => '192.0.2.7', ua => 'curl/8' } );
  $t->advance(42);
  my $view = $t->airlock->inspect( lc $data->{user_code} );
  is_deeply( $view, {
    user_code   => $data->{user_code},
    client_id   => 'cli',
    client_name => 'Test CLI',
    scopes      => [qw( read admin )],
    origin      => { ip => '192.0.2.7', ua => 'curl/8' },
    created     => 1_000_000,
    age         => 42,
    expires_in  => 558
  }, 'the view' );
  ok( !exists $view->{hash} && !exists $view->{device_code}, 'no secret in the view' );
  is( $t->row( $data->{device_code} )->{state}, 'pending', 'looking does not approve' );

  my @none = $t->airlock->inspect( 'ZZZZ-ZZZZ', subject => $alice );
  is( scalar @none, 0, 'unknown code: nothing, also in list context' );
  is( $t->airlock->inspect('not a code'), undef, 'malformed code' );
  is( $t->airlock->inspect(undef),        undef, 'undef' );
  is_deeply( $t->event_names, [qw( opened code_miss code_miss code_miss )], 'misses are reported' );
  is( $t->events->[1]{subject}, 'alice', 'with the subject when there is one' );
};

subtest 'approve, then redeem exactly once' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start( scope => 'read write' );

  my $pending = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' );
  is( $pending->status, 'authorization_pending', 'pending before approval' );
  is_deeply( $pending->oauth, [ 400, { error => 'authorization_pending' } ], 'oauth form' );

  $t->advance(10);
  my $approved = $t->airlock->approve( $data->{user_code}, subject => { id => 'alice', amr => ['pwd'], acr => '1', auth_time => 999_000 } );
  ok( $approved->ok, 'approved' );
  is( $approved->status, 'approved', 'status' );
  my $row = $t->row( $data->{device_code} );
  is( $row->{state}, 'approved', 'row state' );
  is( $t->airlock->inspect( $data->{user_code} ), undef, 'the code no longer inspects' );

  $t->advance(10);
  my $granted = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' );
  ok( $granted->ok, 'granted' );
  is( $granted->status, 'granted', 'status' );
  my $token = $granted->data;
  like( $token->{access_token}, qr/\A[0-9a-f]{64}\z/, 'opaque access token' );
  is( $token->{token_type}, 'Bearer', 'token type' );
  is( $token->{expires_in}, 3600, 'expires_in' );
  is( $token->{scope}, 'read write', 'scope' );
  is( $granted->oauth->[0], 200, 'oauth status' );

  $t->advance(10);
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'invalid_grant', 'second redeem is refused' );
  is_deeply( $t->event_names, [qw( opened approved code_miss redeemed )], 'events' );

  my $grant = $t->airlock->verify_token( $token->{access_token} );
  is_deeply( $grant, {
    subject   => 'alice',
    client_id => 'cli',
    scope     => 'read write',
    scopes    => [qw( read write )],
    amr       => ['pwd'],
    acr       => '1',
    auth_time => 999_000,
    expires   => 1_000_020 + 3600
  }, 'the token carries the grant' );
};

subtest 'deny' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  my $done = $t->airlock->deny( $data->{user_code}, subject => $alice );
  ok( $done->ok, 'denied' );
  is( $done->status, 'denied', 'status' );
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'access_denied', 'the client learns it' );
  is( $t->airlock->approve( $data->{user_code}, subject => $alice )->status, 'unknown_code', 'a denied request cannot be approved' );
  is( $t->airlock->deny( 'ZZZZ-ZZZZ', subject => $alice )->status, 'unknown_code', 'unknown code' );
};

subtest 'approve and deny need a subject' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  for my $bad ( undef, {}, { id => '' }, 'alice' ) {
    ok( !eval { $t->airlock->approve( $data->{user_code}, subject => $bad ); 1 }, 'approve croaks' );
    like( $@, qr/approve needs a subject with an id/, 'and says why' );
  }
  ok( !eval { $t->airlock->deny( $data->{user_code} ); 1 }, 'deny croaks' );
  is( $t->row( $data->{device_code} )->{state}, 'pending', 'and the request is untouched' );
};

subtest 'expiry' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  $t->advance(599);
  ok( $t->airlock->inspect( $data->{user_code} ), 'one second before expiry it still inspects' );
  $t->advance(1);
  is( $t->airlock->inspect( $data->{user_code} ), undef, 'at expiry it does not' );
  is( $t->airlock->approve( $data->{user_code}, subject => $alice )->status, 'unknown_code', 'nor approve' );
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'expired_token', 'the client gets expired_token' );
  is( $t->row( $data->{device_code} )->{state}, 'expired', 'row state' );

  my $late = $t->start;
  $t->airlock->approve( $late->{user_code}, subject => $alice );
  $t->advance(600);
  is( $t->airlock->redeem( device_code => $late->{device_code}, client_id => 'cli' )->status, 'expired_token', 'an approved request expires too' );
};

subtest 'slow_down' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  my $poll = sub { $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status };
  is( $poll->(), 'authorization_pending', 'first poll' );
  $t->advance(4);
  is( $poll->(), 'slow_down', 'four seconds later is too fast' );
  is( $t->row( $data->{device_code} )->{poll_interval}, 10, 'the interval grew by five' );
  $t->advance(9);
  is( $poll->(), 'slow_down', 'nine seconds later is too fast for the new interval' );
  is( $t->row( $data->{device_code} )->{poll_interval}, 15, 'and it grew again' );
  $t->advance(15);
  is( $poll->(), 'authorization_pending', 'waiting the full interval is fine' );

  $t->airlock->approve( $data->{user_code}, subject => $alice );
  $t->advance(1);
  is( $poll->(), 'slow_down', 'polling too fast after approval still slows down' );
  is( $t->row( $data->{device_code} )->{state}, 'approved', 'and does not burn the approval' );
  $t->advance(20);
  is( $poll->(), 'granted', 'the next patient poll gets the token' );
};

subtest 'redeem: refusals' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  is( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'open' )->status, 'invalid_grant', 'another client' );
  is( $t->airlock->redeem( device_code => 'f' x 64, client_id => 'cli' )->status, 'invalid_grant', 'unknown device code' );
  is( $t->airlock->redeem( client_id => 'cli' )->status, 'invalid_request', 'no device code' );
  is( $t->airlock->redeem( device_code => $data->{device_code} )->status, 'invalid_request', 'no client' );
  is( $t->airlock->redeem( device_code => '', client_id => 'cli' )->status, 'invalid_request', 'empty device code' );
  is( $t->row( $data->{device_code} )->{last_poll}, undef, 'a poll by the wrong client does not count as a poll' );
};

subtest 'user codes are reused only after they are released' => sub {
  @FixedCode::QUEUE = qw( BBBBBBBB BBBBBBBB CCCCCCCC BBBBBBBB );
  my $t     = AirlockTest->new( code => FixedCode->new );
  my $first = $t->start;
  is( $first->{user_code}, 'BBBB-BBBB', 'first request' );
  my $second = $t->start;
  is( $second->{user_code}, 'CCCC-CCCC', 'a taken code is skipped' );
  $t->advance(600);
  my $third = $t->start;
  is( $third->{user_code}, 'BBBB-BBBB', 'an expired code is taken over' );
  is( $t->row( $first->{device_code} )->{state}, 'expired', 'and its old request is marked expired' );
  is( $t->airlock->inspect('BBBB-BBBB')->{age}, 0, 'the code now belongs to the new request' );
};

subtest 'custom issuer' => sub {
  my @grants;
  my $t    = AirlockTest->new( issuer => sub { push @grants, $_[0]; { access_token => 'custom', token_type => 'Bearer' } } );
  my $data = $t->start( scope => 'read admin' );
  $t->airlock->approve( $data->{user_code}, subject => { id => 'alice', amr => [qw( pwd otp )], auth_time => 5 } );
  my $granted = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' );
  is_deeply( $granted->data, { access_token => 'custom', token_type => 'Bearer' }, 'the issuer decides the response' );
  is_deeply( $grants[0], {
    subject   => 'alice',
    client_id => 'cli',
    scope     => 'read admin',
    scopes    => [qw( read admin )],
    amr       => [qw( pwd otp )],
    acr       => undef,
    auth_time => 5
  }, 'and gets the grant' );
  is( $t->airlock->verify_token('custom'), undef, 'verify_token knows only opaque tokens' );

  my $broken = AirlockTest->new( issuer => sub { 'not a hash' } );
  my $start  = $broken->start;
  $broken->airlock->approve( $start->{user_code}, subject => $alice );
  ok( !eval { $broken->airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' ); 1 }, 'an issuer returning no hash croaks' );
  like( $@, qr/issuer must return a hash/, 'and says why' );
  is( $broken->row( $start->{device_code} )->{state}, 'redeemed', 'the request is used up, not handed out twice' );
};

subtest 'events carry no secrets' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  $t->airlock->inspect('ZZZZ-ZZZZ');
  $t->airlock->approve( $data->{user_code}, subject => $alice );
  my $token = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data->{access_token};
  my $plain = $data->{user_code} =~ s/-//r;
  for my $event ( @{ $t->events } ) {
    my $dump = join ' ', map { $_ // '' } map { ref $_ ? %$_ : $_ } %$event;
    unlike( $dump, qr/\Q$data->{device_code}\E|\Q$data->{user_code}\E|\Q$plain\E|\Q$token\E|ZZZZ/, $event->{event}.' is clean' );
  }
};

subtest 'construction' => sub {
  ok( !eval { Airlock->new( verification_uri => 'https://x' ); 1 }, 'clients is required' );
  ok( !eval { Airlock->new( clients => {} ); 1 }, 'verification_uri is required' );
  ok( !eval { Airlock->new( clients => {}, verification_uri => 'https://x', store => { insert => sub { }, find => sub { } } ); 1 }, 'a store without update is refused' );
  like( $@, qr/store needs a update sub/, 'and says what is missing' );
  ok( Airlock->new( clients => {}, verification_uri => 'https://x' ), 'the store has a default' );
};

subtest 'a double click on approve is not an error' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  ok( $t->airlock->approve( $data->{user_code}, subject => $alice )->ok, 'first click' );
  my $again = $t->airlock->approve( $data->{user_code}, subject => $alice );
  ok( $again->ok, 'second click by the same person succeeds too' );
  is( $again->status, 'approved', 'with the same status' );
  is( $t->airlock->approve( $data->{user_code}, subject => { id => 'mallory' } )->status, 'unknown_code', 'another person learns nothing' );
  is( $t->airlock->deny( $data->{user_code}, subject => $alice )->status, 'unknown_code', 'an approval cannot be turned into a denial' );
  is( $t->airlock->inspect( $data->{user_code} ), undef, 'and the code no longer inspects' );
  is( scalar( grep { $_ eq 'approved' } @{ $t->event_names } ), 1, 'one approved event, not two' );
  $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' );
  is( $t->airlock->approve( $data->{user_code}, subject => $alice )->status, 'unknown_code', 'after the token is out the code is gone for good' );
  is( $t->row( $data->{device_code} )->{user_code}, undef, 'and released' );
};

subtest 'two polls racing for one approval get one token' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  $t->airlock->approve( $data->{user_code}, subject => $alice );
  my $stale = $t->row( $data->{device_code} );

  # the second poller read the row before the first one redeemed it
  my $late = Airlock->new(
    clients          => { cli => {} },
    verification_uri => 'https://example.org/airlock',
    now              => sub { $t->clock },
    store            => { %{ $t->memory->as_subs }, find => sub { $_[0] eq 'hash' ? { %$stale } : $t->memory->find(@_) } }
  );
  ok( $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->ok, 'the first poll gets the token' );
  is( $late->redeem( device_code => $data->{device_code}, client_id => 'cli' )->status, 'invalid_grant', 'the second, working on what it read earlier, gets none' );
  is( scalar( grep { $_->{kind} eq 'token' } values %{ $t->memory->_rows } ), 1, 'exactly one token exists' );
};

subtest 'a subject id that does not fit' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  ok( !eval { $t->airlock->approve( $data->{user_code}, subject => { id => 'x' x 256 } ); 1 }, 'croaks' );
  like( $@, qr/subject id is longer than 255 characters/, 'and says why' );
  ok( $t->airlock->approve( $data->{user_code}, subject => { id => 'x' x 255 } )->ok, '255 characters fit' );
};

subtest 'the grant says only what the subject said' => sub {
  my $t    = AirlockTest->new;
  my $data = $t->start;
  $t->airlock->approve( $data->{user_code}, subject => { id => 'alice' } );
  my $token = $t->airlock->redeem( device_code => $data->{device_code}, client_id => 'cli' )->data->{access_token};
  my $grant = $t->airlock->verify_token($token);
  is( $grant->{auth_time}, undef, 'no auth_time is invented for a subject that brought none' );
  is_deeply( $grant->{amr}, [], 'nor an amr' );
};

subtest 'text outside ASCII where a secret is expected' => sub {
  my $t = AirlockTest->new;
  is( $t->airlock->redeem( device_code => "\x{263A}", client_id => 'cli' )->status, 'invalid_grant', 'a wide character as device code is just unknown' );
  is( $t->airlock->verify_token("\x{263A}\x{1F600}"), undef, 'and as token' );
  is( $t->airlock->revoke_token("\x{263A}"), 0, 'and for revoke' );
  is( $t->airlock->respond( 'POST', '/token', { grant_type => 'urn:ietf:params:oauth:grant-type:device_code', client_id => 'cli', device_code => "\x{263A}" }, {} )->[0], 400, 'through respond it is a 400, not an exception' );
};

subtest 'the opened event carries the clipped origin' => sub {
  my $t = AirlockTest->new;
  $t->start( origin => { ip => '1' x 200, ua => 'u' x 1000 } );
  is( length $t->events->[0]{origin}{ua}, 255, 'ua clipped in the event too' );
  is( length $t->events->[0]{origin}{ip}, 64,  'ip clipped in the event too' );
};

done_testing;
