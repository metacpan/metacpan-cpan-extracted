use strict;
use warnings;
use Test::More;
use Path::Tiny;

use Command::Template qw< command_runner cr >;

my $sparring = path(__FILE__)->parent->child('sparring')->stringify;
my $cr = cr($sparring, qw{ <channel=stdout> <exit=0> [message=hello] });

my $r = $cr->run();
isa_ok $r, 'Command::Template::Runner::Record';

can_ok $r, qw<
   command
   command_as_string
   exit_code
   failure
   full_exit_code
   merged
   options
   signal
   stderr
   stdout
   success
   timed_out
   timeout
   >;

ok $r->success, 'command execution';
ok ! $r->failure, 'not a failure';
is $r->exit_code, 0, 'exit code';
is $r->signal, 0, 'signal';
is $r->full_exit_code, 0, 'full exit code';
is $r->stdout, 'hello', 'stdout';
is $r->stderr, '', 'stderr';
ok !$r->timed_out, 'no timeout';

for my $case (
   [
      'true',
      [ message => undef ],
      {
         exit_code => 0,
         signal => 0,
         stdout => '',
         stderr => '',
         success => [1],
         failure => [0],
      }
   ],
   [
      'false',
      [ exit => 1, message => undef ],
      {
         exit_code => 1,
         signal => 0,
         stdout => '',
         stderr => '',
         success => [0],
         failure => [1],
      }
   ],
   [
      'echo',
      [ message => "hello, world!\n" ],
      {
         exit_code => 0,
         signal => 0,
         stdout => "hello, world!\n",
         stderr => '',
      }
   ],
   [
      'cat -',
      [ message => '-', -stdin => "hello, world!\n42" ],
      {
         exit_code => 0,
         signal => 0,
         stdout => "hello, world!\n42",
         stderr => '',
      }
   ],
   [
      'killed',
      [ channel => 'stderr', message => 'goodbye', exit => -9 ],
      {
         exit_code => 0,
         signal => 9,
         stdout => '',
         stderr => "goodbye",
         success => [0],
         failure => [1],
      }
   ],
) {
   my ($prefix, $args, $expected) = @$case;
   my $r = $cr->run(@$args);
   while (my ($method, $exp) = each %$expected) {
      my $got = $r->$method;
      if (!ref $exp) {
         is $got, $exp, "$prefix: $method";
      }
      elsif ($exp->[0]) {
         ok $got, "$prefix: $method is true";
      }
      else {
         ok !$got, "$prefix: $method is false";
      }
   }
}

done_testing();
