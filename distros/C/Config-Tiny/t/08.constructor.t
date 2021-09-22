#!/usr/bin/perl

use Config::Tiny;

use Test::More tests => 4;

# ------------------------

my($conf1) = Config::Tiny -> new( { _=>{foo=>"bar"} } );
my($str1)  = $conf1->write_string;
is $str1, "foo=bar\n";

my($conf2) = Config::Tiny -> new( { _=>{hello=>"world"}, Cool=>{Beans=>"Dude",someval=>123} } );
my($str2)  = $conf2->write_string;
is $str2, <<'EOF';
hello=world

[Cool]
Beans=Dude
someval=123
EOF

my($conf3) = Config::Tiny -> new( { one => { alpha=>"aaa", beta=>"bbb" },
	two => { abc => 123, def => 456, ghi => 789 } } );
my($str3)  = $conf3->write_string;
is $str3, <<'EOF';
[one]
alpha=aaa
beta=bbb

[two]
abc=123
def=456
ghi=789
EOF

# from synopsis:
my $config = Config::Tiny->new({
	_ => { rootproperty => "Bar" },
	section => { one => "value", Foo => 42 } });
is $config->write_string, <<'EOF';
rootproperty=Bar

[section]
Foo=42
one=value
EOF

