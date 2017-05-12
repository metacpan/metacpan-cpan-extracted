#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Log::Any::Adapter;
use 5.010;

use AI::CleverbotIO;

plan skip_all => 'no CLEVERBOT_API_USER/CLEVERBOT_API_KEY pair set'
  unless exists($ENV{CLEVERBOT_API_USER})
  && exists($ENV{CLEVERBOT_API_KEY});

Log::Any::Adapter->set('Stderr') if $ENV{CLEVERBOT_STDERR};

my $cleverbot;
lives_ok {
   $cleverbot = AI::CleverbotIO->new(
      key  => $ENV{CLEVERBOT_API_KEY},
      nick => $ENV{CLEVERBOT_NICK} // "AI::CleverbotIO Tester",
      user => $ENV{CLEVERBOT_API_USER},
   );
} ## end lives_ok
'AI::CleverbotIO instantiation lives';

isa_ok $cleverbot, 'AI::CleverbotIO';

my $data;
lives_ok {
   $data = $cleverbot->create();
}
'create() lives';

like $data->{status}, qr{(?mxs:
      \A
      (?:
           success
         | Error:\ reference\ name\ already\ exists
      )
      \z
   )}, 'create() outcome';

diag 'real nick: ' . $cleverbot->nick;

my $answer;
lives_ok {
   $answer = $cleverbot->ask('Hi, I am ' . $cleverbot->nick)->{response};
}
'ask() lives';
like $answer, qr{(?imxs:[a-z])}, 'response has at least... one letter';
diag "received answer: $answer";

done_testing();
