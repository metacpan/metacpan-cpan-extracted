#!perl -T
#
# set options with config file
# NOTE: these tests are white box ones, as I touch option storage directly
# (App::Getconf::View testing is done elsewhere)
#

use strict;
use warnings;
use Test::More tests => 0 + 2 + 1 + 1 + 3 + 2;
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
      string => opt { type => "string" },
    },
  );

  return $conf;
}

#-----------------------------------------------------------------------------

my $conf;

#-----------------------------------------------------------------------------
# flags: these can't be set with config

#$conf = create_app_getconf();
#$conf->options({ optflag => 1 }); # ???
#is($conf->{options}{optflag}{value}, 1, "flag passed once equals to 1");

#-----------------------------------------------------------------------------
# Boolean options

$conf = create_app_getconf();
$conf->options({ optbool => 0 });
is($conf->{options}{optbool}{value}, 0, "Boolean option, negated");

$conf = create_app_getconf();
$conf->options({ optbool => 1 });
is($conf->{options}{optbool}{value}, 1, "Boolean option, affirmed");

#-----------------------------------------------------------------------------
# int options

$conf = create_app_getconf();
$conf->options({ optint => 1024 });
is($conf->{options}{optint}{value}, 1024, "int option");

#-----------------------------------------------------------------------------
# float options

$conf = create_app_getconf();
$conf->options({ optfloat => 0.5 });
is($conf->{options}{optfloat}{value}, 0.5, "float option");

#-----------------------------------------------------------------------------
# string options

$conf = create_app_getconf();
$conf->options({ optstring => undef });
is($conf->{options}{optstring}{value}, undef, "string option, <undef>");

$conf = create_app_getconf();
$conf->options({ optstring => "" });
is($conf->{options}{optstring}{value}, "", "string option, empty");

$conf = create_app_getconf();
$conf->options({ optstring => "foo bar baz" });
is($conf->{options}{optstring}{value}, "foo bar baz", "string option, non-empty");

#-----------------------------------------------------------------------------
# subsystem options

$conf = create_app_getconf();
$conf->options({ subsystem => { string => "string option in subsystem" } });
is(
  $conf->{options}{"subsystem.string"}{value},
  "string option in subsystem",
  "string option, nested"
);

$conf = create_app_getconf();
$conf->options({ "subsystem.string" => "string option in subsystem (dot)" });
is(
  $conf->{options}{"subsystem.string"}{value},
  "string option in subsystem (dot)",
  "string option, nested (dot-notation)"
);

#-----------------------------------------------------------------------------
# vim:ft=perl
