use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $app = {
   name        => 'MAIN',
   help        => 'example command',
   description => 'An example command',
   execute     => \&one_execute_is_enough,
   options     => [
      {
         name    => 'MY FANTASTIC OPTION!',
         getopt  => 'my-option=s',
         default => 'foo',
      },
      {
         name        => 'ANOTHER FANTASTIC OPTION!',
         environment => 'MY_ENV_OPTION',
         default     => 'bar',
      },
      {
         name        => 'ONE LAST FANTASTIC OPTION!',
         getopt      => 'second-option=s',
         environment => 'LAST_ENV_OPTION',
         default     => 'baz',
      },
   ],
};

test_run($app, [ qw< > ], {}, 'MAIN')
   ->no_exceptions('no cmdline, no env, defaults are set')
   ->conf_is(
      {
         'MY FANTASTIC OPTION!' => 'foo',
         'ANOTHER FANTASTIC OPTION!' => 'bar',
         'ONE LAST FANTASTIC OPTION!' => 'baz',
      }
   )
   ;

test_run($app, [ qw< --my-option foobar > ], {}, 'MAIN')
   ->no_exceptions('cmdline, no env')
   ->conf_is(
      {
         'MY FANTASTIC OPTION!' => 'foobar',
         'ANOTHER FANTASTIC OPTION!' => 'bar',
         'ONE LAST FANTASTIC OPTION!' => 'baz',
      }
   )
   ;

test_run($app, [ qw< > ], { MY_ENV_OPTION => 'baz' }, 'MAIN')
   ->no_exceptions('no cmdline, env')
   ->conf_is(
      {
         'MY FANTASTIC OPTION!' => 'foo',
         'ANOTHER FANTASTIC OPTION!' => 'baz',
         'ONE LAST FANTASTIC OPTION!' => 'baz',
      }
   )
   ;

test_run($app, [ qw< --my-option foobar --second-option cmd-GALOOK > ],
      { MY_ENV_OPTION => 'baz', LAST_ENV_OPTION => 'env-GALOOK' }, 'MAIN')
   ->no_exceptions('no cmdline, env')
   ->conf_is(
      {
         'MY FANTASTIC OPTION!' => 'foobar',
         'ANOTHER FANTASTIC OPTION!' => 'baz',
         'ONE LAST FANTASTIC OPTION!' => 'cmd-GALOOK',
      }
   )
   ;

test_run($app, [ qw< --my-option foobar > ],
      { MY_ENV_OPTION => 'baz', LAST_ENV_OPTION => 'env-GALOOK' }, 'MAIN')
   ->no_exceptions('no cmdline, env')
   ->conf_is(
      {
         'MY FANTASTIC OPTION!' => 'foobar',
         'ANOTHER FANTASTIC OPTION!' => 'baz',
         'ONE LAST FANTASTIC OPTION!' => 'env-GALOOK',
      }
   )
   ;

done_testing();

sub one_execute_is_enough ($self) {
   LocalTester::command_execute($self);
   return $self->name;
}
