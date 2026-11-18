#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/transform_input_fields.t - a transform may name input fields that are
# not in the top-level input, so one schema can describe two call shapes.
#
# The top-level input is the arrayref form; the transform describes the
# list form and must be called with its own fields, not the top-level one.
#
# The converse is tested too: a transform that only adjusts a field the
# top-level schema already has must keep the top-level call shape, or the
# other fields disappear from the call.
# ======================================================================

use Test::Most;
use Config;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3 qw(run3);

use App::Test::Generator;

my $dir = tempdir(CLEANUP => 1);
my $lib = File::Spec->catdir($dir, 'lib');
make_path(File::Spec->catdir($lib, 'Transform'));

my $module = File::Spec->catfile($lib, 'Transform', 'OwnInput.pm');
open(my $fh, '>', $module) or die "cannot write $module: $!";
print {$fh} <<'MODULE';
package Transform::OwnInput;
use strict;
use warnings;

# The arrayref form returns 'array'; the list form returns 42.
sub pick
{
	my @args = @_;

	return 'array' if ref($args[0]) eq 'ARRAY';
	die 'pick: expected an arrayref or two scalars'
		unless @args == 2 && !ref($args[0]) && !ref($args[1]);

	return 42;
}
1;
MODULE
close($fh) or die "cannot close $module: $!";

my $harness = File::Spec->catfile($dir, 'transform_input_fields.t');

lives_ok {
	App::Test::Generator->generate(
		schema => {
			module   => 'Transform::OwnInput',
			function => 'pick',
			input    => {
				names => {
					type     => 'arrayref',
					position => 0,
					optional => 0,
				},
			},
			output => { type => 'string' },
			config => {
				test_empty    => 0,
				test_nuls     => 0,
				test_non_ascii => 0,
				test_security => 0,
				test_undef    => 0,
			},
			transforms => {
				list => {
					input => {
						first => {
							type     => 'string',
							position => 0,
							optional => 0,
						},
						second => {
							type     => 'string',
							position => 1,
							optional => 0,
						},
					},
					output => { type => 'number' },
				},
			},
		},
		output_file => $harness,
		quiet       => 1,
	);
} 'generate() accepts a transform with its own input fields';

ok(-f $harness, 'the harness was written');

my ($stdout, $stderr) = ('', '');
local $ENV{PERL5LIB} = join($Config{path_sep}, $lib, $ENV{PERL5LIB} // '');
run3([$^X, $harness], \undef, \$stdout, \$stderr);
my $exit = $? >> 8;

is($exit, 0, 'the generated harness passes') or diag("stdout:\n$stdout\nstderr:\n$stderr");
unlike($stdout, qr/^not ok/m, 'no generated test failed');

# The top-level schema would call pick([...]); only the transform's own basic
# case passes the two scalars it declares, so this line is the transform's.
like(
	$stdout,
	qr/^ok \d+ - pick\(test_value, test_value\) survives \(position test\) - basic list test$/m,
	"the transform's own basic case ran with the transform's fields"
);
my $transform_cases = () = $stdout =~ /^ok \d+ - pick\(.*\) survives \(position test\) - list$/mg;
cmp_ok($transform_cases, '>=', 2, "the transform's generated cases ran ($transform_cases cases)");

# A transform that only adjusts a field already in the top-level schema must
# not replace the top-level input: doing so would drop left and right, and
# join_pair() would die.  The assertion is on the whole call shape, not on a
# generated value, so it cannot pass by accident.
my $narrowing = File::Spec->catfile($lib, 'Transform', 'ExistingField.pm');
open(my $nfh, '>', $narrowing) or die "cannot write $narrowing: $!";
print {$nfh} <<'MODULE';
package Transform::ExistingField;
use strict;
use warnings;

# Every call needs all three fields; 'sep' on its own is not a valid call.
sub join_pair
{
	my (%args) = @_;

	die 'join_pair: left is required' unless defined $args{left};
	die 'join_pair: right is required' unless defined $args{right};
	my $sep = defined $args{sep} ? $args{sep} : ',';

	return join($sep, $args{left}, $args{right});
}
1;
MODULE
close($nfh) or die "cannot close $narrowing: $!";

my $narrow_harness = File::Spec->catfile($dir, 'transform_existing_field.t');

lives_ok {
	App::Test::Generator->generate(
		schema => {
			module   => 'Transform::ExistingField',
			function => 'join_pair',
			input    => {
				left  => { type => 'string', optional => 0 },
				right => { type => 'string', optional => 0 },
				sep   => { type => 'string', optional => 0 },
			},
			output => { type => 'string' },
			config => {
				test_empty    => 0,
				test_nuls     => 0,
				test_non_ascii => 0,
				test_security => 0,
				test_undef    => 0,
			},
			transforms => {
				narrow => {
					input  => { sep => { type => 'string', optional => 0 } },
					output => { type => 'string' },
				},
			},
		},
		output_file => $narrow_harness,
		quiet       => 1,
	);
} 'generate() accepts a transform that narrows an existing field';

ok(-f $narrow_harness, 'the narrowing harness was written');

my ($narrow_out, $narrow_err) = ('', '');
run3([$^X, $narrow_harness], \undef, \$narrow_out, \$narrow_err);
my $narrow_exit = $? >> 8;

is($narrow_exit, 0, 'a transform that only adjusts an existing field keeps the top-level call shape')
	or diag("stdout:\n$narrow_out\nstderr:\n$narrow_err");
unlike($narrow_out, qr/^not ok/m, 'no generated test failed');

# The transform's cases are the tail of the harness, introduced by this
# diagnostic.  Every one of them calls join_pair with the top-level fields,
# so a regression that swapped in the transform's input would die here.
# The transform loop announces itself and then runs its basic case
# unconditionally, so this diagnostic plus a clean exit proves that case ran
# and that it was called with all three top-level fields.
like($narrow_err, qr/^# Run 1 transform tests$/m, 'the narrowing transform was exercised');

done_testing();
