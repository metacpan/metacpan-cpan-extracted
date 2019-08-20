# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;
use Data::Dumper;

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
    ]);

print $t->canonical,"\n";
ok(Data::Dumper->new([$t->as_hash])
          ->Sortkeys(1)
          ->Useqq(1)
          ->Terse(1)
          ->Indent(0)
          ->Dump,
   '{"base" => "/etc","core" => {"file" => "passwd","group" => "group","home" => "/home"},"file" => {"passwd" => {"mode" => "0644","root" => {"dir" => "/root","uid" => 0}}}}');

ok(Data::Dumper->new([$t->tree->File->as_hash])
          ->Sortkeys(1)
          ->Useqq(1)
          ->Terse(1)
          ->Indent(0)
          ->Dump,
   '{"passwd" => {"mode" => "0644","root" => {"dir" => "/root","uid" => 0}}}');
