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
Readonly my $CORPUS_MUTATE_RATIO  => 0.70;  # 70% mutate, 30% explore
Readonly my $RANDOM_KEEP_RATIO    => 0.20;  # keep 20% random when no coverage
Readonly my $EDGE_CASE_RATIO      => 0.40;  # 40% chance to use declared edge case
Readonly my $INT_BOUNDARY_RATIO   => 0.30;  # 30% chance to use boundary int
Readonly my $STR_BOUNDARY_RATIO   => 0.30;  # 30% chance to use boundary length
Readonly my $SEED_CORPUS_SIZE     => 5;     # initial random inputs to seed corpus
Readonly my $DEFAULT_MAX_STR_LEN  => 64;
Readonly my $DEFAULT_MAX_ARRAY    => 4;     # max elements in random array (0..N)
Readonly my $INT32_MAX            => 2**31 - 1;
Readonly my $INT32_MIN            => -(2**31);

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

our $VERSION = '0.33';

=head1 NAME

App::Test::Generator::CoverageGuidedFuzzer - AFL-style coverage-guided
fuzzing for App::Test::Generator

=head1 VERSION

Version 0.33

=head1 SYNOPSIS

    use App::Test::Generator::CoverageGuidedFuzzer;

    my $fuzzer = App::Test::Generator::CoverageGuidedFuzzer->new(
        schema     => $yaml_schema,
        target_sub => \&My::Module::validate,
        iterations => 200,
        seed       => 42,
    );

    my $report = $fuzzer->run();
    $fuzzer->save_corpus('t/corpus/validate.json');

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
Required.

=item * C<target_sub>

A CODE reference to the function under test. Required.

=item * C<iterations>

Number of fuzzing iterations to run. Optional - defaults to 100.

=item * C<seed>

Random seed for reproducible runs. Optional - defaults to C<time()>.

=item * C<instance>

An optional pre-built object to use as the invocant when calling the
target sub as a method.

=back

=head3 Returns

A blessed hashref. Croaks if C<schema> or C<target_sub> is missing.

=head3 API specification

=head4 input

    {
        schema     => { type => HASHREF },
        target_sub => { type => CODEREF },
        iterations => { type => SCALAR,  optional => 1 },
        seed       => { type => SCALAR,  optional => 1 },
        instance   => { type => OBJECT,  optional => 1 },
    }

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::CoverageGuidedFuzzer',
    }

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
		warn "Devel::Cover not available; fuzzing without coverage guidance.\n";
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

=head3 API specification

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

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' } }

=head4 output

    { type => ARRAYREF }

=cut

sub corpus { $_[0]->{corpus} }

=head2 bugs

Return bugs found as an arrayref of hashrefs with keys C<input> and
C<error>.

    my $bugs = $fuzzer->bugs();

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' } }

=head4 output

    { type => ARRAYREF }

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

Nothing. Croaks if the file cannot be written or no JSON module is
available.

=head3 Side effects

Writes a JSON file to C<$path>.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' },
        path => { type => SCALAR },
    }

=head4 output

    { type => UNDEF }

=cut

sub save_corpus {
	my ($self, $path) = @_;

	croak 'path required' unless defined $path;

	my $json = _load_json_module();

	open my $fh, '>', $path
		or croak "Cannot write corpus to $path: $!";

	print $fh $json->new->pretty->encode({
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

Nothing. Croaks if the file cannot be read or no JSON module is
available.

=head3 Side effects

Appends loaded entries to C<< $self->{corpus} >>.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::CoverageGuidedFuzzer' },
        path => { type => SCALAR },
    }

=head4 output

    { type => UNDEF }

=cut

sub load_corpus {
	my ($self, $path) = @_;

	croak 'path required' unless defined $path;

	my $json = _load_json_module();

	open my $fh, '<', $path
		or croak "Cannot read corpus from $path: $!";

	my $data = $json->new->decode(do { local $/; <$fh> });
	close $fh;

	# Load corpus entries with empty coverage — coverage state from a
	# previous process cannot be restored, only the inputs themselves
	for my $entry (@{ $data->{corpus} // [] }) {
		push @{ $self->{corpus} }, {
			input    => $entry->{input},
			coverage => {},
		};
	}
}

# --------------------------------------------------
# _load_json_module
#
# Purpose:    Find and load the first available JSON
#             module from the preference list.
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
	for my $mod (@JSON_MODULES) {
		# Use block eval with require rather than string eval
		# to avoid security issues with arbitrary module names
		my $ok = eval { require $mod; 1 };	## no critic (ProhibitStringyEval)
		return $mod if $ok;
	}
	croak 'No JSON module available; install JSON or JSON::MaybeXS';
}

# --------------------------------------------------
# _run_one
#
# Purpose:    Run the target sub with a single input,
#             record coverage, detect bugs, and update
#             the corpus if the input is interesting.
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

		# Include instance as invocant for method calls
		my @call_args = defined($self->{instance})
			? ($self->{instance}, $input)
			: ($input);

		my @warnings;
		eval {
			local $SIG{__WARN__} = sub { push @warnings, @_ };
			local $SIG{__DIE__};
			$result = $self->{target_sub}->(@call_args);
		};
		$error = $@ if $@;

		# Treat unexpected warnings matching known bad patterns as soft bugs
		if(!defined($error) && @warnings) {
			my $w = join '', @warnings;
			$error = "warning: $w"
				if $w =~ /uninitialized|undefined|blessed|invalid/i;
		}
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
#             as invocant when set.
# --------------------------------------------------
sub _run_with_cover {
	my ($self, $input, $result_ref, $error_ref) = @_;

	Devel::Cover::start() if Devel::Cover->can('start');

	my %before = $self->_snapshot_cover();

	# Include instance as invocant for method calls
	my @call_args = defined($self->{instance})
		? ($self->{instance}, $input)
		: ($input);

	eval {
		local $SIG{__DIE__};
		$$result_ref = $self->{target_sub}->(@call_args);
	};
	$$error_ref = $@ if $@;

	my %after = $self->_snapshot_cover();
	Devel::Cover::stop() if Devel::Cover->can('stop');

	# Return only branches newly hit in this call
	my %delta;
	for my $key (keys %after) {
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
# Exit:       Returns a hash of "file:line:branch" keys.
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
		my $cover = Devel::Cover::get_coverage();
		return unless $cover;

		for my $file (keys %{$cover}) {
			my $branch = $cover->{$file}{branch} or next;
			for my $line (keys %{$branch}) {
				for my $b (0 .. $#{ $branch->{$line} }) {
					$snap{"$file:$line:$b"} = 1
						if $branch->{$line}[$b];
				}
			}
		}
	};

	return %snap;
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

	my @chars = ('a'..'z', 'A'..'Z', '0'..'9', ' ', "\t", "\n", "\0");
	return join '', map { $chars[ int(rand(@chars)) ] } 1 .. $len;
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

	my $input_style = $self->{schema}{input_style} // '';

	if($input_style eq 'hash' || ref($input) eq 'HASH') {
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
			return 0 unless $value =~ /$pat/;
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

	my @ops = (
		sub { $n + 1              },
		sub { $n - 1              },
		sub { $n * 2              },
		sub { $n == 0 ? 1 : int($n / 2) },
		sub { -$n                 },
		sub { 0                   },
		sub { $INT32_MAX          },
		sub { $INT32_MIN          },
	);

	return $ops[ int(rand(@ops)) ]->();
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

	my @ops = (
		sub { $n + rand(10)        },
		sub { $n - rand(10)        },
		sub { $n * (1 + rand())    },
		sub { 0                    },
		sub { -$n                  },
	);

	return $ops[ int(rand(@ops)) ]->();
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
		sub {
			my @interesting = (
				'', ' ', "\0", "\n", "\t",
				'a' x 256,
				'null', 'undefined',
				"'; DROP TABLE foo; --",
				'<script>alert(1)</script>',
			);
			$interesting[ int(rand(@interesting)) ]
		},
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

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created
with the assistance of AI.

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational,
Government) must apply in writing for a licence for use from Nigel Horne
at the above e-mail.

=back

=cut

1;
