package App::Test::Generator::Mutator;

use 5.036;
use autodie qw(:io);    # covers open/close/read/write; excludes system (which legitimately fails)
use Carp qw(croak);
use Config;
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
Readonly my $DEFAULT_LIB_DIR        => 'lib';
Readonly my $DEFAULT_MUTATION_LEVEL => $LEVEL_FULL;

# --------------------------------------------------
# Error message constants — named so test code can
# match against them without duplicating the literal
# --------------------------------------------------
Readonly my $ERR_FILE_REQUIRED     => 'file required';
Readonly my $ERR_WORKSPACE_NOT_SET => 'Workspace not prepared -- call prepare_workspace first';
Readonly my $ERR_RELATIVE_NOT_SET  => 'Relative path not set -- call prepare_workspace first';

our $VERSION = '0.46';

=head1 NAME

App::Test::Generator::Mutator - Generate and apply mutation tests

=head1 VERSION

Version 0.46

=head1 SYNOPSIS

    use App::Test::Generator::Mutator;

    my $mutator = App::Test::Generator::Mutator->new(
        file           => 'lib/My/Module.pm',
        lib_dir        => 'lib',
        mutation_level => 'fast',
    );

    my $mutants = $mutator->generate_mutants();
    printf "Generated %d mutants\n", scalar @{$mutants};

    my $workspace = $mutator->prepare_workspace();

    for my $m (@{$mutants}) {
        $mutator->apply_mutant($m);
        if($mutator->run_tests()) {
            print "SURVIVED: ${\$m->description}\n";
        } else {
            print "KILLED:   ${\$m->description}\n";
        }
    }

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

=head3 EXAMPLE

    my $m = App::Test::Generator::Mutator->new(
        file           => 'lib/Acme/Widget.pm',
        mutation_level => 'fast',
    );

=head3 MESSAGES

=over 4

=item C<file required>

C<file> was not supplied.

=item C<< file not found: PATH >>

C<file> was supplied but does not exist on disk.

=back

=head3 FORMAL SPECIFICATION

Pre:  C<file> is defined ∧ C<-f file>

Post: C<ref(result) eq 'App::Test::Generator::Mutator'>
      ∧ C<result-E<gt>{file} eq file>
      ∧ C<result-E<gt>{mutation_level} ∈ {full, fast}>

=cut

sub new {
	my ($class, %args) = @_;

	# file is required and must exist on disk
	croak $ERR_FILE_REQUIRED unless defined $args{file};
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

    my $mutants = $mutator->generate_mutants();   # scalar context → arrayref
    for my $m (@{$mutants}) { ... }

    my @mutants = $mutator->generate_mutants();   # list context → flat list (backward-compat)

=head3 Arguments

None beyond C<$self>.

=head3 Returns

An arrayref of L<App::Test::Generator::Mutant> objects. In C<fast> mode,
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

=head3 EXAMPLE

    my $mutants = $mutator->generate_mutants();
    printf "%d mutants generated\n", scalar @{$mutants};

    for my $m (@{$mutants}) {
        printf "line %d: %s\n", $m->line, $m->description;
    }

=head3 MESSAGES

=over 4

=item C<< Unable to parse FILE >>

PPI could not parse the source file (syntax error or unreadable file).
FILE is the path passed to C<new>.

=item C<< FILE: MUTANT_SKIP_BEGIN at line N with no prior MUTANT_SKIP_END >>

A C<## MUTANT_SKIP_BEGIN> marker was found while already inside a skip block.

=item C<< FILE: MUTANT_SKIP_END at line N with no matching MUTANT_SKIP_BEGIN >>

A C<## MUTANT_SKIP_END> marker was found with no preceding C<## MUTANT_SKIP_BEGIN>.

=item C<< FILE: MUTANT_SKIP_BEGIN at line N has no matching MUTANT_SKIP_END >>

The source file ended while still inside a skip block.

=back

=head3 FORMAL SPECIFICATION

Pre:  C<prepare_workspace> need not have been called before this method.

Post: C<ref(result) eq 'ARRAY'>
      ∧ C<∀ m ∈ result: ref(m) eq 'App::Test::Generator::Mutant'>
      ∧ C<∀ m ∈ result: ¬ skip_lines{m->line}>

=head3 PSEUDOCODE

    parse file with PPI
    scan lines for MUTANT_SKIP_BEGIN / MUTANT_SKIP_END pairs → skip_lines
    for each registered mutation strategy:
        skip if strategy does not apply_to(doc)
        for each mutant from strategy->mutate(doc):
            include unless mutant.line ∈ skip_lines
    if mutation_level == 'fast':
        deduplicate and remove redundant mutants
    return arrayref (or flat list in list context)

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

	# In fast mode deduplicate and remove redundant mutants before returning.
	# Returns arrayref in scalar context and a flat list in list context so
	# existing callers (my @m = generate_mutants()) continue to work unchanged.
	my $result = $self->{mutation_level} eq $LEVEL_FAST
		? _dedup_mutants(\@mutants)
		: \@mutants;

	return wantarray ? @{$result} : $result;
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
Sets C<< $self->{_workspace} >>, C<< $self->{_relative} >>, and
C<< $self->{_lib_basename} >>. Does not modify C<< $self->{lib_dir} >>.

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

=head3 EXAMPLE

    my $workspace = $mutator->prepare_workspace();
    # workspace is an absolute temp dir path
    # original lib_dir value is unchanged
    printf "original lib_dir still: %s\n", $mutator->{lib_dir};

=head3 MESSAGES

=over 4

=item C<dircopy failed: $!>

The C<lib_dir> tree could not be copied into the temporary workspace directory,
usually a permissions error.

=back

=head3 FORMAL SPECIFICATION

Pre:  C<-d self-E<gt>{lib_dir}>
      ∧ C<self-E<gt>{file}> begins with C<self-E<gt>{lib_dir}>

Post: C<-d result>
      ∧ C<self-E<gt>{_workspace} eq result>
      ∧ C<self-E<gt>{lib_dir}> unchanged

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

	# Store normalised state under private keys — do NOT mutate lib_dir,
	# which callers may inspect after this call expecting the original value.
	$self->{_workspace}    = $tmp;
	$self->{_relative}     = $relative;
	$self->{_lib_basename} = $lib_basename;

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

=head3 EXAMPLE

    $mutator->prepare_workspace();
    for my $m (@{$mutants}) {
        $mutator->apply_mutant($m);
        # workspace file is now mutated; run tests against it
    }

=head3 MESSAGES

=over 4

=item C<Workspace not prepared -- call prepare_workspace first>

C<apply_mutant> was called before C<prepare_workspace>.

=item C<Relative path not set -- call prepare_workspace first>

Internal: the relative-path field was not set by C<prepare_workspace>.

=item C<< Failed to parse TARGET >>

PPI could not parse the workspace copy of the target file.

=back

=head3 FORMAL SPECIFICATION

Pre:  C<self-E<gt>{_workspace}> is defined ∧ C<self-E<gt>{_relative}> is defined
      ∧ C<ref(mutant-E<gt>{transform}) eq 'CODE'>

Post: workspace copy of target file contains the mutated content

=cut

sub apply_mutant {
	my ($self, $mutant) = @_;

	# Workspace must be prepared before applying any mutant
	my $workspace = $self->{_workspace}
		or croak $ERR_WORKSPACE_NOT_SET;

	my $relative  = $self->{_relative}
		or croak $ERR_RELATIVE_NOT_SET;

	# Construct the full path to the file in the workspace
	my $target = File::Spec->catfile(
		$workspace,
		$self->{_lib_basename},
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

=head3 EXAMPLE

    my $survived = $mutator->run_tests();
    if($survived) {
        print "mutant survived\n";
    } else {
        print "mutant killed\n";
    }

=head3 FORMAL SPECIFICATION

Post: C<result ∈ {0, 1}>
      ∧ C<result == 1> ⟺ all tests in C<t/> passed against current C<lib/>

=cut

sub run_tests {
	my $self = $_[0];

	# Derive prove from $^X so CPAN smokers that install to a non-PATH
	# location still resolve the correct perl/prove pair.  Config{bin}
	# is a reliable fallback; bare 'prove' is last resort only.
	my ($vol, $dir) = File::Spec->splitpath($^X);
	my $prove       = File::Spec->catpath($vol, $dir, 'prove');
	$prove          = File::Spec->catfile($Config{bin}, 'prove') unless -x $prove;
	$prove          = 'prove' unless -x $prove;

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

=head1 COMMON PITFALLS

=over 4

=item Calling C<apply_mutant> before C<prepare_workspace>

C<apply_mutant> requires C<prepare_workspace> to have been called first. The
workspace holds the isolated copy of C<lib/> that receives mutations.

=item Passing an absolute path as C<lib_dir>

C<lib_dir> must be a B<relative> path (e.g. C<lib>). An absolute path causes
C<apply_mutant> to construct a doubled directory under the workspace and then
fail to find the target file.

=item Checking C<< $mutator->{workspace} >> after the refactor

Internal workspace state is stored in C<_workspace>, C<_relative>, and
C<_lib_basename> (note the underscore prefix). The original C<lib_dir> value
is never overwritten. Old code that reads C<< $mutator->{workspace} >> or
C<< $mutator->{relative} >> (without underscores) will not find these keys.

=item Forgetting that C<run_tests> drives C<prove> from C<$^X>

C<run_tests> resolves C<prove> from the same Perl binary used to run the script.
If you shell out to C<prove> directly in your own integration code, make sure
you are using the matching C<prove>.

=item C<generate_mutants> in list vs scalar context

C<generate_mutants> returns a flat list in list context and an arrayref in
scalar context.  Assign to an arrayref (C<my $m = $mutator-E<gt>generate_mutants()>)
to guarantee you always get a reference regardless of calling context.

=back

=head1 LIMITATIONS

=over 4

=item * Single strategy registry

The four built-in mutation strategies are hardcoded in C<new>. There is no
plugin mechanism for registering additional strategies without subclassing.
A future version should accept a C<strategies> arrayref argument.

=item * No parallelism

C<run_tests> is synchronous. For large test suites or large mutant sets,
wall-clock time scales linearly. The in-place mutation strategy also
serialises all mutants behind a single file lock.

=item * PPI re-parse per apply_mutant call

C<apply_mutant> re-parses the workspace copy of the target file for every
mutant. For very large single-file modules the PPI parse time may dominate.

=item * apply_mutant does not restore on abnormal exit

If the process is killed between the write and restore in
C<bin/test-generator-mutate>, the project file is left mutated.
A C<git restore lib/...> recovers it.

=back

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
