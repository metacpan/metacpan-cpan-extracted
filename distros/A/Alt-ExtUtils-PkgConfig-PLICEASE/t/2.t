#!/usr/bin/perl
#
# $Id$
#

use strict;
use warnings;

use Test::More tests => 11;
use ExtUtils::PkgConfig;

$ENV{PKG_CONFIG_PATH} = './t/';

my ($major, $minor) = (0,28);

cmd_ok ('modversion');
cmd_ok ('cflags');
cmd_ok ('cflags_only_I');
cmd_ok ('libs');
cmd_ok ('libs_only_L');
cmd_ok ('libs_only_l');

SKIP: {
  skip '*_only_other', 2
    unless ($major > 0 || $minor >= 15);

  cmd_ok ('cflags_only_other');
  cmd_ok ('libs_only_other');
}

SKIP: {
  skip 'static libs', 1
    unless ($major > 0 || $minor >= 20);

  my $data = ExtUtils::PkgConfig->static_libs(qw/test_glib-2.0/);
  like ($data, qr/pthread/);
}

my $data;

$data = ExtUtils::PkgConfig->variable(qw/test_glib-2.0/, 'glib_genmarshal');
ok (defined $data);

$data = ExtUtils::PkgConfig->variable(qw/test_glib-2.0/, '__bad__');
ok (not defined $data);

sub cmd_ok {
  my ($cmd, $desc) = @_;

  my $data = ExtUtils::PkgConfig->$cmd(qw/test_glib-2.0/);
  ok (defined $data, $desc);
}
