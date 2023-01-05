use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $file_prefix = __FILE__ =~ s{\.t\z}{}rmxs;

my $app = {
   aliases     => ['MAIN'],
   help        => 'example command',
   description => 'An example command',
   options     => [
      {
         getopt => 'config=s',

         #default => "$file_prefix.json",
         help => 'path to configuration file',
      },
      {
         getopt      => 'foo|f!',
         environment => 'GALOOK_FOO',
      },
      {
         getopt      => 'bar|b=s',
         environment => 'GALOOK_BAR',
         default     => 'buzz',
      },
      {
         getopt      => 'kabooz|k',
      },
   ],
   'default-child' => 'bar',
   children        => [
      [
         Bar => { # the spec for this is here, implementation in module Bar
            aliases     => ['bar'],
            help        => 'sub-command bar',
            description => 'first-level sub-command bar',
            options     => [],
         }
      ],
      ['Foo'],
   ],
   sources =>
      [
         qw< +CmdLine +Environment +Parent=70 +Default=100 >, # defaults 
         '+JsonFileFromConfig=40',
      ],
};

subtest 'foo baz 1' => sub {
   test_run($app, ['foo', 'baz'], {}, 'baz')
     ->no_exceptions->result_is('BAZ')->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};

subtest 'foo baz 2' => sub {
   test_run(
      $app,
      [
         '--config' => "$file_prefix.1.json",
         qw<
           --foo foo
           --hey you
           baz
           --last 12
           FP >
      ],
      {},
      'baz'
   )->no_exceptions->result_is('BAZ')->conf_is(
      {
         config => "$file_prefix.1.json",
         foo    => 1,
         bar    => 'from_general_configuration_file',
         hey    => 'you',
         last   => 12
      }
   )->args_are(['FP'])->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};

subtest 'foo baz (tests conf_contains works)' => sub {
   test_run(
      $app,
      [
         '--config' => "$file_prefix.2.json",
         qw<
           --foo foo
           --hey you
           baz
           --last 12
           FP >
      ],
      {},
      'baz'
   )->no_exceptions->result_is('BAZ')->conf_contains(
      {
         foo  => 1,
         bar  => 'from_general_configuration_file',
         hey  => 'you',
         last => 12
      }
   )->args_are(['FP'])->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};


$app->{sources} = [
   qw< +CmdLine +Environment +Parent=70 +Default=100 >, # defaults 
   '+JsonFileFromConfig=30', # better than +Parent
   [ '+FromTrail=90', qw< defaults foo baz > ],
];

subtest 'foo baz (source from sub-hash)' => sub {
   test_run(
      $app,
      [
         '--config' => "$file_prefix.2.json",
         qw< foo --hey you baz FP >
      ],
      {},
      'baz'
   )->no_exceptions->result_is('BAZ')->conf_contains(
      {
         foo  => 0,
         bar  => 'from_general_configuration_file',
         hey  => 'you',
         last => 42
      }
   )->args_are(['FP'])->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};


$app->{sources} = [
   qw< +CmdLine +Environment +Parent=70 +Default=100 >, # defaults 
   '+JsonFileFromConfig=30', # better than +Parent
   [ '+FromTrail', {priority => 90}, qw< defaults foo baz > ],
];

subtest 'foo baz (source from sub-hash, .3.json)' => sub {
   test_run(
      $app,
      [
         '--config' => "$file_prefix.3.json",
         qw< foo --hey you baz FP >
      ],
      {},
      'baz'
   )->no_exceptions->result_is('BAZ')->conf_contains(
      {
         foo  => 0,
         bar  => 'from_substuff',
         hey  => 'you',
         last => 42
      }
   )->args_are(['FP'])->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};

$app->{sources} = [
   qw< +CmdLine +Environment +Default=100 +JsonFileFromConfig=30 >,
   '+Parent',
   [ '+FromTrail', qw< defaults foo baz > ],
];

subtest 'foo baz (source from sub-hash, not default)' => sub {
   test_run(
      $app,
      [
         '--config' => "$file_prefix.2.json",
         qw< foo --hey you baz FP >
      ],
      {},
      'baz'
   )->no_exceptions->result_is('BAZ')->conf_contains(
      {
         foo  => 0,
         bar  => 'from_general_configuration_file',
         hey  => 'you',
         last => 42
      }
   )->args_are(['FP'])->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};

done_testing();

package Foo;
use App::Easer::V2 -command => -spec => {
   help        => 'sub-command foo',
   description => 'first-level sub-command foo',
   aliases     => ['foo', 'Foo'],
   options     => [
      {
         getopt => 'hey|h=s',
      },
   ],
   default_child     => 'baz',
   children_prefixes => ['Foo::SubCmd'],
};

package Bar;
use App::Easer::V2 '-command';

sub execute ($self) {
   print {*STDOUT} 'bar on out';
   print {*STDERR} 'bar on err';
   return 'Bar';
}

package Foo::SubCmdBaz;
use App::Easer::V2 -command => -spec => {
   help        => 'sub-sub-command baz',
   description => 'second-level sub-command baz',
   aliases     => ['baz'],
   options     => [
      {
         getopt => 'last|l=i',
      },
   ],
};

sub execute ($self) {
   LocalTester::command_execute($self);
   print {*STDOUT} 'baz on out';
   print {*STDERR} 'baz on err';
   return 'BAZ';
} ## end sub execute ($self)

1;
