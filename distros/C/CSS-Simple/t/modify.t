use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
plan(tests => 2);

use_ok('CSS::Simple');

my $simple = CSS::Simple->new();

$simple->add_selector({selector => '.empty', properties => {}});
$simple->add_selector({selector => '.foo', properties => { color => 'blue', 'font-size' => '16px'}});
$simple->add_selector({selector => '.foo2', properties => { color => 'blue', 'font-size' => '16px'}});
$simple->add_selector({selector => '.foo3', properties => { color => 'blue', 'font-size' => '16px'}});

$simple->modify_selector({selector => '.foo', new_selector => '.bar'});
$simple->modify_selector({selector => '.foo3', new_selector => '.last'});

my $ordered = $simple->write();

my $expected = <<END;
.bar {
	color: blue;
	font-size: 16px;
}
.foo2 {
	color: blue;
	font-size: 16px;
}
.last {
	color: blue;
	font-size: 16px;
}
END

ok($expected eq $ordered);
