#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/mutation_feedback.t - surviving mutants feed back into harness
# generation as boundary constraints.
#
# A numeric-boundary survivor is traced to the comparison it mutated and
# becomes a min/max constraint on the matching input field, so the harness
# generates values on both sides of the boundary the test suite missed.
# ======================================================================

use Test::Most;
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3 qw(run3);
use JSON::MaybeXS qw(encode_json);
use App::Test::Generator;
use App::Test::Generator::Mutation::Feedback;

my $dir = tempdir(CLEANUP => 1);
my $lib = File::Spec->catdir($dir, 'lib');
make_path(File::Spec->catdir($lib, 'Feedback'));

my $source = <<'MODULE';
package Feedback::Target;
use strict;
use warnings;

sub label
{
	my ($count) = @_;

	die 'count must be greater than 10'
		unless defined($count) && !ref($count) && ($count > 10);
	die 'count must be less than 20'
		unless !ref($count) && ($count < 20);

	return "count=$count";
}
1;
MODULE

my $module_file = File::Spec->catfile($lib, 'Feedback', 'Target.pm');
open(my $fh, '>', $module_file) or die "cannot write $module_file: $!";
print {$fh} $source;
close($fh) or die "cannot close $module_file: $!";

# Locate the comparisons so the synthetic survivors point at real lines.
my ($low_line, $high_line);
my $line_number = 0;
foreach my $line (split(/\n/, $source)) {
	$line_number++;
	$low_line  = $line_number if $line =~ /\$count > 10/;
	$high_line = $line_number if $line =~ /\$count < 20/;
}
ok($low_line, 'fixture has the lower-bound comparison');
ok($high_line, 'fixture has the upper-bound comparison');

sub _survivor
{
	my (%args) = @_;

	return {
		id          => $args{id},
		file        => $args{file} // 'lib/Feedback/Target.pm',
		line        => $args{line},
		description => $args{description},
		status      => 'Survived',
		difficulty  => 'HIGH',
		priority    => 3,
		hint        => 'Likely missing edge-case test (boundary value)',
	};
}

my @survivors = (
	_survivor(
		id          => "NUM_BOUNDARY_${low_line}_9_<",
		line        => $low_line,
		description => 'Numeric boundary flip > to <',
	),
	_survivor(
		id          => "NUM_BOUNDARY_${high_line}_9_<=",
		line        => $high_line,
		description => 'Numeric boundary flip < to <=',
	),
	_survivor(
		id          => 'COND_INV_100_2',
		line        => 100,
		description => 'Invert condition if to unless',
	),
	# Belongs to a different module, so must not influence this schema.
	_survivor(
		id          => 'NUM_BOUNDARY_42_5_<',
		file        => 'lib/Other/Module.pm',
		line        => 42,
		description => 'Numeric boundary flip > to <',
	),
);

my $results_file = File::Spec->catfile($dir, 'mutation.json');
open(my $json_fh, '>', $results_file) or die "cannot write $results_file: $!";
print {$json_fh} encode_json({
	score          => 50,
	total          => 8,
	killed_count   => 4,
	survived_count => scalar(@survivors),
	killed         => [],
	survived       => \@survivors,
});
close($json_fh) or die "cannot close $results_file: $!";

sub _schema
{
	return {
		module   => 'Feedback::Target',
		function => 'label',
		input    => {
			count => {
				type     => 'integer',
				optional => 0,
				position => 0,
			},
		},
		output => { type => 'string' },
		config => {
			test_empty     => 0,
			test_nuls      => 0,
			test_non_ascii => 0,
			test_security  => 0,
			test_undef     => 0,
		},
	};
}

# Survivor file paths in the mutation report are relative to the project
# root the mutation run used, so generate from the fixture's root.
sub _in_dir
{
	my ($new_dir, $code) = @_;

	my $old_dir = getcwd();
	chdir($new_dir) or die "cannot chdir to $new_dir: $!";
	my @return = eval { $code->() };
	my $error = $@;
	chdir($old_dir) or die "cannot chdir back to $old_dir: $!";
	die $error if $error;

	return wantarray ? @return : $return[0];
}

sub _run
{
	my ($file) = @_;

	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join(':', grep { defined($_) && length($_) } ($lib, $ENV{PERL5LIB}));
	run3([$^X, $file], \undef, \$stdout, \$stderr);

	return ($? >> 8, "$stdout$stderr");
}

subtest 'survivors are filtered to the schema module' => sub {
	my $feedback = App::Test::Generator::Mutation::Feedback->new(
		mutation_results => $results_file,
		module           => 'Feedback::Target',
		source_root      => $dir,
	);

	my $survivors = $feedback->survivors;
	is(scalar(@{$survivors}), 3, 'only this module\'s survivors are used');
	is_deeply(
		[ map { $_->{id} } @{$survivors} ],
		[ "NUM_BOUNDARY_${low_line}_9_<", "NUM_BOUNDARY_${high_line}_9_<=", 'COND_INV_100_2' ],
		'survivors keep their report order',
	);
};

subtest 'numeric comparisons become boundary constraints' => sub {
	my $feedback = App::Test::Generator::Mutation::Feedback->new(
		mutation_results => $results_file,
		module           => 'Feedback::Target',
		source_root      => $dir,
	);

	my @proposals = @{ $feedback->proposals };
	is(scalar(@proposals), 3, 'one proposal per survivor');

	my %by_kind;
	push @{ $by_kind{ $_->{kind} } }, $_ for @proposals;

	is(scalar(@{ $by_kind{constraint} }), 2, 'two automatic constraints');
	is(scalar(@{ $by_kind{manual} }), 1, 'the conditional inversion needs a hand-written test');

	my ($lower) = grep { $_->{constraint}{min} } @{ $by_kind{constraint} };
	is($lower->{parameter}, 'count', 'the bounded parameter is recovered from the source');
	is_deeply($lower->{constraint}, { min => 11 }, '$count > 10 becomes min => 11');
	is_deeply($lower->{values}, [ 9, 10, 11 ], 'values either side of the boundary are proposed');

	my ($upper) = grep { $_->{constraint}{max} } @{ $by_kind{constraint} };
	is_deeply($upper->{constraint}, { max => 19 }, '$count < 20 becomes max => 19');
};

subtest 'constraints are merged without replacing existing ones' => sub {
	my $feedback = App::Test::Generator::Mutation::Feedback->new(
		mutation_results => $results_file,
		module           => 'Feedback::Target',
		source_root      => $dir,
	);

	my $schema = _schema();
	$schema->{input}{count}{max} = 25;

	my $applied = $feedback->apply_to_schema($schema);
	is(scalar(@{$applied}), 1, 'only the absent constraint is added');
	is($schema->{input}{count}{min}, 11, 'the proposed minimum is set');
	is($schema->{input}{count}{max}, 25, 'the existing maximum is untouched');
	is($schema->{input}{count}{_constraint_source}{min}, 'mutation',
		'the new constraint records where it came from');
	ok(!exists($schema->{input}{count}{_constraint_source}{max}),
		'the existing constraint keeps its own provenance');
};

subtest 'a generated harness exercises the boundary and passes' => sub {
	my $file = File::Spec->catfile($dir, 'feedback_harness.t');

	lives_ok {
		_in_dir($dir, sub {
			App::Test::Generator->generate(
				schema           => _schema(),
				mutation_results => $results_file,
				output_file      => $file,
				quiet            => 1,
			);
		});
	} 'generate() accepts mutation results';

	open(my $harness_fh, '<', $file) or die "cannot read $file: $!";
	my $harness = do { local $/; <$harness_fh> };
	close($harness_fh);

	like($harness, qr/\bmin => 11\b/, 'the harness schema carries the proposed minimum');
	like($harness, qr/\bmax => 19\b/, 'the harness schema carries the proposed maximum');
	like($harness, qr/\$min - 1/, 'the rejected side of the lower boundary is generated');
	like($harness, qr/\$max \+ 1/, 'the rejected side of the upper boundary is generated');

	my ($exit, $output) = _run($file);
	is($exit, 0, 'the harness passes against the unmutated module') or diag($output);
};

subtest 'the CLI accepts --mutation-results' => sub {
	my $yaml = File::Spec->catfile($dir, 'feedback.yaml');
	open(my $yaml_fh, '>', $yaml) or die "cannot write $yaml: $!";
	print {$yaml_fh} <<'YAML';
---
module: Feedback::Target
function: label
input:
  count:
    type: integer
    optional: 0
    position: 0
output:
  type: string
config:
  test_empty: 0
  test_nuls: 0
  test_non_ascii: 0
  test_security: 0
  test_undef: 0
YAML
	close($yaml_fh) or die "cannot close $yaml: $!";

	my $out = File::Spec->catfile($dir, 'feedback_cli.t');
	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join(':', grep { defined($_) && length($_) } ($lib, $ENV{PERL5LIB}));
	my $generator = File::Spec->rel2abs(File::Spec->catfile('bin', 'fuzz-harness-generator'));
	_in_dir($dir, sub {
		run3(
			[$^X, $generator, '--mutation-results', $results_file, '-o', $out, $yaml],
			\undef, \$stdout, \$stderr,
		);
	});

	is($? >> 8, 0, 'the generator exits successfully') or diag("$stdout$stderr");
	like($stdout, qr/Mutation feedback: 3 survivor\(s\), 2 constraint\(s\) applied/,
		'the applied constraints are summarised');
	like($stdout, qr/manual: lib\/Feedback\/Target\.pm/,
		'the survivor that needs a hand-written test is listed');
	ok(-f $out, 'the harness was written');

	my ($exit, $run_output) = _run($out);
	is($exit, 0, 'the CLI-generated harness passes') or diag($run_output);
};

done_testing();
