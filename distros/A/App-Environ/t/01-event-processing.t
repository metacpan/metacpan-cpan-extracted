use 5.008000;
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 10;
use Test::Fatal qw( lives_ok exception );
use App::Environ;

BEGIN {
  $ENV{APPCONF_DIRS} = 't/etc';
}

use Foo;
use Bar;

t_initialize();
t_reload();
t_async_call();
t_unknown_event();
t_handling_error();
t_finalize();


sub t_initialize {
  App::Environ->send_event( 'initialize', 'moo', 'jar' );

  my $t_foo_inst = Foo->instance;
  my $t_bar_inst = Bar->instance;

  is_deeply( $t_foo_inst,
    { config     => {
        param1 => 'foo:value1',
        param2 => 'foo:value2',
      },
      init_args => [ qw( moo jar ) ],
      reloads   => 0,
    }, 'initialization; Foo' );

  is_deeply( $t_bar_inst,
    { config     => {
        param1 => 'bar:value1',
        param2 => 'bar:value2',
      },
      init_args => [ qw( moo jar ) ],
      reloads   => 0,
    }, 'initialization; Bar' );

  return;
}

sub t_reload {
  App::Environ->send_event('reload');

  my $t_foo_inst = Foo->instance;
  my $t_bar_inst = Bar->instance;

  is( $t_foo_inst->{reloads}, 1, 'reload; Foo' );
  is( $t_bar_inst->{reloads}, 1, 'reload; Bar' );

  return;
}

sub t_async_call {
  my $t_done;

  App::Environ->send_event( 'pre_finalize:r', undef, sub { $t_done = 1 } );

  is( $t_done, 1, 'asynchronous event' );

  return;
}

sub t_unknown_event {
  lives_ok {
    App::Environ->send_event('unknown');
  }
  'unknown event';

  return;
}

sub t_handling_error {
  eval { App::Environ->send_event( 'reload', 1 ) };
  my $t_err_sync = $@;

  is( $t_err_sync, "Some error.\n", 'handling error; synchronous' );

  my $t_err_async;
  App::Environ->send_event( 'pre_finalize:r', 1,
      sub { $t_err_async = shift } );

  is( $t_err_async, "Some error.", 'handling error; asynchronous' );

  return;
}

sub t_finalize {
  App::Environ->send_event('finalize:r');

  like(
    exception {
      my $t_foo_inst = Foo->instance;
    },
    qr/Foo must be initialized first/,
    'finalization; Foo'
  );

  like(
    exception {
      my $t_bar_inst = Bar->instance;
    },
    qr/Bar must be initialized first/,
    'finalization; Bar'
  );

  return;
}
