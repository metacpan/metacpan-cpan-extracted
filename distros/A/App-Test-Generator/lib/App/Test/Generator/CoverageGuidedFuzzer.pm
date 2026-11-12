package App::Test::Generator::CoverageGuidedFuzzer;

use strict;
use warnings;
use Carp    qw(croak);
use feature 'state';
use Readonly;

# --------------------------------------------------
# Fuzzing loop parameters
# --------------------------------------------------
Readonly my $DEFAULT_ITERATIONS   => 100;
Readonly my $DEFAULT_TIMEOUT_SECS => 5;     # per-call alarm() timeout; 0 disables
Readonly my $CORPUS_MUTATE_RATIO  => 0.70;  # 70% mutate, 30% explore
Readonly my $RANDOM_KEEP_RATIO    => 0.20;  # keep 20% random when no coverage
Readonly my $EDGE_CASE_RATIO      => 0.40;  # 40% chance to use declared edge case
Readonly my $INT_BOUNDARY_RATIO   => 0.30;  # 30% chance to use boundary int
Readonly my $STR_BOUNDARY_RATIO   => 0.30;  # 30% chance to use boundary length
Readonly my $SEED_CORPUS_SIZE     => 5;     # initial random inputs to seed corpus
Readonly my $DEFAULT_MAX_STR_LEN  => 64;
Readonly my $MATCHES_REGEX_TIMEOUT_SECS => 1; # ReDoS guard for schema 'matches' patterns
Readonly my $DEFAULT_MAX_ARRAY    => 4;     # max elements in random array (0..N)
Readonly my $INT32_MAX            => 2**31 - 1;
Readonly my $INT32_MIN            => -(2**31);

# --------------------------------------------------
# Character set and interesting-string constants —
# computed once at load time rather than rebuilt on
# every _rand_string / _mutate_string call.
# --------------------------------------------------
Readonly my @RAND_CHARS => ('a'..'z', 'A'..'Z', '0'..'9', ' ', "\t", "\n", "\0");
Readonly my @INTERESTING_STRINGS => (
	'', ' ', "\0", "\n", "\t",
	'a' x 256,
	'null', 'undefined',
	"'; DROP TABLE foo; --",
	'<script>alert(1)</script>',
);

# --------------------------------------------------
# Type name constants — used in schema dispatch
# --------------------------------------------------
Readonly my $TYPE_INTEGER => 'integer';
Readonly my $TYPE_NUMBER  => 'number';
Readonly my $TYPE_BOOLEAN => 'boolean';
Readonly my $TYPE_ARRAY   => 'arrayref';
Readonly my $TYPE_HASH    => 'hashref';
Readonly my $TYPE_STRING  => 'string';

# --------------------------------------------------
# JSON module preference order
# --------------------------------------------------
Readonly my @JSON_MODULES => qw(JSON::MaybeXS JSON);

# Devel::Cover files a branch with no else/elsif, and every && / ||,
# under 'condition' rather than 'branch', so both must be read.
Readonly my @COVER_CRITERIA => qw(branch condition);

Readonly my $SOFT_BUG_WARNING_RE => qr/uninitialized|undefined|blessed|invalid/i;

our $VERSION = '0.48';

=encoding utf8

=head1 NAME

App::Test::Generator::CoverageGuidedFuzzer - AFL-style coverage-guided fuzzing for App::Test::Generator

=head1 VERSION

Version 0.48

=head1 SYNOPSIS

"Fuzzing" means calling a function many times with machine-made input,
to find input that makes it fail.  The "corpus" is the list of inputs
that the fuzzer decided to keep.

Pattern 1: fuzz a function that takes one number, then show the failures.
The C<input> key of the schema describes the one argument.

    use App::Test::Generator::CoverageGuidedFuzzer;

    my $fuzzer = App::Test::Generator::CoverageGuidedFuzzer->new(
        schema     => { input => { type => 'integer', min => 0, max => 100 } },
        target_sub => \&My::Module::validate,
        iterations => 200,
        seed       => 42,
    );

    my $report = $fuzzer->run();
    printf "%d failures in %d calls\n",
        $report->{bugs_found}, $report->{total_iterations};
    print "  failed with: $_->{error}" for @{ $report->{bugs} };

Pattern 2: keep what was learned between two runs of your program.

    my $file = 't/corpus/validate.json';
    $fuzzer->load_corpus($file) if -e $file;   # start from the last run
    $fuzzer->run();

    # Optional: trim corpus to minimum branch-covering subset before saving
    my $stats = $fuzzer->minimize_corpus();
    printf "corpus %d -> %d entries\n", $stats->{before}, $stats->{after};

    $fuzzer->save_corpus($file);

Pattern 3: fuzz a method of an object.  The object is passed first and
the generated input second.

    my $fuzzer = App::Test::Generator::CoverageGuidedFuzzer->new(
        schema     => { input => { type => 'string', max => 20 } },
        target_sub => \&My::Parser::parse,
        instance   => My::Parser->new(),
    );
    $fuzzer->run();

Pattern 4: test with your own special values, here with non-ASCII text.
About 4 in 10 new inputs are taken from C<edge_case_array>.

    use utf8;
    my $fuzzer = App::Test::Generator::CoverageGuidedFuzzer->new(
        schema => {
            input => {
                type            => 'string',
                edge_case_array => [ '', 'na\x{EF}ve', "\x{1F600}" ],
            },
        },
        target_sub => sub { length $_[0] },
        timeout    => 2,
    );
    $fuzzer->run();

=head1 DESCRIPTION

Implements coverage-guided fuzzing on top of App::Test::Generator's
existing schema-driven input generation. Instead of purely random
generation it:

=over 4

=item 1. Generates or mutates a structured input

=item 2. Runs the target sub under Devel::Cover to capture branch hits

=item 3. Keeps inputs that discover new branches in a corpus

=item 4. Preferentially mutates corpus entries in future iterations

=back

This is the Perl equivalent of what AFL/libFuzzer do at the byte level,
but operating on typed, schema-validated Perl data structures.

=head1 METHODS

=head2 new

Construct a new coverage-guided fuzzer.

    my $fuzzer = App::Test::Generator::CoverageGuidedFuzzer->new(
        schema     => $yaml_schema,
        target_sub => \&My::Module::validate,
        iterations => 200,
        seed       => 42,
        instance   => $obj,   # optional pre-built object for method calls
    );

=head3 Arguments

=over 4

=item * C<schema>

A hashref representing the parsed YAML schema for the target function.
Required.  Only two keys are used: C<input>, which describes the single
argument that will be generated, and C<input_style>.  Inside C<input> the
keys C<type>, C<min>, C<max>, C<matches>, C<items>, C<properties>,
C<optional> and C<edge_case_array> are used.  For a string, C<min> and
C<max> are lengths counted in characters.

=item * C<target_sub>

A CODE reference to the function under test. Required.

=item * C<iterations>

Number of fuzzing iterations to run. Optional - defaults to 100.

=item * C<seed>

Random seed for reproducible runs. Optional - defaults to C<time()>.

=item * C<instance>

An optional pre-built object to use as the invocant when calling the
target sub as a method.

=item * C<timeout>

Seconds to allow each C<target_sub> call before it is aborted via
C<alarm()> and recorded as a bug. Optional - defaults to 5. Set to 0
to disable the timeout (e.g. for target subs that legitimately block).

=back

=head3 Returns

A blessed hashref. Croaks if C<schema> or C<target_sub> is missing.

=head3 Side effects

Calls Perl's C<srand> with the seed.  This restarts the random number
sequence for the whole program, not only for this object.
Prints one warning per program if L<Devel::Cover> cannot be loaded.

=head3 API SPECIFICATION

=head4 input

    {
        schema     => { type => HASHREF },
        target_sub => { type => CODEREF },
        iterations => { type => SCALAR,  optional => 1 },
        seed       => { type => SCALAR,  optional => 1 },
        instance   => { type => OBJECT,  optional => 1 },
        timeout    => { type => SCALAR,  optional => 1 },
    }

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::CoverageGuidedFuzzer',
    }

=head3 EXAMPLE

    my $fuzzer = App::Test::Generator::CoverageGuidedFuzzer->new(
        schema     => { input => { type => 'string' } },
        target_sub => sub { length($_[0]) },
        iterations => 50,
        seed       => 1234,
    );

=head3 MESSAGES

=over 4

=item C<schema required>

C<schema> was not supplied or was falsy (e.g. C<undef> or C<0>).

=item C<target_sub required>

C<target_sub> was not supplied or was falsy.

=back

The mathematical description is in L</FORMAL SPECIFICATION>.

=cut

sub new {
	my ($class, %args) = @_;

	croak 'schema required'     unless $args{schema};
	croak 'target_sub required' unless $args{target_sub};

	my $self = bless {
		schema     => $args{schema},
		target_sub => $args{target_sub},
		instance   => $args{instance},
		iterations => $args{iterations} // $DEFAULT_ITERATIONS,
		seed       => $args{seed}       // time(),
		timeout    => $args{timeout}    // $DEFAULT_TIMEOUT_SECS,
		corpus     => [],   # [{input => ..., coverage => {...}}]
		covered    => {},   # "file:line:branch" => 1
		bugs       => [],   # [{input => ..., error => ...}]
		stats      => {
			total       => 0,
			interesting => 0,
			bugs        => 0,
			coverage    => 0,
		},
		_cover_available => undef,
	}, $class;

	srand($self->{seed});

	# Probe for Devel::Cover availability once at construction time
	$self->{_cover_available} = eval { require Devel::Cover; 1 } ? 1 : 0;

	# Warn once per process if coverage guidance is unavailable
	state $cover_warned = 0;
	if(!$self->{_cover_available} && !$cover_warned++) {
		warn 'Devel::Cover not available; fuzzing without coverage guidance.';
	}

	return $self;
}

=head2 run

Run the coverage-guided fuzzing loop and return a summary report.

    my $report = $fuzzer->run();
    printf "Branches covered: %d\n", $report->{branches_covered};
    printf "Bugs found:       %d\n", $report->{bugs_found};

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A hashref with keys C<total_iterations>, C<interesting_inputs>,
C<corpus_size>, C<branches_covered>, C<bugs_found>, and C<bugs>.

The numbers are totals for the life of the object.  If you call C<run>
twice, C<total_iterations> is twice the C<iterations> value.

=head3 Side effects

Calls C<target_sub> once per iteration.  Adds five new random inputs to
the corpus at the start of every call.  Uses C<alarm> and the C<ALRM>
signal for the timeout, so any alarm that your own program had set is
cancelled.

=head3 Notes

A call that takes longer than C<timeout> seconds is stopped and recorded
as a bug with the error C<target_sub timed out after Ns>.

The same failing input can be recorded more than once.  The C<bugs> list
is not checked for duplicates.

A C<target_sub> call that dies is only recorded in C<bugs> when the
input that triggered it is valid per C<schema>. A die triggered by an
input the schema itself marks invalid (e.g. out of the declared
C<min>/C<max> range) is expected behaviour, not a bug, and is silently
discarded.

=head3 API SPECIFICATION

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' },
    }

=head4 output

    {
        type => HASHREF,
        keys => {
            total_iterations   => { type => SCALAR  },
            interesting_inputs => { type => SCALAR  },
            corpus_size        => { type => SCALAR  },
            branches_covered   => { type => SCALAR  },
            bugs_found         => { type => SCALAR  },
            bugs               => { type => ARRAYREF },
        },
    }

=head3 EXAMPLE

    my $report = $fuzzer->run();
    printf "Iterations:  %d\n", $report->{total_iterations};
    printf "Corpus size: %d\n", $report->{corpus_size};
    printf "Bugs found:  %d\n", $report->{bugs_found};
    for my $bug (@{ $report->{bugs} }) {
        printf "  input=%s  error=%s\n", $bug->{input}, $bug->{error};
    }

The mathematical description is in L</FORMAL SPECIFICATION>.

=head3 PSEUDOCODE

    seed corpus with SEED_CORPUS_SIZE random inputs
    for i in 1..iterations:
        if corpus non-empty and rand < CORPUS_MUTATE_RATIO:
            input = mutate(random corpus entry)
        else:
            input = generate_random()
        run target_sub(input), record coverage and bugs
    return report hashref

=cut

sub run {
	my ($self) = @_;

	# Phase 1: seed the corpus with a small set of random inputs
	$self->_seed_corpus();

	# Phase 2: main fuzzing loop — alternate between mutation and exploration
	for my $i (1 .. $self->{iterations}) {
		my $input;

		if(@{ $self->{corpus} } && rand() < $CORPUS_MUTATE_RATIO) {
			# Mutate a randomly chosen corpus entry
			my $parent = $self->{corpus}[ int(rand(@{ $self->{corpus} })) ];
			$input = $self->_mutate($parent->{input});
		} else {
			# Fresh random generation for exploration
			$input = $self->_generate_random();
		}

		$self->_run_one($input);
		$self->{stats}{total}++;
	}

	$self->{stats}{coverage} = scalar keys %{ $self->{covered} };
	return $self->_build_report();
}

=head2 corpus

Return the accumulated corpus as an arrayref of hashrefs with keys
C<input> and C<coverage>.

    my $corpus = $fuzzer->corpus();

The arrayref is the fuzzer's own list, not a copy.  Do not change it.
The list is empty until C<run> or C<load_corpus> has been called.

=head3 API SPECIFICATION

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' } }

=head4 output

    { type => ARRAYREF }

=head3 EXAMPLE

    my $corpus = $fuzzer->corpus();
    printf "%d entries in corpus\n", scalar @{$corpus};
    # Each entry: { input => ..., coverage => { 'file:line:branch' => 1, ... } }

=cut

sub corpus { $_[0]->{corpus} }

=head2 bugs

Return bugs found as an arrayref of hashrefs with keys C<input> and
C<error>.

    my $bugs = $fuzzer->bugs();

The arrayref is the fuzzer's own list, not a copy.  Do not change it.
C<error> is always text.  C<input> can be C<undef>.

=head3 API SPECIFICATION

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' } }

=head4 output

    { type => ARRAYREF }

=head3 EXAMPLE

    my $bugs = $fuzzer->bugs();
    for my $b (@{$bugs}) {
        printf "Bug: input=%s  error=%s\n", $b->{input}, $b->{error};
    }

=cut

sub bugs { $_[0]->{bugs} }

=head2 save_corpus

Serialise the corpus to a JSON file for replay or extension on future
runs.

    $fuzzer->save_corpus('t/corpus/validate.json');

=head3 Arguments

=over 4

=item * C<$path>

Path to write the JSON corpus file. Required.

=back

=head3 Returns

Nothing useful. Croaks if the file cannot be written or no JSON module is
available.

=head3 Side effects

Writes a JSON file to C<$path>.  An existing file is replaced.
The file holds the seed, the corpus inputs and the bugs.
Branch data is not saved.  The file is UTF-8.

=head3 API SPECIFICATION

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' },
        path => { type => SCALAR },
    }

=head4 output

    { type => UNDEF }

=head3 EXAMPLE

    $fuzzer->run();
    $fuzzer->minimize_corpus();
    $fuzzer->save_corpus('t/corpus/my_func.json');

=head3 MESSAGES

=over 4

=item C<path required>

No path argument was supplied.

=item C<Cannot write corpus to $path: $!>

The file could not be opened for writing (permissions, missing directory, etc.).

=item C<No JSON module available; install JSON or JSON::MaybeXS>

Neither C<JSON::MaybeXS> nor C<JSON> is installed.

=item C<encountered object ...> or C<encountered CODE ...>

Raised by the JSON module.  A corpus input or bug input holds an object
or a code reference, which JSON cannot store.  This check happens after
the file has been opened, so the file is left empty.

=back

The mathematical description is in L</FORMAL SPECIFICATION>.

=cut

sub save_corpus {
	my ($self, $path) = @_;

	croak 'path required' unless defined $path;

	my $json = _load_json_module();

	open my $fh, '>:raw', $path
		or croak "Cannot write corpus to $path: $!";

	print $fh $json->new->utf8->pretty->encode({
		seed   => $self->{seed},
		corpus => [ map { { input => $_->{input} } } @{ $self->{corpus} } ],
		bugs   => $self->{bugs},
	});

	close $fh;
}

=head2 load_corpus

Load a previously saved corpus JSON file, pre-seeding the fuzzer so
it continues from where it left off.

    $fuzzer->load_corpus('t/corpus/validate.json');

=head3 Arguments

=over 4

=item * C<$path>

Path to the JSON corpus file to load. Required.

=back

=head3 Returns

Nothing useful. Croaks if the file cannot be read or no JSON module is
available.

=head3 Side effects

Appends loaded entries to C<< $self->{corpus} >>.  Entries already in the
corpus are kept, so loading the same file twice gives every entry twice.
C<minimize_corpus> removes such copies.

=head3 API SPECIFICATION

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' },
        path => { type => SCALAR },
    }

=head4 output

    { type => UNDEF }

=head3 EXAMPLE

    my $fuzzer2 = App::Test::Generator::CoverageGuidedFuzzer->new(
        schema     => $schema,
        target_sub => \&My::Module::validate,
    );
    $fuzzer2->load_corpus('t/corpus/my_func.json');
    my $report = $fuzzer2->run();

=head3 MESSAGES

=over 4

=item C<path required>

No path argument was supplied.

=item C<Cannot read corpus from $path: $!>

The file could not be opened for reading (missing file, permissions, etc.).

=item C<malformed JSON string ...> and similar

Raised by the JSON module.  The file is not valid JSON.

=back

=head3 Notes

C<load_corpus> does B<not> restore C<bugs> from the JSON file.
The C<bugs> array in the JSON is written by C<save_corpus> but ignored on load.
The loaded fuzzer starts with an empty C<bugs> list.  Seed values are also not
restored; the constructor-supplied seed is retained.

The mathematical description is in L</FORMAL SPECIFICATION>.

=cut

sub load_corpus {
	my ($self, $path) = @_;

	croak 'path required' unless defined $path;

	my $json = _load_json_module();

	open my $fh, '<:raw', $path
		or croak "Cannot read corpus from $path: $!";

	my $text = do { local $/; <$fh> };
	close $fh;

	# Files written before 0.48 hold Latin-1 bytes rather than UTF-8;
	# those fail the UTF-8 decode and are read the old way instead.
	my $data = eval { $json->new->utf8->decode($text) }
		// $json->new->decode($text);

	# Load corpus entries with empty coverage — coverage state from a
	# previous process cannot be restored, only the inputs themselves
	for my $entry (@{ $data->{corpus} // [] }) {
		push @{ $self->{corpus} }, {
			input    => $entry->{input},
			coverage => {},
		};
	}
}

=head2 minimize_corpus

Reduce the corpus to the smallest subset that still covers every
branch hit by the full corpus, using a greedy set-cover algorithm.

Entries without branch data (loaded from a previous run, or kept by
random sampling when Devel::Cover is unavailable) are deduplicated by
input fingerprint and retained in full.  They cannot be evaluated for
coverage contribution without re-running them.  Bug-triggering inputs
are always kept regardless of coverage contribution.

    my $stats = $fuzzer->minimize_corpus();
    printf "Corpus: %d -> %d entries (%d branches covered)\n",
        $stats->{before}, $stats->{after}, $stats->{branches};

=head3 Returns

A hashref with keys C<before> (corpus size before), C<after> (corpus
size after), and C<branches> (total unique branches still covered).

=head3 API SPECIFICATION

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' } }

=head4 output

    {
        type       => HASHREF,
        constraint => sub { defined $_[0]{before} && defined $_[0]{after} && defined $_[0]{branches} },
    }

=head3 EXAMPLE

    $fuzzer->run();
    my $stats = $fuzzer->minimize_corpus();
    printf "Corpus: %d -> %d entries (%d branches)\n",
        $stats->{before}, $stats->{after}, $stats->{branches};
    $fuzzer->save_corpus('t/corpus/my_func.json');

The mathematical description is in L</FORMAL SPECIFICATION>.

=head3 PSEUDOCODE

    partition corpus into with-coverage and without-coverage entries
    greedy set-cover: repeatedly pick entry covering most uncovered branches
    deduplicate without-coverage entries by JSON fingerprint
    unconditionally add all bug inputs not already in minimized set
    replace self.corpus with minimized list
    return { before, after, branches }

=cut

sub minimize_corpus {
	my ($self) = @_;

	my @all    = @{ $self->{corpus} };
	my $before = scalar @all;

	my @with_cov    = grep {  %{ $_->{coverage} } } @all;
	my @without_cov = grep { !%{ $_->{coverage} } } @all;

	# Greedy set-cover: find the smallest subset of with-coverage entries
	# that still covers every branch seen across the whole corpus.
	my %uncovered;
	$uncovered{$_} = 1 for map { keys %{ $_->{coverage} } } @with_cov;
	my $total_branches = scalar keys %uncovered;

	my @selected;
	while (%uncovered && @with_cov) {
		my ($best, $best_idx, $best_n) = (undef, -1, 0);
		for my $i (0 .. $#with_cov) {
			my $n = grep { $uncovered{$_} } keys %{ $with_cov[$i]{coverage} };
			if ($n > $best_n) {
				$best_n   = $n;
				$best_idx = $i;
				$best     = $with_cov[$i];
			}
		}
		last unless $best_n;

		push @selected, $best;
		splice @with_cov, $best_idx, 1;
		delete $uncovered{$_} for keys %{ $best->{coverage} };
	}

	# Deduplicate no-coverage entries by input fingerprint so that repeated
	# loads of the same corpus file do not cause the entry count to grow.
	my %seen;
	my @deduped;
	for my $entry (@without_cov) {
		my $key = _fingerprint($entry->{input});
		next if $seen{$key}++;
		push @deduped, $entry;
	}

	my @minimized = (@selected, @deduped);

	# Bug-triggering inputs are always kept — they are the most valuable
	# findings regardless of whether they add unique branch coverage.
	my %kept = map { _fingerprint($_->{input}) => 1 } @minimized;
	for my $bug (@{ $self->{bugs} }) {
		my $key = _fingerprint($bug->{input});
		unless ($kept{$key}++) {
			push @minimized, { input => $bug->{input}, coverage => {} };
		}
	}

	$self->{corpus} = \@minimized;

	return {
		before   => $before,
		after    => scalar @minimized,
		branches => $total_branches,
	};
}

# --------------------------------------------------
# _fingerprint
#
# Purpose:    Produce a stable, canonical string key
#             for an arbitrary Perl value, for use as
#             a deduplication key.
#
# Entry:      $val - any Perl value (scalar, ref, undef).
# Exit:       Returns a deterministic string.
# Side effects: None.
#
# Notes:      Uses the JSON module in canonical mode so
#             hash keys are always sorted.  Avoids
#             Data::Dumper whose output includes blessed
#             class names that vary across Perl versions.
# --------------------------------------------------
sub _fingerprint {
	my ($val) = @_;
	return 'null' unless defined $val;
	state $encoder;
	unless ($encoder) {
		my $mod = _load_json_module();
		$encoder = eval { $mod->new->canonical(1) };
	}
	return eval { $encoder->encode($val) } // "$val";
}

# --------------------------------------------------
# _load_json_module
#
# Find and load the first available JSON
#     module from the preference list.
#
# Entry:      None.
# Exit:       Returns the name of the loaded module.
#             Croaks if none are available.
#
# Side effects: Loads a JSON module into the process.
#
# Notes:      Uses explicit require rather than string
#             eval for safety. JSON::MaybeXS is
#             preferred over JSON.
# --------------------------------------------------
sub _load_json_module {
	state $cached;
	return $cached if defined $cached;
	for my $mod (@JSON_MODULES) {
		# Convert package name to file path — require $var does not
		# do the :: -> / conversion that bareword require does
		(my $file = $mod) =~ s{::}{/}g;
		$file .= '.pm';
		if (eval { require $file; 1 }) {
			return $cached = $mod;
		}
	}
	croak 'No JSON module available; install JSON or JSON::MaybeXS';
}

# --------------------------------------------------
# _run_one
#
# Run the target sub with a single input,
#     record coverage, detect bugs, and update
#     the corpus if the input is interesting.
#
# Entry:      $input - the value to pass to target_sub.
#
# Exit:       Returns nothing. Updates $self->{corpus},
#             $self->{bugs}, and $self->{covered}.
#
# Side effects: Calls target_sub. May update corpus
#               and covered hashes.
#
# Notes:      When Devel::Cover is available, coverage
#             is captured via _run_with_cover.
#             Unexpected warnings are treated as soft
#             bugs if they match known warning patterns.
# --------------------------------------------------
sub _run_one {
	my ($self, $input) = @_;

	my ($result, $error, $coverage);

	if($self->{_cover_available}) {
		$coverage = $self->_run_with_cover($input, \$result, \$error);
	} else {
		$coverage = {};
		($result, $error) = $self->_call_target($input);
	}

	# Record bugs — only when the input was valid per the schema.
	# A die on invalid input is correct behaviour, not a bug.
	if($error && $self->_input_is_valid($input)) {
		push @{ $self->{bugs} }, { input => $input, error => "$error" };
		$self->{stats}{bugs}++;
	}

	# Keep the input in the corpus if it exercised new branches
	if($self->_is_interesting($coverage)) {
		push @{ $self->{corpus} }, { input => $input, coverage => $coverage };
		$self->_update_covered($coverage);
		$self->{stats}{interesting}++;
	}
}

# --------------------------------------------------
# _call_target
#
# Purpose:    Call the target sub once with a single
#             input, bounded by the timeout.
#
# Entry:      $input - value to pass to target_sub.
#
# Exit:       Returns ($result, $error). $error is undef
#             when the call neither died nor warned in
#             a way that counts as a soft bug.
#
# Side effects: Calls target_sub. Uses alarm().
#
# Notes:      A hanging target_sub would otherwise hang
#             the whole fuzzing run; alarm() bounds it
#             and surfaces the timeout as an error.
# --------------------------------------------------
sub _call_target {
	my ($self, $input) = @_;

	# Include instance as invocant for method calls
	my @call_args = defined($self->{instance})
		? ($self->{instance}, $input)
		: ($input);

	my ($result, $error, @warnings);
	eval {
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		local $SIG{__DIE__};
		local $SIG{ALRM} = sub { die "target_sub timed out after $self->{timeout}s\n" };
		alarm($self->{timeout}) if $self->{timeout};
		$result = $self->{target_sub}->(@call_args);
	};
	alarm(0) if $self->{timeout};
	$error = $@ if $@;

	if(!defined($error) && @warnings) {
		my $w = join '', @warnings;
		$error = "warning: $w" if $w =~ $SOFT_BUG_WARNING_RE;
	}

	return ($result, $error);
}

# --------------------------------------------------
# _run_with_cover
#
# Purpose:    Run the target sub with Devel::Cover
#             active and return the set of newly hit
#             branches as a hashref.
#
# Entry:      $input      - value to pass to target_sub.
#             $result_ref - scalar ref to store result.
#             $error_ref  - scalar ref to store error.
#
# Exit:       Returns a hashref of newly hit branch
#             keys ("file:line:branch").
#
# Side effects: Calls Devel::Cover::start/stop.
#               Sets $$result_ref and $$error_ref.
#
# Notes:      Snapshot comparison is imprecise for
#             concurrent use but correct for single-
#             threaded fuzzing. Instance is passed
#             as invocant when set. Devel::Cover state
#             only grows, so this iteration's "before"
#             is exactly the previous iteration's
#             "after" -- cached in $self to avoid two
#             full Devel::Cover walks per iteration.
# --------------------------------------------------
sub _run_with_cover {
	my ($self, $input, $result_ref, $error_ref) = @_;

	Devel::Cover::start() if Devel::Cover->can('start');

	my $before_ref = $self->{_last_cover_snapshot} || {};
	my %before = %{$before_ref};

	($$result_ref, my $error) = $self->_call_target($input);
	$$error_ref = $error if defined $error;

	my $after = $self->_snapshot_cover();
	$self->{_last_cover_snapshot} = $after;
	Devel::Cover::stop() if Devel::Cover->can('stop');

	# Return only branches newly hit in this call
	my %delta;
	for my $key (keys %{$after}) {
		$delta{$key} = 1 unless exists $before{$key};
	}

	return \%delta;
}

# --------------------------------------------------
# _snapshot_cover
#
# Purpose:    Take a lightweight snapshot of the
#             currently hit branches from Devel::Cover.
#
# Entry:      None beyond $self.
# Exit:       Returns a hashref of "criterion:op:slot" keys.
#
# Side effects: Reads Devel::Cover internal state.
#
# Notes:      Falls back to empty hash if the
#             Devel::Cover API is not accessible.
#             All errors are silently swallowed since
#             coverage is best-effort.
# --------------------------------------------------
sub _snapshot_cover {
	my ($self) = @_;
	my %snap;

	eval {
		# coverage() is the XS accessor for the live counters. It only
		# exists when the program was started under Devel::Cover; a
		# late require leaves it undefined and nothing is collected.
		# (get_coverage() returns the criteria names, not the data.)
		return unless defined &Devel::Cover::coverage;
		my $cover = Devel::Cover::coverage(0) or return;

		for my $criterion (@COVER_CRITERIA) {
			my $data = $cover->{$criterion} or next;
			for my $key (keys %{$data}) {
				my $counts = $data->{$key};
				next unless ref($counts) eq 'ARRAY';

				# Keys are packed op addresses; hex keeps them printable
				my $id = unpack('H*', $key);
				for my $i (0 .. $#{$counts}) {
					$snap{"$criterion:$id:$i"} = 1 if $counts->[$i];
				}
			}
		}
	};

	return \%snap;
}

# --------------------------------------------------
# _is_interesting
#
# Purpose:    Return true if the coverage hashref
#             contains any branch not yet in the
#             global covered set.
#
# Entry:      $coverage - hashref of branch keys.
# Exit:       Returns 1 if interesting, 0 otherwise.
#
# Side effects: None.
#
# Notes:      When no coverage data is available,
#             keeps a random sample of inputs at
#             RANDOM_KEEP_RATIO so the corpus still
#             grows even without branch feedback.
# --------------------------------------------------
sub _is_interesting {
	my ($self, $coverage) = @_;

	# Check for any newly covered branch
	for my $key (keys %{$coverage}) {
		return 1 unless $self->{covered}{$key};
	}

	# No coverage data — keep a random sample to grow the corpus
	return rand() < $RANDOM_KEEP_RATIO unless %{$coverage};

	return 0;
}

# --------------------------------------------------
# _update_covered
#
# Purpose:    Merge newly covered branches into the
#             global covered set.
#
# Entry:      $coverage - hashref of branch keys.
# Exit:       Returns nothing. Updates $self->{covered}.
# Side effects: Modifies $self->{covered}.
# --------------------------------------------------
sub _update_covered {
	my ($self, $coverage) = @_;
	$self->{covered}{$_} = 1 for keys %{$coverage};
}

# --------------------------------------------------
# _generate_random
#
# Purpose:    Generate a random input value from the
#             top-level schema input specification.
#
# Entry:      None beyond $self.
# Exit:       Returns a randomly generated value.
# Side effects: None.
# --------------------------------------------------
sub _generate_random {
	my ($self) = @_;
	return $self->_generate_for_schema($self->{schema}{input});
}

# --------------------------------------------------
# _generate_for_schema
#
# Purpose:    Recursively generate a random value
#             matching a schema specification hashref.
#
# Entry:      $spec - schema spec hashref or scalar
#             type hint.
#
# Exit:       Returns a generated value appropriate
#             for the spec type, or undef if spec is
#             absent or 'undef'.
#
# Side effects: None.
#
# Notes:      Edge cases declared in edge_case_array
#             are selected at EDGE_CASE_RATIO frequency
#             to bias toward known interesting values.
# --------------------------------------------------
sub _generate_for_schema {
	my ($self, $spec) = @_;

	return undef unless defined $spec;
	return undef if $spec eq 'undef';

	my $type = ref($spec) ? ($spec->{type} // $TYPE_STRING) : $TYPE_STRING;

	# Bias toward declared edge cases at EDGE_CASE_RATIO frequency
	if(ref($spec) && $spec->{edge_case_array} && rand() < $EDGE_CASE_RATIO) {
		my @ec = @{ $spec->{edge_case_array} };
		return $ec[ int(rand(@ec)) ];
	}

	# Dispatch to type-specific generator
	if    ($type eq $TYPE_INTEGER) { return $self->_rand_int($spec)    }
	elsif ($type eq $TYPE_NUMBER)  { return $self->_rand_num($spec)    }
	elsif ($type eq $TYPE_BOOLEAN) { return int(rand(2))               }
	elsif ($type eq $TYPE_ARRAY)   { return $self->_rand_array($spec)  }
	elsif ($type eq $TYPE_HASH)    { return $self->_rand_hash($spec)   }
	else                           { return $self->_rand_string($spec) }
}

# --------------------------------------------------
# _rand_int
#
# Purpose:    Generate a random integer within the
#             spec's min/max range, biased toward
#             boundary values at INT_BOUNDARY_RATIO.
#
# Entry:      $spec - schema spec hashref.
# Exit:       Returns an integer scalar.
# Side effects: None.
# --------------------------------------------------
sub _rand_int {
	my ($self, $spec) = @_;

	my $min = $spec->{min} // $INT32_MIN;
	my $max = $spec->{max} // $INT32_MAX;

	# Bias toward boundary values to probe edge conditions
	if(rand() < $INT_BOUNDARY_RATIO) {
		my @interesting = ($min, $min + 1, 0, -1, 1, $max - 1, $max);
		return $interesting[ int(rand(@interesting)) ];
	}

	return $min + int(rand($max - $min + 1));
}

# --------------------------------------------------
# _rand_num
#
# Purpose:    Generate a random floating point number
#             within the spec's min/max range.
#
# Entry:      $spec - schema spec hashref.
# Exit:       Returns a numeric scalar.
# Side effects: None.
# --------------------------------------------------
sub _rand_num {
	my ($self, $spec) = @_;

	my $min = $spec->{min} // -1e9;
	my $max = $spec->{max} //  1e9;

	return $min + rand($max - $min);
}

# --------------------------------------------------
# _rand_string
#
# Purpose:    Generate a random string within the
#             spec's min/max length range, biased
#             toward boundary lengths.
#
# Entry:      $spec - schema spec hashref.
# Exit:       Returns a string scalar.
# Side effects: None.
#
# Notes:      Character set includes control chars
#             and NUL to probe boundary handling.
# --------------------------------------------------
sub _rand_string {
	my ($self, $spec) = @_;

	my $min_len = $spec->{min} // 0;
	my $max_len = $spec->{max} // $DEFAULT_MAX_STR_LEN;

	# Bias toward boundary lengths at STR_BOUNDARY_RATIO frequency
	my $len;
	if(rand() < $STR_BOUNDARY_RATIO) {
		my @boundary_lens = ($min_len, $min_len + 1, $max_len - 1, $max_len);
		$len = $boundary_lens[ int(rand(@boundary_lens)) ];
	} else {
		$len = $min_len + int(rand($max_len - $min_len + 1));
	}

	# Clamp to non-negative
	$len = 0 if $len < 0;

	return join '', map { $RAND_CHARS[ int(rand(@RAND_CHARS)) ] } 1 .. $len;
}

# --------------------------------------------------
# _rand_array
#
# Purpose:    Generate a random arrayref with 0 to
#             DEFAULT_MAX_ARRAY elements, each
#             generated from the items spec.
#
# Entry:      $spec - schema spec hashref.
# Exit:       Returns an arrayref.
# Side effects: None.
# --------------------------------------------------
sub _rand_array {
	my ($self, $spec) = @_;

	my $items = $spec->{items} // {};
	my $count = int(rand($DEFAULT_MAX_ARRAY + 1));

	return [ map { $self->_generate_for_schema($items) } 1 .. $count ];
}

# --------------------------------------------------
# _rand_hash
#
# Purpose:    Generate a random hashref with values
#             generated from the properties spec.
#
# Entry:      $spec - schema spec hashref.
# Exit:       Returns a hashref.
# Side effects: None.
# --------------------------------------------------
sub _rand_hash {
	my ($self, $spec) = @_;

	my $props = $spec->{properties} // {};
	my %h;

	for my $key (keys %{$props}) {
		$h{$key} = $self->_generate_for_schema($props->{$key});
	}

	return \%h;
}

# --------------------------------------------------
# _input_is_valid
#
# Purpose:    Return true if the input satisfies all
#             constraints in the schema. Used to
#             distinguish real bugs (die on valid
#             input) from expected failures (die on
#             invalid input).
#
# Entry:      $input - the value to validate.
# Exit:       Returns 1 if valid, 0 if not.
#             Returns 1 if no schema is available.
# Side effects: None.
# --------------------------------------------------
sub _input_is_valid {
	my ($self, $input) = @_;

	my $spec = $self->{schema}{input};

	# No schema means we cannot judge validity
	return 1 unless defined $spec && ref($spec);

	# A scalar 'type' makes $spec the description of one value. Without
	# it $spec is a map of named parameters, where a parameter may
	# itself be called 'type' (its spec is then a hashref).
	my $is_value_spec = ref($spec) eq 'HASH'
		&& defined($spec->{type}) && !ref($spec->{type});

	my $input_style = $self->{schema}{input_style} // '';

	if(!$is_value_spec && ($input_style eq 'hash' || ref($input) eq 'HASH')) {
		return $self->_validate_hash_input($input, $spec);
	}

	return $self->_validate_value($input, $spec);
}

# --------------------------------------------------
# _validate_hash_input
#
# Purpose:    Validate a hash-style input against the
#             schema spec, checking each named field.
#
# Entry:      $input - hashref of named parameters.
#             $spec  - schema spec hashref.
# Exit:       Returns 1 if valid, 0 if not.
# Side effects: None.
# --------------------------------------------------
sub _validate_hash_input {
	my ($self, $input, $spec) = @_;

	return 0 unless defined $input;

	for my $key (keys %{$spec}) {
		# Skip internal metadata keys
		next if $key =~ /^_/;

		my $field_spec = $spec->{$key};
		next unless ref($field_spec) eq 'HASH';

		my $value = ref($input) eq 'HASH' ? $input->{$key} : undef;

		# Required field missing is always invalid
		if(!defined($value) && !$field_spec->{optional}) {
			return 0;
		}

		next unless defined $value;

		return 0 unless $self->_validate_value($value, $field_spec);
	}

	return 1;
}

# --------------------------------------------------
# _validate_value
#
# Purpose:    Validate a single value against a schema
#             type spec, checking type and constraints.
#
# Entry:      $value - the value to validate.
#             $spec  - schema spec hashref.
# Exit:       Returns 1 if valid, 0 if not.
# Side effects: None.
#
# Notes:      Number validation accepts both integer
#             and floating point forms including
#             scientific notation. Type mismatch
#             always returns 0.
# --------------------------------------------------
sub _validate_value {
	my ($self, $value, $spec) = @_;

	# Undef is never valid unless optional — caller already checked optional
	return 0 unless defined $value;

	my $type = $spec->{type} // $TYPE_STRING;

	if($type eq $TYPE_INTEGER) {
		return 0 unless $value =~ /^-?\d+$/;
		return 0 if defined($spec->{min}) && $value < $spec->{min};
		return 0 if defined($spec->{max}) && $value > $spec->{max};
	}
	elsif($type eq $TYPE_NUMBER) {
		# Accept integers, decimals, and scientific notation
		return 0 unless $value =~ /^-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?$/;
		return 0 if defined($spec->{min}) && $value < $spec->{min};
		return 0 if defined($spec->{max}) && $value > $spec->{max};
	}
	elsif($type eq $TYPE_STRING) {
		my $len = length($value);
		return 0 if defined($spec->{min}) && $len < $spec->{min};
		return 0 if defined($spec->{max}) && $len > $spec->{max};
		if(defined($spec->{matches})) {
			(my $pat = $spec->{matches}) =~ s{^/(.+)/$}{$1};

			# ReDoS guard: a schema-supplied pattern matched against
			# fuzzer-generated (attacker-shaped) input could exhibit
			# catastrophic backtracking. Bound the match with alarm()
			# the same way target_sub calls are bounded elsewhere in
			# this module, and treat a timeout as a non-match.
			my $matched = eval {
				local $SIG{ALRM} = sub { die "matches regex timed out\n" };
				alarm($MATCHES_REGEX_TIMEOUT_SECS);
				my $m = $value =~ /$pat/;
				alarm(0);
				$m;
			};
			alarm(0);
			return 0 unless $matched;
		}
	}
	elsif($type eq $TYPE_BOOLEAN) {
		return 0 unless $value =~ /^[01]$/;
	}
	elsif($type eq $TYPE_ARRAY || $type eq 'array') {
		return 0 unless ref($value) eq 'ARRAY';
	}
	elsif($type eq $TYPE_HASH || $type eq 'hash') {
		return 0 unless ref($value) eq 'HASH';
		if(ref($spec->{properties}) eq 'HASH') {
			return 0 unless $self->_validate_hash_input($value, $spec->{properties});
		}
	}

	return 1;
}

# --------------------------------------------------
# _mutate
#
# Purpose:    Apply a random mutation to an input
#             value, dispatching on its type.
#
# Entry:      $input - the value to mutate.
# Exit:       Returns a mutated copy of the input.
# Side effects: None.
#
# Notes:      Blessed references are passed through
#             unchanged. Undef is replaced with a
#             freshly generated random value.
# --------------------------------------------------
sub _mutate {
	my ($self, $input) = @_;

	my $type = ref($input);

	if(!defined $input) {
		# Replace undef with a fresh random value
		return $self->_generate_random();
	}
	elsif(!$type) {
		# Dispatch scalar mutation based on apparent type
		if($input =~ /^-?\d+$/) {
			return $self->_mutate_int($input);
		} elsif($input =~ /^-?[\d.]+$/) {
			return $self->_mutate_num($input);
		} else {
			return $self->_mutate_string($input);
		}
	}
	elsif($type eq 'ARRAY') {
		return $self->_mutate_array($input);
	}
	elsif($type eq 'HASH') {
		return $self->_mutate_hash($input);
	}

	# Blessed refs and other types pass through unchanged
	return $input;
}

# --------------------------------------------------
# _mutate_int
#
# Purpose:    Apply a random arithmetic mutation to
#             an integer value.
#
# Entry:      $n - the integer to mutate.
# Exit:       Returns a mutated integer.
# Side effects: None.
# --------------------------------------------------
sub _mutate_int {
	my ($self, $n) = @_;
	my $op = int(rand(8));
	return $n + 1                      if $op == 0;
	return $n - 1                      if $op == 1;
	return $n * 2                      if $op == 2;
	return $n == 0 ? 1 : int($n / 2)  if $op == 3;
	return -$n                         if $op == 4;
	return 0                           if $op == 5;
	return $INT32_MAX                  if $op == 6;
	return $INT32_MIN;
}

# --------------------------------------------------
# _mutate_num
#
# Purpose:    Apply a random arithmetic mutation to
#             a floating point value.
#
# Entry:      $n - the number to mutate.
# Exit:       Returns a mutated number.
# Side effects: None.
# --------------------------------------------------
sub _mutate_num {
	my ($self, $n) = @_;
	my $op = int(rand(5));
	return $n + rand(10)      if $op == 0;
	return $n - rand(10)      if $op == 1;
	return $n * (1 + rand())  if $op == 2;
	return 0                  if $op == 3;
	return -$n;
}

# --------------------------------------------------
# _mutate_string
#
# Purpose:    Apply a random structural mutation to
#             a string value — bit flip, insert,
#             delete, truncate, repeat, or replace
#             with an interesting known value.
#
# Entry:      $s - the string to mutate.
# Exit:       Returns a mutated string.
# Side effects: None.
# --------------------------------------------------
sub _mutate_string {
	my ($self, $s) = @_;

	my $len = length($s);

	my @ops = (
		# Bit flip a random character
		sub {
			return $s unless $len;
			my $pos  = int(rand($len));
			my $char = substr($s, $pos, 1);
			substr($s, $pos, 1) = chr(ord($char) ^ (1 << int(rand(8))));
			$s
		},
		# Insert a random byte
		sub {
			my $pos  = int(rand($len + 1));
			my $char = chr(int(rand(256)));
			substr($s, $pos, 0, $char);
			$s
		},
		# Delete a random character
		sub {
			return $s unless $len;
			substr($s, int(rand($len)), 1, '');
			$s
		},
		# Truncate at a random position
		sub { substr($s, 0, int(rand($len + 1))) },
		# Double the string
		sub { $s x 2 },
		# Replace with a known interesting string
		sub { $INTERESTING_STRINGS[ int(rand(@INTERESTING_STRINGS)) ] },
	);

	return $ops[ int(rand(@ops)) ]->();
}

# --------------------------------------------------
# _mutate_array
#
# Purpose:    Apply a random structural mutation to
#             an arrayref — mutate element, duplicate,
#             delete, or empty.
#
# Entry:      $arr - the arrayref to mutate.
# Exit:       Returns a mutated arrayref copy.
# Side effects: None.
# --------------------------------------------------
sub _mutate_array {
	my ($self, $arr) = @_;

	my @copy = @{$arr};

	my @ops = (
		# Mutate a random element
		sub {
			return [] unless @copy;
			my $i = int(rand(@copy));
			$copy[$i] = $self->_mutate($copy[$i]);
			\@copy
		},
		# Duplicate a random element
		sub {
			return \@copy unless @copy;
			my $i = int(rand(@copy));
			splice @copy, $i, 0, $copy[$i];
			\@copy
		},
		# Delete a random element
		sub {
			return \@copy unless @copy;
			splice @copy, int(rand(@copy)), 1;
			\@copy
		},
		# Return empty array
		sub { [] },
	);

	return $ops[ int(rand(@ops)) ]->();
}

# --------------------------------------------------
# _mutate_hash
#
# Purpose:    Apply a random mutation to one value
#             in a hashref copy.
#
# Entry:      $h - the hashref to mutate.
# Exit:       Returns a mutated hashref copy.
# Side effects: None.
# --------------------------------------------------
sub _mutate_hash {
	my ($self, $h) = @_;

	my %copy = %{$h};
	my @keys = keys %copy;

	# Return unchanged if hash is empty
	return \%copy unless @keys;

	my $k = $keys[ int(rand(@keys)) ];
	$copy{$k} = $self->_mutate($copy{$k});

	return \%copy;
}

# --------------------------------------------------
# _seed_corpus
#
# Purpose:    Pre-populate the corpus with a small
#             set of randomly generated inputs to
#             give the fuzzing loop a starting point.
#
# Entry:      None beyond $self.
# Exit:       Returns nothing. Appends to $self->{corpus}.
# Side effects: Modifies $self->{corpus}.
# --------------------------------------------------
sub _seed_corpus {
	my $self = $_[0];

	for (1 .. $SEED_CORPUS_SIZE) {
		push @{ $self->{corpus} }, {
			input    => $self->_generate_random(),
			coverage => {},
		};
	}
}

# --------------------------------------------------
# _build_report
#
# Purpose:    Construct the summary report hashref
#             returned by run().
#
# Entry:      None beyond $self.
# Exit:       Returns a report hashref.
# Side effects: None.
# --------------------------------------------------
sub _build_report {
	my $self = $_[0];

	return {
		total_iterations   => $self->{stats}{total},
		interesting_inputs => $self->{stats}{interesting},
		corpus_size        => scalar @{ $self->{corpus} },
		branches_covered   => $self->{stats}{coverage},
		bugs_found         => $self->{stats}{bugs},
		bugs               => $self->{bugs},
	};
}

=head1 COMMON PITFALLS

=over 4

=item Forgetting that C<load_corpus> does not restore bugs

The JSON written by C<save_corpus> contains a C<bugs> array, but C<load_corpus>
reads only the C<corpus> key.  A freshly loaded fuzzer always starts with an
empty bugs list.  If you need to carry bugs across sessions, persist them
separately.

=item Assuming coverage guidance is always active

If C<Devel::Cover> is not installed, the fuzzer falls back to random-only mode
and emits a warning.  Corpus entries in this mode have C<coverage =E<gt> {}>
and are kept using the C<RANDOM_KEEP_RATIO> (20%) heuristic rather than branch
novelty.  Install C<Devel::Cover> (or C<cpanm --with-recommends
App::Test::Generator>) for full coverage-guided behaviour.

=item Using C<refaddr> on C<corpus()> after C<minimize_corpus>

C<minimize_corpus> replaces C<$self-E<gt>{corpus}> with a B<new> arrayref.
Any caller that holds a reference to the old arrayref (e.g. from a prior
C<corpus()> call) will see a stale snapshot.  Always call C<corpus()> after
C<minimize_corpus> if you need the current list.

=item Setting C<timeout =E<gt> 0> on blocking targets

Setting C<timeout> to 0 disables the per-call C<alarm()>.  This is correct for
targets that legitimately block (e.g. sleeping, waiting on I/O), but means a
hung target_sub will hang the whole fuzzing run indefinitely.  Use a
process-level timeout (e.g. C<Sys::AlarmCall>) if you need a safety net for
blocking code.

=item A C<timeout> below one second turns the timeout off

C<timeout> is passed to Perl's C<alarm>, which works in whole seconds.
A value such as C<0.5> becomes C<0>, and C<0> means "no timeout".

=item A schema without an C<input> key

The generator reads only C<< $schema->{input} >>.  If that key is missing,
every generated input is C<undef>, and C<target_sub> is called with
C<undef> each time.  No error is raised.

    schema => { name => { type => 'string' } }             # wrong
    schema => { input => { type => 'string' } }            # right

=item C<target_sub> always gets exactly one generated argument

C<input> describes B<one> value.  If C<input> is a list of named
parameters without a C<type> key of its own, one random string is
generated, not a hash.  To pass a hashref, describe it:

    input => {
        type       => 'hashref',
        properties => { age => { type => 'integer', min => 0 } },
    }

=item How C<undef> and other false values are handled

=over 4

=item * C<schema> and C<target_sub> must be B<true> values, not only
defined.  An empty hashref C<{}> is true and is accepted.

=item * C<target_sub> is not checked to be a code reference.  A wrong
value is accepted by C<new>, and then every call in C<run> fails.

=item * C<iterations>, C<seed> and C<timeout> use their default only when
they are missing or C<undef>.  The value C<0> is kept: C<< iterations => 0 >>
runs no calls, C<< seed => 0 >> is a valid fixed seed, C<< timeout => 0 >>
means no time limit.

=item * An C<undef> input can be generated (see above) and can be saved.
It is written to the JSON file as C<null> and comes back as C<undef>.

=item * An C<undef> value for a required field makes an input invalid.
An C<undef> value for a field marked C<optional> is valid.

=item * C<save_corpus(undef)> and C<load_corpus(undef)> croak with
C<path required>.

=back

=item Nested data is copied only one level deep

When a hashref or arrayref input is mutated, only the top level is copied.
Deeper hashes and arrays are shared between the old and the new corpus
entry.  If your C<target_sub> changes its argument in place, it can
silently change other corpus entries too.  Write C<target_sub> so that it
only reads its argument, or make it take a deep copy first.

=item C<load_corpus> adds entries. It does not merge or replace.

Loaded entries are put after the entries already in the corpus.  Nothing
is compared and nothing is overwritten.  Load a file twice and you have
two copies of each entry.

=item Every C<run> adds five more random seed inputs

The corpus grows by at least five entries per C<run> call.  Call
C<minimize_corpus> before C<save_corpus> if the object is used for many
runs.

=item Some warnings are recorded as bugs

A warning from C<target_sub> that contains the word C<uninitialized>,
C<undefined>, C<blessed> or C<invalid> is recorded as a bug, even though
the call did not die.  Warnings are caught during the call, so they are
not printed.  Other warnings are thrown away.

=item C<branches_covered> is 0

This means that no branch data was received.  Branch data is only
available when the whole program is started under C<Devel::Cover>, for
example with C<perl -MDevel::Cover script.pl>.  Having the module
installed is not enough.  Without it the run is random-only.  Do not read
a value of 0 as "the target has no branches".

=item Branch counts include more than your target

C<Devel::Cover> counts every branch in the program.  A few of the
branches counted in C<branches_covered> belong to the fuzzer and to other
modules, not to C<target_sub>.  Use the number to compare two runs, not
as an exact size.

=back

=head1 ENCODING

=over 4

=item * Inputs given to C<target_sub>

All strings are Perl character strings.  Strings made by the fuzzer use
ASCII letters, digits, space, tab, newline and the NUL character.
Mutation can also produce any character from 0 to 255.  The fuzzer never
invents characters above 255 (for example emojis) by itself.

=item * C<edge_case_array> and C<matches> in the schema

Full Unicode is supported, including non-ASCII letters and emojis.  Give
them as decoded character strings (C<use utf8> in your source, or a YAML
file loaded with L<YAML::XS>).  Such values are passed to C<target_sub>
unchanged and are mutated one character at a time.

=item * String C<min> and C<max>

Lengths are counted in characters, not bytes.

=item * C<save_corpus> and C<load_corpus>

Full Unicode is supported.  The file is written as UTF-8 JSON, and every
string, including non-ASCII letters and emojis, is loaded back exactly as
it was saved.  A corpus file written by version 0.47 or earlier, which
could hold Latin-1 bytes, is still read correctly.

=item * The C<path> argument

Passed to the operating system unchanged.  ASCII paths always work.

=item * Error text in C<bugs>

The C<error> value is whatever C<target_sub> died with, turned into a
string.  It is not encoded or decoded.

=back

=head1 LIMITATIONS

=over 4

=item Single-threaded

All fuzzing iterations run sequentially in the calling process.  For large
iteration counts, wall-clock time scales linearly.  Parallelism requires
splitting the iteration budget across multiple fuzzer instances and merging
their corpora.

=item Coverage granularity is branch-level

Branch coverage is the finest granularity Devel::Cover exposes via its public
API.  Path coverage (distinct sequences of branches) is not tracked.  Two
inputs that cover the same branches but exercise different call orders are
treated as equivalent.

=item No inter-run learning without save/load

The corpus is entirely in memory.  To carry learning across separate
invocations, call C<save_corpus> at the end and C<load_corpus> at the start of
each subsequent run.

=back

=head1 SEE ALSO

=over 4

=item L<Devel::Cover>

=item L<App::Test::Generator>

=item C<bin/extract-schemas> (the C<--minimize-corpus> flag)

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created
with the assistance of AI.

=head1 FORMAL SPECIFICATION

This section describes each method in Z notation.  It is for readers who
want an exact, mathematical statement.  You do not need it to use the module.

How to read it: a name ending in C<?> is an input, a name ending in C<!> is
an output, and a name ending in C<'> is the value after the call.
E<0x0394> before the state name means "this call may change the object".
E<0x039E> means "this call does not change the object".
C<#> is the number of items in a list or set.

    Entry == [ input : VALUE ; coverage : ℙ BRANCH ]
    Bug   == [ input : VALUE ; error : STRING ]

    ┌─ Fuzzer ──────────────────────────────────────────
    │ schema : VALUE
    │ target_sub : VALUE
    │ instance : VALUE
    │ iterations, seed, timeout : NUMBER
    │ corpus : seq Entry
    │ bugs : seq Bug
    │ covered : ℙ BRANCH
    │ total, interesting : ℕ
    ├───────────────────────────────────────────────────
    │ schema and target_sub are true values
    │ ⋃ { e : ran corpus • e.coverage } ⊆ covered
    │ interesting ≤ #corpus
    └───────────────────────────────────────────────────

=head2 new

    ┌─ New ─────────────────────────────────────────────
    │ Fuzzer′
    │ schema?, target_sub?, instance? : VALUE
    │ iterations?, seed?, timeout? : NUMBER ∪ { undef }
    │ result! : Fuzzer
    ├───────────────────────────────────────────────────
    │ pre   schema? is true ∧ target_sub? is true
    │ post  schema′ = schema? ∧ target_sub′ = target_sub?
    │       instance′ = instance?
    │       iterations′ = if iterations? = undef then 100 else iterations?
    │       seed′ = if seed? = undef then time() else seed?
    │       timeout′ = if timeout? = undef then 5 else timeout?
    │       corpus′ = ⟨⟩ ∧ bugs′ = ⟨⟩ ∧ covered′ = ∅
    │       total′ = 0 ∧ interesting′ = 0
    │       srand(seed′) has been called
    │       result! = θ Fuzzer′
    └───────────────────────────────────────────────────

    schema? is false      ⇒ croak 'schema required'
    target_sub? is false  ⇒ croak 'target_sub required'

=head2 run

    ┌─ Run ─────────────────────────────────────────────
    │ Δ Fuzzer
    │ result! : REPORT
    ├───────────────────────────────────────────────────
    │ post  total′ = total + iterations
    │       corpus prefix corpus′
    │       #corpus′ ≥ #corpus + 5
    │       #corpus′ − #corpus − 5 = interesting′ − interesting
    │       bugs prefix bugs′
    │       covered ⊆ covered′
    │       ∀ b : ran bugs′ ∖ ran bugs •
    │           b.input is valid for schema.input
    │       result!.total_iterations = total′
    │       result!.interesting_inputs = interesting′
    │       result!.corpus_size = #corpus′
    │       result!.branches_covered = #covered′
    │       result!.bugs_found = #bugs′
    │       result!.bugs = bugs′
    │       schema′ = schema ∧ seed′ = seed
    └───────────────────────────────────────────────────

=head2 corpus

    ┌─ Corpus ──────────────────────────────────────────
    │ Ξ Fuzzer
    │ result! : seq Entry
    ├───────────────────────────────────────────────────
    │ post  result! = corpus      (the same list, not a copy)
    └───────────────────────────────────────────────────

=head2 bugs

    ┌─ Bugs ────────────────────────────────────────────
    │ Ξ Fuzzer
    │ result! : seq Bug
    ├───────────────────────────────────────────────────
    │ post  result! = bugs        (the same list, not a copy)
    └───────────────────────────────────────────────────

=head2 save_corpus

    ┌─ SaveCorpus ──────────────────────────────────────
    │ Ξ Fuzzer
    │ path? : PATH
    ├───────────────────────────────────────────────────
    │ pre   path? ≠ undef ∧ path? can be written
    │       every input in corpus and bugs is plain data
    │ post  content′(path?) = JSON of
    │           [ seed   ↦ seed,
    │             corpus ↦ ⟨ e : corpus • [ input ↦ e.input ] ⟩,
    │             bugs   ↦ bugs ]
    └───────────────────────────────────────────────────

    path? = undef             ⇒ croak 'path required'
    path? cannot be written   ⇒ croak 'Cannot write corpus to ...'

=head2 load_corpus

    ┌─ LoadCorpus ──────────────────────────────────────
    │ Δ Fuzzer
    │ path? : PATH
    │ loaded : seq VALUE
    ├───────────────────────────────────────────────────
    │ pre   path? ≠ undef ∧ path? holds valid JSON
    │ post  loaded = the inputs under the 'corpus' key of the file
    │       corpus′ = corpus ⁀ ⟨ v : loaded • [ input ↦ v, coverage ↦ ∅ ] ⟩
    │       bugs′ = bugs ∧ seed′ = seed ∧ covered′ = covered
    │       total′ = total ∧ interesting′ = interesting
    └───────────────────────────────────────────────────

    path? = undef          ⇒ croak 'path required'
    path? cannot be read   ⇒ croak 'Cannot read corpus from ...'

=head2 minimize_corpus

    fp(v) == the canonical JSON text of v   (the "fingerprint")

    ┌─ MinimizeCorpus ──────────────────────────────────
    │ Δ Fuzzer
    │ result! : [ before, after, branches : ℕ ]
    │ with, without : seq Entry
    ├───────────────────────────────────────────────────
    │ post  with = corpus filtered to entries with coverage ≠ ∅
    │       without = corpus filtered to entries with coverage = ∅
    │       result!.before = #corpus
    │       result!.after = #corpus′
    │       result!.branches = # ⋃ { e : ran with • e.coverage }
    │       ⋃ { e : ran corpus′ • e.coverage }
    │           = ⋃ { e : ran corpus • e.coverage }
    │       ∀ e : ran without • ∃ k : ran corpus′ •
    │           fp(k.input) = fp(e.input)
    │       ∀ b : ran bugs • ∃ k : ran corpus′ •
    │           fp(k.input) = fp(b.input)
    │       corpus′ is a new list (old references are stale)
    │       bugs′ = bugs ∧ covered′ = covered
    │       total′ = total ∧ interesting′ = interesting
    └───────────────────────────────────────────────────

    Calling it a second time changes nothing:
    result!.before = result!.after on the second call.

=head1 STATE DIAGRAM

The state of a fuzzer is the state of its corpus.

      new(schema or target_sub missing or false)
    +--------------------------------------------------+
    |  action: croak, no object                        |
    v                                                  |
  +-------------+                                      |
  |  NO OBJECT  |--------------------------------------+
  +-------------+
        |
        | new(schema, target_sub, ...)
        | action: store settings, call srand(seed),
        |         try to load Devel::Cover
        v
  +---------------------+  minimize_corpus()
  |                     |-----------------------------------------+
  |        EMPTY        |  action: returns 0 / 0 / 0              |
  |  (corpus is empty)  |<----------------------------------------+
  |                     |
  |                     |  save_corpus(path)
  |                     |-----------------------------------------+
  |                     |  action: write a file with no entries   |
  |                     |<----------------------------------------+
  +---------------------+
        |
        | run()
        |   action: add 5 random inputs, call target_sub
        |           'iterations' times, keep interesting inputs,
        |           record bugs, return the report
        | load_corpus(path)
        |   action: add the inputs from the file (no branch data)
        v
  +---------------------+  run()
  |                     |-----------------------------------------+
  |       GROWING       |  action: as above; corpus gets bigger,  |
  |  (corpus may hold   |  totals are added to the old totals     |
  |   copies and spare  |<----------------------------------------+
  |   entries)          |
  |                     |  load_corpus(path)
  |                     |-----------------------------------------+
  |                     |  action: add the file's inputs again    |
  |                     |<----------------------------------------+
  |                     |
  |                     |  save_corpus(path)
  |                     |-----------------------------------------+
  |                     |  action: write the file, no change      |
  |                     |<----------------------------------------+
  +---------------------+
        |            ^
        |            | run()  or  load_corpus(path)
        |            | action: as above
        | minimize_corpus()
        | action: replace the corpus with a new, smaller list;
        |         keep every covered branch and every bug input;
        |         return before / after / branches
        v            |
  +---------------------+  minimize_corpus()
  |                     |-----------------------------------------+
  |      MINIMIZED      |  action: nothing changes (before=after) |
  |  (no spare entries) |<----------------------------------------+
  |                     |
  |                     |  save_corpus(path)
  |                     |-----------------------------------------+
  |                     |  action: write the smallest file        |
  |                     |<----------------------------------------+
  +---------------------+

  In every state: corpus() and bugs() return the current lists and
  change nothing.  A call that croaks (bad path, unwritable file,
  unreadable file) changes nothing.

The usual order of calls in one program run is:

    new -> load_corpus -> run -> minimize_corpus -> save_corpus

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
