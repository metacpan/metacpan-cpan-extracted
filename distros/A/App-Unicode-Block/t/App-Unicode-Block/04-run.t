use strict;
use warnings;

use App::Unicode::Block;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Output;

# Test.
@ARGV = (
	'Basic Latin',
);
my $right_ret = <<'END';
┌────────────────────────────────────────┐
│              Basic Latin               │
├────────┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┤
│        │0│1│2│3│4│5│6│7│8│9│A│B│C│D│E│F│
├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ U+000x │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ U+001x │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ U+002x │ │!│"│#│$│%│&│'│(│)│*│+│,│-│.│/│
├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ U+003x │0│1│2│3│4│5│6│7│8│9│:│;│<│=│>│?│
├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ U+004x │@│A│B│C│D│E│F│G│H│I│J│K│L│M│N│O│
├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ U+005x │P│Q│R│S│T│U│V│W│X│Y│Z│[│\│]│^│_│
├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ U+006x │`│a│b│c│d│e│f│g│h│i│j│k│l│m│n│o│
├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ U+007x │p│q│r│s│t│u│v│w│x│y│z│{│|│}│~│ │
└────────┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘

END
my $foo = stdout_is(
	sub {
		App::Unicode::Block->new->run;
		return;
	},
	$right_ret,
	"Run with listing of 'Basic Latin' unicode block.",
);

# Test.
@ARGV = (
	'Bad block'
);
eval {
	App::Unicode::Block->new->run;
};
is($EVAL_ERROR, "Unicode block 'Bad block' doesn't exist.\n",
	'Run with bad unicode block name.');
clean();

# Test.
@ARGV = (
	'-h',
);
$right_ret = <<'END';
Usage: t/App-Unicode-Block/04-run.t [-h] [-l] [--version] [unicode_block]
	-h		Help.
	-l		List of blocks.
	--version	Print version.
	unicode_block	Unicode block name for print.
END
stderr_is(
	sub {
		App::Unicode::Block->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
