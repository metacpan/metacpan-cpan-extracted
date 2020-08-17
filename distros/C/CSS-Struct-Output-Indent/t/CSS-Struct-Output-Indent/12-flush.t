use strict;
use warnings;

use CSS::Struct::Output::Indent;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Indent->new;
$obj->put(
	['s', 'selector'],
	['d', 'attr', 'value'],
	['e'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
selector {
	attr: value;
}
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->put(
	['s', 'selector'],
	['d', 'attr', 'value'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
selector {
	attr: value;
}
selector {
	attr: value;
}
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->put(
	['s', 'selector'],
	['d', 'attr', 'value'],
	['e'],
);
$ret = $obj->flush(1);
$right_ret = <<'END';
selector {
	attr: value;
}
selector {
	attr: value;
}
selector {
	attr: value;
}
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
$obj->put(
	['s', 'selector'],
	['d', 'attr', 'value'],
	['e'],
);
$ret = $obj->flush;
$right_ret = <<'END';
selector {
	attr: value;
}
END
chomp $right_ret;
is($ret, $right_ret);

# Test.
SKIP: {
	eval {
		require File::Temp;
	};
	if ($EVAL_ERROR) {
		skip 'File::Temp not installed', 1;
	};
	my $temp_fh = File::Temp::tempfile();
	$obj = CSS::Struct::Output::Indent->new(
		'output_handler' => $temp_fh,
	);
	$obj->put(
		['s', 'selector'],
		['d', 'attr', 'value'],
		['e'],
	);
	$temp_fh->close;
	eval {
		$ret = $obj->flush;
	};
	is($EVAL_ERROR, "Cannot write to output handler.\n");
	clean();
}
