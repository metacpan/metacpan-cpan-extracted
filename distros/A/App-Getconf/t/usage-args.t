#!perl -T
#
# non-option arguments
#

use strict;
use warnings;
use Test::More tests => 2 * 6;
use App::Getconf qw{:schema};

#-----------------------------------------------------------------------------

sub create_app_getconf {
  my $conf = new App::Getconf();

  $conf->option_schema(
    flag   => opt_flag,
    number => opt_int,
    text   => opt_string,
  );

  return $conf;
}

#-----------------------------------------------------------------------------

my $conf;
my $ack;

#-----------------------------------------------------------------------------

$conf = create_app_getconf();
$ack = $conf->cmdline([qw[ --flag arg1 arg2 ]]);
is_deeply([ $conf->args ], [ qw{arg1 arg2} ], "arguments after a `--flag'");
is($ack, undef, "arguments after a `--flag' (result empty)");

$conf = create_app_getconf();
$ack = $conf->cmdline([qw[ --number=10 arg1 arg2 ]]);
is_deeply([ $conf->args ], [ qw{arg1 arg2} ], "arguments after a `--number'");
is($ack, undef, "arguments after a `--number' (result empty)");

$conf = create_app_getconf();
$ack = $conf->cmdline([qw[ --number=10 -- arg1 arg2 ]]);
is_deeply([ $conf->args ], [ qw{arg1 arg2} ], "arguments after a `--number --'");
is($ack, undef, "arguments after a `--number --' (result empty)");

$conf = create_app_getconf();
$ack = $conf->cmdline([qw[ --number=10 -- --arg1 arg2 ]]);
is_deeply([ $conf->args ], [ qw{--arg1 arg2} ], "--arguments after a `--number --'");
is($ack, undef, "--arguments after a `--number --' (result empty)");

$conf = create_app_getconf();
$ack = $conf->cmdline([qw[ --arg1 arg2 ]]);
is_deeply([ $conf->args ], [ "arg2" ], "invalid argument specified");
isnt($ack, undef, "invalid argument specified (result non-empty)");

$conf = create_app_getconf();
$ack = $conf->cmdline([qw[ --text --foo arg1 arg2 ]]);
is_deeply([ $conf->args ], [ qw{arg1 arg2} ], "arguments after a `--text --foo'");
is($ack, undef, "arguments after a `--text --foo' (result empty)");

#-----------------------------------------------------------------------------
# vim:ft=perl:nowrap
