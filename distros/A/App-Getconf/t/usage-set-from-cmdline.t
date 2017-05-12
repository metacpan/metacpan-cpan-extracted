#!perl -T
#
# set options with command line
# NOTE: these tests are white box ones, as I touch option storage directly
# (App::Getconf::View testing is done elsewhere)
#

use strict;
use warnings;
use Test::More tests => 5 + 2 + 3 + 3 + 4 + 3;
use App::Getconf qw{:schema};

#-----------------------------------------------------------------------------

sub create_app_getconf {
  my $conf = new App::Getconf();

  $conf->option_schema(
    optflag   => opt { type => "flag"   },
    optbool   => opt { type => "bool"   },
    optint    => opt { type => "int"    },
    optfloat  => opt { type => "float"  },
    optstring => opt { type => "string" },
    subsystem => {
      flag => opt { type => "flag" },
    },
    aliasint     => opt_alias "optint",
    aliassubflag => opt_alias "subsystem.flag",
  );

  return $conf;
}

#-----------------------------------------------------------------------------

my $conf;

#-----------------------------------------------------------------------------
# flags

$conf = create_app_getconf();
is($conf->{options}{optflag}{value}, 0, "omitted flag equals initially to 0");

$conf = create_app_getconf();
$conf->cmdline([qw[ --optflag ]]);
is($conf->{options}{optflag}{value}, 1, "flag passed once equals to 1");

$conf = create_app_getconf();
$conf->cmdline([qw[ --optflag --optflag --optflag ]]);
is($conf->{options}{optflag}{value}, 3, "flag passed three times equals to 3");

$conf = create_app_getconf();
is($conf->{options}{"subsystem.flag"}{value}, 0, "flag in subsystem (omitted)");

$conf = create_app_getconf();
$conf->cmdline([qw[ --subsystem-flag --subsystem-flag --subsystem-flag ]]);
is($conf->{options}{"subsystem.flag"}{value}, 3, "flag in subsystem (passed 3 times)");

#-----------------------------------------------------------------------------
# Boolean options
# NOTE: TRUE and FALSE values could change in future module versions

$conf = create_app_getconf();
$conf->cmdline([qw[ --no-optbool ]]);
is($conf->{options}{optbool}{value}, 0, "Boolean option, negated");

$conf = create_app_getconf();
$conf->cmdline([qw[ --optbool ]]);
is($conf->{options}{optbool}{value}, 1, "Boolean option, affirmed");

#-----------------------------------------------------------------------------
# int options

$conf = create_app_getconf();
$conf->cmdline([qw[ --optint=1024 ]]);
is($conf->{options}{optint}{value}, 1024, "int option");

$conf = create_app_getconf();
$conf->cmdline([qw[ --optint 1024 ]]);
is($conf->{options}{optint}{value}, 1024, "int option passed as two arguments");

$conf = create_app_getconf();
$conf->cmdline([qw[ --optint -1024 ]]);
is($conf->{options}{optint}{value}, -1024, "int option, negative value, as two arguments");

#-----------------------------------------------------------------------------
# float options

$conf = create_app_getconf();
$conf->cmdline([qw[ --optfloat=0.5 ]]);
is($conf->{options}{optfloat}{value}, 0.5, "float option");

$conf = create_app_getconf();
$conf->cmdline([qw[ --optfloat 0.5 ]]);
is($conf->{options}{optfloat}{value}, 0.5, "float option passed as two arguments");

$conf = create_app_getconf();
$conf->cmdline([qw[ --optfloat -0.5 ]]);
is($conf->{options}{optfloat}{value}, -0.5, "float option, negative value, as two arguments");

#-----------------------------------------------------------------------------
# string options

$conf = create_app_getconf();
$conf->cmdline(["--optstring="]);
is($conf->{options}{optstring}{value}, "", "string option, empty");

$conf = create_app_getconf();
$conf->cmdline(["--optstring==foo bar baz"]);
is($conf->{options}{optstring}{value}, "=foo bar baz", "string option, non-empty");

$conf = create_app_getconf();
$conf->cmdline(["--optstring", "=foo bar baz"]);
is($conf->{options}{optstring}{value}, "=foo bar baz", "string option, as two arguments");

$conf = create_app_getconf();
$conf->cmdline(["--optstring", ""]);
is($conf->{options}{optstring}{value}, "", "string option, as two arguments, empty");

#-----------------------------------------------------------------------------
# aliases

#  aliassubflag => opt_alias "subsystem.flag",

$conf = create_app_getconf();
$conf->cmdline([qw{ --aliasint=100 }]);
is($conf->{options}{optint}{value}, 100, "alias to int");

$conf = create_app_getconf();
$conf->cmdline([qw{ --aliasint 200 }]);
is($conf->{options}{optint}{value}, 200, "alias to int, as two arguments");

$conf = create_app_getconf();
$conf->cmdline([qw{ --aliassubflag --aliassubflag }]);
is($conf->{options}{"subsystem.flag"}{value}, 2, "alias to a flag, passed twice");

#-----------------------------------------------------------------------------
# vim:ft=perl
