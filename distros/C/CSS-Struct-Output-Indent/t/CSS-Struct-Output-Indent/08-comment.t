use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Test::More 'tests' => 17;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Indent->new(
	'skip_comments' => 1,
);
$obj->put(
	['c', 'comment'],
);
my $ret = $obj->flush;
is($ret, '', 'Skip comment only.');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment'],
	['s', 'body'],
	['e'],
);
$ret = $obj->flush;
my $right_ret = <<'END';
body {
}
END
chomp $right_ret;
is($ret, $right_ret, 'Skip comment and blank selector.');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment1'],
	['s', 'body'],
	['e'],
	['c', 'comment2'],
	['s', 'div'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body {
}
div {
}
END
chomp $right_ret;
is($ret, $right_ret, 'Skip comments and two blank selectors.');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['c', 'comment'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body {
}
END
chomp $right_ret;
is($ret, $right_ret, 'Skip comment inside selector.');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['c', 'comment1'],
	['c', 'comment2'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body {
}
END
chomp $right_ret;
is($ret, $right_ret, 'Skip two comments in selector.');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['d', 'attr1', 'value1'],
	['c', 'comment'],
	['d', 'attr2', 'value2'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body {
	attr1: value1;
	attr2: value2;
}
END
chomp $right_ret;
is($ret, $right_ret, 'Skip comment between definitions.');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['d', 'attr1', 'value1'],
	['c', 'comment1'],
	['c', 'comment2'],
	['d', 'attr2', 'value2'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body {
	attr1: value1;
	attr2: value2;
}
END
chomp $right_ret;
is($ret, $right_ret, 'Skip two comments between definitions.');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment1'],
	['s', 'body'],
	['c', 'comment2'],
	['s', 'div'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body, div {
}
END
chomp $right_ret;
is($ret, $right_ret, 'Skip comments, advanced version.');

# Debug message.
print "Testing: Comment.\n";

# Test.
$obj = CSS::Struct::Output::Indent->new(
	'skip_comments' => 0,
);
$obj->put(
	['c', 'comment'],
);
$ret = $obj->flush;
is($ret, "/* comment */", 'Simple comment without selector.');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment'],
	['s', 'body'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
/* comment */
body {
}
END
chomp $right_ret;
is($ret, $right_ret, 'Comment before selector.');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment1'],
	['s', 'body'],
	['e'],
	['c', 'comment2'],
	['s', 'div'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
/* comment1 */
body {
}

/* comment2 */
div {
}
END
chomp $right_ret;
is($ret, $right_ret, 'Comments before selectors.');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['c', 'comment'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body {

	/* comment */
}
END
chomp $right_ret;
is($ret, $right_ret, 'Comment inside selector.');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['c', 'comment1'],
	['c', 'comment2'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body {

	/* comment1 */
	/* comment2 */
}
END
chomp $right_ret;
is($ret, $right_ret, 'Two comments inside selector.');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['d', 'attr1', 'value1'],
	['c', 'comment'],
	['d', 'attr2', 'value2'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body {
	attr1: value1;

	/* comment */
	attr2: value2;
}
END
chomp $right_ret;
is($ret, $right_ret, 'Comment between definitions.');

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['d', 'attr1', 'value1'],
	['c', 'comment1'],
	['c', 'comment2'],
	['d', 'attr2', 'value2'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
body {
	attr1: value1;

	/* comment1 */
	/* comment2 */
	attr2: value2;
}
END
chomp $right_ret;
is($ret, $right_ret, 'Two comments between definitions.');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment1'],
	['s', 'body'],
	['c', 'comment2'],
	['s', 'div'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
/* comment1 */
body,

/* comment2 */
div {
}
END
chomp $right_ret;
is($ret, $right_ret, 'Comments, advanced version.');
