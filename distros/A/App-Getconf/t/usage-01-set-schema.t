#!perl -T
#
# set schema in App::Getconf
#

use strict;
use warnings;
use Test::More tests => 2;
use App::Getconf qw{:schema};

#-----------------------------------------------------------------------------
# setting schema

my $conf = eval {
  my $conf = new App::Getconf();

  $conf->option_schema(
    opt1 => opt {},
    opt2 => opt_bool,
    opt3 => opt_flag,
    group1 => schema(
      sub1 => opt_int,
      sub2 => opt_string,
    ),
    group2 => schema(
      sub1 => opt_int,
      sub2 => opt_string,
    ),
    o1 => opt_alias 'opt1',
    o2 => opt_alias 'opt2',
    o3 => opt_alias 'opt3',
  );

  $conf;
};

diag($@) if $@;
BAIL_OUT("creating App::Getconf and setting schema failed") if not $conf;

# XXX: this is white-box testing, I know well how should the $conf look like
is(keys(%{ $conf->{options} }), 3 + 2 + 2, "number of (actual) options");
is(keys(%{ $conf->{aliases} }), 3,         "number of aliases");

#-----------------------------------------------------------------------------
# vim:ft=perl
