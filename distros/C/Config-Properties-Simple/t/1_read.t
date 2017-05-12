# -*- Mode: Perl -*-

use Test::More tests => 19;
BEGIN { use_ok('Config::Properties::Simple') };

my $cfg1;
eval {$cfg1=Config::Properties::Simple->new(file => 't/example1.props',
					    defaults => { doo => 'hello' })};
ok ($cfg1 && !$@, "reading");

is($cfg1->getProperty('foo'), 'foo1', "read value");
is($cfg1->getProperty('doo'), 'hello', "default value");
is($cfg1->getProperty('bye'), undef, "undefined");

my $cfg2;
eval { $cfg2=Config::Properties::Simple->new(file => 't/unexistant') };
ok (!$cfg2 && $@, "unexistant");

my $cfg3;
eval { $cfg3=Config::Properties::Simple->new(file => 't/example1.props',
					     required => [qw(foo bar)]) };
ok ($cfg3 && !$@, "required ok");

my $cfg4;
eval { $cfg4=Config::Properties::Simple->new(file => 't/example1.props',
					     required => [qw(foo)]) };
ok ($cfg4 && !$@, "required ok 2");

my $cfg5;
eval { $cfg5=Config::Properties::Simple->new(file => 't/example1.props',
					     required => [qw(foo doo)]) };
ok (!$cfg5 && $@, "required fail");

my $cfg6;
eval { $cfg6=Config::Properties::Simple->new(file => 't/example1.props',
					     defaults => {doo => 'hello'},
					     required => [qw(foo doo)]) };
ok ($cfg6 && !$@, "required default ok");

my $cfg7;
eval { $cfg7=Config::Properties::Simple->new(file => 't/example1.props',
					     validate => [qw(foo doo bar)]) };
ok ($cfg7 && !$@, "validate array ok");

my $cfg8;
eval { $cfg8=Config::Properties::Simple->new(file => 't/example1.props',
					     validate => [qw(foo doo)]) };
ok (!$cfg8 && $@, "validate array fail");

undef $@;
my $cfg9;
eval { $cfg9=Config::Properties::Simple->new(file => 't/example1.props',
					     aliases => { foo => 'moc' }) };
ok ($cfg9 && !$@, "load 9");
is ($cfg9->getProperty('moc'), 'foo1', "alias 1");
is ($cfg9->getProperty('bar'), 'bar2', "alias 2");
is ($cfg9->getProperty('foo', 'def'), 'def', "alias 3");

my $cfg10;
eval { $cfg10=Config::Properties::Simple->new(file => 't/example2.props',
					      defaults => $cfg7) };
ok ($cfg10 && !$@, "cascade");
is ($cfg10->getProperty('foo'), 'foo2', "cascade 2");
is ($cfg10->getProperty('bar'), 'bar2', "cascade 3");
