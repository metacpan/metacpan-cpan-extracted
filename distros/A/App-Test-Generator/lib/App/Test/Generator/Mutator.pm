package App::Test::Generator::Mutator;

use strict;
use warnings;
use Carp qw(croak);
use Config;
use File::Copy qw(copy);
use File::Copy::Recursive qw(dircopy);
use File::Spec;
use File::Temp qw(tempdir);
use PPI;
use Readonly;

use App::Test::Generator::Mutation::BooleanNegation;
use App::Test::Generator::Mutation::ConditionalInversion;
use App::Test::Generator::Mutation::NumericBoundary;
use App::Test::Generator::Mutation::ReturnUndef;

# --------------------------------------------------
# Valid mutation level values
# --------------------------------------------------
Readonly my $LEVEL_FULL => 'full';
Readonly my $LEVEL_FAST => 'fast';

# --------------------------------------------------
# Default values for optional constructor arguments
# --------------------------------------------------
Readonly my $DEFAULT_LIB_DIR => 'lib';
Readonly my $DEFAULT_MUTATION_LEVEL => $LEVEL_FULL;

our $VERSION = '0.44';

=head1 NAME

App::Test::Generator::Mutator - Generate and apply mutation tests

=head1 VERSION

Version 0.44

=head1 DESCRIPTION

B<App::Test::Generator::Mutator> is a mutation engine that programmatically
alters Perl source files to evaluate the effectiveness of a project's test
suite. It analyses modules, generates systematic code mutations (such as
conditional inversions, logical operator changes, and numeric boundary
flips), and applies them within an isolated workspace so tests can be
executed safely against each modified variant.

By tracking which mutants are killed (cause tests to fail) versus those that
survive (tests still pass), the module enables calculation of a mutation
score, providing a quantitative measure of how well the test suite detects
unintended behavioural changes.

=head2 new

Construct a new Mutator for a given source file.

    my $mutator = App::Test::Generator::Mutator->new(
        file           => 'lib/My/Module.pm',
        lib_dir        => 'lib',
        mutation_level => 'full',
    );

=head3 Arguments

=over 4

=item * C<file>

Path to the Perl source file to mutate. Required. Must exist on disk.

=item * C<lib_dir>

Root library directory. Optional - defaults to C<lib>.

=item * C<mutation_level>

Controls the breadth of mutation. C<full> applies all mutations;
C<fast> deduplicates and removes redundant mutants first.
Optional - defaults to C<full>.

=back

=head3 Returns

A blessed hashref. Croaks if C<file> is missing or does not exist.

=head3 API specification

=head4 input

    {
        file           => { type => SCALAR },
        lib_dir        => { type => SCALAR, optional => 1 },
        mutation_level => { type => SCALAR, optional => 1 },
    }

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::Mutator',
    }

=cut

sub new {
	my ($class, %args) = @_;

	# file is required and must exist on disk
	croak 'file required' unless defined $args{file};
	croak "file not found: $args{file}" unless -f $args{file};

	return bless {
		file           => $args{file},
		lib_dir        => $args{lib_dir}        || $DEFAULT_LIB_DIR,
		mutation_level => $args{mutation_level} || $DEFAULT_MUTATION_LEVEL,

		# Instantiate all registered mutation strategies
		mutations => [
			App::Test::Generator::Mutation::BooleanNegation->new(),
			App::Test::Generator::Mutation::ReturnUndef->new(),
			App::Test::Generator::Mutation::NumericBoundary->new(),
			App::Test::Generator::Mutation::ConditionalInversion->new(),
		],
	}, $class;
}

=head2 generate_mutants

Parse the target file and generate all mutants by running each registered
mutation strategy against the PPI document.

    my @mutants = $mutator->generate_mutants();

=head3 Arguments

None beyond C<$self>.

=head3 Returns

=head3 Returns

A list of L<App::Test::Generator::Mutant> objects. In C<fast> mode,
redundant and duplicate mutants are removed before returning.
Lines within C<## MUTANT_SKIP_BEGIN> / C<## MUTANT_SKIP_END> annotation
blocks are excluded from the candidate list entirely.
After this method returns,
C<$self-E<gt>{skip_lines}> contains a hashref mapping excluded
line numbers to 1.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutator' },
    }

=head4 output

    {
        type     => ARRAYREF,
        elements => { type => OBJECT, isa => 'App::Test::Generator::Mutant' },
    }

=cut

sub generate_mutants {
	my $self = $_[0];

	# Parse the target file into a PPI document
	my $doc = PPI::Document->new($self->{file}) or croak "Unable to parse $self->{file}";

	# Build set of lines excluded by ## MUTANT_SKIP_BEGIN / ## MUTANT_SKIP_END
	my %skip_lines;
	my $in_skip  = 0;
	my $skip_start = 0;
	my $line_num = 0;

	for my $line (split /\n/, $doc->serialize()) {
		$line_num++;

		# Match only lines where the annotation is the entire content —
		# prevents false positives in comments or POD that mention the tag
		if($line =~ /^\s*##\s*MUTANT_SKIP_BEGIN\s*$/) {
			croak "$self->{file}: MUTANT_SKIP_BEGIN at line $line_num with no prior MUTANT_SKIP_END"
				if $in_skip;
			$in_skip    = 1;
			$skip_start = $line_num;
		}
		$skip_lines{$line_num} = 1 if $in_skip;

		# Match only lines where the annotation is the entire content —
		# prevents false positives in comments or POD that mention the tag
		if($line =~ /^\s*##\s*MUTANT_SKIP_END\s*$/) {
			croak "$self->{file}: MUTANT_SKIP_END at line $line_num with no matching MUTANT_SKIP_BEGIN"
				unless $in_skip;
			$in_skip = 0;
		}
	}
	# Unclosed MUTANT_SKIP_BEGIN is fatal
	croak "$self->{file}: MUTANT_SKIP_BEGIN at line $skip_start has no matching MUTANT_SKIP_END" if $in_skip;

	# Store skip lines for use by the report generator
	$self->{skip_lines} = \%skip_lines;

	my @mutants;

	# Run each registered mutation strategy against the document,
	# excluding any candidates on skip-annotated lines. applies_to()
	# is a cheap pre-filter -- skip the mutate() walk entirely for
	# strategies that have nothing to match in this document.
	for my $mutation (@{$self->{mutations}}) {
		next unless $mutation->applies_to($doc);
		push @mutants, grep { !$skip_lines{$_->line} } $mutation->mutate($doc);
	}

	# In fast mode deduplicate and remove redundant mutants
	if($self->{mutation_level} eq $LEVEL_FAST) {
		return @{_dedup_mutants(\@mutants)};
	}

	return @mutants;
}

=head2 prepare_workspace

Prepare an isolated temporary workspace for a single mutation test run.

The entire C<lib_dir> tree is copied into the workspace so that all module
dependencies resolve correctly when the test suite runs against the mutant.
Only after this copy is complete is the single target file overwritten by
C<apply_mutant>.

    my $workspace = $mutator->prepare_workspace();
    $mutator->apply_mutant($mutant);
    local $ENV{PERL5LIB} = "$workspace/lib";
    my $survived = (system('prove', 't') == 0);

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A string containing the absolute path to the temporary directory created.
The directory is automatically removed when the object goes out of scope
via L<File::Temp>'s C<CLEANUP =E<gt> 1> behaviour.

=head3 Side effects

Creates a temporary directory. Recursively copies C<lib_dir> into it.
Sets C<< $self->{workspace} >> and C<< $self->{relative} >>.

=head3 Notes

Call C<prepare_workspace> once per file, then C<apply_mutant> once per
mutant within that file. Do not store the returned path beyond the
lifetime of the enclosing scope.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutator' },
    }

=head4 output

    {
        type => SCALAR,
    }

=cut

sub prepare_workspace {
	my $self = $_[0];

	# Create a self-cleaning temporary directory
	my $tmp = tempdir(CLEANUP => 1);

	# Normalise lib_dir to its final component so workspace paths
	# are relative regardless of whether an absolute path was passed in
	my $lib_basename = (File::Spec->splitdir($self->{lib_dir}))[-1];

	# Derive the file's path relative to lib_dir for use by apply_mutant
	my $relative = $self->{file};
	$relative =~ s/^\Q$self->{lib_dir}\E\/?//;

	# Copy the entire lib tree so all dependencies resolve in the workspace
	dircopy($self->{lib_dir}, File::Spec->catfile($tmp, $lib_basename)) or croak "dircopy failed: $!";

	$self->{workspace} = $tmp;
	$self->{relative}  = $relative;
	$self->{lib_dir}   = $lib_basename;	# normalise for apply_mutant

	return $tmp;
}

=head2 apply_mutant

Apply a single mutant's transform to the target file in the workspace.

    $mutator->apply_mutant($mutant);

=head3 Arguments

=over 4

=item * C<$mutant>

An L<App::Test::Generator::Mutant> object whose C<transform> closure
will be applied to the workspace copy of the target file.

=back

=head3 Returns

Nothing. Modifies the workspace copy of the target file in place.

=head3 Side effects

Overwrites the target file in the workspace with the mutated version.

=head3 API specification

=head4 input

    {
        self   => { type => OBJECT, isa => 'App::Test::Generator::Mutator' },
        mutant => { type => OBJECT, isa => 'App::Test::Generator::Mutant'  },
    }

=head4 output

    { type => UNDEF }

=cut

sub apply_mutant {
	my ($self, $mutant) = @_;

	# Workspace must be prepared before applying any mutant
	my $workspace = $self->{workspace}
		or croak 'Workspace not prepared — call prepare_workspace first';

	my $relative  = $self->{relative}
		or croak 'Relative path not set — call prepare_workspace first';

	# Construct the full path to the file in the workspace
	my $target = File::Spec->catfile(
		$workspace,
		$self->{lib_dir},
		$relative,
	);

	# Parse the workspace copy and apply the mutation transform
	my $doc = PPI::Document->new($target) or croak "Failed to parse $target";

	$mutant->transform->($doc);

	$doc->save($target);
}

=head2 run_tests

Run the test suite against the current workspace and return whether all
tests passed.

    my $survived = $mutator->run_tests();

=head3 Arguments

None beyond C<$self>.

=head3 Returns

1 if all tests passed (mutant survived), 0 if any test failed (mutant
killed).

=head3 Side effects

Executes an external process running the test suite.

=head3 Notes

Uses C<prove> found on PATH. Sets C<PERL5LIB> to include the workspace
lib directory before running.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutator' },
    }

=head4 output

    { type => SCALAR }

=cut

sub run_tests {
	my $self = $_[0];

	# Locate prove on PATH — fall back to bare 'prove' and let shell find it
	my $prove = File::Spec->catfile($Config{bin}, 'prove');
	$prove = 'prove' unless -x $prove;

	return system($prove, '-l', 't') == 0;
}

# --------------------------------------------------
# _dedup_mutants
#
# Purpose:    Remove duplicate and redundant mutants
#             from a list, used in fast mutation mode
#             to reduce the number of mutants to run.
#
# Entry:      $mutants - arrayref of Mutant objects.
#
# Exit:       Returns an arrayref of deduplicated
#             Mutant objects.
#
# Side effects: None.
#
# Notes:      Deduplication key uses line, original,
#             and description rather than the transform
#             coderef, which is not stable as a string.
# --------------------------------------------------
sub _dedup_mutants {
	my ($mutants) = @_;
	my @rc;
	my %seen;

	for my $m (@{$mutants}) {
		# Build a stable key from metadata — not from the coderef
		my $key = join '|',
			$m->line        // '',
			$m->original    // '',
			$m->description // '';

		next if $seen{$key}++;
		next if _is_redundant_mutation($m);

		push @rc, $m;
	}

	return \@rc;
}

# --------------------------------------------------
# _is_redundant_mutation
#
# Return true if a mutant is considered
#     redundant and should be skipped in fast
#     mutation mode.
#
# Entry:      $m - a Mutant object.
#
# Exit:       Returns 1 if redundant, 0 otherwise.
#
# Notes:      Checks for arithmetic no-ops, double
#             negation inside conditionals, boolean
#             literal flips, mutations inside comments,
#             and equivalent numeric comparisons.
#             Does not compare transform coderefs —
#             they are not meaningful as strings.
# --------------------------------------------------
sub _is_redundant_mutation {
	my ($m) = @_;

	my $orig = $m->original // '';

	# Arithmetic no-ops add nothing to mutation coverage
	return 1 if $orig =~ /\+\s*0$/;
	return 1 if $orig =~ /-\s*0$/;

	# Double negation inside conditionals forces boolean context
	# in Perl and is not a meaningful mutation
	if($m->context && $m->context eq 'conditional') {
		return 1 if $orig =~ /^\!\!/;
	}

	# Boolean literal flip on a standalone 1 or 0 is trivial
	return 1 if $orig =~ /^\s*(?:1|0)\s*$/;

	# Mutations inside comments are unreachable code
	return 1 if $m->line_content && $m->line_content =~ /^\s*#/;

	return 0;
}

=head1 SEE ALSO

=over 4

=item C<bin/test-generator-mutate>

=item L<Devel::Mutator>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

1;
