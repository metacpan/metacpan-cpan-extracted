# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Test::Trap;

eval {
  require DBD::SQLite;
  plan tests => 9;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use_ok('ClearPress::util');

{
  my $util = ClearPress::util->new();
  isa_ok($util, 'ClearPress::util');

  is($util->dbsection(), 'live', 'default dbsection');
  local $ENV{dev} = 'test';
  is($util->dbsection(), 'test', 'ENV dbsection');

  is($util->configpath(), 'data/config.ini', 'default cnofigpath');
  is($util->configpath('t/data/config.ini'), 't/data/config.ini', 'user defined configpath');

  trap {
    ok($util->log(q[a message]), 'log yields true');
  };
  like($trap->stderr(), qr/a\ message/mx, 'stderr logging');

  is($util->quote(q['foo']), q['''foo''']);
}
