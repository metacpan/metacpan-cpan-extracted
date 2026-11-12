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

our $VERSION = '0.48';

=encoding utf8

=head1 NAME

App::Test::Generator::Mutator - Generate and apply mutation tests

=head1 VERSION

Version 0.48

=head1 SYNOPSIS

A "mutant" is a copy of your code with one small, deliberate mistake.
If your tests still pass, the mutant "survived" and your tests missed the
mistake.  If a test fails, the mutant was "killed", which is good.

Pattern 1: list the mutants for a file.  Nothing is changed on disk.

    use App::Test::Generator::Mutator;

    my $mutator = App::Test::Generator::Mutator->new(
        file    => 'lib/My/Module.pm',
        lib_dir => 'lib',
    );

    my $mutants = $mutator->generate_mutants();
    printf "Generated %d mutants\n", scalar @{$mutants};
    printf "line %d: %s\n", $_->line, $_->description for @{$mutants};

Pattern 2: test every mutant.  Run this from the top directory of the
project.  The mutated file is copied over the real file for the test run
and the real file is always put back.  This is what
C<bin/test-generator-mutate> does.

    my $file = 'lib/My/Module.pm';
    my $read = sub { open my $fh, '<', $_[0]; local $/; <$fh> };
    my $original = $read->($file);

    for my $m (@{$mutants}) {
        my $workspace = $mutator->prepare_workspace();    # clean copy each time
        $mutator->apply_mutant($m);
        my $mutated = $read->("$workspace/$file");

        { open my $fh, '>', $file; print $fh $mutated }
        my $survived = $mutator->run_tests();
        { open my $fh, '>', $file; print $fh $original }

        printf "%s: %s\n", ($survived ? 'SURVIVED' : 'KILLED'), $m->description;
    }

Pattern 3: use C<fast> mode to get fewer mutants and a shorter run.

    my $quick = App::Test::Generator::Mutator->new(
        file           => 'lib/My/Module.pm',
        mutation_level => 'fast',
    );
    my $fewer = $quick->generate_mutants();
    printf "fast: %d mutants, full: %d mutants\n",
        scalar @{$fewer}, scalar @{$mutants};

Pattern 4: protect lines of your own code from mutation.  Put these two
comment lines around them in the file to be mutated.  Each marker must
be alone on its line.

    ## MUTANT_SKIP_BEGIN
    return 1 if $n <= 1;    # no mutant will be made for this line
    ## MUTANT_SKIP_END

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
Use a relative path. C<file> must begin with this path.

=item * C<mutation_level>

Controls the breadth of mutation. C<full> applies all mutations;
C<fast> deduplicates and removes redundant mutants first.
Optional - defaults to C<full>.

=back

=head3 Returns

A blessed hashref. Croaks if C<file> is missing or does not exist.
The file is only checked here. It is read later, by C<generate_mutants>.

=head3 API SPECIFICATION

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

The mathematical description is in L</FORMAL SPECIFICATION>.

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

    my $mutants = $mutator->generate_mutants();   # scalar context: arrayref
    for my $m (@{$mutants}) { ... }

    my @mutants = $mutator->generate_mutants();   # list context: flat list (backward-compat)

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

=head3 API SPECIFICATION

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

The mathematical description is in L</FORMAL SPECIFICATION>.

=head3 PSEUDOCODE

    parse file with PPI
    scan lines for MUTANT_SKIP_BEGIN / MUTANT_SKIP_END pairs, giving skip_lines
    for each registered mutation strategy:
        skip if strategy does not apply_to(doc)
        for each mutant from strategy->mutate(doc):
            include unless mutant.line is in skip_lines
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

Prepare an isolated temporary workspace for a single mutant.

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
The directory is removed automatically when the program ends
(L<File::Temp>'s C<CLEANUP =E<gt> 1> behaviour). It is not removed earlier.

=head3 Side effects

Creates a temporary directory. Recursively copies C<lib_dir> into it.
Sets C<< $self->{_workspace} >>, C<< $self->{_relative} >>, and
C<< $self->{_lib_basename} >>. Does not modify C<< $self->{lib_dir} >>.

=head3 Notes

Call C<prepare_workspace> again before B<each> C<apply_mutant> call.
C<apply_mutant> does not undo the previous mutant, so two mutants applied
to the same workspace are both present in the file.

Each call makes a new directory and a new full copy of C<lib_dir>. The
object then points at the new one. Older workspaces stay on disk until the
program ends, so a long run needs disk space for one copy per call.

=head3 API SPECIFICATION

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

The mathematical description is in L</FORMAL SPECIFICATION>.

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

Nothing useful. Do not test the return value.
Modifies the workspace copy of the target file in place.

=head3 Side effects

Overwrites the target file in the workspace with the mutated version.
The real project file is never touched by this method.

=head3 API SPECIFICATION

=head4 input

    {
        self   => { type => OBJECT, isa => 'App::Test::Generator::Mutator' },
        mutant => { type => OBJECT, isa => 'App::Test::Generator::Mutant'  },
    }

=head4 output

    { type => UNDEF }

=head3 EXAMPLE

    for my $m (@{$mutants}) {
        my $workspace = $mutator->prepare_workspace();
        $mutator->apply_mutant($m);
        # "$workspace/lib/My/Module.pm" now holds exactly one mutation
    }

=head3 MESSAGES

=over 4

=item C<Workspace not prepared -- call prepare_workspace first>

C<apply_mutant> was called before C<prepare_workspace>.

=item C<Relative path not set -- call prepare_workspace first>

Internal: the relative-path field was not set by C<prepare_workspace>.

=item C<< Failed to parse TARGET >>

PPI could not parse the workspace copy of the target file.

=item C<Can't call method "transform" on an undefined value>

A Perl error, not a message from this module. C<$mutant> was C<undef>.

=back

The mathematical description is in L</FORMAL SPECIFICATION>.

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

Run the project's test suite and return whether all tests passed.

    my $survived = $mutator->run_tests();

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A true value (1) if all tests passed (mutant survived). A false value
(the empty string, not 0) if any test failed or C<prove> could not be
started (mutant killed). Test it with C<if>, not with C<== 0>.

=head3 Side effects

Executes an external process running the test suite. The output of
C<prove> goes to the terminal.

=head3 Notes

Runs C<prove -l t> in the current directory. This tests the F<lib>
directory of the project, B<not> the workspace. To test a mutant, copy
the mutated file from the workspace over the project file first, and put
the original back afterwards. See Pattern 2 in the L</SYNOPSIS>.

The C<prove> program is looked for next to the running C<perl> first,
then in Perl's own C<bin> directory, and only then on C<PATH>.

There is no time limit. A mutant that causes an endless loop makes this
call wait for ever.

=head3 API SPECIFICATION

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

The mathematical description is in L</FORMAL SPECIFICATION>.

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

=item Applying two mutants to one workspace

C<apply_mutant> changes the workspace file and leaves it changed. If you
apply a second mutant without a new C<prepare_workspace> call, the file
holds both mutations and your results are wrong.

=item Expecting C<run_tests> to test the workspace

C<run_tests> runs the tests against the project's own F<lib> directory.
If you only call C<apply_mutant> and then C<run_tests>, the tests load the
original code, every mutant "survives", and the kill rate is 0%.

=item An unknown C<mutation_level> is not an error

Only the exact text C<fast> turns on fast mode. Any other value, for
example C<Fast> or C<quick>, is accepted silently and works like C<full>.

=item How C<undef> and other false values are handled

=over 4

=item * C<< file => undef >> makes C<new> croak with C<file required>.
An empty string makes it croak with C<file not found>.

=item * C<lib_dir> and C<mutation_level> use their default when the value
is C<undef>, an empty string or C<0>. You cannot have a library directory
that is really named C<0>.

=item * C<apply_mutant(undef)> stops with a Perl error, after the
workspace check.

=item * C<run_tests> returns an empty string for "failed". It never
returns C<undef>.

=item * A mutant's C<line>, C<original> or C<description> may be C<undef>.
Fast mode treats each missing value as an empty string when it looks for
duplicates.

=back

=item Extra arguments to C<new> are ignored

A wrong spelling such as C<libdir> or C<level> is not reported. The
default value is used and no warning is given.

=item Skip markers must be alone on their line

C<## MUTANT_SKIP_BEGIN> and C<## MUTANT_SKIP_END> are only seen when
nothing else except spaces is on the same line. Markers cannot be nested.
The two marker lines themselves are also skipped.

=back

=head1 ENCODING

=over 4

=item * The C<file> and C<lib_dir> arguments

Paths are passed to the operating system unchanged. ASCII paths always
work. For non-ASCII directory or file names, pass the path as bytes in
the encoding of your file system (normally UTF-8).

=item * Source file contents

The file to mutate is read and written by L<PPI> as raw bytes. UTF-8
text, other non-ASCII text and emojis inside strings, comments and POD
are copied to the mutated file byte for byte. They are not damaged and
they do not need to be decoded first.

=item * Text returned by a mutant

C<< $mutant->original >>, C<< $mutant->description >> and
C<< $mutant->line_content >> can contain pieces of your source code.
These are byte strings. If the source is UTF-8 and you print them through
a UTF-8 file handle, decode them first with
C<Encode::decode('UTF-8', $text)>.

=item * Skip markers

The markers are ASCII. They are found correctly in a file of any
ASCII-compatible encoding, including UTF-8.

=item * Error messages

Messages contain the file path exactly as you gave it.

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

=head1 FORMAL SPECIFICATION

This section describes each method in Z notation.  It is for readers who
want an exact, mathematical statement.  You do not need it to use the module.

How to read it: a name ending in C<?> is an input, a name ending in C<!> is
an output, and a name ending in C<'> is the value after the call.
E<0x0394> before the state name means "this call may change the object".
E<0x039E> means "this call does not change the object".

    LEVEL == { 'full', 'fast' }

    ┌─ Mutator ─────────────────────────────────────────
    │ file, lib_dir : PATH
    │ mutation_level : STRING
    │ skip_lines : ℙ ℕ₁ ∪ { undef }
    │ workspace : PATH ∪ { undef }
    │ relative : PATH ∪ { undef }
    ├───────────────────────────────────────────────────
    │ workspace = undef ⇔ relative = undef
    └───────────────────────────────────────────────────

=head2 new

    ┌─ New ─────────────────────────────────────────────
    │ Mutator′
    │ file? : VALUE
    │ lib_dir?, mutation_level? : VALUE
    │ result! : Mutator
    ├───────────────────────────────────────────────────
    │ pre   file? ≠ undef ∧ file? names an existing plain file
    │ post  file′ = file?
    │       lib_dir′ = if lib_dir? is true
    │                  then lib_dir? else 'lib'
    │       mutation_level′ = if mutation_level? is true
    │                         then mutation_level? else 'full'
    │       skip_lines′ = undef ∧ workspace′ = undef ∧ relative′ = undef
    │       result! = θ Mutator′
    └───────────────────────────────────────────────────

    file? = undef                  ⇒ croak 'file required'
    file? is not an existing file  ⇒ croak 'file not found: ' ⁀ file?

=head2 generate_mutants

    ┌─ GenerateMutants ─────────────────────────────────
    │ Δ Mutator
    │ result! : seq Mutant
    │ all : seq Mutant
    ├───────────────────────────────────────────────────
    │ pre   file is valid Perl that PPI can parse
    │       skip markers in file are paired and not nested
    │ post  skip_lines′ = { n : ℕ₁ | line n of file lies between
    │                       a BEGIN marker and its END marker,
    │                       both marker lines included }
    │       all = every mutant that the four strategies
    │             produce for file, in strategy order
    │       ∀ m : ran result! • m ∈ ran all ∧ m.line ∉ skip_lines′
    │       mutation_level ≠ 'fast' ⇒
    │           result! = all with skipped lines removed
    │       mutation_level = 'fast' ⇒
    │           (∀ i, j : dom result! • i ≠ j ⇒
    │               key(result!(i)) ≠ key(result!(j)))
    │           ∧ (∀ m : ran result! • ¬ redundant(m))
    │       file′ = file ∧ lib_dir′ = lib_dir
    │       workspace′ = workspace ∧ relative′ = relative
    └───────────────────────────────────────────────────

    key(m) == (m.line, m.original, m.description)

    In list context the members of result! are returned as a list.

=head2 prepare_workspace

    ┌─ PrepareWorkspace ────────────────────────────────
    │ Δ Mutator
    │ result! : PATH
    ├───────────────────────────────────────────────────
    │ pre   lib_dir names a directory that can be copied
    │ post  result! names a directory created by this call
    │       result! ≠ workspace
    │       result!/basename(lib_dir) is a full copy of lib_dir
    │       workspace′ = result!
    │       relative′ = file with the leading lib_dir removed
    │       file′ = file ∧ lib_dir′ = lib_dir
    │       mutation_level′ = mutation_level
    │       skip_lines′ = skip_lines
    └───────────────────────────────────────────────────

    the copy fails  ⇒ croak 'dircopy failed: ' ⁀ reason

=head2 apply_mutant

    ┌─ ApplyMutant ─────────────────────────────────────
    │ Ξ Mutator
    │ mutant? : Mutant
    │ target : PATH
    ├───────────────────────────────────────────────────
    │ pre   workspace ≠ undef ∧ relative is true
    │       mutant?.transform is a CODE reference
    │       target = workspace/basename(lib_dir)/relative
    │       target is valid Perl that PPI can parse
    │ post  content′(target) = mutant?.transform(content(target))
    │       content′(file) = content(file)
    └───────────────────────────────────────────────────

    workspace = undef  ⇒ croak 'Workspace not prepared -- ...'
    relative is false  ⇒ croak 'Relative path not set -- ...'
    target not parsed  ⇒ croak 'Failed to parse ' ⁀ target

=head2 run_tests

    ┌─ RunTests ────────────────────────────────────────
    │ Ξ Mutator
    │ result! : { 1, '' }
    ├───────────────────────────────────────────────────
    │ post  result! = 1 ⇔ the command 'prove -l t', run in the
    │                     current directory, exits with status 0
    └───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The object has three states. The state says what has been prepared so far.

      new(file => undef) or new(file => missing file)
    +--------------------------------------------------+
    |  action: croak, no object                        |
    v                                                  |
  +-------------+                                      |
  |  NO OBJECT  |--------------------------------------+
  +-------------+
        |
        | new(file => existing file)
        | action: store file, lib_dir, mutation_level;
        |         build the four mutation strategies
        v
  +---------------------+  generate_mutants()
  |                     |-----------------------------------------+
  |     CONSTRUCTED     |  action: read file, set skip_lines,     |
  |  (no workspace yet) |  return the mutants (state stays same)  |
  |                     |<----------------------------------------+
  |                     |
  |                     |  run_tests()
  |                     |-----------------------------------------+
  |                     |  action: run 'prove -l t', return 1/''  |
  |                     |<----------------------------------------+
  |                     |
  |                     |  apply_mutant(m)
  |                     |-----------------------------------------+
  |                     |  action: croak 'Workspace not prepared' |
  |                     |<----------------------------------------+
  +---------------------+
        |
        | prepare_workspace()
        | action: make temp directory, copy lib_dir into it,
        |         remember workspace path and relative file path
        v
  +---------------------+  generate_mutants()   (as above)
  |                     |-----------------------------------------+
  |   WORKSPACE CLEAN   |<----------------------------------------+
  |  (copy is the same  |
  |   as the original)  |  run_tests()          (as above)
  |                     |-----------------------------------------+
  |                     |<----------------------------------------+
  |                     |
  |                     |  prepare_workspace()
  |                     |-----------------------------------------+
  |                     |  action: new directory, new clean copy  |
  |                     |<----------------------------------------+
  +---------------------+
        |            ^
        |            | prepare_workspace()
        |            | action: new directory, new clean copy;
        |            |         the mutated copy is left behind
        | apply_mutant(m)
        | action: rewrite the workspace copy of the file
        |         with one mutation
        v            |
  +---------------------+  apply_mutant(m2)
  |                     |-----------------------------------------+
  |  WORKSPACE MUTATED  |  action: a second mutation is added on  |
  |                     |  top of the first (usually a mistake)   |
  |                     |<----------------------------------------+
  |                     |
  |                     |  generate_mutants(), run_tests()
  |                     |-----------------------------------------+
  |                     |  action: as above, state stays the same |
  |                     |<----------------------------------------+
  +---------------------+

  From any state: when the program ends, every temporary workspace
  directory is deleted.

A call that croaks leaves the object in the state it was in. The
workspace file is only rewritten after the mutation has succeeded.

No method of this class changes the real project file.

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

1;
