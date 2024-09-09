use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;
use JSON::PP ();

my $file_prefix = __FILE__ =~ s{\.t\z}{}rmxs;

my $app = {
   name        => 'MAIN',
   help        => 'example command',
   description => 'An example command',
   options     => [
      { getopt => 'config=s',   transmit => 1,                    },
      { getopt => 'fcmd1=s',    transmit => 1, default => 'this!' },
      { getopt => 'fcmd2=s',    transmit => 1, default => 'this!' },
      { getopt => 'fcmd3=s',    transmit => 1, default => 'this!' },
      { getopt => 'fenv=s',     transmit => 1, default => 'this!', environment => 'FENV' },
      { getopt => 'ffile=s',    transmit => 1, default => 'this!' },
      { getopt => 'fdefault=s', transmit => 1, default => 'this!' },
   ],
   children => [
      {
         name => 'foo',
         options => [ '+parent' ],
         default_child => '-self',
         fallback_to => '-default',
         children => [
            {
               default => '-self',
               fallback_to => '-default',
               name => 'bar',
               options => [ '+parent' ],
               commit => sub ($s) { logit('bar commit') },
               execute => sub ($s) { logit('bar execute') },
               commit  => logger('commit'),
               execute => logger('execute'),
            }
         ],
         commit  => logger('commit'),
         execute => logger('execute'),
      },
   ],
   commit  => logger('commit'),
   execute => logger('execute'),
   default_child => '-self',
   fallback_to => '-default',
   sources => {
      current => [ '+CmdLine', '+Parent' ],
      final   => [
         qw<
            +LastCmdLine=10
            +Parent=20
            +FinalEnvironment=30
            +FinalDefault=50
            +JsonFileFromConfig=40
         >
      ]
   },
};

# test_run($app, $cmdline, $env, $expected_final_command_name);
test_run($app, [ qw< > ], { qw< > }, 'MAIN')
   ->no_exceptions('simple invocation, no args at all')
   ->name_is('MAIN')
   ->conf_is(
      {
         fcmd1 => 'this!',
         fcmd2 => 'this!',
         fcmd3 => 'this!',
         fenv  => 'this!',
         ffile => 'this!',
         fdefault => 'this!',
      }
   );

test_run($app, [ qw< --fcmd1 FOO > ], { qw< FENV AHOY > }, 'MAIN')
   ->no_exceptions('upper level command, one arg, env set')
   ->name_is('MAIN')
   ->conf_is(
      {
         fcmd1 => 'FOO',
         fcmd2 => 'this!',
         fcmd3 => 'this!',
         fenv  => 'AHOY',
         ffile => 'this!',
         fdefault => 'this!',
      }
   );

test_run($app, [ qw< --fcmd1 FOO foo > ], { qw< FENV AHOY > }, 'foo')
   ->no_exceptions('first-level subcommand, one arg up, env set')
   ->name_is('foo')
   ->conf_is(
      {
         fcmd1 => 'FOO',
         fcmd2 => 'this!',
         fcmd3 => 'this!',
         fenv  => 'AHOY',
         ffile => 'this!',
         fdefault => 'this!',
      }
   );

test_run($app, [ qw< --fcmd1 FOO foo --fcmd2 BAR > ], { qw< FENV AHOY > }, 'foo')
   ->no_exceptions('first-level subcommand, one arg up, one sub, env set')
   ->name_is('foo')
   ->conf_is(
      {
         fcmd1 => 'FOO',
         fcmd2 => 'BAR',
         fcmd3 => 'this!',
         fenv  => 'AHOY',
         ffile => 'this!',
         fdefault => 'this!',
      }
   );

test_run($app, [ qw< --fcmd1 FOO foo --fcmd2 BAR --fcmd1 FOOBAR > ], { qw< FENV AHOY > }, 'foo')
   ->no_exceptions('first-level subcommand, one arg up, overriddine, plus one sub, env set')
   ->name_is('foo')
   ->conf_is(
      {
         fcmd1 => 'FOOBAR',
         fcmd2 => 'BAR',
         fcmd3 => 'this!',
         fenv  => 'AHOY',
         ffile => 'this!',
         fdefault => 'this!',
      }
   );

test_run($app,
   [ qw< --fcmd1 FOO foo --fcmd2 BAR bar --fcmd1 FOOBAR --fcmd3 BAZ > ],
   { qw< FENV AHOY > }, 'bar')
   ->no_exceptions('second-level subcommand, one arg up, overriddine, one sub, one subsub env set')
   ->name_is('bar')
   ->conf_is(
      {
         fcmd1 => 'FOOBAR',
         fcmd2 => 'BAR',
         fcmd3 => 'BAZ',
         fenv  => 'AHOY',
         ffile => 'this!',
         fdefault => 'this!',
      }
   );

test_run($app,
   [ qw< --fcmd1 FOO foo --fcmd2 BAR --config >, "$file_prefix.1.json", qw< bar --fcmd1 FOOBAR --fcmd3 BAZ > ],
   { qw< FENV AHOY > }, 'bar')
   ->no_exceptions('second-level subcommand, one arg up, overridden, one sub plus config, one subsub env set, one from config file')
   ->name_is('bar')
   ->conf_is(
      {
         fcmd1 => 'FOOBAR',
         fcmd2 => 'BAR',
         fcmd3 => 'BAZ',
         fenv  => 'AHOY',
         ffile => 'from_general_configuration_file',
         fdefault => 'this!',
         config => "$file_prefix.1.json",
      }
   );

done_testing();

sub logger ($phase) {
   state $enc = JSON::PP->new->ascii->canonical->pretty;
   return sub ($self) {
      my $name = $self->name;
      LocalTester::command_execute($self) if $phase eq 'execute';
      my @stack;
      my $instance = $self;
      while (defined($instance)) {
         my @args = $instance->residual_args;
         my $ch   = $instance->config_hash;
         my $fch  = $instance->_rwn('config') // {};
         unshift @stack, 
            { args => \@args, config => $ch, full_config => $fch };
         $instance = $instance->parent;
      }
      say {*STDERR} "$phase $name " . $enc->encode(\@stack);
   };
}
