use strict;
use warnings;

use App::Pod::Example;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use IO::CaptureOutput qw(capture);
use Readonly;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Constants.
Readonly::Scalar our $EMPTY_STR => q{};

# Test.
eval {
	App::Pod::Example->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad parameter \'\'.');
clean();

# Test.
eval {
	App::Pod::Example->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad parameter \'something\'.');
clean();

# Test.
@ARGV = (
	'Foo',
);
eval {
       App::Pod::Example->new;
};
is($EVAL_ERROR, "Cannot process any action (-p or -r options).\n",
	'No action.');
clean();

# Test.
SKIP: {
skip "Problem with IO::CaptureOutput::capture", 1;
my $right_ret = <<'END';
Usage: t/App-Pod-Example/04-new.t [-d flag] [-e] [-h] [-n number] [-p] [-r]
        [-s section] [--version] pod_file_or_module [argument ..]

        -d flag         Turn debug (0/1) (default is 1).
        -e              Enumerate lines. Only for print mode.
        -h              Help.
        -n number       Number of example (default is nothing).
        -p              Print example.
        -r              Run example.
        -s section      Use section (default EXAMPLE).
        --version       Print version.
END
my ($stderr, $stdout);
my $obj = capture sub {
	return App::Pod::Example->new;
} => \$stdout, \$stderr;
isa_ok($obj, 'App::Pod::Example');
is($stdout, $EMPTY_STR, 'No stdout.');
like($stderr, $right_ret, 'Print help.');
}
