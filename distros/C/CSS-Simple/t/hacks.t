use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
plan(tests => 2);

use_ok('CSS::Simple');

my $css = <<END;
.foo {
	*color: red;
}
.bar {
	_font-weight: bold;
}
.biz {
	-font-size: 10px;
}
.foo2 {
	w\\idth: 500px;
	width: 130px;
}
END

my $correct = <<END;
.foo2 {
	width: 130px;
}
END

my $simple = CSS::Simple->new();

$simple->read({css => $css});

my $ordered = $simple->write();

# check to make sure that our shuffled hashes matched up...
ok($correct eq $ordered);
