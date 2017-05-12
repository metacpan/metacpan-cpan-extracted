use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
plan(tests => 2);

use_ok('CSS::Simple');

my $css = <<END;
.foo {
	color: red;
}
.bar {
	color: blue;
	font-weight: bold;
}
.biz {
	color: green;
	font-size: 10px;
}
.foo2 {
	color: red;
}
.bar2 {
	color: blue;
	font-weight: bold;
}
.biz2 {
	color: green;
	font-size: 10px;
}
.foo3 {
	color: red;
}
.bar3 {
	color: blue;
	font-weight: bold;
}
.biz3 {
	color: green;
	font-size: 10px;
}
.foo4 {
	color: red;
}
.bar4 {
	color: blue;
	font-weight: bold;
}
.biz4 {
	color: green;
	font-size: 10px;
}
.foo5 {
	color: red;
}
.bar5 {
	color: blue;
	font-weight: bold;
}
.biz5 {
	color: blue;
}
.biz5 {
	color: green;
	font-size: 10px;
}
.bar5, .biz5 {
	line-height: 20px;
}
END

my $correct = <<END;
.foo {
	color: red;
}
.bar {
	color: blue;
	font-weight: bold;
}
.biz {
	color: green;
	font-size: 10px;
}
.foo2 {
	color: red;
}
.bar2 {
	color: blue;
	font-weight: bold;
}
.biz2 {
	color: green;
	font-size: 10px;
}
.foo3 {
	color: red;
}
.bar3 {
	color: blue;
	font-weight: bold;
}
.biz3 {
	color: green;
	font-size: 10px;
}
.foo4 {
	color: red;
}
.bar4 {
	color: blue;
	font-weight: bold;
}
.biz4 {
	color: green;
	font-size: 10px;
}
.foo5 {
	color: red;
}
.bar5 {
	color: blue;
	font-weight: bold;
	line-height: 20px;
}
.biz5 {
	color: green;
	font-size: 10px;
	line-height: 20px;
}
END

my $simple = CSS::Simple->new();

$simple->read({css => $css});

my $ordered = $simple->write();

# check to make sure that our shuffled hashes matched up...
ok($correct eq $ordered);
