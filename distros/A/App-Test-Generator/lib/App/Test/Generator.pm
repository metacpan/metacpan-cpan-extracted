package App::Test::Generator;

# TODO: Test validator from Params::Validate::Strict 0.16
# TODO: $seed should be passed to Data::Random::String::Matches
# TODO: positional args - when config_undef is set, see what happens when not all args are given

use strict;
use warnings;
use autodie qw(:all);

use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use open qw(:std :encoding(UTF-8));

use Carp qw(carp croak);
use Config::Abstraction 0.36;
use Data::Dumper;
use Data::Section::Simple;
use File::Basename qw(basename);
use File::Spec;
use Module::Load::Conditional qw(check_install can_load);
use Template;
use YAML::XS qw(LoadFile);

use Exporter 'import';

our @EXPORT_OK = qw(generate);

our $VERSION = '0.14';

=head1 NAME

App::Test::Generator - Generate fuzz and corpus-driven test harnesses

=head1 VERSION

Version 0.14

=head1 SYNOPSIS

From the command line:

  fuzz-harness-generator t/conf/add.yml > t/add_fuzz.t

From Perl:

  use App::Test::Generator qw(generate);

  # Generate to STDOUT
  App::Test::Generator::generate("t/conf/add.yml");

  # Generate directly to a file
  App::Test::Generator::generate('t/conf/add.yml', 't/add_fuzz.t');

=encoding utf8

=head1 OVERVIEW

This module takes a formal input/output specification for a routine or
method and automatically generates test cases. In effect, it allows you
to easily add comprehensive black-box tests in addition to the more
common white-box tests that are typically written for CPAN modules and other
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

It reads configuration files in any format
(including Perl C<.conf> with C<our> variables, though this format will be deprecated in a future release)
and optional YAML corpus files,
and generates a L<Test::Most>-based fuzzing harness combining:

=over 4

=item * Randomized fuzzing of inputs (with edge cases)

=item * Optional static corpus tests from Perl C<%cases> or YAML file (C<yaml_cases> key)

=item * Functional or OO mode (via C<$new>)

=item * Reproducible runs via C<$seed> and configurable iterations via C<$iterations>

=back

=head1 CONFIGURATION

The configuration file is either a file that can be read by L<Config::Abstraction> or a B<trusted input> Perl file that should set variables with C<our>.

The documentation here covers the old trusted input style input, but that will go away so you are recommended to use
L<Config::Abstraction> files.
Example: the generator expects your config to use C<our %input>, C<our $function>, etc.

=head2 SCHEMA

Recognized items:

=over 4

=item * C<%input> - input params with keys => type/optional specs:

When using named parameters

  input:
    name:
      type: string
      optional: false
    age:
      type: integer
      optional: true

Supported basic types used by the fuzzer: C<string>, C<integer>, C<number>, C<boolean>, C<arrayref>, C<hashref>.
(You can add more types; they will default to C<undef> unless extended.)

For routines with one unnamed parameter

  input:
    type: string

Currently, routines with more than one unnamed parameter are not supported.

The keyword C<undef> is used to indicate that the C<function> takes no arguments.

=item * C<%output> - output param types for Return::Set checking:

  output:
    type: string

If the output hash contains the key _STATUS, and if that key is set to DIES,
the routine should die with the given arguments; otherwise, it should live.
If it's set to WARNS,
the routine should warn with the given arguments.
The output can be set to the string 'undef' if the routine should return the undefined value:

  ---
  module: Scalar::Util
  function: blessed

  input:
    arg1: string

  output: undef

The keyword C<undef> is used to indicate that the C<function> returns nothing.

=item * C<%transforms> - list of transformations from input sets to output sets

It takes a list of subsets of the input and output definitions,
and verifies that data from each input subset is correctly transformed into data from the matching output subset.

This is a draft definition of the schema.

  ---
  module: builtin
  function: abs

  config:
    test_undef: no
    test_empty: no
    test_nuls: no

  input:
    number:
      type: number
      position: 0
  output:
    type: number
    min: 0
  transforms:
    positive:
      input:
        number:
          type: number
          position: 0
          min: 0
      output:
        type: number
        min: 0
    negative:
      input:
        number:
          type: number
          position: 0
          max: 0
      output:
        type: number
        min: 0
    error:
      input:
        undef
      output:
        _STATUS: DIES

If the output hash contains the key _STATUS, and if that key is set to DIES,
the routine should die with the given arguments; otherwise, it should live.
If it's set to WARNS,
the routine should warn with the given arguments.

The keyword C<undef> is used to indicate that the C<function> returns nothing.

=item * C<$module> - module name (optional).

Using the reserved word C<builtin> means you're testing a Perl builtin function.

If omitted, the generator will guess from the config filename:
C<My-Widget.conf> -> C<My::Widget>.

=item * C<$function> - function/method to test (defaults to C<run>).

=item * C<$new> - optional hashref of args to pass to the module's constructor (object mode):

  new:
    api_key: ABC123
    verbose: true

To ensure C<new()> is called with no arguments, you still need to define new, thus:

  module: MyModule
  function: my_function

  new:

For the legacy Perl variable syntax, use the empty string:

  our $new = '';

=item * C<%cases> - optional Perl static corpus, when the output is a simple string (expected => [ args... ]):

Maps the expected output string to the input and _STATUS

  cases:
    ok:
      input: ping
      status: OK
    error:
      input: ""
      status: DIES

=item * C<$yaml_cases> - optional path to a YAML file with the same shape as C<%cases>.

=item * C<$seed> - optional integer. When provided, the generated C<t/fuzz.t> will call C<srand($seed)> so fuzz runs are reproducible.

=item * C<$iterations> - optional integer controlling how many fuzz iterations to perform (default 50).

=item * C<%edge_cases> - optional hash mapping of extra values to inject:

	# Two named parameters
	our %edge_cases = (
		name => [ '', 'a' x 1024, \"\x{263A}" ],
		age => [ -1, 0, 99999999 ],
	);

	# Takes a string input
	our %edge_cases (
		'foo', 'bar'
	);

(Values can be strings or numbers; strings will be properly quoted.)
Note that this only works with routines that take named parameters.

=item * C<%type_edge_cases> - optional hash mapping types to arrayrefs of extra values to try for any field of that type:

	our %type_edge_cases = (
		string => [ '', ' ', "\t", "\n", "\0", 'long' x 1024, chr(0x1F600) ],
		number => [ 0, 1.0, -1.0, 1e308, -1e308, 1e-308, -1e-308, 'NaN', 'Infinity' ],
		integer => [ 0, 1, -1, 2**31-1, -(2**31), 2**63-1, -(2**63) ],
	);

=item * C<%edge_case_array> - specify edge case values for routines that accept a single unnamed parameter

This is specifically designed for simple functions that take one argument without a parameter name.
These edge cases supplement the normal random string generation, ensuring specific problematic values are always tested.
During fuzzing iterations, there's a 40% probability that a test case will use a value from edge_case_array instead of randomly generated data.

  ---
  module: Text::Processor
  function: sanitize

  input:
    type: string
    min: 1
    max: 1000

  edge_case_array:
    - "<script>alert('xss')</script>"
    - "'; DROP TABLE users; --"
    - "\0null\0byte"
    - "emoji😊test"
    - ""
    - " "

  seed: 42
  iterations: 50

=item * C<%config> - optional hash of configuration.

The current supported variables are

=over 4

=item * C<test_nuls>, inject NUL bytes into strings (default: 1)

=item * C<test_undef>, test with undefined value (default: 1)

=item * C<test_empty>, test with empty strings (default: 1)

=item * C<dedup>, fuzzing can create duplicate tests, go some way to remove duplicates (default: 1)

=back

=back

=head2 OUTPUT

The generated test:

=over 4

=item * Seeds RND (if configured) for reproducible fuzz runs

=item * Uses edge cases (per-field and per-type) with configurable probability

=item * Runs C<$iterations> fuzz cases plus appended edge-case runs

=item * Validates inputs with Params::Get / Params::Validate::Strict

=item * Validates outputs with L<Return::Set>

=item * Runs static C<is(... )> corpus tests from Perl and/or YAML corpus

=back

=head2 TRANSFORMS

=head3 Overview

Transforms allow you to define how input data should be transformed into output data.
This is useful for testing functions that convert between formats, normalize data,
or apply business logic transformations on a set of data to different set of data.

Transform schema also have the keyword C<value>, when a specific value is required

=head3 Configuration Example

  ---
  module: Math::Utils
  function: normalize_number

  input:
    value:
      type: number
      position: 0

  output:
    type: number

  transforms:
    positive_stays_positive:
      input:
        value:
          type: number
          min: 0
          max: 1000
      output:
        type: number
        min: 0
        max: 1

    negative_becomes_zero:
      input:
        value:
          type: number
          max: 0
      output:
        type: number
        value: 0

    preserves_zero:
      input:
        value:
          type: number
          value: 0
      output:
        type: number
        value: 0

=head3 Transform Validation Rules

For each transform:
1. Generate test cases using the transform's input schema
2. Call the function with those inputs
3. Validate the output matches the transform's output schema
4. If output has a specific 'value', check exact match
5. If output has constraints (min/max), validate within bounds

=head2 EDGE CASE GENERATION

In addition to purely random fuzz cases, the harness generates
deterministic edge cases for parameters that declare C<min>, C<max> or C<len> in their schema definitions.

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

Uses strings of lengths one below, equal to, and one above the boundary.

=item * C<arrayref>

Uses references to arrays of with the number of elements one below, equal to, and one above the boundary.

=item * C<hashref>

Uses hashes with key counts one below, equal to, and one above the
boundary (C<min> = minimum number of keys, C<max> = maximum number
of keys).

=item * C<memberof> - arrayref of allowed values for a parameter

This example is for a routine called C<input()> that takes two arguments: C<status> and C<level>.
C<status> is a string that must have the value C<ok>, C<error> or C<pending>.
The C<level> argument is an integer that must be one of C<1>, C<5> or C<111>.

  ---
  input:
    status:
      type: string
      memberof:
        - ok
        - error
        - pending
    level:
      type: integer
      memberof:
        - 1
        - 5
        - 111

The generator will automatically create test cases for each allowed value (inside the member list),
and at least one value outside the list (which should die or C<croak>, C<_STATUS = 'DIES'>).
This works for strings, integers, and numbers.

=item * C<boolean> - automatic boundary tests for boolean fields

  input:
    flag:
      type: boolean

The generator will automatically create test cases for 0 and 1; true and false; off and on, and values that should trigger C<_STATUS = 'DIES'>.

=back

These edge cases are inserted automatically, in addition to the random
fuzzing inputs, so each run will reliably probe boundary conditions
without relying solely on randomness.

=head1 EXAMPLES

=head2 Math::Simple::add()

Functional fuzz + Perl corpus + seed:

  our $module = 'Math::Simple';
  our $function = 'add';
  our %input = ( a => { type => 'integer' }, b => { type => 'integer' } );
  our %output = ( type => 'integer' );
  our %cases = (
    '3' => [1, 2],
    '0' => [0, 0],
    '-1' => [-2, 1],
    '_STATUS:DIES' => [ 'a', 'b' ],     # non-numeric args should die
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
    tags => { type => 'arrayref', optional => 1 },
    config => { type => 'hashref' },
  );
  our %output = ( type => 'hashref' );

=head2 Example with memberof

  our %input = (
      status => { type => 'string', memberof => [ 'ok', 'error', 'pending' ] },
  );
  our %output = ( type => 'string' );
  our %config = ( test_nuls => 0, test_undef => 1 );

This will generate fuzz cases for 'ok', 'error', 'pending', and one invalid string that should die.

=head2 Adding Scheduled fuzz Testing with GitHub Actions to Your Code

To automatically create and run tests on a regular basis on GitHub Actions,
you need to create a configuration file for each method and subroutine that you're testing,
and a GitHub Actions configuration file.

This example takes you through testing the online_render method of L<HTML::Genealogy::Map>.

=head3 t/conf/online_render.yml

  ---

  module: HTML::Genealogy::Map
  function: onload_render

  input:
    gedcom:
      type: object
      can: individuals
    geocoder:
      type: object
      can: geocode
    debug:
      type: boolean
      optional: true
    google_key:
      type: string
      optional: true
      min: 39
      max: 39
      matches: "^AIza[0-9A-Za-z_-]{35}$"

  config:
    test_undef: 0

=head3 .github/actions/fuzz.t

  ---
  name: Fuzz Testing

  permissions:
    contents: read

  on:
    push:
      branches: [main, master]
    pull_request:
      branches: [main, master]
    schedule:
      - cron: '29 5 14 * *'

  jobs:
    generate-fuzz-tests:
      strategy:
        fail-fast: false
        matrix:
          os:
            - macos-latest
            - ubuntu-latest
            - windows-latest
          perl: ['5.42', '5.40', '5.38', '5.36', '5.34', '5.32', '5.30', '5.28', '5.22']

      runs-on: ${{ matrix.os }}
      name: Fuzz testing with perl ${{ matrix.perl }} on ${{ matrix.os }}

      steps:
        - uses: actions/checkout@v5

        - name: Set up Perl
          uses: shogo82148/actions-setup-perl@v1
          with:
            perl-version: ${{ matrix.perl }}

        - name: Install App::Test::Generator this module's dependencies
          run: |
            cpanm App::Test::Generator
            cpanm --installdeps .

        - name: Make Module
          run: |
            perl Makefile.PL
            make
          env:
            AUTOMATED_TESTING: 1
            NONINTERACTIVE_TESTING: 1

        - name: Generate fuzz tests
          run: |
            mkdir t/fuzz
            find t/conf -name '*.yml' | while read config; do
              test_name=$(basename "$config" .conf)
              fuzz-harness-generator "$config" > "t/fuzz/${test_name}_fuzz.t"
            done

        - name: Run generated fuzz tests
          run: |
            prove -lr t/fuzz/
          env:
            AUTOMATED_TESTING: 1
            NONINTERACTIVE_TESTING: 1

=head1 METHODS

  generate($schema_file, $test_file)

Takes a schema file and produces a test file (or STDOUT).

=cut

sub generate
{
	my ($schema_file, $test_file) = @_;

	# --- Globals exported by the user's conf (all optional except function maybe) ---
	# Ensure data don't persist across calls, which would allow
	local our (%input, %output, %config, $module, $function, $new, %cases, $yaml_cases, %transforms);
	local our ($seed, $iterations);
	local our (%edge_cases, @edge_case_array, %type_edge_cases);

	@edge_case_array = ();

	if(defined($schema_file)) {
		# --- Load configuration safely (require so config can use 'our' variables) ---
		# FIXME:  would be better to use Config::Abstraction, since requiring the user's config could execute arbitrary code
		# my $abs = $schema_file;
		# $abs = "./$abs" unless $abs =~ m{^/};
		# require $abs;

		my $config;
		if($config = Config::Abstraction->new(config_dirs => ['.', ''], config_file => $schema_file)) {
			$config = $config->all();
			if(defined($config->{'$module'}) || defined($config->{'our $module'}) || !defined($config->{'module'})) {
				# Legacy file format. This will go away.
				# TODO: remove this code
				$config = _load_conf(File::Spec->rel2abs($schema_file));
				if($config) {
					carp("$schema_file: Loading perl files as configs is deprecated and will be removed soon.");
				}
			}
		}

		if($config) {
			%config = %{$config->{config}} if(exists($config->{config}));
			if(exists($config->{input})) {
				if(ref($config->{input}) eq 'HASH') {
					%input = %{$config->{input}}
				} elsif(defined($config->{'input'}) && ($config->{'input'} ne 'undef')) {
					croak("$schema_file: input should be a hash, not ", ref($config->{'input'}));
				}
			}
			if(exists($config->{output})) {
				if(ref($config->{output}) eq 'HASH') {
					%output = %{$config->{output}}
				} elsif(defined($config->{'output'}) && ($config->{'output'} ne 'undef')) {
					croak("$schema_file: output should be a hash");
				}
			}
			if(exists($config->{transforms})) {
				if(ref($config->{transforms}) eq 'HASH') {
					%transforms = %{$config->{transforms}}
				} elsif(defined($config->{'transforms'}) && ($config->{'transforms'} ne 'undef')) {
					croak("$schema_file: transforms should be a hash");
				}
			}
			%cases = %{$config->{cases}} if(exists($config->{cases}));
			%edge_cases = %{$config->{edge_cases}} if(exists($config->{edge_cases}));
			%type_edge_cases = %{$config->{type_edge_cases}} if(exists($config->{type_edge_cases}));

			$module = $config->{module} if(exists($config->{module}));
			$function = $config->{function} if(exists($config->{function}));
			if(exists($config->{new})) {
				$new = defined($config->{'new'}) ? $config->{new} : '_UNDEF';
			}
			$yaml_cases = $config->{yaml_cases} if(exists($config->{yaml_cases}));
			$seed = $config->{seed} if(exists($config->{seed}));
			$iterations = $config->{iterations} if(exists($config->{iterations}));

			@edge_case_array = @{$config->{edge_case_array}} if(exists($config->{edge_case_array}));
		}
		_validate_config($config);
	} else {
		croak 'Usage: generate(schema_file [, outfile])';
	}

	# dedup: fuzzing can easily generate repeats, default is to remove duplicates
	foreach my $field ('test_nuls', 'test_undef', 'test_empty', 'dedup') {
		if(exists($config{$field})) {
			if(($config{$field} eq 'false') || ($config{$field} eq 'off') || ($config{$field} eq 'no')) {
				$config{$field} = 0;
			} elsif(($config{$field} eq 'true') || ($config{$field} eq 'on') || ($config{$field} eq 'yes')) {
				$config{$field} = 1;
			}
		} else {
			$config{$field} = 1;
		}
	}

	# Guess module name from config file if not set
	if($module eq 'builtin') {
		undef $module;
	} elsif(!$module) {
		(my $guess = basename($schema_file)) =~ s/\.(conf|pl|pm|yml|yaml)$//;
		$guess =~ s/-/::/g;
		$module = $guess || 'builtin';
	}

	if($module && ($module ne 'builtin')) {
		_validate_module($module, $schema_file)
	}

	# sensible defaults
	$function ||= 'run';
	$iterations ||= 50;		 # default fuzz runs if not specified
	$seed = undef if defined $seed && $seed eq '';	# treat empty as undef

	# --- YAML corpus support (yaml_cases is filename string) ---
	my %yaml_corpus_data;
	if (defined $yaml_cases) {
		croak("$yaml_cases: $!") if(!-f $yaml_cases);

		my $yaml_data = LoadFile(Encode::decode('utf8', $yaml_cases));
		if ($yaml_data && ref($yaml_data) eq 'HASH') {
			# Validate that the corpus inputs are arrayrefs
			# e.g: "FooBar": 	["foo_bar"]
			my $valid_input = 1;
			for my $expected (keys %{$yaml_data}) {
				my $outputs = $yaml_data->{$expected};
				unless($outputs && (ref $outputs eq 'ARRAY')) {
					carp("$yaml_cases: $expected does not point to an array ref, ignoring");
					$valid_input = 0;
				}
			}

			%yaml_corpus_data = %$yaml_data if($valid_input);
		}
	}

	# Merge Perl %cases and YAML corpus safely
	# my %all_cases = (%cases, %yaml_corpus_data);
	my %all_cases = (%yaml_corpus_data, %cases);
	for my $k (keys %yaml_corpus_data) {
		if (exists $cases{$k} && ref($cases{$k}) eq 'ARRAY' && ref($yaml_corpus_data{$k}) eq 'ARRAY') {
			$all_cases{$k} = [ @{$yaml_corpus_data{$k}}, @{$cases{$k}} ];
		}
	}

	# --- Helpers for rendering data structures into Perl code for the generated test ---

	sub _load_conf {
		my $file = $_[0];

		my $pkg = 'ConfigLoader';

		# eval in a separate package
		{
			package ConfigLoader;
			no strict 'refs';
			do $file or die "Error loading $file: ", ($@ || $!);
		}

		# Now pull variables from ConfigLoader
		my @vars = qw(
			module new edge_cases function input output cases yaml_cases
			seed iterations edge_case_array type_edge_cases config
		);

		my %conf;
		no strict 'refs';	# allow symbolic references here
		for my $v (@vars) {
			if(my $full = "${pkg}::$v") {
				if (defined ${$full}) {	# scalar
					$conf{$v} = ${$full};
				} elsif (@{$full}) {	# array
					$conf{$v} = [ @{$full} ];
				} elsif (%{$full}) {	# hash
					$conf{$v} = { %{$full} };
				}
			}
		}

		return \%conf;
	}

	# Input validation for configuration
	sub _validate_config {
		my $config = $_[0];

		if((!defined($config->{'module'})) && (!defined($config->{'function'}))) {
			# Can't work out what should be tested
			croak('At least one of function and module must be defined');
		}

		if((!defined($config->{'input'})) && (!defined($config->{'output'}))) {
			# Routine takes no input and no output, so there's nothing that would be gained using this software
			croak('You must specify at least one of input and output');
		}
		if(($config->{'input'}) && (ref($config->{input}) ne 'HASH')) {
			if($config->{'input'} eq 'undef') {
				delete $config->{'input'};
			} else {
				croak('Invalid input specification')
			}
		}

		# Validate types, constraints, etc.
		for my $param (keys %{$config->{input}}) {
			my $spec = $config->{input}{$param};
			if(ref($spec)) {
				croak "Invalid type for parameter '$param'" unless _valid_type($spec->{type});
			} else {
				croak "Invalid type $spec for parameter '$param'" unless _valid_type($spec);
			}
		}
	}

	sub _valid_type
	{
		my $type = $_[0];

		return(($type eq 'string') ||
			($type eq 'boolean') ||
			($type eq 'integer') ||
			($type eq 'number') ||
			($type eq 'float') ||
			($type eq 'object'));
	}

	sub _validate_module {
		my ($module, $schema_file) = @_;

		return 1 unless $module;	# No module to validate (builtin functions)

		# Check if the module can be found
		my $mod_info = check_install(module => $module);

		if (!$mod_info) {
			# Module not found - this is just a warning, not an error
			# The module might not be installed on the generation machine
			# but could be on the test machine
			carp("Warning: Module '$module' not found in \@INC during generation.");
			carp("  Config file: $schema_file");
			carp("  This is OK if the module will be available when tests run.");
			carp('  If this is unexpected, check your module name and installation.');
			return 0;  # Not found, but not fatal
		}

		# Module was found
		if ($ENV{TEST_VERBOSE} || $ENV{GENERATOR_VERBOSE}) {
			print STDERR "Found module '$module' at: $mod_info->{file}\n",
				'  Version: ', ($mod_info->{version} || 'unknown'), "\n";
		}

		# Optionally try to load it (disabled by default since it can have side effects)
		if ($ENV{GENERATOR_VALIDATE_LOAD}) {
			my $loaded = can_load(modules => { $module => undef }, verbose => 0);

			if (!$loaded) {
				carp("Warning: Module '$module' found but failed to load: $Module::Load::Conditional::ERROR");
				carp("  This might indicate a broken installation or missing dependencies.");
				return 0;
			}

			if ($ENV{TEST_VERBOSE} || $ENV{GENERATOR_VERBOSE}) {
				print STDERR "Successfully loaded module '$module'\n";
			}
		}

		return 1;
	}

	sub perl_sq {
		my $s = $_[0];
		$s =~ s/\\/\\\\/g; $s =~ s/'/\\'/g; $s =~ s/\n/\\n/g; $s =~ s/\r/\\r/g; $s =~ s/\t/\\t/g;
		return $s;
	}

	sub perl_quote {
		my $v = $_[0];
		return 'undef' unless defined $v;
		if(ref($v)) {
			if(ref($v) eq 'ARRAY') {
				my @quoted_v = map { perl_quote($_) } @{$v};
				return '[ ' . join(', ', @quoted_v) . ' ]';
			}
			if(ref($v) eq 'Regexp') {
				my $s = "$v";

				# default to qr{...}
				return "qr{$s}" unless $s =~ /[{}]/;

				# fallback: quote with slash if no slash inside
				return "qr/$s/" unless $s =~ m{/};

				# fallback: quote with # if slash inside
				return "qr#$s#";
			}
			# Generic fallback
			$v = Dumper($v);
			$v =~ s/\$VAR1 =//;
			$v =~ s/;//;
			return $v;
		}
		$v =~ s/\\/\\\\/g;
		# return $v =~ /^-?\d+(\.\d+)?$/ ? $v : "'" . ( $v =~ s/'/\\'/gr ) . "'";
		return $v =~ /^-?\d+(\.\d+)?$/ ? $v : "'" . perl_sq($v) . "'";
	}

	sub render_hash {
		my $href = $_[0];
		return '' unless $href && ref($href) eq 'HASH';
		my @lines;
		for my $k (sort keys %$href) {
			my $def = $href->{$k} || {};
			next unless ref $def eq 'HASH';
			my @pairs;
			for my $subk (sort keys %$def) {
				next unless defined $def->{$subk};
				if(ref($def->{$subk})) {
					unless((ref($def->{$subk}) eq 'ARRAY') || (ref($def->{$subk}) eq 'Regexp')) {
						croak(__PACKAGE__, ": schema_file, $subk is a nested element, not yet supported (", ref($def->{$subk}), ')');
					}
				}
				if(($subk eq 'matches') || ($subk eq 'nomatch')) {
					push @pairs, "$subk => qr/$def->{$subk}/";
				} else {
					push @pairs, "$subk => " . perl_quote($def->{$subk});
				}
			}
			push @lines, '	' . perl_quote($k) . " => { " . join(", ", @pairs) . " }";
		}
		return join(",\n", @lines);
	}

	sub render_args_hash {
		my $href = $_[0];
		return '' unless $href && ref($href) eq 'HASH';
		my @pairs = map { perl_quote($_) . ' => ' . perl_quote($href->{$_}) } sort keys %$href;
		return join(', ', @pairs);
	}

	sub render_arrayref_map {
		my $href = $_[0];
		return '()' unless $href && ref($href) eq 'HASH';
		my @entries;
		for my $k (sort keys %$href) {
			my $aref = $href->{$k};
			next unless ref $aref eq 'ARRAY';
			my $vals = join(', ', map { perl_quote($_) } @$aref);
			push @entries, '	' . perl_quote($k) . " => [ $vals ]";
		}
		return join(",\n", @entries);
	}

	# Robustly quote a string (GitHub#1)
	sub q_wrap {
		my $s = $_[0];
		for my $p ( ['{','}'], ['(',')'], ['[',']'], ['<','>'] ) {
			my ($l,$r) = @$p;
			return "q$l$s$r" unless $s =~ /\Q$l\E|\Q$r\E/;
		}
		for my $d ('~', '!', '%', '^', '=', '+', ':', ',', ';', '|', '/', '#') {
			return "q$d$s$d" unless index($s, $d) >= 0;
		}
		(my $esc = $s) =~ s/'/\\'/g;
		return "'$esc'";
	}

	# render edge case maps for inclusion in the .t
	my $edge_cases_code = render_arrayref_map(\%edge_cases);
	my $type_edge_cases_code = render_arrayref_map(\%type_edge_cases);

	my $edge_case_array_code = '';
	if(scalar(@edge_case_array)) {
		$edge_case_array_code = join(', ', map { q_wrap($_) } @edge_case_array);
	}

	# Render configuration - all the values are integers for now, if that changes, wrap the $config{$key} in single quotes
	my $config_code = '';
	foreach my $key (sort keys %config) {
		$config_code .= "'$key' => $config{$key},\n";
	}

	# Render input/output
	my $input_code = '';
	if(((scalar keys %input) == 1) && exists($input{'type'}) && !ref($input{'type'})) {
		# our %input = ( type => 'string' );
		foreach my $key (sort keys %input) {
			$input_code .= "'$key' => '$input{$key}',\n";
		}
	} else {
		# our %input = ( str => { type => 'string' } );
		$input_code = render_hash(\%input);
	}
	if(defined(my $re = $output{'matches'})) {
		if(ref($re) ne 'Regexp') {
			$re = qr/$re/;
			$output{'matches'} = $re;
		}
	}
	my $output_code = render_args_hash(\%output);
	my $new_code = ($new && (ref $new eq 'HASH')) ? render_args_hash($new) : '';

	my $transforms_code;
	if(keys %transforms) {
		foreach my $transform(keys %transforms) {
			if($transforms_code) {
				$transforms_code .= "},\n";
			}
			$transforms_code .= "$transform => {\n" .
				"\t'input' => { " .
				render_args_hash($transforms{$transform}->{'input'}) .
				"\t}, 'output' => { " .
			render_args_hash($transforms{$transform}->{'output'}) .
			"\t},\n";
		}
		$transforms_code .= "}\n";
	}

	# Setup / call code (always load module)
	my $setup_code = ($module) ? "BEGIN { use_ok('$module') }" : '';
	my $call_code;
	if(defined($new)) {
		# keep use_ok regardless (user found earlier issue)
		if($new_code eq '') {
			$setup_code .= "\nmy \$obj = new_ok('$module');";
		} else {
			$setup_code .= "\nmy \$obj = new_ok('$module' => [ { $new_code } ] );";
		}
		$call_code = "\$result = \$obj->$function(\$input);";
	} elsif(defined($module)) {
		$call_code = "\$result = $module\->$function(\$input);";
	} else {
		$call_code = "\$result = $function(\$input);";
	}

	# Build static corpus code
	my $corpus_code = '';
	if (%all_cases) {
		$corpus_code = "\n# --- Static Corpus Tests ---\n";
		for my $expected (sort keys %all_cases) {
			my $inputs = $all_cases{$expected};
			next unless($inputs && (ref $inputs eq 'ARRAY'));

			my $expected_str = perl_quote($expected);
			my $status = ((ref($inputs) eq 'HASH') && $inputs->{'_STATUS'}) // 'OK';
			if($expected_str eq "'_STATUS:DIES'") {
				$status = 'DIES';
			} elsif($expected_str eq "'_STATUS:WARNS'") {
				$status = 'WARNS';
			}

			if(ref($inputs) eq 'HASH') {
				$inputs = $inputs->{'input'};
			}
			my $input_str = join(', ', map { perl_quote($_) } @$inputs);
			if ($new) {
				if($status eq 'DIES') {
					$corpus_code .= "dies_ok { \$obj->$function($input_str) } " .
							"'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") dies';\n";
				} elsif($status eq 'WARNS') {
					$corpus_code .= "warnings_exist { \$obj->$function($input_str) } qr/./, " .
							"'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") warns';\n";
				} else {
					my $desc = sprintf("$function(%s) returns %s",
						perl_quote(join(', ', map { $_ // '' } @$inputs )),
						$expected_str
					);
					$corpus_code .= "is(\$obj->$function($input_str), $expected_str, " . q_wrap($desc) . ");\n";
				}
			} else {
				if($status eq 'DIES') {
					$corpus_code .= "dies_ok { $module\::$function($input_str) } " .
						"'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") dies';\n";
				} elsif($status eq 'WARNS') {
					$corpus_code .= "warnings_exist { $module\::$function($input_str) } qr/./, " .
						"'$function(" . join(", ", map { $_ // '' } @$inputs ) . ") warns';\n";
				} else {
					my $desc = sprintf("$function(%s) returns %s",
						perl_quote(join(', ', map { $_ // '' } @$inputs )),
						$expected_str
					);
					$corpus_code .= "is($module\::$function($input_str), $expected_str, " . q_wrap($desc) . ");\n";
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
	# Generate the test content
	my $tt = Template->new({ ENCODING => 'utf8', TRIM => 1 });

	# Read template from DATA handle
	my $template = Data::Section::Simple::get_data_section('test.tt');

	my $vars = {
		setup_code => $setup_code,
		edge_cases_code => $edge_cases_code,
		edge_case_array_code => $edge_case_array_code,
		type_edge_cases_code => $type_edge_cases_code,
		config_code => $config_code,
		seed_code => $seed_code,
		input_code => $input_code,
		output_code => $output_code,
		transforms_code => $transforms_code,
		corpus_code => $corpus_code,
		call_code => $call_code,
		function => $function,
		iterations_code => int($iterations),
		module => $module
	};

	my $test;
	$tt->process(\$template, $vars, \$test) or die $tt->error();

	if ($test_file) {
		open my $fh, '>:encoding(UTF-8)', $test_file or die "Cannot open $test_file: $!";
		print $fh "$test\n";
		close $fh;
		if($module) {
			print "Generated $test_file for $module\::$function with fuzzing + corpus support\n";
		} else {
			print "Generated $test_file for $function with fuzzing + corpus support\n";
		}
	} else {
		print "$test\n";
	}
}

1;

=head1 NOTES

=over 4

=item * The legacy format conf file must use C<our> declarations so variables are visible to the generator via C<require>.

=back

=head1 SEE ALSO

=over 4

=item * L<https://nigelhorne.github.io/App-Test-Generator/coverage/>: Test Coverage Report

=item * L<Params::Validate::Strict>: Schema Definition

=item * L<Params::Get>: Input validation

=item * L<Return::Set>: Output validation

=item * L<Test::Most>

=item * L<YAML::XS>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created with the
assistance of L<ChatGPT|https://openai.com/> (GPT-5), with final curation
and authorship by Nigel Horne.

=cut

__DATA__

@@ test.tt
#!/usr/bin/env perl

use strict;
use warnings;

use utf8;
use open qw(:std :encoding(UTF-8));	# https://github.com/nigelhorne/App-Test-Generator/issues/1

use Data::Dumper;
use Data::Random qw(:all);
use Data::Random::String::Matches 0.02;
use Test::Most;
use Test::Returns 0.02;

[% setup_code %]

[% IF module %]
	diag('[% module %]->[% function %] test case created by https://github.com/nigelhorne/App-Test-Generator');
[% ELSE %]
	diag('[% function %] test case created by https://github.com/nigelhorne/App-Test-Generator');
[% END %]

# Edge-case maps injected from config (optional)
my %edge_cases = (
[% edge_cases_code %]
);
my @edge_case_array = (
[% edge_case_array_code %]
);
my %type_edge_cases = (
[% type_edge_cases_code %]
);
my %config = (
[% config_code %]
);

# Seed for reproducible fuzzing (if provided)
[% seed_code %]

my %input = (
[% input_code %]
);

my %output = (
[% output_code %]
);

my %transforms = (
[% transforms_code %]
);

# Candidates for regex comparisons
my @candidate_good = ('123', 'abc', 'A1B2', '0');
my @candidate_bad = (
	"😊",	# emoji
	"１２３",	# full-width digits
	"١٢٣",	# Arabic digits
	'..',	# regex metachars
	"a\nb",	# newline in middle
	"é",	# E acute
	'x' x 5000,	# huge string

	# Added later if the configuration says so
	# '',	# empty
	# undef,	# undefined
	# "\0",	# null byte
);

# --- Fuzzer helpers ---
sub _pick_from {
	my $arrayref = $_[0];
	return undef unless $arrayref && ref $arrayref eq 'ARRAY' && @$arrayref;
	return $arrayref->[ int(rand(scalar @$arrayref)) ];
}

sub rand_ascii_str {
	my $len = shift || int(rand(10)) + 1;
	join '', map { chr(97 + int(rand(26))) } 1..$len;
}

my @unicode_codepoints = (
    0x00A9,        # ©
    0x00AE,        # ®
    0x03A9,        # Ω
    0x20AC,        # €
    0x2013,        # – (en-dash)
    0x0301,        # combining acute accent
    0x0308,        # combining diaeresis
    0x1F600,       # 😀 (emoji)
    0x1F62E,       # 😮
    0x1F4A9,       # 💩 (yes)
);

# Tests for matches or nomatch
my @regex_tests = (
	'match123',
	'nope',
	'/fullpath',
	'/',
	'/etc/passwd',
	"/etc/passwd\0",
	"D:\\dos_path",
	"I:\\",
);

sub rand_unicode_char {
	my $cp = $unicode_codepoints[ int(rand(@unicode_codepoints)) ];
	return chr($cp);
}

# Generate a string: mostly ASCII, sometimes unicode, sometimes nul bytes or combining marks
sub rand_str
{
	my $len = shift || int(rand(10)) + 1;

	my @chars;
	for (1..$len) {
		my $r = rand();
		if ($r < 0.72) {
			push @chars, chr(97 + int(rand(26)));          # a-z
		} elsif ($r < 0.88) {
			push @chars, chr(65 + int(rand(26)));          # A-Z
		} elsif ($r < 0.95) {
			push @chars, chr(48 + int(rand(10)));          # 0-9
		} elsif ($r < 0.975) {
			push @chars, rand_unicode_char();              # occasional emoji/marks
		} elsif($config{'test_nuls'}) {
			push @chars, chr(0);                           # nul byte injection
		} else {
			push @chars, chr(97 + int(rand(26)));          # a-z
		}
	}
	# Occasionally prepend/append a combining mark to produce combining sequences
	if (rand() < 0.08) {
		unshift @chars, chr(0x0301);
	}
	if (rand() < 0.08) {
		push @chars, chr(0x0308);
	}
	return join('', @chars);
}

# Random character either upper or lower case
sub rand_char
{
	return rand_chars(set => 'all', min => 1, max => 1);

	# my $char = '';
	# my $upper_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	# my $lower_chars = 'abcdefghijklmnopqrstuvwxyz';
	# my $combined_chars = $upper_chars . $lower_chars;

	# # Generate a random index between 0 and the length of the string minus 1
	# my $rand_index = int(rand(length($combined_chars)));

	# # Get the character at that index
	# return substr($combined_chars, $rand_index, 1);
}

# Integer generator: mix typical small ints with large limits
sub rand_int {
	my $r = rand();
	if ($r < 0.75) {
		return int(rand(200)) - 100;	# -100 .. 100 (usual)
	} elsif ($r < 0.9) {
		return int(rand(2**31)) - 2**30;	# 32-bit-ish
	} elsif ($r < 0.98) {
		return (int(rand(2**63)) - 2**62);	# 64-bit-ish
	} else {
		# very large/suspicious values
		return 2**63 - 1;
	}
}
sub rand_bool { rand() > 0.5 ? 1 : 0 }

# Number generator (floating), includes tiny/huge floats
sub rand_num {
	my $r = rand();
	if ($r < 0.7) {
		return (rand() * 200 - 100);	# -100 .. 100
	} elsif ($r < 0.9) {
		return (rand() * 1e12) - 5e11;          # large-ish
	} elsif ($r < 0.98) {
		return (rand() * 1e308) - 5e307;	# very large floats
	} else {
		return 1e-308 * (rand() * 1000);	# tiny float, subnormal-like
	}
}

sub rand_arrayref {
	my $len = shift || int(rand(3)) + 1; # small arrays

	return [ map { rand_str() } 1..$len ];
}

sub rand_hashref {
	my $len = shift || int(rand(3)) + 1; # small hashes
	my %h;
	for (1..$len) {
		$h{rand_str(3)} = rand_str(5);
	}
	return \%h;
}

sub fuzz_inputs
{
	my @cases;

	# Are any options manadatory?
	my $all_optional = 1;
	my %mandatory_strings;	# List of mandatory strings to be added to all tests, always put at start so it can be overwritten
	my %mandatory_objects;
	my %mandatory_numbers;
	my $class_simple_loaded;
	foreach my $field (keys %input) {
		my $spec = $input{$field} || {};
		if((ref($spec) eq 'HASH') && (!$spec->{optional})) {
			$all_optional = 0;
			if($spec->{'type'} eq 'string') {
				local $config{'test_undef'} = 0;
				local $config{'test_nuls'} = 0;
				local $config{'test_empty'} = 0;
				$mandatory_strings{$field} = rand_ascii_str();
			} elsif($spec->{'type'} eq 'object') {
				my $method = $spec->{'can'};
				if(!$class_simple_loaded) {
					require_ok('Class::Simple');
					eval {
						Class::Simple->import();
						$class_simple_loaded = 1;
					};
				}
				my $obj = new_ok('Class::Simple');
				$obj->$method(1);
				$mandatory_objects{$field} = $obj;
				$config{'dedup'} = 0;	# FIXME:	Can't yet dedup with class method calls
			} elsif(($spec->{'type'} eq 'float') || ($spec->{'type'} eq 'number')) {
				my $min = $spec->{'min'};
				my $max = $spec->{'max'};
				my $number;
				if(defined($min)) {
					$number = rand($min);
				} else {
					$number = rand(100000);
				}
				if(defined($max)) {
					if($number > $max) {
						$number = $max;
					}
				}
				$mandatory_numbers{$field} = $number;
			} else {
				die 'TODO: type = ', $spec->{'type'};
			}
		}
	}
	my %mandatory_args = (%mandatory_strings, %mandatory_objects, %mandatory_numbers);

	if(($all_optional) || ((scalar keys %input) > 1)) {
		# Basic test cases
		if(((scalar keys %input) == 1) && exists($input{'type'}) && !ref($input{'type'})) {
			# our %input = ( type => 'string' );
			my $type = $input{'type'};

			foreach my $field(keys %input) {
				if(!grep({ $_ eq $field } ('type', 'min', 'max', 'optional', 'matches', 'can'))) {
					diag(__LINE__, ": TODO: handle schema keyword '$field'");
				}
			}

			if ($type eq 'string') {
				# Is hello allowed?
				if(!defined($input{'memberof'}) || (grep { $_ eq 'hello' } @{$input{'memberof'}})) {
					if(defined($input{'notmemberof'}) && (grep { $_ eq 'hello' } @{$input{'notmemberof'}})) {
						push @cases, { _input => 'hello', _STATUS => 'DIES' };
					} else {
						push @cases, { _input => 'hello' };
					}
				} elsif(defined($input{'memberof'}) && !defined($input{'max'})) {
					# Data::Random
					push @cases, { _input => rand_set(set => $input{'memberof'}, size => 1) }
				} else {
					if((!defined($input{'min'})) || ($input{'min'} >= 1)) {
						push @cases, { _input => '0' } if(!defined($input{'memberof'}));
					}
					if(defined($input{'notmemberof'}) || (!grep { $_ eq 'hello' } @{$input{'memberof'}})) {
						push @cases, { _input => 'hello' };
					} else {
						push @cases, { _input => 'hello', _STATUS => 'DIES' };
					}
				}
				push @cases, { _input => '' } if((!exists($input{'min'})) || ($input{'min'} == 0));
				# push @cases, { $field => "emoji \x{1F600}" };
				push @cases, { _input => "\0null" } if($config{'test_nuls'});
			} else {
				die 'TODO';
			}
		} else {
			# our %input = ( str => { type => 'string' } );
			foreach my $arg_name (keys %input) {
				my $spec = $input{$arg_name} || {};
				my $type = lc((!ref($spec)) ? $spec : $spec->{type}) || 'string';

				foreach my $field(keys %{$spec}) {
					if(!grep({ $_ eq $field } ('type', 'min', 'max', 'optional', 'matches', 'can'))) {
						diag(__LINE__, ": TODO: handle schema keyword '$field'");
					}
				}

				# --- Type-based seeds ---
				if ($type eq 'number') {
					push @cases, { $arg_name => 0 };
					push @cases, { $arg_name => 1.23 };
					push @cases, { $arg_name => -42 };
					push @cases, { $arg_name => 'abc', _STATUS => 'DIES' };
				}
				elsif ($type eq 'integer') {
					push @cases, { %mandatory_args, ( $arg_name => 42 ) };
					if((!defined $spec->{min}) || ($spec->{min} <= -1)) {
						push @cases, { %mandatory_args, ( $arg_name => -1, _LINE => __LINE__ ) };
					}
					push @cases, { %mandatory_args, ( $arg_name => 3.14, _STATUS => 'DIES' ) };
					push @cases, { %mandatory_args, ( $arg_name => 'xyz', _STATUS => 'DIES' ) };
					# --- min/max numeric boundaries ---
					# Probably duplicated below, but here as well just in case
					if (defined $spec->{min}) {
						my $min = $spec->{min};
						push @cases, { %mandatory_args, ( $arg_name => $min - 1, _STATUS => 'DIES' ) };
						push @cases, { %mandatory_args, ( $arg_name => $min, _LINE => __LINE__ ) };
						push @cases, { %mandatory_args, ( $arg_name => $min + 1 ) };
					}
					if (defined $spec->{max}) {
						my $max = $spec->{max};
						push @cases, { %mandatory_args, ( $arg_name => $max - 1 ) };
						push @cases, { %mandatory_args, ( $arg_name => $max ) };
						push @cases, { %mandatory_args, ( $arg_name => $max + 1, _STATUS => 'DIES' ) };
					}
				} elsif ($type eq 'string') {
					# Is hello allowed?
					if(my $re = $spec->{matches}) {
						if(ref($re) ne 'Regexp') {
							$re = qr/$re/;
						}
						my $random_string;
						if($spec->{'max'}) {
							$random_string = Data::Random::String::Matches->create_random_string({ length => $spec->{'max'}, regex => $re });
						} elsif($spec->{'min'}) {
							$random_string = Data::Random::String::Matches->create_random_string({ length => $spec->{'min'}, regex => $re });
						} else {
							$random_string = Data::Random::String::Matches->create_random_string({ regex => $re });
						}
    						foreach my $str('hello', $random_string) {
							if($str =~ $re) {
								if(!defined($spec->{'memberof'}) || (grep { $_ eq $str } @{$spec->{'memberof'}})) {
									if(defined($spec->{'notmemberof'}) && (grep { $_ eq $str } @{$spec->{'notmemberof'}})) {
										push @cases, { %mandatory_args, ( $arg_name => $str, _STATUS => 'DIES' ) };
									} else {
										push @cases, { %mandatory_args, ( $arg_name => $str ) };
									}
								} elsif(defined($spec->{'memberof'}) && !defined($spec->{'max'})) {
									# Data::Random
									push @cases, { %mandatory_args, ( _input => rand_set(set => $spec->{'memberof'}, size => 1) ) }
								} else {
									push @cases, { %mandatory_args, ( $arg_name => $str, _STATUS => 'DIES' ) };
								}
							} else {
								push @cases, { %mandatory_args, ( $arg_name => $str, _STATUS => 'DIES' ) };
							}
						}
					} else {
						if(!defined($spec->{'memberof'}) || (grep { $_ eq 'hello' } @{$spec->{'memberof'}})) {
							if(defined($spec->{'notmemberof'}) && (grep { $_ eq 'hello' } @{$spec->{'notmemberof'}})) {
								push @cases, { %mandatory_args, ( $arg_name => 'hello', _LINE => __LINE__, _STATUS => 'DIES' ) };
							} else {
								push @cases, { %mandatory_args, ( $arg_name => 'hello' ) };
							}
						} else {
							push @cases, { %mandatory_args, ( $arg_name => 'hello', _LINE => __LINE__, _STATUS => 'DIES' ) };
						}
					}
					if((!exists($spec->{min})) || ($spec->{min} == 0)) {
						# '' should die unless it's in the memberof list
						if(defined($spec->{'memberof'}) && (!grep { $_ eq '' } @{$spec->{'memberof'}})) {
							push @cases, { %mandatory_args, ( $arg_name => '', _NAME => $arg_name, _STATUS => 'DIES' ) }
						} elsif(defined($spec->{'memberof'}) && !defined($spec->{'max'})) {
							# Data::Random
							push @cases, { %mandatory_args, _input => rand_set(set => $spec->{'memberof'}, size => 1) }
						} else {
							push @cases, { %mandatory_args, ( $arg_name => '', _NAME => $arg_name ) } if((!exists($spec->{min})) || ($spec->{min} == 0));
						}
					}
					# push @cases, { $arg_name => "emoji \x{1F600}" };
					push @cases, { %mandatory_args, ( $arg_name => "\0null" ) } if($config{'test_nuls'} && (!(defined $spec->{memberof})) && !defined($spec->{matches}));

					unless(defined($spec->{memberof}) || defined($spec->{matches})) {
						# --- min/max string/array boundaries ---
						if (defined $spec->{min}) {
							my $len = $spec->{min};
							push @cases, { %mandatory_args, ( $arg_name => 'a' x ($len - 1), _STATUS => 'DIES' ) } if($len > 0);
							push @cases, { %mandatory_args, ( $arg_name => 'a' x $len ) };
							push @cases, { %mandatory_args, ( $arg_name => 'a' x ($len + 1) ) };
						}
						if (defined $spec->{max}) {
							my $len = $spec->{max};
							push @cases, { %mandatory_args, ( $arg_name => 'a' x ($len - 1) ) };
							push @cases, { %mandatory_args, ( $arg_name => 'a' x $len ) };
							push @cases, { %mandatory_args, ( $arg_name => 'a' x ($len + 1), _STATUS => 'DIES' ) };
						}
					}
				}
				elsif ($type eq 'boolean') {
					push @cases, { %mandatory_args, ( $arg_name => 0 ) };
					push @cases, { %mandatory_args, ( $arg_name => 1 ) };
					push @cases, { %mandatory_args, ( $arg_name => 'true' ) };
					push @cases, { %mandatory_args, ( $arg_name => 'false' ) };
					push @cases, { %mandatory_args, ( $arg_name => 'off' ) };
					push @cases, { %mandatory_args, ( $arg_name => 'on' ) };
					push @cases, { %mandatory_args, ( $arg_name => 'bletch', _STATUS => 'DIES' ) };
				}
				elsif ($type eq 'hashref') {
					push @cases, { $arg_name => { a => 1 } };
					push @cases, { $arg_name => [], _STATUS => 'DIES' };
				}
				elsif ($type eq 'arrayref') {
					push @cases, { $arg_name => [1,2] };
					push @cases, { $arg_name => { a => 1 }, _STATUS => 'DIES' };
				}

				# --- matches (regex) ---
				if (defined $spec->{matches}) {
					my $regex = $spec->{matches};
					for my $string(@regex_tests) {
						if($string =~ $regex) {
							push @cases, { %mandatory_args, ( $arg_name => $string ) };
						} else {
							push @cases, { %mandatory_args, ( $arg_name => $string, _STATUS => 'DIES' ) };
						}
					}
				}

				# --- nomatch (regex) ---
				if (defined $spec->{nomatch}) {
					my $regex = $spec->{nomatch};
					for my $string(@regex_tests) {
						if($string =~ $regex) {
							push @cases, { %mandatory_args, ( $arg_name => $string, _STATUS => 'DIES' ) };
						} else {
							push @cases, { %mandatory_args, ( $arg_name => $string ) };
						}
					}
				}

				# --- memberof ---
				if (defined $spec->{memberof}) {
					my @set = @{ $spec->{memberof} };
					push @cases, { %mandatory_args, ( $arg_name => $set[0] ) } if @set;
					push @cases, { %mandatory_args, ( $arg_name => '_not_in_set_', _STATUS => 'DIES' ) };
				}

				# --- notmemberof ---
				if (defined $spec->{notmemberof}) {
					my @set = @{ $spec->{notmemberof} };
					push @cases, { %mandatory_args, ( $arg_name => $set[0], _STATUS => 'DIES' ) } if @set;
					push @cases, { %mandatory_args, ( $arg_name => '_not_in_set_' ) };
				}
			}
		}
	}

	# Optional deduplication
	# my %seen;
	# @cases = grep { !$seen{join '|', %$_}++ } @cases;

	# Random data test cases
	if(scalar keys %input) {
		if(((scalar keys %input) == 1) && exists($input{'type'}) && !ref($input{'type'})) {
			# our %input = ( type => 'string' );
			my $type = $input{'type'};
			for (1..[% iterations_code %]) {
				my $case_input;
				if (@edge_case_array && rand() < 0.4) {
					# Sometimes pick a field-specific edge-case
					$case_input = _pick_from(\@edge_case_array);
				} elsif(exists $type_edge_cases{$type} && rand() < 0.3) {
					# Sometimes pick a type-level edge-case
					$case_input = _pick_from($type_edge_cases{$type});
				} elsif($type eq 'string') {
					if($input{matches}) {
						$case_input = Data::Random::String::Matches->create_random_string({ regex => $input{'matches'} });
					} else {
						$case_input = rand_str();
					}
				} elsif($type eq 'integer') {
					$case_input = rand_int() + $input{'min'};
				} elsif(($type eq 'number') || ($type eq 'float')) {
					$case_input = rand_num() + $input{'min'};
				} elsif($type eq 'boolean') {
					$case_input = rand_bool();
				} else {
					die 'TODO';
				}
				push @cases, { _input => $case_input, status => 'OK', _LINE => __LINE__ } if($case_input);
			}
		} else {
			# our %input = ( str => { type => 'string' } );
			foreach my $field (keys %input) {
				my $spec = $input{$field} || {};
				foreach my $field(keys %{$spec}) {
					if(!grep({ $_ eq $field } ('type', 'min', 'max', 'optional', 'matches', 'can', 'position'))) {
						diag(__LINE__, ": TODO: handle schema keyword '$field'");
					}
				}
			}
			for (1..[% iterations_code %]) {
				my %case_input = (%mandatory_args);
				foreach my $field (keys %input) {
					my $spec = $input{$field} || {};
					next if $spec->{'memberof'};	# Memberof data is created below
					my $type = $spec->{type} || 'string';

					# 1) Sometimes pick a field-specific edge-case
					if (exists $edge_cases{$field} && rand() < 0.4) {
						$case_input{$field} = _pick_from($edge_cases{$field});
						next;
					}

					# 2) Sometimes pick a type-level edge-case
					if (exists $type_edge_cases{$type} && rand() < 0.3) {
						$case_input{$field} = _pick_from($type_edge_cases{$type});
						next;
					}

					# 3) Sormal random generation by type
					if ($type eq 'string') {
						if(my $re = $spec->{matches}) {
							if(ref($re) ne 'Regexp') {
								$re = qr/$re/;
							}
							if($spec->{'max'}) {
								$case_input{$field} = Data::Random::String::Matches->create_random_string({ length => $spec->{'max'}, regex => $re });
							} elsif($spec->{'min'}) {
								$case_input{$field} = Data::Random::String::Matches->create_random_string({ length => $spec->{'min'}, regex => $re });
							} else {
								$case_input{$field} = Data::Random::String::Matches->create_random_string({ regex => $re });
							}
						} else {
							if(my $min = $spec->{min}) {
								$case_input{$field} = rand_str($min);
								if($config{'test_empty'} && ($min == 0)) {
									push @cases, { _input => \%case_input, status => 'OK' } if(keys %case_input);
									$case_input{$field} = '';
								}
							} else {
								$case_input{$field} = rand_str();
								if($config{'test_empty'}) {
									push @cases, { _input => \%case_input, status => 'OK' } if(keys %case_input);
									$case_input{$field} = '';
								}
							}
						}
					} elsif ($type eq 'integer') {
						if(my $min = $spec->{min}) {
							if(my $max = $spec->{'max'}) {
								$case_input{$field} = int(rand($max - $min + 1)) + $min;
							} else {
								$case_input{$field} = rand_int() + $min;
							}
						} elsif(exists($spec->{min})) {
							# min == 0
							if(my $max = $spec->{'max'}) {
								$case_input{$field} = int(rand($max + 1));
							} else {
								$case_input{$field} = abs(rand_int());
							}
						} else {
							$case_input{$field} = rand_int();
						}
					}
					elsif ($type eq 'boolean') {
						$case_input{$field} = rand_bool();
					}
					elsif ($type eq 'number') {
						if(my $min = $spec->{min}) {
							$case_input{$field} = rand_num() + $min;
						} else {
							$case_input{$field} = rand_num();
						}
					}
					elsif ($type eq 'arrayref') {
						$case_input{$field} = rand_arrayref();
					}
					elsif ($type eq 'hashref') {
						$case_input{$field} = rand_hashref();
					} elsif($config{'test_undef'}) {
						$case_input{$field} = undef;
					}

					# 4) occasionally drop optional fields
					if ($spec->{optional} && rand() < 0.25) {
						delete $case_input{$field};
					}
				}
				push @cases, { _input => \%case_input, status => 'OK' } if(keys %case_input);
			}
		}
	}

	# edge-cases
	if($config{'test_undef'}) {
		if($all_optional) {
			push @cases, {};
		} else {
			# Note that this is set on the input rather than output
			push @cases, { '_STATUS' => 'DIES' };	# At least one argument is needed
		}
	}

	if(scalar keys %input) {
		push @cases, { '_STATUS' => 'DIES', map { $_ => undef } keys %input } if($config{'test_undef'});
	} else {
		push @cases, { };	# Takes no input
	}

	# If it's not in mandatory_strings it sets to 'undef' which is the idea, to test { value => undef } in the args
	push @cases, { map { $_ => $mandatory_strings{$_} } keys %input, %mandatory_objects } if($config{'test_undef'});

	push @candidate_bad, '' if($config{'test_empty'});
	push @candidate_bad, undef if($config{'test_undef'});
	push @candidate_bad, "\0" if($config{'test_nuls'});

	# generate numeric, string, hashref and arrayref min/max edge cases
	# TODO: For hashref and arrayref, if there's a $spec->{schema} field, use that for the data that's being generated
	if(((scalar keys %input) == 1) && exists($input{'type'}) && !ref($input{'type'})) {
		# our %input = ( type => 'string' );
		my $type = $input{type};
		if (exists $input{memberof} && ref $input{memberof} eq 'ARRAY' && @{$input{memberof}}) {
			# Generate edge cases for memberof inside values
			foreach my $val (@{$input{memberof}}) {
				push @cases, { _input => $val };
			}
			# outside value
			my $outside;
			if(($type eq 'integer') || ($type eq 'number') || ($type eq 'float')) {
				$outside = (sort { $a <=> $b } @{$input{memberof}})[-1] + 1;
			} else {
				$outside = 'INVALID_MEMBEROF';
			}
			push @cases, { _input => $outside, _STATUS => 'DIES' };
		} else {
			# Generate edge cases for min/max
			if ($type eq 'number' || $type eq 'integer') {
				if (defined $input{min}) {
					push @cases, { %mandatory_args, ( _input => $input{min} + 1 ) };	# just inside
					push @cases, { %mandatory_args, ( _input => $input{min} ) };	# border
					push @cases, { %mandatory_args, ( _input => $input{min} - 1, _STATUS => 'DIES' ) }; # outside
				} else {
					push @cases, { %mandatory_args, ( _input => 0, _LINE => __LINE__ ) };	# No min, so 0 should be allowable
					push @cases, { %mandatory_args, ( _input => -1, _LINE => __LINE__ ) };	# No min, so -1 should be allowable
				}
				if (defined $input{max}) {
					push @cases, { %mandatory_args, ( _input => $input{max} - 1 ) };	# just inside
					push @cases, { %mandatory_args, ( _input => $input{max} ) };	# border
					push @cases, { %mandatory_args, ( _input => $input{max} + 1, _STATUS => 'DIES' ) }; # outside
				}
			} elsif ($type eq 'string') {
				if (defined $input{min}) {
					my $len = $input{min};
					push @cases, { _input => 'a' x ($len + 1) };	# just inside
					if($len == 0) {
						push @cases, { _input => '' } if($config{'test_empty'});
					} else {
						# outside
						push @cases, { _input => 'a' x $len };	# border
						push @cases, { _input => 'a' x ($len - 1), _STATUS => 'DIES' };
					}
					if($len >= 1) {
						# Test checking of 'defined'/'exists' rather than if($string)
						push @cases, { %mandatory_args, ( _input => '0', _LINE => __LINE__ ) };
					} else {
						push @cases, { _input => '0', _STATUS => 'DIES' }
					}
				} else {
					push @cases, { _input => '', _LINE => __LINE__ } if($config{'test_empty'});	# No min, empty string should be allowable
				}
				if (defined $input{max}) {
					my $len = $input{max};
					push @cases, { %mandatory_args, ( _input => 'a' x ($len - 1) ) };	# just inside
					push @cases, { %mandatory_args, ( _input => 'a' x $len ) };	# border
					push @cases, { %mandatory_args, ( _input => 'a' x ($len + 1), _STATUS => 'DIES' ) }; # outside
				}
				if(defined $input{matches}) {
					my $re = $input{matches};

					# --- Positive controls ---
					foreach my $val (@candidate_good) {
						if ($val =~ $re) {
							push @cases, { %mandatory_args, ( _input => $val ) };
							last; # one good match is enough
						}
					}

					# --- Negative controls ---
					foreach my $val (@candidate_bad) {
						if(!defined($val)) {
							push @cases, { _input => undef, _STATUS => 'DIES' };
						} elsif ($val !~ $re) {
							push @cases, { _input => $val, _STATUS => 'DIES' };
						}
					}
					push @cases, { _input => undef, _STATUS => 'DIES' } if($config{'test_undef'});
					push @cases, { _input => "\0", _STATUS => 'DIES' } if($config{'test_nuls'});
				}
				if(defined $input{nomatch}) {
					my $re = $input{nomatch};

					# --- Positive controls ---
					foreach my $val (@candidate_good) {
						if ($val !~ $re) {
							push @cases, { %mandatory_args, ( _input => $val ) };
							last; # one good match is enough
						}
					}

					# --- Negative controls ---
					foreach my $val (@candidate_bad) {
						if ($val =~ $re) {
							push @cases, { _input => $val, _STATUS => 'DIES' };
						}
					}
				}
			} elsif ($type eq 'arrayref') {
				if (defined $input{min}) {
					my $len = $input{min};
					push @cases, { _input => [ (1) x ($len + 1) ] };	# just inside
					push @cases, { _input => [ (1) x $len ] };	# border
					push @cases, { _input => [ (1) x ($len - 1) ], _STATUS => 'DIES' } if $len > 0; # outside
				} else {
					push @cases, { _input => [] } if($config{'test_empty'});	# No min, empty array should be allowable
				}
				if (defined $input{max}) {
					my $len = $input{max};
					push @cases, { _input => [ (1) x ($len - 1) ] };	# just inside
					push @cases, { _input => [ (1) x $len ] };	# border
					push @cases, { _input => [ (1) x ($len + 1) ], _STATUS => 'DIES' }; # outside
				}
			} elsif ($type eq 'hashref') {
				if (defined $input{min}) {
					my $len = $input{min};
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. ($len + 1) } };
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. $len } };
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. ($len - 1) }, _STATUS => 'DIES' } if $len > 0;
				} else {
					push @cases, { _input => {} } if($config{'test_empty'});	# No min, empty hash should be allowable
				}
				if (defined $input{max}) {
					my $len = $input{max};
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. ($len - 1) } };
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. $len } };
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. ($len + 1) }, _STATUS => 'DIES' };
				}
			} elsif ($type eq 'boolean') {
				if (exists $input{memberof} && ref $input{memberof} eq 'ARRAY') {
					# memberof already defines allowed booleans
					foreach my $val (@{$input{memberof}}) {
						push @cases, { _input => $val };
					}
				} else {
					# basic boolean edge cases
					push @cases, { _input => 0 };
					push @cases, { _input => 1 };
					push @cases, { _input => 'off' };
					push @cases, { _input => 'on' };
					push @cases, { _input => 'false' };
					push @cases, { _input => 'true' };
					push @cases, { _input => undef, _STATUS => 'DIES' } if($config{'test_undef'});
					push @cases, { _input => 2, _STATUS => 'DIES' };	# invalid boolean
					push @cases, { _input => 'plugh', _STATUS => 'DIES' };	# invalid boolean
				}
			}

			# Test all edge cases
			foreach my $edge(@edge_case_array) {
				push @cases, { _input => $edge };
			}
		}
	} else {
		# our %input = ( str => { type => 'string' } );
		push @cases, @{generate_tests(\%input, \%mandatory_args)};
	}

	# FIXME: I don't think this catches them all
	# FIXME: Handle cases with Class::Simple calls
	if($config{'dedup'}) {
		require JSON::MaybeXS;
		JSON::MaybeXS->import();

		# dedup, fuzzing can easily generate repeats
		my %seen;
		@cases = grep {
			my $dump = encode_json($_);
			!$seen{$dump}++
		} @cases;
	}

	# use Data::Dumper;
	# die(Dumper(@cases));

	return \@cases;
}

sub generate_tests
{
	my $input = $_[0];
	my %mandatory_args = %{$_[1]};

	my @cases;

	foreach my $field (keys %input) {
		my $spec = $input{$field} || {};
		my $type = $spec->{type} || 'string';

		if (exists $spec->{memberof} && ref $spec->{memberof} eq 'ARRAY' && @{$spec->{memberof}}) {
			# Generate edge cases for memberof
			# inside values
			foreach my $val (@{$spec->{memberof}}) {
				push @cases, { %mandatory_args, ( $field => $val ) };
			}
			# outside value
			my $outside;
			if ($type eq 'integer' || $type eq 'number') {
				$outside = (sort { $a <=> $b } @{$spec->{memberof}})[-1] + 1;
			} else {
				$outside = 'INVALID_MEMBEROF';
			}
			push @cases, { %mandatory_args, ( $field => $outside, _STATUS => 'DIES' ) };
		} else {
			# Generate edge cases for min/max
			if(($type eq 'number') || ($type eq 'integer') || ($type eq 'float')) {
				if(defined $spec->{min}) {
					push @cases, { %mandatory_args, ( $field => $spec->{min} + 1 ) };	# just inside
					push @cases, { %mandatory_args, ( $field => $spec->{min} ) };	# border
					push @cases, { %mandatory_args, ( $field => $spec->{min} - 1, _STATUS => 'DIES' ) }; # outside
				} else {
					push @cases, { $field => 0, _LINE => __LINE__ };	# No min, so 0 should be allowable
					push @cases, { $field => -1, _LINE => __LINE__ };	# No min, so -1 should be allowable
				}
				if(defined $spec->{max}) {
					push @cases, { %mandatory_args, ( $field => $spec->{max} - 1, _LINE => __LINE__ ) };	# just inside
					push @cases, { %mandatory_args, ( $field => $spec->{max}, _LINE => __LINE__ ) };	# border
					push @cases, { %mandatory_args, ( $field => $spec->{max} + 1, _STATUS => 'DIES', _LINE => __LINE__ ) }; # outside
				}

				[% IF module %]
					# Send wrong data type - builtins aren't good at checking this
					push @cases, { %mandatory_args, ( $field => 'test string in integer field', _STATUS => 'DIES', _LINE => __LINE__ ) };
					push @cases, { %mandatory_args, ( $field => {}, _STATUS => 'DIES', _LINE => __LINE__ ) };
					push @cases, { %mandatory_args, ( $field => [], _STATUS => 'DIES', _LINE => __LINE__ ) };
				[% END %]
				if($type eq 'integer') {
					# Float
					push @cases, { %mandatory_args, ( $field => 0.5, _STATUS => 'DIES', _LINE => __LINE__ ) };
				}
			} elsif($type eq 'string') {
				if (defined $spec->{min}) {
					my $len = $spec->{min};
					if(my $re = $spec->{matches}) {
						for my $count ($len + 1, $len, $len - 1) {
							next if ($count < 0);
							my $str = rand_char() x $count;
							if($str =~ $re) {
								push @cases, { %mandatory_args, ( $field => $str ) };
							} else {
								push @cases, { %mandatory_args, ( $field => $str, _STATUS => 'DIES' ) };
							}
						}
					} else {
						push @cases, { %mandatory_args, ( $field => 'a' x ($len + 1) ) };	# just inside
						push @cases, { %mandatory_args, ( $field => 'a' x $len ) };	# border
						if($len > 0) {
							if($len > 0) {
								if(($len > 1) || $config{'test_empty'}) {
									# outside
									push @cases, { %mandatory_args, ( $field => 'a' x ($len - 1), _STATUS => 'DIES' ) };
								}
								# Test checking of 'defined'/'exists' rather than if($string)
								push @cases, { %mandatory_args, ( $field => '0' ) };
							} else {
								push @cases, { %mandatory_args, ( $field => '' ) } if($config{'test_empty'});	# min == 0, empty string should be allowable
								# Don't confuse if() with if(defined())
								push @cases, { %mandatory_args, ( $field => '0', _STATUS => 'DIES' ) };
							}
						} else {
							push @cases, { %mandatory_args, ( $field => '' ) } if($config{'test_empty'});	# min == 0, empty string should be allowable
							# Don't confuse if() with if(defined())
							push @cases, { %mandatory_args, ( $field => '0', _STATUS => 'DIES' ) };
						}
					}
				} else {
					push @cases, { %mandatory_args, ( $field => '' ) } if($config{'test_empty'});	# No min, empty string should be allowable
				}
				if (defined $spec->{max}) {
					my $len = $spec->{max};
					if((!defined($spec->{min})) || ($spec->{min} != $len)) {
						if(my $re = $spec->{matches}) {
							for my $count ($len - 1, $len, $len + 1) {
								my $str = rand_char() x $count;
								if($str =~ $re) {
									if($count > $len) {
										push @cases, { %mandatory_args, ( $field => $str, _LINE => __LINE__, _STATUS => 'DIES' ) };
									} else {
										push @cases, { %mandatory_args, ( $field => $str, _LINE => __LINE__ ) };
									}
								} else {
									push @cases, { %mandatory_args, ( $field => $str, _STATUS => 'DIES', _LINE => __LINE__ ) };
								}
							}
						} else {
							push @cases, { %mandatory_args, ( $field => 'a' x ($len - 1), _LINE => __LINE__ ) };	# just inside
							push @cases, { %mandatory_args, ( $field => 'a' x $len, _LINE => __LINE__ ) };	# border
							push @cases, { %mandatory_args, ( $field => 'a' x ($len + 1), _LINE => __LINE__, _STATUS => 'DIES' ) }; # outside
						}
					}
				} else {
					if(exists($spec->{'min'})) {
						push @cases, { %mandatory_args, ( $field => 'a' x (($spec->{'min'} + 1) * 1_000), _LINE => __LINE__ ) };
					} else {
						push @cases, { %mandatory_args, ( $field => 'a' x 10_000, _LINE => __LINE__ ) };
					}
				}

				if(defined $spec->{matches}) {
					my $re = $spec->{matches};

					# --- Positive controls ---
					foreach my $val (@candidate_good) {
						if ($val =~ $re) {
							push @cases, { %mandatory_args, ( $field => $val ) };
							last; # one good match is enough
						}
					}

					# --- Negative controls ---
					foreach my $val (@candidate_bad) {
						if(!defined($val)) {
							push @cases, { _input => undef, _STATUS => 'DIES' } if($config{'test_undef'});
						} elsif ($val !~ $re) {
							push @cases, { _input => $val, _STATUS => 'DIES' };
						}
					}
					push @cases, { $field => undef, _STATUS => 'DIES' } if($config{'test_undef'});
					push @cases, { $field => "\0", _STATUS => 'DIES' } if($config{'test_nuls'});
				}
				if(defined $spec->{nomatch}) {
					my $re = $spec->{nomatch};

					# --- Positive controls ---
					foreach my $val (@candidate_good) {
						if ($val !~ $re) {
							push @cases, { %mandatory_args, ( $field => $val ) };
							last; # one good match is enough
						}
					}

					# --- Negative controls ---
					foreach my $val (@candidate_bad) {
						if ($val =~ $re) {
							push @cases, { $field => $val, _STATUS => 'DIES' };
						}
					}
				}
				# Send wrong data type
				push @cases, { %mandatory_args, ( $field => [], _STATUS => 'DIES', _LINE => __LINE__ ) } if($config{'test_empty'});
				push @cases, { %mandatory_args, ( $field => {}, _STATUS => 'DIES', _LINE => __LINE__ ) } if($config{'test_empty'});
			} elsif ($type eq 'arrayref') {
				if (defined $spec->{min}) {
					my $len = $spec->{min};
					push @cases, { $field => [ (1) x ($len + 1) ] };	# just inside
					push @cases, { $field => [ (1) x $len ] };	# border
					push @cases, { $field => [ (1) x ($len - 1) ], _STATUS => 'DIES' } if $len > 0; # outside
				} else {
					push @cases, { $field => [] } if($config{'test_empty'});	# No min, empty array should be allowable
				}
				if (defined $spec->{max}) {
					my $len = $spec->{max};
					push @cases, { $field => [ (1) x ($len - 1) ] };	# just inside
					push @cases, { $field => [ (1) x $len ] };	# border
					push @cases, { $field => [ (1) x ($len + 1) ], _STATUS => 'DIES' }; # outside
				}
			} elsif ($type eq 'hashref') {
				if (defined $spec->{min}) {
					my $len = $spec->{min};
					push @cases, { $field => { map { "k$_" => 1 }, 1 .. ($len + 1) } };
					push @cases, { $field => { map { "k$_" => 1 }, 1 .. $len } };
					push @cases, { $field => { map { "k$_" => 1 }, 1 .. ($len - 1) }, _STATUS => 'DIES' } if $len > 0;
				} else {
					push @cases, { $field => {} } if($config{'test_empty'});	# No min, empty hash should be allowable
				}
				if (defined $spec->{max}) {
					my $len = $spec->{max};
					push @cases, { $field => { map { "k$_" => 1 }, 1 .. ($len - 1) } };
					push @cases, { $field => { map { "k$_" => 1 }, 1 .. $len } };
					push @cases, { $field => { map { "k$_" => 1 }, 1 .. ($len + 1) }, _STATUS => 'DIES' };
				}
			} elsif ($type eq 'boolean') {
				if (exists $spec->{memberof} && ref $spec->{memberof} eq 'ARRAY') {
					# memberof already defines allowed booleans
					foreach my $val (@{$spec->{memberof}}) {
						push @cases, { %mandatory_args, ( $field => $val ) };
					}
				} else {
					# basic boolean edge cases
					push @cases, { %mandatory_args, ( $field => 0 ) };
					push @cases, { %mandatory_args, ( $field => 1 ) };
					push @cases, { %mandatory_args, ( $field => 'false' ) };
					push @cases, { %mandatory_args, ( $field => 'true' ) };
					push @cases, { %mandatory_args, ( $field => 'off' ) };
					push @cases, { %mandatory_args, ( $field => 'on' ) };
					push @cases, { %mandatory_args, ( $field => undef, _STATUS => 'DIES' ) } if($config{'test_undef'});
					push @cases, { %mandatory_args, ( $field => 2, _STATUS => 'DIES' ) };	# invalid boolean
					push @cases, { %mandatory_args, ( $field => 'xyzzy', _STATUS => 'DIES' ) };	# invalid boolean
				}
			}
		}

		# case_sensitive tests for memberof
		if (defined $spec->{memberof} && exists $spec->{case_sensitive}) {
			if (!$spec->{case_sensitive}) {
				# Generate mixed-case versions of memberof values
				foreach my $val (@{$spec->{memberof}}) {
					push @cases, { %mandatory_args, ( $field => uc($val) ) },
						{ %mandatory_args, ( $field => lc($val) ) },
						{ %mandatory_args, ( $field => ucfirst(lc($val)) ) };
				}
			}
		}

		# Add notmemberof tests
		if (defined $spec->{notmemberof}) {
			my @blacklist = @{$spec->{notmemberof}};
			# Each blacklisted value should die
			foreach my $val (@blacklist) {
				push @cases, { %mandatory_args, ( $field => $val, _STATUS => 'DIES' ) };
			}
			# Non-blacklisted value should pass
			push @cases, { %mandatory_args, ( $field => '_not_in_blacklist_' ) };
		}

		# TODO:	How do we generate tests for cross-field validation?
	}

	return \@cases;
}

sub populate_positions
{
	my $input = shift;

	my $rc;
	foreach my $arg (keys %{$input}) {
		my $spec = $input->{$arg} || {};
		if(defined($spec->{'position'})) {
			$rc->{$arg} = $spec->{'position'};
		} else {
			if($rc) {
				::diag("$arg is missing a position parameter in its schema");
			}
			return;	# All must be defined
		}
	}

	return $rc;
}

sub run_test
{
	my($case, $input, $output, $positions) = @_;

	if($ENV{'TEST_VERBOSE'}) {
		diag('input: ', Dumper($input));
	}

	my $name = $case->{'_NAME'};
	my $result;
	my $mess;
	if(defined($input) && !ref($input)) {
		if($name) {
			$mess = "[% function %]($name = '$input') %s";
		} else {
			$mess = "[% function %]('$input') %s";
		}
	} elsif(defined($input)) {
		my @alist = ();
		if($positions) {
			# Positional args
			foreach my $key (keys %{$input}) {
				if($key ne '_STATUS') {
					if(exists($positions->{$key})) {
						$alist[$positions->{$key}] = delete $input->{$key};
					} else {
						diag("Lost position number for $key");
					}
				}
			}
			@alist = grep { defined $_ } @alist;	# Undefs will cause not enough args to be sent, which is a nice test
			$input = join(', ', @alist);
		} else {
			# Named args
			foreach my $key (sort keys %{$input}) {
				if($key ne '_STATUS') {
					if(defined($input->{$key})) {
						push @alist, "'$key' => '$input->{$key}'";
					} else {
						push @alist, "'$key' => undef";
					}
				}
			}
		}
		my $args = join(', ', @alist);
		$args =~ s/%/%%/g;
		$mess = "[% function %]($args) %s";
	} else {
		$mess = "[% function %] %s";
	}

	if(my $status = (delete $case->{'_STATUS'} || delete $output->{'_STATUS'})) {
		if($status eq 'DIES') {
			dies_ok { [% call_code %] } sprintf($mess, 'dies');
		} elsif($status eq 'WARNS') {
			warnings_exist { [% call_code %] } qr/./, sprintf($mess, 'warns');
		} else {
			lives_ok { [% call_code %] } sprintf($mess, 'survives');
		}
	} else {
		lives_ok { [% call_code %] } sprintf($mess, 'survives');
	}

	if(scalar keys %{$output}) {
		if($ENV{'TEST_VERBOSE'}) {
			diag('result: ', Dumper($result));
		}
		returns_ok($result, $output, 'output validates');
	}
}

my $positions = populate_positions(\%input);

diag('Run Fuzz Tests') if($ENV{'TEST_VERBOSE'});

foreach my $case (@{fuzz_inputs()}) {
	# my %params;
	# lives_ok { %params = get_params(\%input, %$case) } 'Params::Get input check';
	# lives_ok { validate_strict(\%input, %params) } 'Params::Validate::Strict input check';

	my $input;
	if((ref($case) eq 'HASH') && exists($case->{'_input'})) {
		$input = $case->{'_input'};
	} else {
		$input = $case;
	}

	if(my $line = (delete $case->{'_LINE'} || delete $input{'_LINE'})) {
		diag("Test case from line number $line") if($ENV{'TEST_VERBOSE'});
	}

	{
		# local %ENV;
		run_test($case, $input, \%output, $positions);
		# delete $ENV{'LANG'};
		# delete $ENV{'LC_ALL'};
		# run_test($case, $input, \%output, $positions);
		# $ENV{'LANG'} = 'fr_FR.utf8';
		# $ENV{'LC_ALL'} = 'fr_FR.utf8';
		# run_test($case, $input, \%output, $positions);
	}
}

diag('Run ', scalar(keys %transforms), ' transform tests') if($ENV{'TEST_VERBOSE'});
# diag('-' x 60);

# Build the foundation - which is a basic test with sensible defaults in the field
foreach my $transform (keys %transforms) {
	my $foundation;	# basic set of data with every field filled in with a sensible default value

	foreach my $field (keys %input) {
		my $spec = $input{$field} || {};
		my $type = $spec->{type} || 'string';

		if(($type eq 'number') || ($type eq 'float')) {
			if(defined $spec->{min}) {
				if(defined $spec->{max}) {
					$foundation->{$field} = $spec->{max};	# border
				} else {
					$foundation->{$field} = rand_num() + $spec->{'min'};
				}
			} else {
				if(defined $spec->{max}) {
					$foundation->{$field} = $spec->{max};	# border
				} else {
					$foundation->{$field} = -0.1;	# No min, so -0.1 should be allowable
				}
			}
		} elsif($type eq 'string') {
			if(defined $spec->{min} && $spec->{min} > 0) {
				$foundation->{$field} = 'a' x $spec->{min};
			} elsif(defined $spec->{max} && $spec->{max} > 0) {
				$foundation->{$field} = 'b' x $spec->{max};
			} else {
				$foundation->{$field} = 'test_value';
			}
		} elsif ($type eq 'integer') {
			if (defined $spec->{min}) {
				$foundation->{$field} = $spec->{min};
			} elsif (defined $spec->{max}) {
				$foundation->{$field} = rand_int() + $spec->{max};
			} else {
				$foundation->{$field} = rand_int();
			}
		} elsif ($type eq 'boolean') {
			$foundation->{$field} = 1;
		} elsif ($type eq 'arrayref') {
			$foundation->{$field} = rand_arrayref(defined($spec->{'min'}) ? $spec->{'min'} : ($spec->{'max'} // 5));
		} elsif ($type eq 'hashref') {
			$foundation->{$field} = { key => 'value' };
		} else {
			die("TODO: transform type $type for foundation");
		}
	}

	# The foundation should work
	my $case = { _NAME => "basic $transform test", _LINE => __LINE__ };
	my $positions = populate_positions(\%input);
	run_test($case, $foundation, \%output, $positions);

	# Generate transform tests
	# Don't generate invalid data, that's all already done,
	#	this is about verifying the transorms
	my @tests;
	diag("tests for transform $transform") if($ENV{'TEST_VERBOSE'});

	# Now modify the foundation with test code

	# BUILD CODE TO CALL FUNCTION
	# CALL FUNCTION
	# CHECK STATUS CORRECT
	# IF STATUS EQ LIVES
	#   CHECK OUTPUT USING returns_ok
	# FI

	my $transform_input = $transforms{$transform}{'input'} || {};

	foreach my $field (keys %input) {
		my $spec = $transform_input->{$field} || {};
		my $type = $spec->{type} || 'string';

		# If there's a specific value, test that exact value
		if (exists $spec->{value}) {
			push @tests, {
				%{$foundation},
				$field => $spec->{value},
				_LINE => __LINE__
				# _DESCRIPTION => "$transform_name: $field=$spec->{value}"
			};
			next;
		}

		# Generate edge cases based on type and contraints
		if(($type eq 'number') || ($type eq 'integer') || ($type eq 'float')) {
			if(defined $spec->{min}) {
				push @tests, { %{$foundation}, ( $field => $spec->{min} + 1 ) };	# just inside
				push @tests, { %{$foundation}, ( $field => $spec->{min} ) };	# border
				# Test 0 if it's in range
				push @tests, { %{$foundation}, ( $field => 0 ) } if($spec->{'min'} < -1);
				if(!defined($spec->{'max'})) {
					if($type eq 'integer') {
						push @tests, { %{$foundation}, ( $field => abs(rand_int()) ) };
					} else {
						push @tests, { %{$foundation}, ( $field => abs(rand_num()) ) };
					}
				}
			} else {
				push @tests, { %{$foundation}, ( $field => 0 ) };	# No min, so 0 should be allowable
				push @tests, { %{$foundation}, ( $field => (($type eq 'integer') ? -1 : -0.1), _LINE => __LINE__ ) };	# No min, so -1 should be allowable
				if(defined($spec->{'max'})) {
					if($type eq 'integer') {
						push @tests, { %{$foundation}, ( $field => $spec->{'max'} - abs(rand_int()) ) };
					} else {
						push @tests, { %{$foundation}, ( $field => $spec->{'max'} - abs(rand_num()) ) };
					}
				} else {
					if($type eq 'integer') {
						push @tests, { %{$foundation}, ( $field => rand_int() ) };
					} else {
						push @tests, { %{$foundation}, ( $field => rand_num() ) };
					}
				}
			}
			if(defined $spec->{max}) {
				push @tests, { %{$foundation}, ( $field => $spec->{max} - (($type eq 'integer') ? 1 : 0.1 ) ) };	# just inside
				if((defined $spec->{min}) && ($spec->{'min'} != $spec->{'max'})) {
					push @tests, { %{$foundation}, ( $field => $spec->{max} ) };	# border
				}
			}
		} elsif($type eq 'string') {
			if(defined $spec->{min}) {
				push @tests, { %{$foundation}, ( $field => rand_str($spec->{min} + 1) ) };	# just inside
				push @tests, { %{$foundation}, ( $field => rand_str($spec->{min}) ) };	# border
			} else {
				push @tests, { %{$foundation}, ( $field => rand_str() ) };
			}
			if(defined $spec->{max}) {
				push @tests, { %{$foundation}, ( $field => rand_str($spec->{max} - 1) ) };	# just inside
				if((defined $spec->{min}) && ($spec->{'min'} != $spec->{'max'})) {
					push @tests, { %{$foundation}, ( $field => rand_str($spec->{max}) ) };	# border
				}
			}
		} elsif($type eq 'boolean') {
			push @tests, { %{$foundation}, ( $field => 1 ) }, { %{$foundation}, ( $field => 0 ) };
		} elsif ($type eq 'arrayref') {
			if(defined $spec->{min}) {
				push @tests, { %{$foundation}, ( $field => rand_arrayref($spec->{min} + 1) ) };	# just inside
				push @tests, { %{$foundation}, ( $field => rand_arrayref($spec->{min}) ) };	# border
			} else {
				push @tests, { %{$foundation}, ( $field => rand_arrayref() ) };
			}
			if(defined $spec->{max}) {
				push @tests, { %{$foundation}, ( $field => rand_arrayref($spec->{max} - 1) ) };	# just inside
				if((defined $spec->{min}) && ($spec->{'min'} != $spec->{'max'})) {
					push @tests, { %{$foundation}, ( $field => rand_arrayref($spec->{max}) ) };	# border
				}
			}
		} else {
			die("TODO: transform type $type for test case");
		}
	}

	if($config{'dedup'}) {
		# dedup, fuzzing can easily generate repeats
		my %seen;
		@tests = grep {
			my $dump = encode_json($_);
			!$seen{$dump}++
		} @tests;
	}

	{
		# local %ENV;
		my $transform_output = $transforms{$transform}{'output'} || {};
		foreach my $test(@tests) {
			if(my $line = (delete $test->{'_LINE'} || delete $input{'_LINE'})) {
				diag("Test case from line number $line") if($ENV{'TEST_VERBOSE'});
			}
			run_test({ _NAME => $transform }, $test, $transform_output, $positions);
			# delete $ENV{'LANG'};
			# delete $ENV{'LC_ALL'};
			# run_test({ _NAME => $transform }, $test, \%output, $positions);
			# $ENV{'LANG'} = 'fr_FR.utf8';
			# $ENV{'LC_ALL'} = 'fr_FR.utf8';
			# run_test({ _NAME => $transform }, $test, \%output, $positions);
		}
	}
}

[% corpus_code %]

done_testing();
__END__
