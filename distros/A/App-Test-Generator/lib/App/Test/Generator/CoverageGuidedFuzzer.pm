package App::Test::Generator::CoverageGuidedFuzzer;

use strict;
use warnings;

our $VERSION = '0.31';

=head1 NAME

App::Test::Generator::CoverageGuidedFuzzer - AFL-style coverage-guided fuzzing
for App::Test::Generator

=head1 VERSION

Version 0.31

=head1 SYNOPSIS

    use App::Test::Generator::CoverageGuidedFuzzer;

    my $fuzzer = App::Test::Generator::CoverageGuidedFuzzer->new(
        schema      => $yaml_schema,   # your existing parsed YAML schema
        target_sub  => \&My::Module::validate,
        iterations  => 200,
        seed        => 42,
    );

    my $report = $fuzzer->run();
    $fuzzer->save_corpus('t/corpus/validate.json');

=head1 DESCRIPTION

Implements coverage-guided fuzzing on top of App::Test::Generator's existing
schema-driven input generation.  Instead of purely random generation, it:

  1. Generates or mutates a structured input
  2. Runs the target sub under Devel::Cover to capture branch hits
  3. Keeps inputs that discover *new* branches in a corpus
  4. Preferentially mutates corpus entries in future iterations

This is the Perl equivalent of what AFL/libFuzzer do at the byte level, but
operating on typed, schema-validated Perl data structures.

=head1 HOW CORPUS FILES ARE USED

=head2 Overview

Each time C<extract-schemas --fuzz> runs, it creates or updates one JSON file
per fuzzed method under C<schemas/corpus/> (or C<--corpus-dir> if specified).
For example:

    schemas/corpus/translate.json
    schemas/corpus/lookup.json

These files are the fuzzer's memory. Without them, every run starts from
scratch. With them, each run builds on the discoveries of every previous run.

=head2 What is stored in a corpus file

Each file is a JSON object with three keys:

    {
      "seed": 1234567890,
      "corpus": [
        { "input": "en" },
        { "input": "12345678901" },
        ...
      ],
      "bugs": [
        { "input": "...", "error": "..." }
      ]
    }

The C<corpus> array contains every input that was judged "interesting" during
past runs. An input is interesting if it triggered at least one branch in the
target code that no previous input had reached. These are the inputs that
proved useful for exploring the method's behaviour - not just random values,
but ones that actually exercised distinct paths through the code.

The C<bugs> array records every input that caused the target method to die or
throw an exception, along with the error message. This is preserved across
runs so you have a permanent record of discovered failure cases even after
fixing them.

The C<seed> records the random seed of the run that created the file. This is
informational only and is not reused on subsequent runs.

=head2 How the corpus is used at the start of a run

When C<extract-schemas --fuzz> runs and finds an existing corpus file for a
method, it calls C<load_corpus()> before starting the fuzzing loop. This
pre-populates the fuzzer's internal corpus with all the previously interesting
inputs. They are loaded with an empty coverage hash (C<coverage =E<gt> {}>)
because coverage state from a previous process cannot be restored - only the
inputs themselves are persisted.

=head2 How the corpus influences the fuzzing loop

During the main fuzzing loop, on each of the C<--fuzz-iters> iterations, the
fuzzer makes a weighted random choice:

=over 4

=item 70% of iterations: mutate a corpus entry

A random entry is picked from the corpus (which now includes both the loaded
entries from previous runs and any new entries discovered in this run so far).
That entry's input is mutated - characters are flipped, numbers are nudged,
strings are truncated or extended, array elements are duplicated or deleted -
and the mutated value is run against the target method.

The key property here is that mutations are applied to inputs that are already
known to reach interesting parts of the code. Rather than generating a fresh
random string that will probably hit the same early conditional as everything
else, the fuzzer is specifically probing the neighbourhood of inputs that
previously pushed into new territory.

=item 30% of iterations: fresh random generation

A completely new input is generated from the schema. This is the exploration
budget - it ensures the fuzzer does not get permanently stuck mutating a
narrow slice of the input space and occasionally tries something entirely new.

=back

=head2 How new entries are added to the corpus during a run

After each input is run against the target method, the fuzzer checks whether
it was interesting. With C<Devel::Cover> available, an input is interesting if
it hit at least one branch that no previous input in this session had hit.
Without C<Devel::Cover>, 20% of inputs are kept at random so the corpus
continues to grow even without branch feedback.

Interesting inputs are appended to the in-memory corpus immediately, so they
can be selected and mutated within the same run. They are also written to the
JSON file at the end of the run via C<save_corpus()>.

=head2 How the corpus grows across multiple runs

On the first run, the corpus file does not exist. The fuzzer seeds itself with
five randomly generated inputs, runs all iterations, and saves the interesting
ones. A typical first run might produce a corpus of 15-30 entries.

On the second run, those 15-30 entries are loaded before any iteration begins.
The fuzzer immediately starts mutating inputs that are already known to reach
interesting branches, rather than spending iterations rediscovering them from
scratch. It finds new interesting inputs on top of the existing ones, and the
corpus grows further.

By the third, fourth and subsequent runs the corpus has stabilised for the
easy-to-reach branches and is increasingly focused on harder-to-reach ones.
The coverage plateau is reached more slowly each time, which is exactly the
right behaviour - the fuzzer is spending its budget on genuinely new territory.

=head2 Practical implications

=over 4

=item Running once gives limited value; running repeatedly gives compounding value.

The first run with 100 iterations is roughly equivalent to C<App::Test::Generator>
with 100 random iterations. By the fifth run, the corpus is directed at branches
that purely random generation would almost never reach.

=item The corpus is human-readable and editable.

Because inputs are stored as plain JSON values, you can open a corpus file and
add your own known-tricky inputs by hand. They will be picked up on the next
run and mutated like any other corpus entry.

=item Deleting a corpus file resets the fuzzer for that method.

If you significantly change a method's implementation, the old corpus may be
less useful. Delete the relevant C<schemas/corpus/method.json> and the fuzzer
will start fresh with the new code.

=item The bugs array is a regression record.

Even after you fix a bug that was found by fuzzing, the input that triggered it
remains in the C<bugs> array of the corpus file. You can use these as the basis
for specific regression tests to ensure the fix holds.

=back

=head2 Corpus file location

By default corpus files are written to C<schemas/corpus/>, one file per method,
named C<method_name.json>. This can be changed with the C<--corpus-dir> option:

    extract-schemas --fuzz --corpus-dir t/corpus lib/MyModule.pm

It is recommended to commit the corpus directory to version control. This means
every developer and every CI run benefits from the accumulated discoveries of
all previous runs rather than starting from scratch each time.

=cut

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;

    die "schema required"     unless $args{schema};
    die "target_sub required" unless $args{target_sub};

    my $self = bless {
        schema      => $args{schema},
        target_sub  => $args{target_sub},
        instance    => $args{instance},    # optional pre-built object for method calls
        iterations  => $args{iterations}  // 100,
        seed        => $args{seed}        // time(),
        corpus      => [],          # [{input => ..., coverage => {...}}]
        covered     => {},          # "file:line:branch" => 1
        bugs        => [],          # [{input => ..., error => ...}]
        stats       => {
            total       => 0,
            interesting => 0,
            bugs        => 0,
            coverage    => 0,
        },
        _cover_available => undef,
    }, $class;

    srand( $self->{seed} );

    # Probe for Devel::Cover availability once at construction time
    $self->{_cover_available} = eval { require Devel::Cover; 1 } ? 1 : 0;
    our $__cover_warned;
    if (!$self->{_cover_available} && !$__cover_warned++) {
        warn "Devel::Cover not available; fuzzing without coverage guidance.\n";
    }

    return $self;
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

=head2 run

Run the coverage-guided fuzzing loop.  Returns a hashref summary report.

=cut

sub run {
    my ($self) = @_;

    # Phase 1: seed the corpus with one random input per interesting type combo
    $self->_seed_corpus();

    # Phase 2: main fuzzing loop
    for my $i (1 .. $self->{iterations}) {
        my $input;

        if (@{$self->{corpus}} && rand() < 0.7) {
            # 70% of the time: mutate a corpus entry
            my $parent = $self->{corpus}[ int(rand(@{$self->{corpus}})) ];
            $input = $self->_mutate( $parent->{input} );
        } else {
            # 30% of the time: fresh random generation (exploration)
            $input = $self->_generate_random();
        }

        $self->_run_one($input);
        $self->{stats}{total}++;
    }

    $self->{stats}{coverage} = scalar keys %{$self->{covered}};
    return $self->_build_report();
}

=head2 corpus

Returns the accumulated corpus as an arrayref of hashrefs with keys
C<input> and C<coverage>.

=cut

sub corpus { $_[0]->{corpus} }

=head2 bugs

Returns bugs found as an arrayref of hashrefs with keys C<input> and C<error>.

=cut

sub bugs { $_[0]->{bugs} }

=head2 save_corpus( $path )

Serialises the corpus to a JSON file so it can be replayed or extended.
Requires JSON::MaybeXS or JSON.

=cut

sub save_corpus {
    my ($self, $path) = @_;

    my $json_module;
    for my $mod (qw(JSON::MaybeXS JSON)) {
        eval "require $mod" and $json_module = $mod and last;
    }
    die "No JSON module available; install JSON or JSON::MaybeXS" unless $json_module;

    open my $fh, '>', $path or die "Cannot write corpus to $path: $!";
    print $fh $json_module->new->pretty->encode({
        seed   => $self->{seed},
        corpus => [ map { { input => $_->{input} } } @{$self->{corpus}} ],
        bugs   => $self->{bugs},
    });
    close $fh;
}

=head2 load_corpus( $path )

Loads a previously saved corpus JSON file, pre-seeding the fuzzer so it
continues from where it left off.

=cut

sub load_corpus {
    my ($self, $path) = @_;

    my $json_module;
    for my $mod (qw(JSON::MaybeXS JSON)) {
        eval "require $mod" and $json_module = $mod and last;
    }
    die "No JSON module available" unless $json_module;

    open my $fh, '<', $path or die "Cannot read corpus from $path: $!";
    my $data = $json_module->new->decode(do { local $/; <$fh> });
    close $fh;

    for my $entry (@{ $data->{corpus} // [] }) {
        push @{$self->{corpus}}, { input => $entry->{input}, coverage => {} };
    }
}

# ---------------------------------------------------------------------------
# Internal: core loop
# ---------------------------------------------------------------------------

sub _run_one {
    my ($self, $input) = @_;

    my ($result, $error, $coverage);

    if ($self->{_cover_available}) {
        $coverage = $self->_run_with_cover($input, \$result, \$error);
    } else {
        $coverage = {};
        my @call_args = defined($self->{instance}) ? ($self->{instance}, $input) : ($input);
        my @warnings;
        eval {
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            local $SIG{__DIE__};
            $result = $self->{target_sub}->(@call_args);
        };
        $error = $@ if $@;
        # Treat unexpected warnings as soft bugs worth recording
        if (!defined $error && @warnings) {
            my $w = join "", @warnings;
            $error = "warning: $w" if $w =~ /uninitialized|undefined|blessed|invalid/i;
        }
    }

    # Record bugs — but only if the input was valid according to the schema.
    # A die on invalid input is correct behaviour, not a bug.
    if ($error) {
        if ($self->_input_is_valid($input)) {
            push @{$self->{bugs}}, { input => $input, error => "$error" };
            $self->{stats}{bugs}++;
        }
        # Still keep this input if it's interesting coverage-wise
    }

    # Is this input interesting (new branches)?
    if ($self->_is_interesting($coverage)) {
        push @{$self->{corpus}}, { input => $input, coverage => $coverage };
        $self->_update_covered($coverage);
        $self->{stats}{interesting}++;
    }
}

# ---------------------------------------------------------------------------
# Internal: coverage capture via Devel::Cover
# ---------------------------------------------------------------------------

sub _run_with_cover {
    my ($self, $input, $result_ref, $error_ref) = @_;

    # We snapshot the Devel::Cover DB before and after the call.
    # This is imprecise for concurrent use but fine for single-threaded fuzzing.

    Devel::Cover::start() if Devel::Cover->can('start');

    my %before = $self->_snapshot_cover();

    eval {
        local $SIG{__DIE__};
        $$result_ref = $self->{target_sub}->($input);
    };
    $$error_ref = $@ if $@;

    my %after  = $self->_snapshot_cover();
    Devel::Cover::stop()  if Devel::Cover->can('stop');

    # Return only the *newly* hit branches in this call
    my %delta;
    for my $key (keys %after) {
        $delta{$key} = 1 unless exists $before{$key};
    }
    return \%delta;
}

# Lightweight branch snapshot from Devel::Cover internals.
# Falls back to empty hash if the API isn't accessible.
sub _snapshot_cover {
    my ($self) = @_;
    my %snap;
    eval {
        my $cover = Devel::Cover::get_coverage();
        return unless $cover;
        for my $file (keys %$cover) {
            if (my $branch = $cover->{$file}{branch}) {
                for my $line (keys %$branch) {
                    for my $b (0 .. $#{ $branch->{$line} }) {
                        $snap{"$file:$line:$b"} = 1
                            if $branch->{$line}[$b];
                    }
                }
            }
        }
    };
    return %snap;
}

sub _is_interesting {
    my ($self, $coverage) = @_;
    for my $key (keys %$coverage) {
        return 1 unless $self->{covered}{$key};
    }
    # If no coverage data at all (Devel::Cover unavailable),
    # keep a random 20% sample so the corpus still grows
    return rand() < 0.20 unless %$coverage;
    return 0;
}

sub _update_covered {
    my ($self, $coverage) = @_;
    $self->{covered}{$_} = 1 for keys %$coverage;
}

# ---------------------------------------------------------------------------
# Internal: structured input generation from schema
# ---------------------------------------------------------------------------

sub _generate_random {
    my ($self) = @_;
    return $self->_generate_for_schema( $self->{schema}{input} );
}

sub _generate_for_schema {
    my ($self, $spec) = @_;

    return undef unless defined $spec;
    return undef if $spec eq 'undef';

    my $type = ref($spec) ? ($spec->{type} // 'string') : 'string';

    # 40% chance to use a declared edge case (matches existing behaviour)
    if (ref($spec) && $spec->{edge_case_array} && rand() < 0.40) {
        my @ec = @{ $spec->{edge_case_array} };
        return $ec[ int(rand(@ec)) ];
    }

    if    ($type eq 'integer') { return $self->_rand_int($spec)    }
    elsif ($type eq 'number')  { return $self->_rand_num($spec)    }
    elsif ($type eq 'boolean') { return int(rand(2))               }
    elsif ($type eq 'arrayref'){ return $self->_rand_array($spec)  }
    elsif ($type eq 'hashref') { return $self->_rand_hash($spec)   }
    else                       { return $self->_rand_string($spec) }
}

sub _rand_int {
    my ($self, $spec) = @_;
    my $min = $spec->{min} // -2**31;
    my $max = $spec->{max} //  2**31;
    # Bias toward boundary values
    my @interesting = ($min, $min+1, 0, -1, 1, $max-1, $max);
    return $interesting[ int(rand(@interesting)) ] if rand() < 0.30;
    return $min + int(rand($max - $min + 1));
}

sub _rand_num {
    my ($self, $spec) = @_;
    my $min = $spec->{min} // -1e9;
    my $max = $spec->{max} //  1e9;
    return $min + rand($max - $min);
}

sub _rand_string {
    my ($self, $spec) = @_;
    my $min_len = $spec->{min} // 0;
    my $max_len = $spec->{max} // 64;

    # Boundary lengths
    my @len_choices = ($min_len, $min_len+1, $max_len-1, $max_len);
    my $len = (rand() < 0.30)
        ? $len_choices[ int(rand(@len_choices)) ]
        : $min_len + int(rand($max_len - $min_len + 1));
    $len = 0 if $len < 0;

    my @chars = ('a'..'z', 'A'..'Z', '0'..'9', ' ', "\t", "\n", "\0");
    return join '', map { $chars[int(rand(@chars))] } 1 .. $len;
}

sub _rand_array {
    my ($self, $spec) = @_;
    my $items = $spec->{items} // {};
    my $count = int(rand(5));   # 0..4 elements
    return [ map { $self->_generate_for_schema($items) } 1..$count ];
}

sub _rand_hash {
    my ($self, $spec) = @_;
    my $props = $spec->{properties} // {};
    my %h;
    for my $key (keys %$props) {
        $h{$key} = $self->_generate_for_schema($props->{$key});
    }
    return \%h;
}

# ---------------------------------------------------------------------------
# Internal: schema validation
# ---------------------------------------------------------------------------

# Returns true if the input satisfies all constraints in the schema.
# A die on a valid input is a real bug; a die on an invalid input is expected.
sub _input_is_valid {
    my ($self, $input) = @_;

    my $spec = $self->{schema}{input};
    return 1 unless defined $spec && ref($spec);  # no schema = can't judge

    my $input_style = $self->{schema}{input_style} // '';

    if ($input_style eq 'hash' || ref($input) eq 'HASH') {
        # Hash-style: validate each named parameter
        return $self->_validate_hash_input($input, $spec);
    } else {
        # Scalar: validate against the single input spec
        return $self->_validate_value($input, $spec);
    }
}

sub _validate_hash_input {
    my ($self, $input, $spec) = @_;

    return 0 unless defined $input;

    for my $key (keys %$spec) {
        next if $key =~ /^_/;   # skip metadata keys
        my $field_spec = $spec->{$key};
        next unless ref($field_spec) eq 'HASH';

        my $value = ref($input) eq 'HASH' ? $input->{$key} : undef;

        # Required field missing
        if (!defined($value) && !$field_spec->{optional}) {
            return 0;
        }

        next unless defined $value;

        return 0 unless $self->_validate_value($value, $field_spec);
    }

    return 1;
}

sub _validate_value {
    my ($self, $value, $spec) = @_;

    return 0 unless defined $value;  # undef always invalid unless optional

    my $type = $spec->{type} // 'string';

    if ($type eq 'integer') {
        return 0 unless $value =~ /^-?\d+$/;
        return 0 if defined($spec->{min}) && $value < $spec->{min};
        return 0 if defined($spec->{max}) && $value > $spec->{max};
    }
    elsif ($type eq 'number') {
        return 0 unless $value =~ /^-?(?:\d+\.?\d*|\.\d+)$/;
        return 0 if defined($spec->{min}) && $value < $spec->{min};
        return 0 if defined($spec->{max}) && $value > $spec->{max};
    }
    elsif ($type eq 'string') {
        my $len = length($value);
        return 0 if defined($spec->{min}) && $len < $spec->{min};
        return 0 if defined($spec->{max}) && $len > $spec->{max};
        if (defined($spec->{matches})) {
            (my $pat = $spec->{matches}) =~ s{^/(.+)/$}{$1};
            return 0 unless $value =~ /$pat/;
        }
    }
    elsif ($type eq 'boolean') {
        return 0 unless $value =~ /^[01]$/;
    }
    elsif ($type =~ /^(arrayref|array)$/) {
        return 0 unless ref($value) eq 'ARRAY';
    }
    elsif ($type =~ /^(hashref|hash)$/) {
        return 0 unless ref($value) eq 'HASH';
    }

    return 1;
}
# ---------------------------------------------------------------------------
# Internal: mutation operators
# ---------------------------------------------------------------------------

sub _mutate {
    my ($self, $input) = @_;

    my $type = ref($input);

    if (!defined $input) {
        # Mutate undef into something
        return $self->_generate_random();
    }
    elsif (!$type) {
        # Scalar
        if ($input =~ /^-?\d+$/) {
            return $self->_mutate_int($input);
        } elsif ($input =~ /^-?[\d.]+$/) {
            return $self->_mutate_num($input);
        } else {
            return $self->_mutate_string($input);
        }
    }
    elsif ($type eq 'ARRAY') {
        return $self->_mutate_array($input);
    }
    elsif ($type eq 'HASH') {
        return $self->_mutate_hash($input);
    }
    else {
        return $input;  # blessed ref etc — pass through
    }
}

sub _mutate_int {
    my ($self, $n) = @_;
    my @ops = (
        sub { $n + 1 },
        sub { $n - 1 },
        sub { $n * 2 },
        sub { $n == 0 ? 1 : int($n / 2) },
        sub { -$n },
        sub { 0 },
        sub { 2**31 - 1 },
        sub { -(2**31) },
    );
    return $ops[ int(rand(@ops)) ]->();
}

sub _mutate_num {
    my ($self, $n) = @_;
    my @ops = (
        sub { $n + rand(10) },
        sub { $n - rand(10) },
        sub { $n * (1 + rand()) },
        sub { 0 },
        sub { -$n },
    );
    return $ops[ int(rand(@ops)) ]->();
}

sub _mutate_string {
    my ($self, $s) = @_;
    my $len = length($s);
    my @ops = (
        # Bit flip on a random character
        sub {
            return $s unless $len;
            my $pos  = int(rand($len));
            my $char = substr($s, $pos, 1);
            substr($s, $pos, 1) = chr(ord($char) ^ (1 << int(rand(8))));
            $s
        },
        # Insert a random char
        sub {
            my $pos  = int(rand($len + 1));
            my $char = chr(int(rand(256)));
            substr($s, $pos, 0, $char);
            $s
        },
        # Delete a random char
        sub {
            return $s unless $len;
            my $pos = int(rand($len));
            substr($s, $pos, 1, '');
            $s
        },
        # Truncate
        sub { substr($s, 0, int(rand($len + 1))) },
        # Repeat
        sub { $s x 2 },
        # Interesting strings
        sub {
            my @interesting = ('', ' ', "\0", "\n", "\t",
                               'a' x 256, "null", "undefined",
                               "'; DROP TABLE foo; --",
                               "<script>alert(1)</script>");
            $interesting[ int(rand(@interesting)) ]
        },
    );
    return $ops[ int(rand(@ops)) ]->();
}

sub _mutate_array {
    my ($self, $arr) = @_;
    my @copy = @$arr;
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
        # Empty array
        sub { [] },
    );
    return $ops[ int(rand(@ops)) ]->();
}

sub _mutate_hash {
    my ($self, $h) = @_;
    my %copy = %$h;
    my @keys = keys %copy;
    return \%copy unless @keys;
    my $k = $keys[ int(rand(@keys)) ];
    $copy{$k} = $self->_mutate($copy{$k});
    return \%copy;
}

# ---------------------------------------------------------------------------
# Internal: corpus seeding
# ---------------------------------------------------------------------------

sub _seed_corpus {
    my ($self) = @_;
    # Generate a small set of diverse starting inputs
    for (1..5) {
        my $input = $self->_generate_random();
        push @{$self->{corpus}}, { input => $input, coverage => {} };
    }
}

# ---------------------------------------------------------------------------
# Internal: report
# ---------------------------------------------------------------------------

sub _build_report {
    my ($self) = @_;
    return {
        total_iterations => $self->{stats}{total},
        interesting_inputs => $self->{stats}{interesting},
        corpus_size      => scalar @{$self->{corpus}},
        branches_covered => $self->{stats}{coverage},
        bugs_found       => $self->{stats}{bugs},
        bugs             => $self->{bugs},
    };
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created with the
assistance of AI.

=cut

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
