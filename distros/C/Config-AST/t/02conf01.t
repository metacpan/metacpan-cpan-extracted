# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;
use Data::Dumper;

plan(tests => 4);

my $t = new TestConfig(
    config => [
	base => '/etc',
	'file.passwd.mode' => '0644',
	'file.passwd.root.uid' => 0,
	'file.passwd.root.dir' => '/root',
    ]);

ok($t->tree->File->Passwd->Root->Dir);
ok($t->tree->File->Passwd->Root->Dir,'/root');
ok($t->tree->File->Base->Name->is_null);
ok(!$t->tree->File->Base->Name);
