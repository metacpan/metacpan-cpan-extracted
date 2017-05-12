# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

eval {
  require DBD::mysql;
  plan tests => 3;
} or do {
  plan skip_all => 'DBD::mysql not installed';
};

use_ok('ClearPress::driver::mysql');

my $drv = ClearPress::driver::mysql->new({
					  dbname => '___',
					  dbhost => 'localhost',
					  dbport => 65535,
					 });

{
  isa_ok($drv, 'ClearPress::driver::mysql');
}

{
  eval {
    my $dbh = $drv->dbh();
  };
  like($EVAL_ERROR, qr/failed/mix, 'eval error');
}
