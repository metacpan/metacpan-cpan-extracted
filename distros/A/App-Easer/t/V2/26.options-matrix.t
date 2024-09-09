use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;
use JSON::PP ();

my $file_prefix = __FILE__ =~ s{\.t\z}{}rmxs;

my $instance;
sub remember_instance ($i) { $instance = $i };
my $app = {
   name        => 'MAIN',
   help        => 'example command',
   description => 'An example command',
   options     => [
      { getopt => 'config=s',   transmit => 1,                    },
      { getopt => 'fcmd1=s',    transmit => 1, default => 'this!' },
      { getopt => 'fcmd2=s',    transmit => 1, default => 'this!' },
      { getopt => 'fcmd3=s',    transmit => 1, default => 'this!' },
      { getopt => 'fenv=s',     transmit => 0, default => 'this!', environment => 'FENV' },
      { getopt => 'ffile=s',    transmit => 1, default => 'this!' },
      { getopt => 'fdefault=s', transmit => 1, default => 'this!' },
   ],
   children => [
      {
         name => 'foo',
         options => [
            qw< config fcmd1 fcmd2 fcmd3 fenv ffile >,
         ],
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
               execute => executor(\&remember_instance),
            }
         ],
         execute => executor(\&remember_instance),
      },
   ],
   execute => executor(\&remember_instance),
   default_child => '-self',
   fallback_to => '-default',
   sources => {
      current => [ qw< +CmdLine +Environment > ],
      final   => [ qw<
         +LastCmdLine
         +Parent
         +FinalEnvironment
         +FinalDefault=100
         +JsonFileFromConfig=40
         > ],
   },
};

# test_run($app, $cmdline, $env, $expected_final_command_name);
test_run($app, [ qw< > ], { qw< > }, 'MAIN')
   ->no_exceptions('baseline, simple invocation, "array-based" opts')
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
   )
   ;

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

# in "legacy" mode option fdefault is not set in descendant commands
# because it is not transmitted. This might or might not be something
# considered good: transmitting all options means that commands down the
# line have huge command line helps, not transmitting them might miss
# some options which might not make too sense because they are usually
# set via environment variables.
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
         # fdefault => 'this!',
      }
   );

# change sources from baseline to new approach
$app->{config_hash_key} = 'v2.008';
$app->{sources} = {
   current => [ qw< +CmdLine +Environment +Default=100 +ParentSlices> ],
   final   => [ qw< +JsonFileFromConfig=40 > ],
};

test_run($app, [ qw< > ], { qw< > }, 'MAIN')
   ->no_exceptions('baseline, simple invocation, "matrix-based" opts')
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
   )
   ;

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
   )
   ;

#test_run($app,
#   [ qw< --fcmd1 FOO foo --fcmd2 BAR --config >, "$file_prefix.1.json",
#      qw< bar --fcmd1 FOOBAR --fcmd3 BAZ > ],
#   { qw< FENV AHOY > }, 'bar')
#   ->no_exceptions('second-level subcommand, one arg up, overridden, ' .
#      'one sub plus config, one subsub env set, one from config file')
#   ->name_is('bar')
#   ->conf_is(
#      {
#         fcmd1 => 'FOOBAR',
#         fcmd2 => 'BAR',
#         fcmd3 => 'BAZ',
#         fenv  => 'AHOY',
#         ffile => 'from_general_configuration_file',
#         fdefault => 'this!',
#         config => "$file_prefix.1.json",
#      }
#   );

#diag App::Easer::V2::d($instance->config_hash(1));

done_testing();
