#!perl -T
#
# different views on options
#

use strict;
use warnings;
use Test::More tests => 4 + 4 + 4 + 4;
use App::Getconf qw{:schema};

#-----------------------------------------------------------------------------

sub create_app_getconf {
  my $conf = new App::Getconf();

  $conf->option_schema(
    option => opt_string,
    subsystem => {
      option => opt_string,
      subsystem => { option => opt_string },
    },
  );

  $conf->options({
    option => "toplevel option",
    subsystem => { option => "subsystem option" },
    "subsystem.subsystem.option" => "try confuse the user",
  });

  return $conf;
}

#-----------------------------------------------------------------------------

my $conf;
my $view;

#-----------------------------------------------------------------------------
# root view

$conf = create_app_getconf();
$view = $conf->getopt("");
is($view->get("option"), "toplevel option", "root view, get(option)");
is($view->top("option"), "toplevel option", "root view, top(option)");
is($view->get("subsystem.option"), "subsystem option", "root view, get(subsystem.option)");
is($view->top("subsystem.option"), "subsystem option", "root view, top(subsystem.option)");

#-----------------------------------------------------------------------------
# subsystem view

$conf = create_app_getconf();
$view = $conf->getopt("subsystem");
is($view->get("option"), "subsystem option", "subsystem view, get(option)");
is($view->top("option"), "toplevel option",  "subsystem view, top(option)");
is($view->get("subsystem.option"), "try confuse the user", "subsystem view, get(subsystem.option)");
is($view->top("subsystem.option"), "subsystem option",     "subsystem view, top(subsystem.option)");

#-----------------------------------------------------------------------------
# sub-subsystem view

$conf = create_app_getconf();
$view = $conf->getopt("subsystem.further");
is($view->get("option"), "subsystem option", "sub-subsystem view, get(option)");
is($view->top("option"), "toplevel option",  "sub-subsystem view, top(option)");
is($view->get("subsystem.option"), "try confuse the user", "sub-subsystem view, get(subsystem.option)");
is($view->top("subsystem.option"), "subsystem option",     "sub-subsystem view, top(subsystem.option)");

#-----------------------------------------------------------------------------
# sub-subsystem view

$conf = create_app_getconf();
$view = $conf->getopt("elsewhere");
is($view->get("option"), "toplevel option", "different subsystem view, get(option)");
is($view->top("option"), "toplevel option", "different subsystem view, top(option)");
is($view->get("subsystem.option"), "subsystem option", "different subsystem view, get(subsystem.option)");
is($view->top("subsystem.option"), "subsystem option", "different subsystem view, top(subsystem.option)");

#-----------------------------------------------------------------------------
# vim:ft=perl:nowrap
