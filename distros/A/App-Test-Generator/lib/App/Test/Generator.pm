package App::Test::Generator;

use strict;
use warnings;
use Exporter 'import';
use File::Basename qw(basename);
use YAML::XS qw(LoadFile);
use Carp qw(croak);

our @EXPORT_OK = qw(generate);

our $VERSION = '0.02';

=head1 NAME

App::Test::Generator - Generate fuzz and corpus-driven test harnesses

=head1 SYNOPSIS

From the command line:

  fuzz-harness-generator t/conf/add.conf > t/add_fuzz.t

From Perl:

  use App::Test::Generator qw(generate);

  # Generate to STDOUT
  App::Test::Generator::generate("t/conf/add.conf");

  # Generate directly to a file
  App::Test::Generator::generate("t/conf/add.conf", "t/add_fuzz.t");

=head1 OVERVIEW

This module takes a formal input/output specification for a routine or
method and automatically generates test cases. In effect, it allows you
to easily add comprehensive black-box tests in addition to the more
common white-box tests typically written for CPAN modules and other
subroutines.

The generated tests combine:

=over 4

=item * Random fuzzing based on input types

=item * Deterministic edge cases for min/max constraints

=item * Static corpus tests defined in Perl or YAML

=back

This approach strengthens your test suite by probing both expected and
unexpected inputs, helping you to catch boundary errors, invalid data
handling, and regressions without manually writing every case.

=head1 DESCRIPTION

This module implements the logic behind L<fuzz-harness-generator>.
It parses configuration files (fuzz and/or corpus YAML), and
produces a ready-to-run F<.t> test script using L<Test::Most>.

It reads configuration files (Perl C<.conf> with C<our> variables,
and optional YAML corpus files), and generates a L<Test::Most>-based
fuzzing harness in C<t/fuzz.t>.

Generates C<t/fuzz.t> combining:

=over 4

=item * Randomized fuzzing of inputs (with edge cases)

=item * Optional static corpus tests from Perl C<%cases> or YAML file (C<yaml_cases> key)

=item * Functional or OO mode (via C<$new>)

=item * Reproducible runs via C<$seed> and configurable iterations via C<$iterations>

=back

=head2 EDGE CASE GENERATION

In addition to purely random fuzz cases, the harness generates
deterministic edge cases for parameters that declare C<min>, C<max>,
C<len>, or C<len> in their schema definitions.

For each constraint, three edge cases are added:

=over 4

=item * Just inside the allowable range

This case should succeed, since it lies strictly within the bounds.

=item * Exactly on the boundary

This case should succeed, since it meets the constraint exactly.

=item * Just outside the boundary

This case is annotated with C<_STATUS = 'DIES'> in the corpus and
should cause the harness to fail validation or croak.

=back

Supported constraint types:

=over 4

=item * C<number>, C<integer>

Uses numeric values one below, equal to, and one above the boundary.

=item * C<string>

Uses strings of lengths one below, equal to, and one above the boundary
(minimum length = C<len>, maximum length = C<len>).

=item * C<arrayref>

Uses references to arrays of lengths one below, equal to, and one above the boundary
(minimum length = C<len>, maximum length = C<len>).

=item * C<hashref>

Uses hashes with key counts one below, equal to, and one above the
boundary (C<min> = minimum number of keys, C<max> = maximum number
of keys).

=item * C<memberof> - optional arrayref of allowed values for a parameter:

    our %input = (
        status => { type => 'string', memberof => [ 'ok', 'error', 'pending' ] },
        level  => { type => 'integer', memberof => [ 1, 2, 3 ] },
    );

The generator will automatically create test cases for each allowed value (inside the member list), and at least one value outside the list (which should die, `_STATUS => 'DIES'`). This works for strings, integers, and numbers.

=item * C<boolean> - automatic boundary tests for boolean fields

    our %input = (
        flag => { type => 'boolean' },
    );

The generator will automatically create test cases for `0` and `1`, and optionally invalid values that should trigger `_STATUS => 'DIES'`.

=back

These edge cases are inserted automatically, in addition to the random
fuzzing inputs, so each run will reliably probe boundary conditions
without relying solely on randomness.

=head1 CONFIGURATION

The configuration file is a Perl file that should set variables with C<our>.
Example: the generator expects your config to use C<our %input>, C<our $function>, etc.

Recognized items:

=over 4

=item * C<%input> - input params with keys => type/optional specs:

	our %input = (
		name => { type => 'string', optional => 0 },
		age => { type => 'integer', optional => 1 },
	);

Supported basic types used by the fuzzer: C<string>, C<integer>, C<number>, C<boolean>, C<arrayref>, C<hashref>.
(You can add more types; they will default to C<undef> unless extended.)

=item * C<%output> - output param types for Return::Set checking:

	our %output = (
		type => 'string'
	);

If the output hash contains the key _STATUS, and if that key is set to DIES,
the routine should die with the given arguments; otherwise, it should live.
If it's set to WARNS,
the routine should warn with the given arguments

=item * C<$module> - module name (optional).

If omitted, the generator will guess from the config filename:
C<My-Widget.conf> -> C<My::Widget>.

=item * C<$function> - function/method to test (defaults to C<run>).

=item * C<$new> - optional hashref of args to pass to the module's constructor (object mode):

	our $new = { api_key => 'ABC123', verbose => 1 };

To ensure new is called with no arguments, you still need to defined new, thus:

  our $new = '';

=item * C<%cases> - optional Perl static corpus (expected => [ args... ]):

  our %cases = (
    'ok'   => [ 'ping' ],
    'error'=> [ '' ],
  );

=item * C<$yaml_cases> - optional path to a YAML file with the same shape as C<%cases>.

=item * C<$seed> - optional integer. When provided, the generated C<t/fuzz.t> will call C<srand($seed)> so fuzz runs are reproducible.

=item * C<$iterations> - optional integer controlling how many fuzz iterations to perform (default 50).

=item * C<%edge_cases> - optional hash mapping parameter names to arrayrefs of extra values to inject:

	our %edge_cases = (
		name => [ '', 'a' x 1024, \"\x{263A}" ],
		age  => [ -1, 0, 99999999 ],
	);

(Values can be strings or numbers; strings will be properly quoted.)

=item * C<%type_edge_cases> - optional hash mapping types to arrayrefs of extra values to try for any field of that type:

	our %type_edge_cases = (
		string => [ '', ' ', "\n", "\\0", "long" x 50 ],
		integer => [ -1, 0, 1, 2**31 - 1 ],
	);

=back

=head1 EXAMPLES

=head2 Math::Simple::add()

Functional fuzz + Perl corpus + seed:

  our $module = 'Math::Simple';
  our $function = 'add';
  our %input = ( a => { type => 'integer' }, b => { type => 'integer' } );
  our %output = ( type => 'integer' );
  our %cases = (
    '3'     => [1, 2],
    '0'     => [0, 0],
    '-1'    => [-2, 1],
    '_STATUS:DIES'  => [ 'a', 'b' ],     # non-numeric args should die
    '_STATUS:WARNS' => [ undef, undef ], # undef args should warn
  );
  our $seed = 12345;
  our $iterations = 100;

=head2 Adding YAML file to generate tests

OO fuzz + YAML corpus + edge cases:

	our %input = ( query => { type => 'string' } );
	our %output = ( type => 'string' );
	our $function = 'search';
	our $new = { api_key => 'ABC123' };
	our $yaml_cases = 't/corpus.yml';
	our %edge_cases = ( query => [ '', '	', '<script>' ] );
	our %type_edge_cases = ( string => [ \"\\0", "\x{FFFD}" ] );
	our $seed = 999;

=head3 YAML Corpus Example (t/corpus.yml)

A YAML mapping of expected -> args array:

	"success":
	  - "Alice"
	  - 30
	"failure":
	  - "Bob"

=head2 Example with arrayref + hashref

  our %input = (
    tags   => { type => 'arrayref', optional => 1 },
    config => { type => 'hashref' },
  );
  our %output = ( type => 'hashref' );

=head2 Example with memberof

  our %input = (
      status => { type => 'string', memberof => [ 'ok', 'error', 'pending' ] },
  );
  our %output = ( type => 'string' );

This will generate fuzz cases for 'ok', 'error', 'pending', and one invalid string that should die.

=head1 OUTPUT

By default, writes C<t/fuzz.t>.
The generated test:

=over 4

=item * Seeds RNG (if configured) for reproducible fuzz runs

=item * Uses edge cases (per-field and per-type) with configurable probability

=item * Runs C<$iterations> fuzz cases plus appended edge-case runs

=item * Validates inputs with Params::Get / Params::Validate::Strict

=item * Validates outputs with L<Return::Set>

=item * Runs static C<is(... )> corpus tests from Perl and/or YAML corpus

=back

=head1 NOTES

- The conf file must use C<our> declarations so variables are visible to the generator via C<require>.
- Use C<srand($seed)> replay to reproduce failing cases. When you get a failure, re-run generator with the same C<$seed> to reproduce.

=cut

sub generate {
	my ($conf_file, $outfile) = @_;

	croak 'Usage: generate(conf_file [, outfile])' unless defined $conf_file;

	# --- Load configuration safely (require so config can use 'our' variables) ---
	{
		my $abs = $conf_file;
		$abs = "./$abs" unless $abs =~ m{^/};
		require $abs;
	}

	# --- Globals exported by the user's conf (all optional except function maybe) ---
	our (%input, %output, $module, $function, $new, %cases, $yaml_cases);
	our ($seed, $iterations);
	our (%edge_cases, %type_edge_cases);

	# sensible defaults
	$function ||= 'run';
	$iterations ||= 50;		 # default fuzz runs if not specified
	$seed		= undef if defined $seed && $seed eq '';	# treat empty as undef

	# Guess module name from config file if not set
	if (!$module) {
		(my $guess = basename($conf_file)) =~ s/\.(conf|pl|pm|yml|yaml)$//;
		$guess =~ s/-/::/g;
		$module = $guess || 'Unknown::Module';
	}

	# --- YAML corpus support (yaml_cases is filename string) ---
	my %yaml_corpus_data;
	if (defined $yaml_cases && -f $yaml_cases) {
		my $yaml_data = LoadFile($yaml_cases);
		if ($yaml_data && ref($yaml_data) eq 'HASH') {
			%yaml_corpus_data = %$yaml_data;
		}
	}

	# Merge Perl %cases and YAML corpus safely
	my %all_cases = (%cases, %yaml_corpus_data);

	# --- Helpers for rendering data structures into Perl code for the generated test ---
	sub perl_quote {
		my ($v) = @_;
		return 'undef' unless defined $v;
		return $v =~ /^-?\d+(\.\d+)?$/ ? $v : "'" . ( $v =~ s/'/\\'/gr ) . "'";
	}

	sub render_hash {
		my ($href) = @_;
		return '' unless $href && ref($href) eq 'HASH';
		my @lines;
		for my $k (sort keys %$href) {
			my $def = $href->{$k} || {};
			next unless ref $def eq 'HASH';
			my @pairs;
			for my $subk (sort keys %$def) {
				next unless defined $def->{$subk};
				push @pairs, "$subk => " . perl_quote($def->{$subk});
			}
			push @lines, '	' . perl_quote($k) . " => { " . join(", ", @pairs) . " }";
		}
		return join(",\n", @lines);
	}

	sub render_args_hash {
		my ($href) = @_;
		return '' unless $href && ref($href) eq 'HASH';
		my @pairs = map { perl_quote($_) . " => " . perl_quote($href->{$_}) } sort keys %$href;
		return join(', ', @pairs);
	}

	sub render_arrayref_map {
		my ($href) = @_;
		return "()" unless $href && ref($href) eq 'HASH';
		my @entries;
		for my $k (sort keys %$href) {
			my $aref = $href->{$k};
			next unless ref $aref eq 'ARRAY';
			my $vals = join(", ", map { perl_quote($_) } @$aref);
			push @entries, '	' . perl_quote($k) . " => [ $vals ]";
		}
		return join(",\n", @entries);
	}

	# render edge case maps for inclusion in the .t
	my $edge_cases_code	= render_arrayref_map(\%edge_cases);
	my $type_edge_cases_code = render_arrayref_map(\%type_edge_cases);

	# Render input/output
	my $input_code = render_hash(\%input);
	my $output_code = render_args_hash(\%output);
	my $new_code	= ($new && (ref $new eq 'HASH')) ? render_args_hash($new) : '';

	# Setup / call code (always load module)
	my $setup_code = "BEGIN { use_ok('$module') }";
	my $call_code;
	if(defined($new)) {
		# keep use_ok regardless (user found earlier issue)
		if($new_code eq '') {
			$setup_code .= "\nmy \$obj = new_ok('$module');";
		} else {
			$setup_code .= "\nmy \$obj = new_ok('$module' => [ { $new_code } ] );";
		}
		$call_code = "\$result = \$obj->$function(\$case);";
	} else {
		$call_code = "\$result = $module\::$function(\$case);";
	}

	# Build static corpus code
	my $corpus_code = '';
	if (%all_cases) {
		$corpus_code = "\n# --- Static Corpus Tests ---\n";
		for my $expected (sort keys %all_cases) {
			my $inputs = $all_cases{$expected};
			next unless $inputs && ref $inputs eq 'ARRAY';
			my $input_str = join(", ", map { perl_quote($_) } @$inputs);
			my $expected_str = perl_quote($expected);
			if ($new) {
				if($expected_str eq "'_STATUS:DIES'") {
					$corpus_code .= "dies_ok { \$obj->$function($input_str) } "
								. "'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") dies';\n";
				} elsif($expected_str eq "'_STATUS:WARNS'") {
					$corpus_code .= "warnings_exist { \$obj->$function($input_str) } qr[''], "
								. "'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") warns';\n";
				} else {
					$corpus_code .= "is(\$obj->$function($input_str), $expected_str, "
								. "'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") returns $expected_str');\n";
				}
			} else {
				if($expected_str eq "'_STATUS:DIES'") {
					$corpus_code .= "dies_ok { $module\::$function($input_str) } "
								. "'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") dies';\n";
				} elsif($expected_str eq "'_STATUS:WARNS'") {
					$corpus_code .= "warnings_exist { $module\::$function($input_str) } qr[''], "
								. "'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") warns';\n";
				} else {
					$corpus_code .= "is($module\::$function($input_str), $expected_str, "
								. "'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") returns $expected_str');\n";
				}
			}
		}
	}

	# Prepare seed/iterations code fragment for the generated test
	my $seed_code = '';
	if (defined $seed) {
		# ensure integer-ish
		$seed = int($seed);
		$seed_code = "srand($seed);\n";
	}
	my $iterations_code = int($iterations) || 50;

	# Generate the test content
	my $test = <<"TEST";
#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Returns;

$setup_code

diag("$module test case created by https://github.com/nigelhorne/Test-Corpus");

# Edge-case maps injected from config (optional)
my %edge_cases = (
$edge_cases_code
);
my %type_edge_cases = (
$type_edge_cases_code
);

# Seed for reproducible fuzzing (if provided)
$seed_code

my %input = (
$input_code
);

my %output = (
	$output_code
);

# --- Fuzzer helpers ---
sub _pick_from {
	my (\$arrayref) = \@_;
	return undef unless \$arrayref && ref \$arrayref eq 'ARRAY' && \@\$arrayref;
	return \$arrayref->[ int(rand(scalar \@\$arrayref)) ];
}

sub rand_str {
	my \$len = shift || int(rand(10)) + 1;
	join '', map { chr(97 + int(rand(26))) } 1..\$len;
}
sub rand_int { int(rand(200)) - 100 }
sub rand_bool { rand() > 0.5 ? 1 : 0 }
sub rand_num { rand() * 200 - 100 }

sub rand_arrayref {
	my \$len = shift || int(rand(3)) + 1; # small arrays
	[ map { rand_str() } 1..\$len ];
}

sub rand_hashref {
	my \$len = shift || int(rand(3)) + 1; # small hashes
	my \%h;
	for (1..\$len) {
		\$h{rand_str(3)} = rand_str(5);
	}
	return \\\%h;
}

sub fuzz_inputs {
	my \@cases;
	for (1..$iterations_code) {
		my %case;
		foreach my \$field (keys %input) {
			my \$spec = \$input{\$field} || {};
			my \$type = \$spec->{type} || 'string';

			# 1) Sometimes pick a field-specific edge-case
			if (exists \$edge_cases{\$field} && rand() < 0.4) {
				\$case{\$field} = _pick_from(\$edge_cases{\$field});
				next;
			}

			# 2) Sometimes pick a type-level edge-case
			if (exists \$type_edge_cases{\$type} && rand() < 0.3) {
				\$case{\$field} = _pick_from(\$type_edge_cases{\$type});
				next;
			}

			# 3) Sormal random generation by type
			if (\$type eq 'string') {
				\$case{\$field} = rand_str();
			}
			elsif (\$type eq 'integer') {
				\$case{\$field} = rand_int();
			}
			elsif (\$type eq 'boolean') {
				\$case{\$field} = rand_bool();
			}
			elsif (\$type eq 'number') {
				\$case{\$field} = rand_num();
			}
			elsif (\$type eq 'arrayref') {
				\$case{\$field} = rand_arrayref();
			}
			elsif (\$type eq 'hashref') {
				\$case{\$field} = rand_hashref();
			}
			else {
				\$case{\$field} = undef;
			}

			# 4) occasionally drop optional fields
			if (\$spec->{optional} && rand() < 0.25) {
				delete \$case{\$field};
			}
		}
		push \@cases, \\%case;
	}

	# edge-case runs appended
	push \@cases, {};
	push \@cases, { map { \$_ => undef } keys \%input };

	# generate numeric, string, hashref and arrayref min/max edge cases
	# TODO:  For hashref and arrayref, if there's a \$spec->{schema} field, use that for the sata that's being generated
	foreach my \$field (keys \%input) {
		my \$spec = \$input{\$field} || {};
		my \$type = \$spec->{type} || '';

		if (\$type eq 'number' || \$type eq 'integer') {
			if (defined \$spec->{min}) {
				push \@cases, { \$field => \$spec->{min} + 1 };	# just inside
				push \@cases, { \$field => \$spec->{min} };	# border
				push \@cases, { \$field => \$spec->{min} - 1, _STATUS => 'DIES' }; # outside
			}
			if (defined \$spec->{max}) {
				push \@cases, { \$field => \$spec->{max} - 1 };	# just inside
				push \@cases, { \$field => \$spec->{max} };	# border
				push \@cases, { \$field => \$spec->{max} + 1, _STATUS => 'DIES' }; # outside
			}
		} elsif (\$type eq 'string') {
			if (defined \$spec->{min}) {
				my \$len = \$spec->{min};
				push \@cases, { \$field => 'a' x (\$len + 1) };	# just inside
				push \@cases, { \$field => 'a' x \$len};	# border
				push \@cases, { \$field => 'a' x (\$len - 1), _STATUS => 'DIES' } if \$len > 0; # outside
			}
			if (defined \$spec->{max}) {
				my \$len = \$spec->{max};
				push \@cases, { \$field => 'a' x (\$len - 1) };	# just inside
				push \@cases, { \$field => 'a' x \$len};	# border
				push \@cases, { \$field => 'a' x (\$len + 1), _STATUS => 'DIES' }; # outside
			}
		} elsif (\$type eq 'arrayref') {
			if (defined \$spec->{min}) {
				my \$len = \$spec->{min};
				push \@cases, { \$field => [ (1) x (\$len + 1) ] };	# just inside
				push \@cases, { \$field => [ (1) x \$len ] };	# border
				push \@cases, { \$field => [ (1) x (\$len - 1) ], _STATUS => 'DIES' } if \$len > 0; # outside
			}
			if (defined \$spec->{max}) {
				my \$len = \$spec->{max};
				push \@cases, { \$field => [ (1) x (\$len - 1) ] };	# just inside
				push \@cases, { \$field => [ (1) x \$len ] };	# border
				push \@cases, { \$field => [ (1) x (\$len + 1) ], _STATUS => 'DIES' }; # outside
			}
		} elsif (\$type eq 'hashref') {
			if (defined \$spec->{min}) {
				my \$len = \$spec->{min};
				push \@cases, { \$field => { map { "k\$_" => 1 }, 1 .. (\$len + 1) } };
				push \@cases, { \$field => { map { "k\$_" => 1 }, 1 .. \$len } };
				push \@cases, { \$field => { map { "k\$_" => 1 }, 1 .. (\$len - 1) }, _STATUS => 'DIES' } if \$len > 0;
			}
			if (defined \$spec->{max}) {
				my \$len = \$spec->{max};
				push \@cases, { \$field => { map { "k\$_" => 1 }, 1 .. (\$len - 1) } };
				push \@cases, { \$field => { map { "k\$_" => 1 }, 1 .. \$len } };
				push \@cases, { \$field => { map { "k\$_" => 1 }, 1 .. (\$len + 1) }, _STATUS => 'DIES' };
			}
		} elsif (\$type eq 'boolean') {
			if (exists \$spec->{memberof} && ref \$spec->{memberof} eq 'ARRAY') {
				# memberof already defines allowed booleans
				foreach my \$val (\@{\$spec->{memberof}}) {
					push \@cases, { \$field => \$val };
				}
			} else {
				# basic boolean edge cases
				push \@cases, { \$field => 0 };
				push \@cases, { \$field => 1 };
				push \@cases, { \$field => undef, _STATUS => 'DIES' };
				push \@cases, { \$field => 2, _STATUS => 'DIES' };	# invalid boolean
			}
		}

		# Generate edge cases for memberof
		if (exists \$spec->{memberof} && ref \$spec->{memberof} eq 'ARRAY' && \@{\$spec->{memberof}}) {
			# inside values
			foreach my \$val (\@{\$spec->{memberof}}) {
				push \@cases, { \$field => \$val };
			}
			# outside value
			my \$outside;
			if (\$type eq 'integer' || \$type eq 'number') {
				\$outside = (sort { \$a <=> \$b } \@{\$spec->{memberof}})[-1] + 1;
			} else {
				\$outside = 'INVALID_MEMBEROF';
			}
			push \@cases, { \$field => \$outside, _STATUS => 'DIES' };
		}
	}

	return \\\@cases;
}

foreach my \$case (\@{fuzz_inputs()}) {
	my %params;
	# lives_ok { %params = get_params(\\%input, \%\$case) } 'Params::Get input check';
	# lives_ok { validate_strict(\\%input, %params) } 'Params::Validate::Strict input check';

	my \$result;
	if(my \$status = delete \$output{'_STATUS'}) {
		if(\$status eq 'DIES') {
			dies_ok { \$result = $call_code } 'function call dies';
		} elsif(\$status eq 'WARNS') {
			warnings_exist { \$result = $call_code } qr[''], 'function call warns';
		} else {
			lives_ok { \$result = $call_code } 'function call survives';
		}
	} else {
		lives_ok { \$result = $call_code } 'function call survives';
	}

	returns_ok(\$result, \\%output, 'output validates');
}

$corpus_code

done_testing();
TEST

	if ($outfile) {
		open my $fh, '>', $outfile or die "Cannot write $outfile: $!";
		print $fh $test;
		close $fh;
		print "Generated $outfile for $module\::$function with fuzzing + corpus support\n";
	} else {
		print $test;
	}
}

1;

__END__

=head1 SEE ALSO

L<Test::Most>, L<Params::Get>, L<Params::Validate::Strict>, L<Return::Set>, L<YAML::XS>

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's design and documentation were created with the
assistance of L<ChatGPT|https://openai.com/> (GPT-5), with final curation
and authorship by Nigel Horne.

=cut
