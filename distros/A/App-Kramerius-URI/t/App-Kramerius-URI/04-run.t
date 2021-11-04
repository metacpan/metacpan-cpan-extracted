use strict;
use warnings;

use App::Kramerius::URI;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Output;

# Test.
@ARGV = (
	'mzk',
);
my $right_ret = <<'END';
http://kramerius.mzk.cz/ 4
END
stdout_is(
	sub {
		App::Kramerius::URI->new->run;
		return;
	},
	$right_ret,
	"Run with listing of 'mzk' Kramerius system.",
);

# Test.
@ARGV = (
	'-h',
);
$right_ret = <<'END';
Usage: t/App-Kramerius-URI/04-run.t [-h] [--version] kramerius_id
	-h		Help.
	--version	Print version.
	kramerius_id	Kramerius system id. e.g. mzk
END
stderr_is(
	sub {
		App::Kramerius::URI->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
