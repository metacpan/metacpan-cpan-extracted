#!perl -T
#
# default and initial arguments
# NOTE: these tests are white box ones, as I touch option storage directly
# (App::Getconf::View testing is done elsewhere)
#

use strict;
use warnings;
use Test::More tests => 4 + 3 + 3;
use App::Getconf qw{:schema};

#-----------------------------------------------------------------------------

sub create_app_getconf {
  my $conf = new App::Getconf();

  $conf->option_schema(
    flag => opt_flag,
    has  => {
      initial => opt { value => "initial (just)" },
      default => opt {                            default => "default (just)" },
      both    => opt { value => "initial (both)", default => "default (both)" },
    },
  );

  return $conf;
}

#-----------------------------------------------------------------------------

my $conf;

#-----------------------------------------------------------------------------
# initial values

$conf = create_app_getconf();
is($conf->{options}{flag}{value}, 0, "omitted flag equals initially to 0");

$conf = create_app_getconf();
is($conf->{options}{"has.initial"}{value}, "initial (just)", "initial value, unspec");

$conf = create_app_getconf();
is($conf->{options}{"has.both"}{value}, "initial (both)", "initial+default, unspec");

$conf = create_app_getconf();
is($conf->{options}{"has.default"}{value}, undef, "default value, unspec");

#-----------------------------------------------------------------------------
# values set with `--opt'

$conf = create_app_getconf();

$conf = create_app_getconf();
eval { $conf->cmdline([qw{ --has-initial }]) };
is($conf->{options}{"has.initial"}{value}, "initial (just)", "initial value, `--foo'");

$conf = create_app_getconf();
$conf->cmdline([qw{ --has-both }]);
is($conf->{options}{"has.both"}{value}, "default (both)", "initial+default, `--foo'");

$conf = create_app_getconf();
$conf->cmdline([qw{ --has-default }]);
is($conf->{options}{"has.default"}{value}, "default (just)", "default value, `--foo'");

#-----------------------------------------------------------------------------
# values set with `--opt=###'

$conf = create_app_getconf();
$conf->cmdline([qw{ --has-initial=initial_specified }]);
is($conf->{options}{"has.initial"}{value}, "initial_specified", "initial value, `--foo=value'");

$conf = create_app_getconf();
$conf->cmdline([qw{ --has-both=both_specified }]);
is($conf->{options}{"has.both"}{value}, "both_specified", "initial+default, `--foo=value'");

$conf = create_app_getconf();
$conf->cmdline([qw{ --has-default=default_specified }]);
is($conf->{options}{"has.default"}{value}, "default_specified", "default value, `--foo=value'");

#-----------------------------------------------------------------------------
# vim:ft=perl:nowrap
