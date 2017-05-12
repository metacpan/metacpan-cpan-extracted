# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Carp;

eval {
  require DBD::mysql;
  my $dbh = DBI->connect('DBI:mysql:database=test;host=localhost', 'root', undef, {RaiseError=>1}) or croak 'failed to connect';
  $dbh->do(q[DROP TABLE IF EXISTS derived]);
  plan tests => 6;
} or do {
  plan skip_all => 'DBD::mysql not installed and/or mysql test database unavailable';
};

use_ok('ClearPress::driver::mysql');

my $cfg = {
	   dbname     => 'test',
	   dbuser     => q[root],
	   dbpass     => undef,
	   dbhost     => q[localhost],
	   dbport     => q[3306],
	  };

my $drv = ClearPress::driver::mysql->new($cfg);
isa_ok($drv, 'ClearPress::driver::mysql');

{
  eval {
    $drv->create_table('derived', {});
  };
  like($EVAL_ERROR, qr/determine\ primary\ key/mix, 'create without pk');
}

{
  ok($drv->create_table('derived',
			{
			 id_derived  => 'primary key',
			 text_dummy  => 'text',
			 char_dummy  => 'char(128)',
			 int_dummy   => 'integer unsigned',
			 float_dummy => 'float unsigned',
			}, 'create table'));
}

ok($drv->create(q[INSERT INTO derived(text_dummy) values('foo')]));

ok($drv->drop_table('derived'), 'drop table');

