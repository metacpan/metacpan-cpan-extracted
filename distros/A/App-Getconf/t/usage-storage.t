#!perl -T
#
# non-scalar storage types for options
#
# NOTE: these tests are white box ones, as I touch option storage directly
# (App::Getconf::View testing is done elsewhere)
#

use strict;
use warnings;
use Test::More;
use Test::More tests => 2 + 2 + 3 + 3 + 3 + 3;
use App::Getconf qw{:schema};

#-----------------------------------------------------------------------------

sub create_app_getconf {
  my $conf = new App::Getconf();

  $conf->option_schema(
    numbers   => opt { type => "int",    storage => [] },
    variables => opt { type => "string", storage => {} },
  );

  return $conf;
}

#-----------------------------------------------------------------------------

my $conf;
my $ack;

#-----------------------------------------------------------------------------
# raw storage, nothing passed yet

$conf = create_app_getconf();
is_deeply($conf->{options}{numbers}{value}, [], "array storage, unspec");

$conf = create_app_getconf();
is_deeply($conf->{options}{variables}{value}, {}, "hash storage, unspec");

#-----------------------------------------------------------------------------
# array storage, command line

$conf = create_app_getconf();
$conf->cmdline([qw[ --numbers 10 ]]);
is_deeply($conf->{options}{numbers}{value}, [10], "array storage, cmdline, passed once");

$conf = create_app_getconf();
$conf->cmdline([qw[ --numbers 1 --numbers 2 --numbers=3 ]]);
is_deeply($conf->{options}{numbers}{value}, [1, 2, 3], "array storage, cmdline, passed 3 times");

#-----------------------------------------------------------------------------
# array storage, config file

$conf = create_app_getconf();
$conf->options({ numbers => 8 });
is_deeply($conf->{options}{numbers}{value}, [8], "array storage, config, passed once");

$conf = create_app_getconf();
$conf->options({ numbers => 2 });
$conf->options({ numbers => 4 });
$conf->options({ numbers => 6 });
is_deeply($conf->{options}{numbers}{value}, [2, 4, 6], "array storage, config, passed 3 times");

$conf = create_app_getconf();
$conf->options({ numbers => [10, 11, 12] });
is_deeply($conf->{options}{numbers}{value}, [10, 11, 12], "array storage, config, passed array");

#-----------------------------------------------------------------------------
# hash storage, command line

$conf = create_app_getconf();
$conf->cmdline([qw[ --variables=foo=bar ]]);
is_deeply(
  $conf->{options}{variables}{value},
  { foo => "bar" },
  "hash storage, config, passed once as single argument"
);

$conf = create_app_getconf();
$conf->cmdline([qw[ --variables baz=nabla ]]);
is_deeply(
  $conf->{options}{variables}{value},
  { baz => "nabla" },
  "hash storage, config, passed once as two arguments"
);

$conf = create_app_getconf();
$conf->cmdline([qw[
  --variables=arg1=val1
  --variables=arg2=val2
  --variables=arg3=val3
]]);
is_deeply(
  $conf->{options}{variables}{value},
  { arg1 => "val1", arg2 => "val2", arg3 => "val3" },
  "hash storage, config, passed 3 times"
);

#-----------------------------------------------------------------------------
# hash storage, config file

$conf = create_app_getconf();
$conf->options({ variables => { foo => "bar" } });
is_deeply(
  $conf->{options}{variables}{value},
  { foo => "bar" },
  "hash storage, config, passed once"
);

$conf = create_app_getconf();
$conf->options({ variables => { val1 => 1 } });
$conf->options({ variables => { val2 => 2 } });
$conf->options({ variables => { val3 => 3 } });
is_deeply(
  $conf->{options}{variables}{value},
  { val1 => 1, val2 => 2, val3 => 3 },
  "hash storage, config, passed 3 times"
);

$conf = create_app_getconf();
$conf->options({ variables => { val1 => "v1", val2 => "v2", val3 => "v3" } });
is_deeply(
  $conf->{options}{variables}{value},
  { val1 => "v1", val2 => "v2", val3 => "v3" },
  "hash storage, config, passed once 3 variables"
);

#-----------------------------------------------------------------------------
# hash storage, config file (maybe it will work some day)

$conf = create_app_getconf();
$ack = eval { $conf->options({ variables => "val1=1" }); "PASSED" };
is($ack, "PASSED", "setting `x=y' in config with a scalar works");
is_deeply(
  $conf->{options}{variables}{value},
  { val1 => "1" },
  "setting `x=y' in config with a scalar works (data matches)"
);

$conf = create_app_getconf();
$ack = eval { $conf->options({ variables => ["val1=a", "val2=b"] }); "PASSED" };
is($ack, undef, "setting `x=y' in config with an array won't work");

#-----------------------------------------------------------------------------
# vim:ft=perl:nowrap
