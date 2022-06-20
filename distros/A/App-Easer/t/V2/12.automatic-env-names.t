use v5.24;
use experimental 'signatures';
use Test::More;
use Test::Output;
use Test::Exception;

use App::Easer V2 => 'run';

my $last;
sub cleanup { $last = undef }

sub check_last_run ($expected, $name) {
   is_deeply $last->{conf}, $expected->{conf}, "$name: configuration";
   is_deeply $last->{args}, $expected->{args}, "$name: residual arguments";
}

sub execute ($app) {
   my $conf = { $app->config_hash->%* };
   $conf->{foo} = '' if exists $conf->{foo} && !$conf->{foo};   # normalize
   $last = {conf => $conf, args => [$app->residual_args]};
   return 0;
} ## end sub execute

my $app = {
   name               => 'MAIN',
   environment_prefix => 'GALOOK_',
   help        => 'example command',
   description => 'An example command',
   options     => [
      {
         getopt      => 'foo|f!',
         environment => 1,
      },
      {
         getopt      => 'bar|b=s',
         environment => 1,
         default     => 'buzz',
      },
   ],
   execute => \&execute,
   default_child => '-self',
   force_auto_children => 1,
};

my @tests = (
   {
      name    => 'no input, just defaults',
      cmdline => [],
      env     => {},
      outcome => {conf => {bar => 'buzz'}, args => []},
   },
   {
      name    => 'env only for foo',
      cmdline => [],
      env     => {GALOOK_FOO => 1},
      outcome => {conf => {foo => 1, bar => 'buzz'}, args => []},
   },
   {
      name    => 'env only (foo & bar)',
      cmdline => [],
      env     => {GALOOK_FOO => 1, GALOOK_BAR => 'BuZz'},
      outcome => {conf => {foo => 1, bar => 'BuZz'}, args => []},
   },
   {
      name    => 'env + cmdline for foo',
      cmdline => [qw< --no-foo >],
      env     => {GALOOK_FOO => 1},
      outcome => {conf => {foo => '', bar => 'buzz'}, args => []},
   },
   {
      name    => 'env + cmdline',
      cmdline => [qw< --no-foo --bar BAAZ >],
      env     => {GALOOK_FOO => 1},
      outcome => {conf => {foo => '', bar => 'BAAZ'}, args => []},
   },
);

for my $test (@tests) {
   my ($cmdline, $env, $outcome, $name) =
     $test->@{qw< cmdline env outcome name >};
   delete @ENV{qw< GALOOK_FOO GALOOK_BAR >};
   $ENV{$_} = $env->{$_} for keys(($env // {})->%*);
   cleanup();
   run($app, MAIN => $cmdline->@*);
   check_last_run($outcome, $name);
} ## end for my $test (@tests)

stdout_like { run($app, MAIN => 'help') } qr{(?mxs:
   example \s+ command .*?
   An \s+ example \s+ command .*?
   --foo .*
   GALOOK_BAR .*?
   help .*?
   commands .*?
)}, 'output of help command';

stdout_like { run($app, MAIN => 'commands') } qr{(?mxs:
   help .*?
   commands .*?
)}, 'output of help command';

throws_ok { run($app, MAIN => 'inexistent') } qr{(?mxs:
   cannot .*? inexistent
)}, 'inexistent command generates complaint';

done_testing();
