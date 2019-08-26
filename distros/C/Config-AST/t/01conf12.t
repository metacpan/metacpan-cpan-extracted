# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 2);

my $t = new TestConfig(
    config => [
	base => '/etc',
	'core.file' => 'passwd',
	'core.home' => '/home',
	
	'file.passwd.mode' => '0644',
	'file.passwd.root.uid' => 0,
	'file.passwd.root.dir' => '/root',

	'core.group' => 'group'
    ],
    lexicon => { '*' => '*' } );

ok($t->canonical,
   q{base="/etc" core.file="passwd" core.group="group" core.home="/home" file.passwd.mode="0644" file.passwd.root.dir="/root" file.passwd.root.uid=0});

ok($t->file->passwd->mode,'0644');
