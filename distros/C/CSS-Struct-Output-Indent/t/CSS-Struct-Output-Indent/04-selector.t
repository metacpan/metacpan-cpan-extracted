use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Indent->new;
$obj->put(
	['s', 'body'],
);
my $ret = $obj->flush;
is($ret, '');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['e'],
);
$ret = $obj->flush;
my $right_ret = <<'END';
body {
}
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['s', 'div'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body, div {
}
END
chomp $right_ret;
is($ret, $right_ret);
