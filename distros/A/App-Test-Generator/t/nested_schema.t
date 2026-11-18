#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/nested_schema.t - arrayref and hashref parameters can describe their
# elements, so generated valid data is not homogeneous filler.
#
# Each fixture routine rejects any value that does not match its nested
# schema, so a passing harness run proves the generated elements carry the
# declared type, bounds and shape.  Recursion, fixed hash keys and object
# elements are covered.
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
make_path(File::Spec->catdir($lib, 'Nested'));

my $module = File::Spec->catfile($lib, 'Nested', 'Data.pm');
open(my $fh, '>', $module) or die "cannot write $module: $!";
print {$fh} <<'MODULE';
package Nested::Data;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);

sub words
{
	my ($words) = @_;

	croak('words: expected an arrayref') unless ref($words) eq 'ARRAY';
	croak('words: one to three words') unless @{$words} >= 1 && @{$words} <= 3;
	foreach my $word (@{$words}) {
		croak('words: each word must be a string') unless defined($word) && !ref($word);
		croak('words: each word must be three to six characters')
			unless length($word) >= 3 && length($word) <= 6;
	}

	return join(' ', @{$words});
}

sub scores
{
	my ($scores) = @_;

	croak('scores: expected a hashref') unless ref($scores) eq 'HASH';
	croak('scores: at least one score is required') unless keys %{$scores};
	foreach my $name (keys %{$scores}) {
		my $score = $scores->{$name};
		croak('scores: a score must be an integer')
			unless defined($score) && !ref($score) && $score =~ /^\d+$/;
		croak('scores: a score must be between 0 and 100')
			unless $score >= 0 && $score <= 100;
	}

	return scalar keys %{$scores};
}

sub record
{
	my ($record) = @_;

	croak('record: expected a hashref') unless ref($record) eq 'HASH';
	foreach my $key (qw(name age)) {
		croak("record: $key is required") unless exists $record->{$key};
	}
	croak('record: name must be two to twenty characters')
		unless defined($record->{name}) && !ref($record->{name})
			&& length($record->{name}) >= 2 && length($record->{name}) <= 20;
	croak('record: age must be an integer')
		unless defined($record->{age}) && !ref($record->{age})
			&& looks_like_number($record->{age})
			&& $record->{age} == int($record->{age});

	return $record->{name};
}

sub grid
{
	my ($grid) = @_;

	croak('grid: expected an arrayref') unless ref($grid) eq 'ARRAY';
	croak('grid: one or two rows') unless @{$grid} >= 1 && @{$grid} <= 2;
	foreach my $row (@{$grid}) {
		croak('grid: each row must be an arrayref') unless ref($row) eq 'ARRAY';
		croak('grid: one or two cells per row') unless @{$row} >= 1 && @{$row} <= 2;
		foreach my $cell (@{$row}) {
			croak('grid: each cell must be 0 to 9')
				unless defined($cell) && !ref($cell) && $cell =~ /^\d+$/ && $cell <= 9;
		}
	}

	return scalar @{$grid};
}

sub things
{
	my ($things) = @_;

	croak('things: expected an arrayref') unless ref($things) eq 'ARRAY';
	croak('things: at least one thing is required') unless @{$things};
	foreach my $thing (@{$things}) {
		croak('things: every element must be a Nested::Thing')
			unless ref($thing) && $thing->isa('Nested::Thing');
		croak('things: a thing must have a label') unless defined($thing->label);
	}

	return scalar @{$things};
}

package Nested::Thing;

sub new { return bless {}, shift }
sub label { return 'thing' }

1;
MODULE
close($fh) or die "cannot close $module: $!";

sub _generate
{
	my ($name, $function, $input, $output_type) = @_;

	my $file = File::Spec->catfile($dir, "$name.t");
	lives_ok {
		App::Test::Generator->generate(
			schema => {
				module   => 'Nested::Data',
				function => $function,
				input    => $input,
				output   => { type => $output_type },
				config   => {
					test_empty     => 0,
					test_nuls      => 0,
					test_non_ascii => 0,
					test_security  => 0,
					test_undef     => 0,
				},
			},
			output_file => $file,
			quiet       => 1,
		);
	} "$name: generate() accepts the nested schema";

	ok(-f $file, "$name: the harness was written");
	return $file;
}

sub _run
{
	my ($file) = @_;

	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join($Config{path_sep}, $lib, $ENV{PERL5LIB} // '');
	run3([$^X, $file], \undef, \$stdout, \$stderr);

	return ($? >> 8, "$stdout$stderr");
}

subtest 'array elements carry their own string bounds' => sub {
	my $file = _generate(
		'nested_words', 'words',
		{
words => {
				type     => 'arrayref',,
				optional => 0,
				position => 0,
				min      => 1,
				max      => 3,
				schema   => { type => 'string', min => 3, max => 6 },
			},
		},
		'string'
	);

	my ($exit, $output) = _run($file);
	is($exit, 0, 'the routine accepts every generated element') or diag($output);
	unlike($output, qr/^not ok/m, 'no generated test failed');
};

subtest 'hash values carry their own numeric bounds' => sub {
	my $file = _generate(
		'nested_scores', 'scores',
		{
scores => {
				type     => 'hashref',,
				optional => 0,
				position => 0,
				schema   => { type => 'integer', min => 0, max => 100 },
			},
		},
		'integer'
	);

	my ($exit, $output) = _run($file);
	is($exit, 0, 'the routine accepts every generated value') or diag($output);
	unlike($output, qr/^not ok/m, 'no generated test failed');
};

subtest 'a hash schema of fixed keys generates exactly those keys' => sub {
	my $file = _generate(
		'nested_record', 'record',
		{
record => {
				type     => 'hashref',,
				optional => 0,
				position => 0,
									schema   => {
					name => { type => 'string', min => 2, max => 20 },
					# A bare type name is shorthand for { type => ... }.
					age  => 'integer',
				},
			},
		},
		'string'
	);

	my ($exit, $output) = _run($file);
	is($exit, 0, 'the routine finds both declared keys with valid values') or diag($output);
	unlike($output, qr/^not ok/m, 'no generated test failed');
};

subtest 'element schemas nest recursively' => sub {
	my $file = _generate(
		'nested_grid', 'grid',
		{
grid => {
				type     => 'arrayref',,
				optional => 0,
				position => 0,
				min      => 1,
				max      => 2,
				schema   => {
					type   => 'arrayref',
					min    => 1,
					max    => 2,
					schema => { type => 'integer', min => 0, max => 9 },
				},
			},
		},
		'integer'
	);

	my ($exit, $output) = _run($file);
	is($exit, 0, 'the routine accepts a grid of constrained integers') or diag($output);
	unlike($output, qr/^not ok/m, 'no generated test failed');
};

subtest 'object element schemas build real objects' => sub {
	my $file = _generate(
		'nested_things', 'things',
		{
things => {
				type     => 'arrayref',,
				optional => 0,
				position => 0,
				min      => 1,
				schema   => { type => 'object', isa => 'Nested::Thing' },
			},
		},
		'integer'
	);

	my ($exit, $output) = _run($file);
	is($exit, 0, 'the routine receives Nested::Thing objects') or diag($output);
	unlike($output, qr/^not ok/m, 'no generated test failed');
};

subtest 'an invalid element schema is rejected before generation' => sub {
	throws_ok {
		App::Test::Generator->generate(
			schema => {
				module   => 'Nested::Data',
				function => 'words',
				input    => {
					words => { type => 'arrayref', schema => { type => 'bogus' } },
				},
				output => { type => 'string' },
			},
			output_file => File::Spec->catfile($dir, 'bad_type.t'),
			quiet       => 1,
		);
	} qr/Invalid element type 'bogus' for 'words'/, 'an unknown element type is rejected';

	throws_ok {
		App::Test::Generator->generate(
			schema => {
				module   => 'Nested::Data',
				function => 'things',
				input    => {
					things => { type => 'arrayref', schema => { type => 'object' } },
				},
				output => { type => 'integer' },
			},
			output_file => File::Spec->catfile($dir, 'bad_object.t'),
			quiet       => 1,
		);
	} qr/Object element schema for 'things' needs 'isa' or 'can'/,
		'an object element without a class or method is rejected';
};

done_testing();
