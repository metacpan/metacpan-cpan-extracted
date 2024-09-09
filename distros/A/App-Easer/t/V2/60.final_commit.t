use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;
use JSON::PP ();

my $file_prefix = __FILE__ =~ s{\.t\z}{}rmxs;

my ($var1, $var2);
my $app = {
   name        => 'MAIN',
   help        => 'example command',
   description => 'An example command',
   options     => [
      { getopt => 'cmdp=s', transmit => 1, default => 'this!' },
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
               execute => \&one_execute_is_enough,
            }
         ],
         execute => \&one_execute_is_enough,
      },
   ],
   commit => sub ($cmd) {
      $var1 = $cmd->config('cmdp');
   },
   final_commit => sub ($cmd) {
      my ($executor) = $cmd->final_commit_stack;
      $var2 = $executor->config('cmdp');
   },
   execute => \&one_execute_is_enough,
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
($var1, $var2) = ();
test_run($app, [ qw< > ], {}, 'MAIN')
   ->no_exceptions('simple invocation, no args at all')
   ->name_is('MAIN')
   ->conf_is( { cmdp => 'this!' });
is $var1, undef, 'var1 from commit';
is $var2, 'this!', 'var2 from final_commit';

($var1, $var2) = ();
test_run($app, [ qw< --cmdp FOO > ], {}, 'MAIN')
   ->no_exceptions('upper level command, one arg')
   ->name_is('MAIN')
   ->conf_is( { cmdp => 'FOO' });
is $var1, 'FOO', 'var1 from commit';
is $var2, 'FOO', 'var2 from final_commit';

($var1, $var2) = ();
test_run($app, [ qw< --cmdp FOO foo > ], {}, 'foo')
   ->no_exceptions('first-level subcommand, one arg up')
   ->name_is('foo')
   ->conf_is( { cmdp => 'FOO' });
is $var1, 'FOO', 'var1 from commit';
is $var2, 'FOO', 'var2 from final_commit';

($var1, $var2) = ();
test_run($app, [ qw< --cmdp FOO foo --cmdp BAR > ], {}, 'foo')
   ->no_exceptions('first-level subcommand, one arg up, override')
   ->name_is('foo')
   ->conf_is( { cmdp => 'BAR' });
is $var1, 'FOO', 'var1 from commit';
is $var2, 'BAR', 'var2 from final_commit';

($var1, $var2) = ();
test_run($app, [ qw< --cmdp FOO foo --cmdp BAR bar --cmdp BAZ > ], {}, 'bar')
   ->no_exceptions('second-level subcommand, one arg up, double override')
   ->name_is('bar')
   ->conf_is( { cmdp => 'BAZ' });
is $var1, 'FOO', 'var1 from commit';
is $var2, 'BAZ', 'var2 from final_commit';

done_testing();

sub one_execute_is_enough ($self) {
   LocalTester::command_execute($self);
   return $self->name;
}
