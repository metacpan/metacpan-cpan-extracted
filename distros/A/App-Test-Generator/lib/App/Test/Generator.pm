package App::Test::Generator;

# TODO: Test validator from Params::Validate::Strict 0.16
# TODO: $seed should be passed to Data::Random::String::Matches
# TODO: positional args - when config_undef is set, see what happens when not all args are given

use 5.036;

use strict;
use warnings;
use autodie qw(:all);

use utf8;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use open qw(:std :encoding(UTF-8));

use App::Test::Generator::Template;
use Carp qw(carp croak);
use Config::Abstraction 0.36;
use Data::Dumper;
use Data::Section::Simple;
use File::Basename qw(basename);
use File::Spec;
use Module::Load::Conditional qw(check_install can_load);
use Params::Get;
use Params::Validate::Strict 0.30;
use Readonly;
use Readonly::Values::Boolean;
use Scalar::Util qw(looks_like_number);
use re 'regexp_pattern';
use Template;
use YAML::XS qw(LoadFile);

use Exporter 'import';

our @EXPORT_OK = qw(generate);

our $VERSION = '0.33';

use constant {
	DEFAULT_ITERATIONS => 30,
	DEFAULT_PROPERTY_TRIALS => 1000
};

use constant CONFIG_TYPES => ('test_nuls', 'test_undef', 'test_empty', 'test_non_ascii', 'dedup', 'properties', 'close_stdin', 'test_security');

# --------------------------------------------------
# Delimiter pairs tried in order when wrapping a
# string with q{} — bracket forms are preferred as
# they are most readable in generated test code
# --------------------------------------------------
Readonly my @Q_BRACKET_PAIRS => (
	['{', '}'],
	['(', ')'],
	['[', ']'],
	['<', '>'],
);

# --------------------------------------------------
# Single-character delimiters tried when no bracket
# pair is usable — each is tried in order and the
# first one not present in the string is used.
# The # character is last since it starts comments
# in many contexts and is least readable
# --------------------------------------------------
Readonly my @Q_SINGLE_DELIMITERS => (
	'~', '!', '%', '^', '=', '+', ':', ',', ';', '|', '/', '#'
);

# --------------------------------------------------
# Sentinel returned by index() when the search
# string is not found — used to make the >= 0
# boundary check self-documenting and to prevent
# NumericBoundary mutants from surviving
# --------------------------------------------------
Readonly my $INDEX_NOT_FOUND => -1;

# --------------------------------------------------
# Readonly constants for schema validation
# --------------------------------------------------
Readonly my $CONFIG_PROPERTIES_KEY => 'properties';
Readonly my $LEGACY_PERL_KEY_1     => '$module';
Readonly my $LEGACY_PERL_KEY_2     => 'our $module';
Readonly my $SOURCE_KEY            => '_source';

# --------------------------------------------------
# Readonly constants for render_hash key detection
# --------------------------------------------------
Readonly my $KEY_MATCHES => 'matches';
Readonly my $KEY_NOMATCH => 'nomatch';

# --------------------------------------------------
# Reserved module name indicating a Perl builtin
# function rather than a CPAN or user module
# --------------------------------------------------
Readonly my $MODULE_BUILTIN => 'builtin';

# --------------------------------------------------
# Regex pattern matched against transform names to
# detect the positive/non-negative idempotence
# heuristic in _detect_transform_properties
# --------------------------------------------------
Readonly my $TRANSFORM_POSITIVE_PATTERN => 'positive';

# --------------------------------------------------
# Default type assumed for schema fields that declare
# no explicit type — used in generator selection and
# dominant-type detection
# --------------------------------------------------
Readonly my $DEFAULT_FIELD_TYPE => 'string';

# --------------------------------------------------
# Default range used by the LectroTest float/integer
# generators when no min or max constraint is given.
# Chosen to provide a useful spread without producing
# values so large they overflow downstream arithmetic.
# --------------------------------------------------
Readonly my $DEFAULT_GENERATOR_RANGE => 1000;

# --------------------------------------------------
# Default upper bound on the number of elements in
# generated arrayrefs and hashrefs when no max is
# declared in the schema.
# --------------------------------------------------
Readonly my $DEFAULT_MAX_COLLECTION_SIZE => 10;

# --------------------------------------------------
# Default upper bound on generated string length
# when no max is declared in the schema.
# --------------------------------------------------
Readonly my $DEFAULT_MAX_STRING_LEN => 100;

# --------------------------------------------------
# Sentinel for the zero boundary used in float
# generator selection — comparing min/max against
# this constant makes the boundary intent explicit
# and prevents NumericBoundary mutants from surviving.
# --------------------------------------------------
Readonly my $ZERO_BOUNDARY => 0;

# --------------------------------------------------
# Environment variable names used to control verbose
# output and optional load validation in
# _validate_module. Centralised here so they are
# easy to find and consistent across the codebase.
# --------------------------------------------------
Readonly my $ENV_TEST_VERBOSE       => 'TEST_VERBOSE';
Readonly my $ENV_GENERATOR_VERBOSE  => 'GENERATOR_VERBOSE';
Readonly my $ENV_VALIDATE_LOAD      => 'GENERATOR_VALIDATE_LOAD';

=head1 NAME

App::Test::Generator - Fuzz Testing, Mutation Testing, LCSAJ Metrics and Test Dashboard for Perl modules

=head1 VERSION

Version 0.33

=head1 SYNOPSIS

C<App::Test::Generator> is a suite to help the testing of CPAN modules.
It consists of 4 modules:

=over 4

=item * Fuzz Tester

=item * Mutation Testing

=item * LCSAJ Metrics

=item * Test Dashboard

=back

From the command line:

  # Takes the formal definition of a routine, creates tests against that routine, and runs the test
  fuzz-harness-generator -r t/conf/add.yml

  # Attempt to create a formal definition from a routine package, then run tests against that formal definition
  # This is the holy grail of automatic test generation, just by looking at the source code
  extract-schemas bin/extract-schemas lib/Sample/Module.pm && fuzz-harness-generator -r schemas/greet.yaml

From Perl:

  use App::Test::Generator qw(generate);

  # Generate to STDOUT
  App::Test::Generator->generate("t/conf/add.yml");

  # Generate directly to a file
  App::Test::Generator->generate('t/conf/add.yml', 't/add_fuzz.t');

  # Holy grail mode - read a Perl file, generate tests, and run them
  # This is a long way away yet, but see t/schema_input.t for a proof of concept
  my $extractor = App::Test::Generator::SchemaExtractor->new(
    input_file => 'Foo.pm',
    output_dir => $dir
  );
  my $schemas = $extractor->extract_all();
  foreach my $schema(keys %{$schemas}) {
    my $tempfile = '/var/tmp/foo.t';	# Use File::Temp in real life
    App::Test::Generator->generate(
      schema => $schemas->{$schema},
      output_file => $tempfile,
    );
    system("$^X -I$dir $tempfile");
    unlink $tempfile;
  }

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
produces a ready-to-run F<.t> test script to run through C<prove>.

It reads configuration files in any format,
and optional YAML corpus files.
All of the examples in this documentation are in C<YAML> format,
other formats may not work as they aren't so heavily tested.
It then generates a L<Test::Most>-based fuzzing harness combining:

=over 4

=item * Randomized fuzzing of inputs (with edge cases)

=item * Optional static corpus tests from Perl C<%cases> or YAML file (C<yaml_cases> key)

=item * Functional or OO mode (via C<$new>)

=item * Reproducible runs via C<$seed> and configurable iterations via C<$iterations>

=back

=head1 MUTATION-GUIDED TEST GENERATION

C<App::Test::Generator> includes a pipeline that automatically closes the
feedback loop between mutation testing, schema extraction, and fuzz
testing. The goal is that surviving mutants drive the creation of new
tests that kill them on the next run, without manual intervention.

=head2 The Pipeline

    mutation survivor
        |
        v
    SchemaExtractor extracts the schema for the enclosing sub
        |
        v
    Schema augmented with boundary values from the mutant
        |
        v
    Augmented schema written to t/conf/
        |
        v
    t/fuzz.t picks up the new schema and runs fuzz tests
        |
        v
    Mutation killed on next run

=head2 How to Use It

The pipeline is driven by three flags passed to
C<bin/test-generator-index>, which is invoked automatically by
C<bin/generate-test-dashboard> on each CI push.

=head3 Step 1: Generate TODO stubs for all survivors

    bin/test-generator-index --generate_mutant_tests=t

Produces C<t/mutant_YYYYMMDD_HHMMSS.t> containing:

=over 4

=item * TODO stubs for HIGH and MEDIUM difficulty survivors, with
boundary value suggestions, environment variable hints, and the
enclosing subroutine name for navigation context.

=item * Comment-only hints for LOW difficulty survivors.

=back

Multiple mutations on the same source line are deduplicated into one
stub. One good test kills all variants on that line.

=head3 Step 2: Generate runnable schemas for NUM_BOUNDARY survivors

    bin/test-generator-index \
        --generate_mutant_tests=t \
        --generate_test=mutant

For each NUM_BOUNDARY survivor, calls
L<App::Test::Generator::SchemaExtractor> to extract the schema for
the enclosing subroutine. If the confidence level is sufficient, the
schema is augmented with the boundary value from the mutant (plus one
value either side) and written to C<t/conf/> as a runnable YAML file.
L<t/fuzz.t> picks it up automatically on the next test run.

Falls back to a TODO stub if:

=over 4

=item * SchemaExtractor cannot parse the file

=item * The enclosing sub cannot be determined

=item * The extracted schema confidence is C<very_low> or C<none>

=back

=head3 Step 3: Augment existing schemas with survivor boundary values

    bin/test-generator-index \
        --generate_mutant_tests=t \
        --generate_test=mutant \
        --generate_fuzz

Scans C<t/conf/> for existing YAML schema files (hand-written or
previously generated) and writes augmented copies with boundary values
from surviving NUM_BOUNDARY mutants merged in. The original schema is
never modified. Augmented copies are written as
C<t/conf/mutant_fuzz_YYYYMMDD_HHMMSS_FUNCTION.yml> and picked up
automatically by C<t/fuzz.t>.

Schemas whose filename already starts with C<mutant_fuzz_> are skipped
to prevent cascading augmentation. Schemas with no matching survivors
are skipped, with a note if C<--verbose> is active.

=head3 Putting It All Together

The recommended invocation in C<bin/generate-test-dashboard>
Step 7 runs all three stages together:

    bin/test-generator-index \
        --generate_mutant_tests=t \
        --generate_test=mutant \
        --generate_fuzz

The GitHub Actions workflow in C<.github/workflows/dashboard.yml>
then commits any new C<t/mutant_*.t> and C<t/conf/mutant_*.yml> files
to the repository so they accumulate over time as the test suite
improves.

=head2 Confidence Levels

L<App::Test::Generator::SchemaExtractor> assigns a confidence level
to each extracted schema:

=over 4

=item * C<high> / C<medium> / C<low> - Schema is used for test generation

=item * C<very_low> / C<none> - Falls back to TODO stub

=back

Confidence is based on how much type and constraint information could
be inferred from the source code and its POD documentation. Methods
with explicit parameter validation (L<Params::Validate::Strict>,
L<Params::Get>) or comprehensive POD will produce higher-confidence
schemas.

=head2 Files Produced

=over 4

=item * C<t/mutant_YYYYMMDD_HHMMSS.t>

TODO stub file for all survivors. Committed to the repository by the
GitHub Actions workflow.

=item * C<t/conf/mutant_MODNAME_FUNCTION_YYYYMMDD_HHMMSS.yml>

Runnable YAML schema for a NUM_BOUNDARY survivor where SchemaExtractor
confidence was sufficient. Picked up by C<t/fuzz.t>.

=item * C<t/conf/mutant_fuzz_YYYYMMDD_HHMMSS_FUNCTION.yml>

Augmented copy of an existing schema with survivor boundary values
merged in. Picked up by C<t/fuzz.t>.

=back

=head2 See Also

=over 4

=item * L<App::Test::Generator::SchemaExtractor> - Schema extraction
from Perl source code

=item * L<bin/test-generator-index> - Dashboard generator and
pipeline driver

=item * L<bin/generate-test-dashboard> - Full pipeline runner

=back

=encoding utf8

=head1 CONFIGURATION

The configuration file,
for each set of tests to be produced,
is a file containing a schema that can be read by L<Config::Abstraction>.

=head2 SCHEMA

The schema is split into several sections.

=head3 C<%input> - input params with keys => type/optional specs

When using named parameters

  input:
    name:
      type: string
      optional: false
    age:
      type: integer
      optional: true

Supported basic types used by the fuzzer: C<string>, C<integer>, C<float>, C<number>, C<boolean>, C<arrayref>, C<hashref>.
See also L<Params::Validate::Strict>.
You can add more custom types using properties.

For routines with one unnamed parameter

  input:
    type: string

For routines with more than one named parameter, use the C<position> keyword.

  module: Math::Simple::MinMax
  fuction: max

  input:
    left:
      type: number
      position: 0
    right:
      type: number
      position: 1

  output:
    type: number

The keyword C<undef> is used to indicate that the C<function> takes no arguments.

=head3 C<%output> - output param types for L<Return::Set> checking

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
    type: string

  output: undef

The keyword C<undef> is used to indicate that the C<function> returns nothing.

=head3 C<%config> - optional hash of configuration.

The current supported variables are

=over 4

=item * C<close_stdin>

Tests should not attempt to read from STDIN (default: 1).
This is ignored on Windows, when never closes STDIN.

=item * C<test_nuls>, inject NUL bytes into strings (default: 1)

With this test enabled, the function is expected to die when a NUL byte is passed in.

=item * C<test_undef>, test with undefined value (default: 1)

=item * C<test_empty>, test with empty strings (default: 1)

=item * C<test_non_ascii>, test with strings that contain non ascii characters (default: 1)

=item * C<timeout>, ensure tests don't hang (default: 10)

Setting this to 0 disables timeout testing.

=item * C<dedup>, fuzzing can create duplicate tests, go some way to remove duplicates (default: 1)

=item * C<properties>, enable L<Test::LectroTest> Property tests (default: 0)

*item * C<test_security>, send some security string based tests (default: 0)

=back

All values default to C<true>.

=head3 C<%accessor> - this is an accessor routine

  accessor:
    property: ua
    type: getset

Has two mandatory elements:

=over 4

=item * C<property>

The name of the property in the object that the routine controls.

=item * C<type>

One of C<getter>, C<setter>, C<getset>.

=back

=head3 C<%transforms> - list of transformations from input sets to output sets

Transforms allow you to define how input data should be transformed into output data.
This is useful for testing functions that convert between formats, normalize data,
or apply business logic transformations on a set of data to different set of data.
It takes a list of subsets of the input and output definitions,
and verifies that data from each input subset is correctly transformed into data from the matching output subset.

=head4 Transform Validation Rules

For each transform:

=over 4

=item 1. Generate test cases using the transform's input schema

=item 2. Call the function with those inputs

=item 3. Validate the output matches the transform's output schema

=item 4. If output has a specific 'value', check exact match

=item 5. If output has constraints (min/max), validate within bounds

=back

=head4 Example 1

  ---
  module: builtin
  function: abs

  config:
    test_undef: no
    test_empty: no
    test_nuls: no
    test_non_ascii: no

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
If it's set to WARNS, the routine should warn with the given arguments.

The keyword C<undef> is used to indicate that the C<function> returns nothing.

=head4 Example 2

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

=head3 C<$module>

The name of the module (optional).

Using the reserved word C<builtin> means you're testing a Perl builtin function.

If omitted, the generator will guess from the config filename:
C<My-Widget.conf> -> C<My::Widget>.

=head3 C<$function>

The function/method to test.

This defaults to C<run>.

=head3 C<%new>

An optional hashref of args to pass to the module's constructor.

  new:
    api_key: ABC123
    verbose: true

To ensure C<new()> is called with no arguments, you still need to define new, thus:

  module: MyModule
  function: my_function

  new:

=head3 C<%cases>

An optional Perl static corpus, when the output is a simple string (expected => [ args... ]).

Maps the expected output string to the input and _STATUS

  cases:
    ok:
      input: ping
      _STATUS: OK
    error:
      input: ""
      _STATUS: DIES

=head3 C<$yaml_cases> - optional path to a YAML file with the same shape as C<%cases>.

=head3 C<$seed>

An optional integer.
When provided, the generated C<t/fuzz.t> will call C<srand($seed)> so fuzz runs are reproducible.

=head3 C<$iterations>

An optional integer controlling how many fuzz iterations to perform (default 30).

=head3 C<%edge_cases>

An optional hash mapping of extra values to inject.

	# Two named parameters
	edge_cases:
		name: [ '', 'a' x 1024, \"\x{263A}" ]
		age: [ -1, 0, 99999999 ]

	# Takes a string input
	edge_cases: [ 'foo', 'bar' ]

Values can be strings or numbers; strings will be properly quoted.
Note that this only works with routines that take named parameters.

=head3 C<%type_edge_cases>

An optional hash mapping types to arrayrefs of extra values to try for any field of that type:

	type_edge_cases:
		string: [ '', ' ', "\t", "\n", "\0", 'long' x 1024, chr(0x1F600) ]
		number: [ 0, 1.0, -1.0, 1e308, -1e308, 1e-308, -1e-308, 'NaN', 'Infinity' ]
		integer: [ 0, 1, -1, 2**31-1, -(2**31), 2**63-1, -(2**63) ]

=head3 C<%edge_case_array>

Specify edge case values for routines that accept a single unnamed parameter.
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
  iterations: 30

=head3 Semantic Data Generators

For property-based testing with L<Test::LectroTest>,
you can use semantic generators to create realistic test data.

C<unix_timestamp> is currently fully supported,
other fuzz testing support for C<semantic> entries is being developed.

  input:
    email:
      type: string
      semantic: email

    user_id:
      type: string
      semantic: uuid

    phone:
      type: string
      semantic: phone_us

=head4 Available Semantic Types

=over 4

=item * C<email> - Valid email addresses (user@domain.tld)

=item * C<url> - HTTP/HTTPS URLs

=item * C<uuid> - UUIDv4 identifiers

=item * C<phone_us> - US phone numbers (XXX-XXX-XXXX)

=item * C<phone_e164> - International E.164 format (+XXXXXXXXXXXX)

=item * C<ipv4> - IPv4 addresses (0.0.0.0 - 255.255.255.255)

=item * C<ipv6> - IPv6 addresses

=item * C<username> - Alphanumeric usernames with _ and -

=item * C<slug> - URL slugs (lowercase-with-hyphens)

=item * C<hex_color> - Hex color codes (#RRGGBB)

=item * C<iso_date> - ISO 8601 dates (YYYY-MM-DD)

=item * C<iso_datetime> - ISO 8601 datetimes (YYYY-MM-DDTHH:MM:SSZ)

=item * C<semver> - Semantic version strings (major.minor.patch)

=item * C<jwt> - JWT-like tokens (base64url format)

=item * C<json> - Simple JSON objects

=item * C<base64> - Base64-encoded strings

=item * C<md5> - MD5 hashes (32 hex chars)

=item * C<sha256> - SHA-256 hashes (64 hex chars)

=item * C<unix_timestamp>

=back

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

=item * C<number>, C<integer>, C<float>

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

=item * C<enum> - synonym of C<memberof>

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

See the files in C<t/conf> for examples.

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

=head2 Fuzz Testing your CPAN Module

Running fuzz tests when you run C<make test> in your CPAN module.

Create a directory <t/conf> which contains the schemas.

Then create this file as <t/fuzz.t>:

  #!/usr/bin/env perl

  use strict;
  use warnings;

  use FindBin qw($Bin);
  use IPC::Run3;
  use IPC::System::Simple qw(system);
  use Test::Needs 'App::Test::Generator';
  use Test::Most;

  my $dirname = "$Bin/conf";

  if((-d $dirname) && opendir(my $dh, $dirname)) {
	while (my $filename = readdir($dh)) {
		# Skip '.' and '..' entries and vi temporary files
		next if ($filename eq '.' || $filename eq '..') || ($filename =~ /\.swp$/);

		my $filepath = "$dirname/$filename";

		if(-f $filepath) {	# Check if it's a regular file
			my ($stdout, $stderr);
			run3 ['fuzz-harness-generator', '-r', $filepath], undef, \$stdout, \$stderr;

			ok($? == 0, 'Generated test script exits successfully');

			if($? == 0) {
				ok($stdout =~ /^Result: PASS/ms);
				if($stdout =~ /Files=1, Tests=(\d+)/ms) {
					diag("$1 tests run");
				}
			} else {
				diag("$filepath: STDOUT:\n$stdout");
				diag($stderr) if(length($stderr));
				diag("$filepath Failed");
				last;
			}
			diag($stderr) if(length($stderr));
		}
	}
	closedir($dh);
  }

  done_testing();

=head2 Property-Based Testing with Transforms

The generator can create property-based tests using L<Test::LectroTest> when the
C<properties> configuration option is enabled.
This provides more comprehensive
testing by automatically generating thousands of test cases and verifying that
mathematical properties hold across all inputs.

=head3 Basic Property-Based Transform Example

Here's a complete example testing the C<abs> builtin function:

B<t/conf/abs.yml>:

  ---
  module: builtin
  function: abs

  config:
    test_undef: no
    test_empty: no
    test_nuls: no
    properties:
      enable: true
      trials: 1000

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
          min: 0
      output:
        type: number
        min: 0

    negative:
      input:
        number:
          type: number
          max: 0
      output:
        type: number
        min: 0

This configuration:

=over 4

=item * Enables property-based testing with 1000 trials per property

=item * Defines two transforms: one for positive numbers, one for negative

=item * Automatically generates properties that verify C<abs()> always returns non-negative numbers

=back

Generate the test:

  fuzz-harness-generator t/conf/abs.yml > t/abs_property.t

The generated test will include:

=over 4

=item * Traditional edge-case tests for boundary conditions

=item * Random fuzzing with 30 iterations (or as configured)

=item * Property-based tests that verify the transforms with 1000 trials each

=back

=head3 What Properties Are Tested?

The generator automatically detects and tests these properties based on your transform specifications:

=over 4

=item * B<Range constraints> - If output has C<min> or C<max>, verifies results stay within bounds

=item * B<Type preservation> - Ensures numeric inputs produce numeric outputs

=item * B<Definedness> - Verifies the function doesn't return C<undef> unexpectedly

=item * B<Specific values> - If output specifies a C<value>, checks exact equality

=back

For the C<abs> example above, the generated properties verify:

  # For the "positive" transform:
  - Given a positive number, abs() returns >= 0
  - The result is a valid number
  - The result is defined

  # For the "negative" transform:
  - Given a negative number, abs() returns >= 0
  - The result is a valid number
  - The result is defined

=head3 Advanced Example: String Normalization

Here's a more complex example testing a string normalization function:

B<t/conf/normalize.yml>:

  ---
  module: Text::Processor
  function: normalize_whitespace

  config:
    properties:
      enable: true
      trials: 500

  input:
    text:
      type: string
      min: 0
      max: 1000
      position: 0

  output:
    type: string
    min: 0
    max: 1000

  transforms:
    empty_preserved:
      input:
        text:
          type: string
          value: ""
      output:
        type: string
        value: ""

    single_space:
      input:
        text:
          type: string
          min: 1
          matches: '^\S+(\s+\S+)*$'
      output:
        type: string
        matches: '^\S+( \S+)*$'

    length_bounded:
      input:
        text:
          type: string
          min: 1
          max: 100
      output:
        type: string
        min: 1
        max: 100

This tests that the normalization function:

=over 4

=item * Preserves empty strings (C<empty_preserved> transform)

=item * Collapses multiple spaces into single spaces (C<single_space> transform)

=item * Maintains length constraints (C<length_bounded> transform)

=back

=head3 Interpreting Property Test Results

When property-based tests run, you'll see output like:

  ok 123 - negative property holds (1000 trials)
  ok 124 - positive property holds (1000 trials)

If a property fails, Test::LectroTest will attempt to find the minimal failing
case and display it:

  not ok 123 - positive property holds (47 trials)
  # Property failed
  # Reason: counterexample found

This helps you quickly identify edge cases that your function doesn't handle correctly.

=head3 Configuration Options for Property-Based Testing

In the C<config> section:

  config:
    properties:
      enable: true     # Enable property-based testing (default: false)
      trials: 1000     # Number of test cases per property (default: 1000)

You can also disable traditional fuzzing and only use property-based tests:

  config:
    properties:
      enable: true
      trials: 5000

  iterations: 0  # Disable random fuzzing, use only property tests

=head3 When to Use Property-Based Testing

Property-based testing with transforms is particularly useful for:

=over 4

=item * Mathematical functions (C<abs>, C<sqrt>, C<min>, C<max>, etc.)

=item * Data transformations (encoding, normalization, sanitization)

=item * Parsers and formatters

=item * Functions with clear input-output relationships

=item * Code that should satisfy mathematical properties (commutativity, associativity, idempotence)

=back

=head3 Requirements

Property-based testing requires L<Test::LectroTest> to be installed:

  cpanm Test::LectroTest

If not installed, the generated tests will automatically skip the property-based
portion with a message.

=head3 Testing Email Validation

  ---
  module: Email::Valid
  function: rfc822

  config:
    properties:
      enable: true
      trials: 200
    close_stdin: true
    test_undef: no
    test_empty: no
    test_nuls: no

  input:
    email:
      type: string
      semantic: email
      position: 0

  output:
    type: boolean

  transforms:
    valid_emails:
      input:
        email:
          type: string
          semantic: email
      output:
        type: boolean

This generates 200 realistic email addresses for testing, rather than random strings.

=head3 Combining Semantic with Regex

You can combine semantic generators with regex validation:

  input:
    corporate_email:
      type: string
      semantic: email
      matches: '@company\.com$'

The semantic generator creates realistic emails, and the regex ensures they match your domain.

=head3 Custom Properties for Transforms

You can define additional properties that should hold for your transforms beyond
the automatically detected ones.

=head4 Using Built-in Properties

  transforms:
    positive:
      input:
        number:
          type: number
          min: 0
      output:
        type: number
        min: 0
      properties:
        - idempotent       # f(f(x)) == f(x)
        - non_negative     # result >= 0
        - positive         # result > 0

Available built-in properties:

=over 4

=item * C<idempotent> - Function is idempotent: f(f(x)) == f(x)

=item * C<non_negative> - Result is always >= 0

=item * C<positive> - Result is always > 0

=item * C<non_empty> - String result is never empty

=item * C<length_preserved> - Output length equals input length

=item * C<uppercase> - Result is all uppercase

=item * C<lowercase> - Result is all lowercase

=item * C<trimmed> - No leading/trailing whitespace

=item * C<sorted_ascending> - Array is sorted ascending

=item * C<sorted_descending> - Array is sorted descending

=item * C<unique_elements> - Array has no duplicates

=item * C<preserves_keys> - Hash has same keys as input

=back

=head4 Custom Property Code

Custom properties allows the definition additional invariants and relationships that should hold for their transforms,
beyond what's auto-detected.
For example:

=over 4

=item * Idempotence: f(f(x)) == f(x)

=item * Commutativity: f(x, y) == f(y, x)

=item * Associativity: f(f(x, y), z) == f(x, f(y, z))

=item * Inverse relationships: decode(encode(x)) == x

=item * Domain-specific invariants: Custom business logic

=back

Define your own properties with custom Perl code:

  transforms:
    normalize:
      input:
        text:
          type: string
      output:
        type: string
      properties:
        - name: single_spaces
          description: "No multiple consecutive spaces"
          code: $result !~ /  /

        - name: no_leading_space
          description: "No space at start"
          code: $result !~ /^\s/

        - name: reversible
          description: "Can be reversed back"
          code: length($result) == length($text)

The code has access to:

=over 4

=item * C<$result> - The function's return value

=item * Input variables - All input parameters (e.g., C<$text>, C<$number>)

=item * The function itself - Can call it again for idempotence checks

=back

=head4 Combining Auto-detected and Custom Properties

The generator automatically detects properties from your output spec, and adds
your custom properties:

  transforms:
    sanitize:
      input:
        html:
          type: string
      output:
        type: string
        min: 0              # Auto-detects: defined, min_length >= 0
        max: 10000
      properties:           # Additional custom checks:
        - name: no_scripts
          code: $result !~ /<script/i
        - name: no_iframes
          code: $result !~ /<iframe/i

=head2 GENERATED OUTPUT

The generated test:

=over 4

=item * Seeds RND (if configured) for reproducible fuzz runs

=item * Uses edge cases (per-field and per-type) with configurable probability

=item * Runs C<$iterations> fuzz cases plus appended edge-case runs

=item * Validates inputs with Params::Get / Params::Validate::Strict

=item * Validates outputs with L<Return::Set>

=item * Runs static C<is(... )> corpus tests from Perl and/or YAML corpus

=item * Runs L<Test::LectroTest> tests

=back

=head1 METHODS

=head2 generate

  generate($schema_file, $test_file)

Takes a schema file and produces a test file (or STDOUT).

=cut

sub generate
{
	croak 'Usage: generate(schema_file [, outfile])' if(scalar(@_) <= 1);

	my $class = shift;
	my $args = $_[0];

	my ($schema_file, $test_file, $schema);
	# Globals loaded from the user's conf (all optional except function maybe)
	my ($module, $function, $new, $yaml_cases);
	my ($seed, $iterations);

	if((ref($args) eq 'HASH') || defined($_[2])) {
		# Modern API
		my $params = Params::Validate::Strict::validate_strict({
			args => Params::Get::get_params(undef, \@_),
			schema => {
				input_file => { type => 'string', optional => 1 },
				schema_file => { type => 'string', optional => 1 },
				output_file => { type => 'string', optional => 1 },
				schema => { type => 'hashref', optional => 1 },
				quiet => { type => 'boolean', optional => 1 },	# Not yet used
			}
		});
		if($params->{'schema_file'}) {
			$schema_file = $params->{'schema_file'};
		} elsif($params->{'input_file'}) {
			$schema_file = $params->{'input_file'};
		} elsif($params->{'schema'}) {
			$schema = $params->{'schema'};
		} else {
			croak(__PACKAGE__, ': Usage: generate(input_file|schema [, output_file]');
		}
		if(defined($schema_file)) {
			$schema = _load_schema($schema_file);
		}
		$test_file = $params->{'output_file'};
	} else {
		# Legacy API
		($schema_file, $test_file) = @_;
		if(defined($schema_file)) {
			$schema = _load_schema($schema_file);
		} else {
			croak 'Usage: generate(schema_file [, outfile])';
		}
	}

	# Parse the schema file and load into our structures
	my %input = %{_load_schema_section($schema, 'input', $schema_file)};
	my %output = %{_load_schema_section($schema, 'output', $schema_file)};
	my %transforms = %{_load_schema_section($schema, 'transforms', $schema_file)};
	my %accessor = %{_load_schema_section($schema, 'accessor', $schema_file)};

	my %cases = %{$schema->{cases}} if(exists($schema->{cases}));
	my %edge_cases = %{$schema->{edge_cases}} if(exists($schema->{edge_cases}));
	my %type_edge_cases = %{$schema->{type_edge_cases}} if(exists($schema->{type_edge_cases}));

	$module = $schema->{module} if(exists($schema->{module}) && length($schema->{module}));
	$function = $schema->{function} if(exists($schema->{function}));
	if(exists($schema->{new})) {
		$new = defined($schema->{'new'}) ? $schema->{new} : '_UNDEF';
	}
	$yaml_cases = $schema->{yaml_cases} if(exists($schema->{yaml_cases}));
	$seed = $schema->{seed} if(exists($schema->{seed}));
	$iterations = $schema->{iterations} if(exists($schema->{iterations}));

	my @edge_case_array = @{$schema->{edge_case_array}} if(exists($schema->{edge_case_array}));
	_validate_config($schema);

	my %config = %{$schema->{config}} if(exists($schema->{config}));

	_normalize_config(\%config);

	# Guess module name from config file if not set
	if(!$module) {
		if($schema_file) {
			($module = basename($schema_file)) =~ s/\.(conf|pl|pm|yml|yaml)$//;
			$module =~ s/-/::/g;
		}
	} elsif($module eq 'builtin') {
		undef $module;
	}

	if($module && length($module) && ($module ne 'builtin')) {
		_validate_module($module, $schema_file);
	}

	# sensible defaults
	$function ||= 'run';
	$iterations ||= DEFAULT_ITERATIONS;		 # default fuzz runs if not specified
	$seed = undef if defined $seed && $seed eq '';	# treat empty as undef

	# --- YAML corpus support (yaml_cases is filename string) ---
	my %yaml_corpus_data;
	if (defined $yaml_cases) {
		croak("$yaml_cases: $!") if(!-f $yaml_cases);

		my $yaml_data = LoadFile(Encode::decode('utf8', $yaml_cases));
		if ($yaml_data && ref($yaml_data) eq 'HASH') {
			# Validate that the corpus inputs are arrayrefs
			# e.g: "FooBar": 	["foo_bar"]
			# Skip only invalid entries:
			for my $expected (keys %{$yaml_data}) {
				my $outputs = $yaml_data->{$expected};
				unless($outputs && (ref $outputs eq 'ARRAY')) {
					carp("$yaml_cases: $expected does not point to an array ref, ignoring");
					next;
				}
				$yaml_corpus_data{$expected} = $outputs;
			}
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

	if(my $hints = delete $schema->{_yamltest_hints}) {
		if(my $boundaries = $hints->{boundary_values}) {
			push @edge_case_array, @{$boundaries};
		}
		if(my $invalid = $hints->{invalid}) {
			carp('TODO: handle yamltest_hints->invalid');
		}
	}

	# If the schema says the type is numeric, normalize
	if ($schema->{type} && $schema->{type} =~ /^(integer|number|float)$/) {
		for (@edge_case_array) {
			next unless defined $_;
			$_ += 0 if Scalar::Util::looks_like_number($_);
		}
	}

	# Load relationships from the schema if present and well-formed.
	# SchemaExtractor may set this to undef or an empty arrayref when
	# no relationships were detected, so guard both existence and type.
	my @relationships;
	if(exists($schema->{relationships}) && ref($schema->{relationships}) eq 'ARRAY') {
		@relationships = @{$schema->{relationships}};
	}

	# Serialise the relationships array from the schema into Perl source
	# code for embedding in the generated test file. Each relationship
	# type is rendered as a hashref in the @relationships array.

	my $relationships_code = '';

	# Walk each relationship in the order SchemaExtractor produced them
	for my $rel (@relationships) {
		my $type = $rel->{type} // '';

		# Mutually exclusive: both params being set should cause the method to die
		if($type eq 'mutually_exclusive') {
			$relationships_code .= "{ type => 'mutually_exclusive', params => [" .
				join(', ', map { perl_quote($_) } @{$rel->{params}}) .
				"] },\n";

		# Required group: at least one of the params must be present
		} elsif($type eq 'required_group') {
			$relationships_code .= "{ type => 'required_group', params => [" .
				join(', ', map { perl_quote($_) } @{$rel->{params}}) .
				"], logic => " . perl_quote($rel->{logic} // 'or') . " },\n";

		# Conditional requirement: if one param is set, another becomes mandatory
		} elsif($type eq 'conditional_requirement') {
			$relationships_code .= "{ type => 'conditional_requirement', if => " .
				perl_quote($rel->{'if'}) . ", then_required => " .
				perl_quote($rel->{then_required}) . " },\n";

		# Dependency: one param requires another to also be present
		} elsif($type eq 'dependency') {
			$relationships_code .= "{ type => 'dependency', param => " .
				perl_quote($rel->{param}) . ", requires => " .
				perl_quote($rel->{requires}) . " },\n";

		# Value constraint: one param being set forces another to a specific value
		} elsif($type eq 'value_constraint') {
			$relationships_code .= "{ type => 'value_constraint', if => " .
				perl_quote($rel->{'if'}) . ", then => " .
				perl_quote($rel->{then}) . ", operator => " .
				perl_quote($rel->{operator}) . ", value => " .
				perl_quote($rel->{value}) . " },\n";

		# Value conditional: one param equalling a specific value requires another param
		} elsif($type eq 'value_conditional') {
			$relationships_code .= "{ type => 'value_conditional', if => " .
				perl_quote($rel->{'if'}) . ", equals => " .
				perl_quote($rel->{equals}) . ", then_required => " .
				perl_quote($rel->{then_required}) . " },\n";

		# Unknown type — warn and skip rather than emitting broken code
		} else {
			carp "Unknown relationship type '$type', skipping";
		}
	}

	# Dedup the edge cases
	my %seen;
	@edge_case_array = grep {
		my $key = defined($_) ? (Scalar::Util::looks_like_number($_) ? "N:$_" : "S:$_") : 'U';
		!$seen{$key}++;
	} @edge_case_array;

	# Sort the edge cases to keep it consistent across runs
	@edge_case_array = sort {
		return -1 if !defined $a;
		return 1 if !defined $b;

		my $na = Scalar::Util::looks_like_number($a);
		my $nb = Scalar::Util::looks_like_number($b);

		return $a <=> $b if $na && $nb;
		return -1 if $na;
		return 1 if $nb;
		return $a cmp $b;
	} @edge_case_array;

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
		# Skip nested structures like 'properties' - they're used during
		# generation but don't need to be in the generated test
		if(ref($config{$key}) eq 'HASH') {
			next;
		}
		if((!defined($config{$key})) || !$config{$key}) {
			# YAML will strip the word 'false'
			# e.g. in 'test_undef: false'
			$config_code .= "'$key' => 0,\n";
		} else {
			$config_code .= "'$key' => $config{$key},\n";
		}
	}

	# Render input/output
	my $input_code = '';
	if(((scalar keys %input) == 1) && exists($input{'type'}) && !ref($input{'type'})) {
		# %input = ( type => 'string' );
		foreach my $key (sort keys %input) {
			$input_code .= "'$key' => '$input{$key}',\n";
		}
	} else {
		# %input = ( str => { type => 'string' } );
		$input_code = render_hash(\%input);
	}
	if(defined(my $re = $output{'matches'})) {
		if(ref($re) ne 'Regexp') {
			# Use eval to compile safely — qr/$re/ would interpolate
			# the string first, corrupting patterns containing [ or \
			my $compiled = eval { qr/$re/ };
			if($@) {
				carp("Invalid matches pattern '$re': $@");
			} else {
				$output{'matches'} = $compiled;
			}
		}
	}

	# Compile nomatch pattern to a Regexp object so it renders
	# as qr{} in the generated test rather than a raw string.
	# Without this, patterns containing [ or other regex
	# metacharacters cause compilation failures in validators
	if(defined(my $re = $output{'nomatch'})) {
		if(ref($re) ne 'Regexp') {
			# Use eval to compile safely — qr/$re/ would interpolate
			# the string first, corrupting patterns containing [ or \
			my $compiled = eval { qr/$re/ };
			if($@) {
				carp("Invalid nomatch pattern '$re': $@");
			} else {
				$output{'nomatch'} = $compiled;
			}
		}
	}

	my $output_code = render_args_hash(\%output);
	my $new_code = ($new && (ref $new eq 'HASH')) ? render_args_hash($new) : '';

	my $transforms_code;
	if(keys %transforms) {
		foreach my $transform(keys %transforms) {
			my $properties = render_fallback($transforms{$transform}->{'properties'});

			if($transforms_code) {
				$transforms_code .= "},\n";
			}
			$transforms_code .= "$transform => {\n" .
				"\t'input' => { " .
				render_args_hash($transforms{$transform}->{'input'}) .
				"\t}, 'output' => { " .
				render_args_hash($transforms{$transform}->{'output'}) .
				"\t}, 'properties' => $properties\n" .
				"\t,\n";
		}
		$transforms_code .= "}\n";
	}

	my $transform_properties_code = '';
	my $use_properties = 0;

	if (keys %transforms && ($config{properties}{enable} // 0)) {
		$use_properties = 1;

		# Generate property-based tests for transforms
		my $properties = _generate_transform_properties(
			\%transforms,
			$function,
			$module,
			\%input,
			\%config,
			$new
		);

		# Convert to code for template
		$transform_properties_code = _render_properties($properties);
	}

	if(keys %accessor) {
		# Sanity test
		my $property = $accessor{property};
		my $type = $accessor{type};

		if(!defined($new)) {
			croak("BUG: $property: accessor $type can only work on an object, incorrectly tagged as $type");
		}
		if($type eq 'getset') {
			if(scalar(keys %input) != 1) {
				croak("BUG: $property: getset must take one input argument, incorrectly tagged as getset");
			}
			if(scalar(keys %output) == 0) {
				croak("BUG: $property: getset must give one output, incorrectly tagged as getset");
			}
		}
	}

	# Setup / call code (always load module)
	my $setup_code = ($module) ? "BEGIN { use_ok('$module') }" : '';
	my $call_code;	# Code to call the function being test when used with named arguments
	my $position_code;	# Code to call the function being test when used with position arguments
	my $has_positions = _has_positions(\%input);
	if(defined($new) && defined($module)) {
		# keep use_ok regardless (user found earlier issue)
		if($new_code eq '') {
			$new_code = "new_ok('$module')";
		} else {
			$new_code = "new_ok('$module' => [ { $new_code } ] )";
		}
		$setup_code .= "\nmy \$obj = $new_code;";
		if($has_positions) {
			$position_code = "\$result = (scalar(\@alist) == 1) ? \$obj->$function(\$alist[0]) : (scalar(\@alist) == 0) ? \$obj->$function() : \$obj->$function(\@alist);";
			if(defined($accessor{type})) {
				if($accessor{type} eq 'getter') {
					$position_code .= "my \$prev_value = \$obj->{$accessor{property}};";
				} elsif($accessor{type} eq 'getset') {
					$position_code .= 'if(scalar(@alist) == 1) { ';
					$position_code .= "cmp_ok(\$result, 'eq', \$alist[0], 'getset function returns what was put in'); ok(\$obj->$function() eq \$result, 'test getset accessor');";
					$position_code .= '}';
				}
				if(($accessor{type} eq 'getset') || ($accessor{type} eq 'getter')) {
					# Since Perl doesn't support data encapsulation, we can test the getter returns the correct item
					$position_code .= 'if(scalar(@alist) == 1) { ';
					$position_code .= "cmp_ok(\$result, 'eq', \$obj->{$accessor{property}}, 'getset function returns correct item');";
					if($accessor{type} eq 'getter') {
						$position_code .= "if(defined(\$prev_value)) { cmp_ok(\$result, 'eq', \$prev_value, 'getter does not change value'); } ";
					}
					$position_code .= '}';
				}
				if($output{'_returns_self'}) {
					croak("$accessor{type} for $accessor{property} cannot return \$self");
				}
			}
		} else {
			$call_code = "\$result = \$obj->$function(\$input);";
			if($output{'_returns_self'}) {
				$call_code .= "ok(defined(\$result)); ok(\$result eq \$obj, '$function returns self')";
			} elsif(defined($accessor{type}) && ($accessor{type} eq 'getset')) {
				$call_code .= "ok(\$obj->$function() eq \$result, 'test getset accessor');"
			}
			if(scalar(keys %input) == 0) {
				if(defined($accessor{type}) && ($accessor{type} eq 'getter')) {
					$call_code .= "cmp_ok(\$result, 'eq', \$obj->{$accessor{property}}, 'getter function returns correct item') if(defined(\$result));";
				}
			}
		}
	} elsif(defined($module) && length($module)) {
		if($function eq 'new') {
			if($has_positions) {
				$position_code = "\$result = (scalar(\@alist) == 1) ? ${module}\->$function(\$alist[0]) : (scalar(\@alist) == 0) ? ${module}\->$function() : ${module}\->$function(\@alist);";
			} else {
				$call_code = "\$result = ${module}\->$function(\$input);";
			}
		} else {
			if($has_positions) {
				$position_code = "\$result = (scalar(\@alist) == 1) ? ${module}::$function(\$alist[0]) : (scalar(\@alist) == 0) ? ${module}::$function() : ${module}::$function(\@alist);";
			} else {
				$call_code = "\$result = ${module}::$function(\$input);";
			}
		}
	} else {
		if($has_positions) {
			$position_code = "\$result = $function(\@alist);";
		} else {
			$call_code = "\$result = $function(\$input);";
		}
	}

	# Build static corpus code
	my $corpus_code = '';
	if (%all_cases) {
		$corpus_code = "\n# --- Static Corpus Tests ---\n" .
			"diag('Running " . scalar(keys %all_cases) . " corpus tests');\n";

		for my $expected (sort keys %all_cases) {
			my $inputs = $all_cases{$expected};
			next unless($inputs);

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
			my $input_str;
			if(ref($inputs) eq 'ARRAY') {
				$input_str = join(', ', map { perl_quote($_) } @{$inputs});
			} elsif(ref($inputs) eq 'HASH') {
				$input_str = Dumper($inputs);
				$input_str =~ s/\$VAR1 =//;
				$input_str =~ s/;//;
				$input_str =~ s/=> 'undef'/=> undef/gms;
			} else {
				$input_str = $inputs;
			}
			if(($input_str eq 'undef') && (!$config{'test_undef'})) {
				carp('corpus case set to undef, yet test_undef is not set in config');
			}
			if($new) {
				if($status eq 'DIES') {
					$corpus_code .= "dies_ok { \$obj->$function($input_str) } " .
							"'$function(" . join(', ', map { $_ // '' } @$inputs ) . ") dies';\n";
				} elsif($status eq 'WARNS') {
					$corpus_code .= "warnings_exist { \$obj->$function($input_str) } qr/./, " .
							"'$function(" . join(', ', map { $_ // '' } @$inputs ) . ") warns';\n";
				} else {
					my $desc = sprintf("$function(%s) returns %s",
						perl_quote(join(', ', map { $_ // '' } @$inputs )),
						$expected_str
					);
					if(($output{'type'} // '') eq 'boolean') {
						if($expected_str eq '1') {
							$corpus_code .= "ok(\$obj->$function($input_str), " . q_wrap($desc) . ");\n";
						} elsif($expected_str eq '0') {
							$corpus_code .= "ok(!\$obj->$function($input_str), " . q_wrap($desc) . ");\n";
						} else {
							croak("Boolean is expected to return $expected_str");
						}
					} else {
						$corpus_code .= "is(\$obj->$function($input_str), $expected_str, " . q_wrap($desc) . ");\n";
					}
				}
			} else {
				if($status eq 'DIES') {
					if($module) {
						$corpus_code .= "dies_ok { $module\::$function($input_str) } " .
							"'Corpus $expected dies';\n";
					} else {
						$corpus_code .= "dies_ok { $function($input_str) } " .
							"'Corpus $expected dies';\n";
					}
				} elsif($status eq 'WARNS') {
					if($module) {
						$corpus_code .= "warnings_exist { $module\::$function($input_str) } qr/./, " .
							"'Corpus $expected warns';\n";
					} else {
						$corpus_code .= "warnings_exist { $function($input_str) } qr/./, " .
							"'Corpus $expected warns';\n";
					}
				} else {
					my $desc = sprintf("$function(%s) returns %s",
						perl_quote((ref $inputs eq 'ARRAY') ? (join(', ', map { $_ // '' } @{$inputs})) : $inputs),
						$expected_str
					);
					if(($output{'type'} // '') eq 'boolean') {
						if($expected_str eq '1') {
							$corpus_code .= "ok(\$obj->$function($input_str), " . q_wrap($desc) . ");\n";
						} elsif($expected_str eq '0') {
							$corpus_code .= "ok(!\$obj->$function($input_str), " . q_wrap($desc) . ");\n";
						} else {
							croak("Boolean is expected to return $expected_str");
						}
					} else {
						$corpus_code .= "is(\$obj->$function($input_str), $expected_str, " . q_wrap($desc) . ");\n";
					}
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

	my $determinism_code = 'my $result2;' .
		'eval { $result2 = do { ' . (defined($position_code) ? $position_code : $call_code) . " }; };\n" .
		'is_deeply($result2, $result, "deterministic result for same input");' .
		"\n";

	# Generate the test content
	my $tt = Template->new({ ENCODING => 'utf8', TRIM => 1 });

	# Read template from DATA handle
	my $template_package = __PACKAGE__ . '::Template';
	my $template = $template_package->get_data_section('test.tt');

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
		position_code => $position_code,
		determinism_code => $determinism_code,
		function => $function,
		iterations_code => int($iterations),
		use_properties => $use_properties,
		transform_properties_code => $transform_properties_code,
		property_trials => $config{properties}{trials} // DEFAULT_PROPERTY_TRIALS,
		relationships_code => $relationships_code,
		module => $module
	};

	my $test;
	$tt->process($template, $vars, \$test) or croak($tt->error());

	if ($test_file) {
		open my $fh, '>:encoding(UTF-8)', $test_file or croak "Cannot open $test_file: $!";
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

# --- Helpers for rendering data structures into Perl code for the generated test ---

# --------------------------------------------------
# _load_schema
#
# Load and parse a schema file using
#     Config::Abstraction, returning the
#     schema as a hashref.
#
# Entry:      $schema_file - path to the schema file.
#             Must be defined, non-empty, and readable.
#
# Exit:       Returns a hashref of the parsed schema
#             with a '_source' key added containing
#             the originating file path.
#             Croaks on any error.
#
# Side effects: Reads from the filesystem.
#
# Notes:      Legacy Perl-file configs (containing
#             '$module' or 'our $module' keys) are
#             rejected with a clear error. Config::
#             Abstraction is used rather than require()
#             to avoid executing arbitrary code from
#             user-supplied config files.
# --------------------------------------------------
sub _load_schema {
	my $schema_file = $_[0];

	# Validate the argument before touching the filesystem
	croak(__PACKAGE__, ': Usage: _load_schema($schema_file)') unless defined $schema_file;

	croak(__PACKAGE__, ': _load_schema given empty filename') unless length($schema_file);

	# Confirm the file exists and is readable before attempting
	# to load it — gives a clearer error than Config::Abstraction would
	croak(__PACKAGE__, ": _load_schema($schema_file): $!") unless -r $schema_file;

	# Load configuration via Config::Abstraction which supports
	# YAML, JSON, and other formats without executing arbitrary code.
	# no_fixate prevents automatic type coercion that could alter values
	if(my $schema = Config::Abstraction->new(
		config_dirs  => ['.', ''],
		config_file  => $schema_file,
		no_fixate    => 1,
	)) {
		if($schema = $schema->all()) {
			# Detect legacy Perl config files by the presence of
			# variable declaration keys — these are no longer supported
			if(exists($schema->{$LEGACY_PERL_KEY_1}) ||
			   exists($schema->{$LEGACY_PERL_KEY_2})) {
				croak("$schema_file: Loading perl files as configs is no longer supported");
			}

			# Tag the schema with its source path for error messages
			$schema->{$SOURCE_KEY} = $schema_file;
			return $schema;
		}
	}

	croak "Failed to load schema from $schema_file";
}

# --------------------------------------------------
# _load_schema_section
#
# Purpose:    Extract a named section from a parsed
#             schema hashref, validating that it is
#             a hashref if present.
#
# Entry:      $schema      - the full parsed schema hashref.
#             $section     - name of the section to extract
#                            (e.g. 'input', 'output').
#             $schema_file - path of the schema file,
#                            used in error messages only.
#
# Exit:       Returns the section hashref if present,
#             or an empty hashref {} if absent.
#             Croaks if the section exists but is not
#             a hashref (and not the string 'undef').
#
# Side effects: None.
#
# Notes:      The string 'undef' is treated as an
#             absent section — callers that set a
#             section to 'undef' in YAML get the same
#             result as omitting it entirely.
# --------------------------------------------------
sub _load_schema_section {
	my ($schema, $section, $schema_file) = @_;

	# Section absent — return empty hash as the safe default
	return {} unless exists $schema->{$section};

	# Section present and is a hashref — return it directly
	return $schema->{$section}
		if ref($schema->{$section}) eq 'HASH';

	# Treat the YAML scalar 'undef' as equivalent to absent
	return {}
		if defined($schema->{$section}) &&
		   $schema->{$section} eq 'undef';

	# Section present but wrong type — croak with a clear message
	# showing what type was found so the user can fix their schema
	croak(
		"$schema_file: $section should be a hash, not ",
		ref($schema->{$section}) || $schema->{$section}
	);
}

# --------------------------------------------------
# _validate_config
#
# Purpose:    Validate the top-level schema hashref
#             loaded from a schema file, checking that
#             required fields are present and that all
#             input parameters, types, positions, and
#             transform properties are well-formed.
#
# Entry:      $schema - the full parsed schema hashref
#             as returned by _load_schema().
#
# Exit:       Returns nothing on success.
#             Croaks on any structural error.
#             Carps on non-fatal warnings (unknown
#             semantic types, position gaps, missing
#             input/output definitions).
#
# Side effects: May delete $schema->{input} if its
#               value is the string 'undef'.
#
# Notes:      The parameter is named $schema throughout
#             to distinguish the top-level schema from
#             the nested config sub-hash. _validate_config
#             is called before _normalize_config so config
#             boolean normalisation has not yet occurred.
# --------------------------------------------------
sub _validate_config {
	my $schema = $_[0];

	# At least one of module or function must be present —
	# without these we cannot generate any meaningful test
	if(!defined($schema->{'module'}) && !defined($schema->{'function'})) {
		croak('At least one of function and module must be defined');
	}

	# Warn if neither input nor output is defined — a few
	# generic tests can still be generated but it is unusual
	if(!defined($schema->{'input'}) && !defined($schema->{'output'})) {
		carp('Neither input nor output is defined, only a few tests will be generated');
	}

	# Normalise input: the string 'undef' means no input defined
	if($schema->{'input'} && ref($schema->{input}) ne 'HASH') {
		if($schema->{'input'} eq 'undef') {
			delete $schema->{'input'};
		} else {
			croak("Invalid input specification: expected hash, got '$schema->{'input'}'");
		}
	}

	# Validate each input parameter if input is defined
	if($schema->{input}) {
		_validate_input_params($schema);
		_validate_input_positions($schema);
		_validate_input_semantics($schema);
	}

	# Validate transform property definitions if present
	if(exists($schema->{transforms}) && ref($schema->{transforms}) eq 'HASH') {
		_validate_transform_properties($schema);
	}

	# Validate any nested config sub-hash keys against known types
	if(ref($schema->{config}) eq 'HASH') {
		for my $k (keys %{$schema->{'config'}}) {
			# CONFIG_TYPES is the authoritative list of valid keys
			croak "unknown config setting '$k'"
				unless grep { $_ eq $k } CONFIG_TYPES;
		}
	}
}

# --------------------------------------------------
# _validate_input_params
#
# Purpose:    Validate type specifications for each
#             named input parameter.
#
# Entry:      $schema - the full parsed schema hashref.
#             $schema->{input} must be a hashref.
#
# Exit:       Returns nothing. Croaks on invalid type.
# Side effects: None.
# --------------------------------------------------
sub _validate_input_params {
	my $schema = $_[0];

	for my $param (keys %{$schema->{input}}) {
		# Catch empty parameter names — these would produce
		# broken Perl variable names in the generated test
		croak 'Empty input parameter name'
			unless length($param);

		my $spec = $schema->{input}{$param};

		# Validate the type field — required for all parameters
		if(ref($spec)) {
			croak("Missing type for parameter '$param'")
				unless defined $spec->{type};
			croak("Invalid type '$spec->{type}' for parameter '$param'")
				unless _valid_type($spec->{type});
		} else {
			croak("Invalid type '$spec' for parameter '$param'")
				unless _valid_type($spec);
		}
	}
}

# --------------------------------------------------
# _validate_input_positions
#
# Purpose:    Validate positional argument declarations
#             in the input schema — positions must be
#             non-negative integers with no duplicates,
#             and either all or no parameters must have
#             positions.
#
# Entry:      $schema - the full parsed schema hashref.
#             $schema->{input} must be a hashref.
#
# Exit:       Returns nothing. Croaks on invalid or
#             duplicate positions. Carps on gaps.
# Side effects: None.
# --------------------------------------------------
sub _validate_input_positions {
	my $schema = $_[0];

	my $has_positions = 0;
	my %positions;

	for my $param (keys %{$schema->{input}}) {
		my $spec = $schema->{input}{$param};

		# Only process params that explicitly declare a position
		next unless ref($spec) eq 'HASH' && defined($spec->{position});

		$has_positions = 1;
		my $pos = $spec->{position};

		# Position must be a non-negative integer
		croak "Position for '$param' must be a non-negative integer"
			unless $pos =~ /^\d+$/;

		# Duplicate positions would produce ambiguous generated tests
		croak "Duplicate position $pos for parameters '$positions{$pos}' and '$param'"
			if exists $positions{$pos};

		$positions{$pos} = $param;
	}

	# If any param has a position, all params must have one
	if($has_positions) {
		for my $param (keys %{$schema->{input}}) {
			my $spec = $schema->{input}{$param};
			unless(ref($spec) eq 'HASH' && defined($spec->{position})) {
				croak "Parameter '$param' missing position " .
					'(all params must have positions if any do)';
			}
		}

		# Check for gaps — positions must be a contiguous sequence
		# starting at 0, otherwise the generated test will be wrong
		my @sorted = sort { $a <=> $b } keys %positions;
		for my $i (0 .. $#sorted) {
			if($sorted[$i] != $i) {
				carp "Position sequence has gaps (positions: @sorted)";
				last;
			}
		}
	}
}

# --------------------------------------------------
# _validate_input_semantics
#
# Purpose:    Validate semantic type annotations and
#             enum/memberof constraints on input params.
#
# Entry:      $schema - the full parsed schema hashref.
#             $schema->{input} must be a hashref.
#
# Exit:       Returns nothing. Croaks on conflicting
#             or malformed enum/memberof. Carps on
#             unknown semantic types.
# Side effects: None.
# --------------------------------------------------
sub _validate_input_semantics {
	my $schema = $_[0];

	my $semantic_generators = _get_semantic_generators();

	for my $param (keys %{$schema->{input}}) {
		my $spec = $schema->{input}{$param};
		next unless ref($spec) eq 'HASH';

		# Warn on unknown semantic types rather than croaking —
		# new semantic types may be added without updating this list
		if(defined($spec->{semantic})) {
			my $semantic = $spec->{semantic};
			unless(exists $semantic_generators->{$semantic}) {
				carp "Unknown semantic type '$semantic' for parameter '$param'. " .
					'Available types: ' .
					join(', ', sort keys %{$semantic_generators});
			}
		}

		# enum and memberof are mutually exclusive representations
		# of the same concept — having both is always a schema error
		if($spec->{'enum'} && $spec->{'memberof'}) {
			croak "$param: has both enum and memberof";
		}

		# Both enum and memberof must be arrayrefs when present
		for my $type ('enum', 'memberof') {
			if(exists $spec->{$type}) {
				croak "$type must be an arrayref"
					unless ref($spec->{$type}) eq 'ARRAY';
			}
		}
	}
}

# --------------------------------------------------
# _validate_transform_properties
#
# Purpose:    Validate the properties array in each
#             transform definition, checking that each
#             property is either a known builtin name
#             or a custom hashref with name and code.
#
# Entry:      $schema - the full parsed schema hashref.
#             $schema->{transforms} must be a hashref.
#
# Exit:       Returns nothing. Croaks on invalid property
#             definitions. Carps on unknown builtins.
# Side effects: None.
# --------------------------------------------------
sub _validate_transform_properties {
	my $schema = $_[0];

	my $builtin_props = _get_builtin_properties();

	for my $transform_name (keys %{$schema->{transforms}}) {
		my $transform = $schema->{transforms}{$transform_name};

		# properties is optional — skip transforms that don't define it
		next unless exists $transform->{properties};

		croak "Transform '$transform_name': properties must be an array"
			unless ref($transform->{properties}) eq 'ARRAY';

		for my $prop (@{$transform->{properties}}) {
			if(!ref($prop)) {
				# Plain string — must be a known builtin property name
				unless(exists $builtin_props->{$prop}) {
					carp "Transform '$transform_name': unknown built-in property '$prop'. " .
						'Available: ' .
						join(', ', sort keys %{$builtin_props});
				}
			} elsif(ref($prop) eq 'HASH') {
				# Custom property — must have both name and code fields
				unless($prop->{name} && $prop->{code}) {
					croak "Transform '$transform_name': " .
						"custom properties must have 'name' and 'code' fields";
				}
			} else {
				croak "Transform '$transform_name': invalid property definition";
			}
		}
	}
}

# --------------------------------------------------
# _normalize_config
#
# Purpose:    Normalise boolean string values in the
#             config sub-hash to Perl integers (1/0),
#             and default absent boolean fields to 1
#             (enabled). The 'properties' field is a
#             hashref not a boolean and is handled
#             separately.
#
# Entry:      $config - the config sub-hash extracted
#             from the schema (i.e. $schema->{config}).
#             May be empty.
#
# Exit:       Returns nothing. Modifies $config in place.
#
# Side effects: Modifies the caller's config hashref.
#
# Notes:      String-to-boolean conversion is delegated
#             to %Readonly::Values::Boolean::booleans
#             which handles 'yes'/'no', 'on'/'off',
#             'true'/'false' etc. Fields not present in
#             the config hash are defaulted to 1 so
#             that test generation is maximally thorough
#             unless the schema explicitly disables a
#             feature.
# --------------------------------------------------
sub _normalize_config {
	my $config = $_[0];

	for my $field (CONFIG_TYPES) {
		# The properties field is a hashref not a boolean —
		# it is handled at the end of this function separately
		next if $field eq $CONFIG_PROPERTIES_KEY;

		if(exists($config->{$field}) && defined($config->{$field})) {
			# Convert string boolean representations to integers
			# using the lookup table from Readonly::Values::Boolean
			if(defined(my $b = $Readonly::Values::Boolean::booleans{$config->{$field}})) {
				$config->{$field} = $b;
			}
		} else {
			# Default absent boolean fields to enabled (1) so that
			# test generation is comprehensive unless explicitly disabled
			$config->{$field} = 1;
		}
	}

	# Ensure properties is always a hashref — if absent or set to
	# a non-hash value, replace with a disabled default so that
	# downstream code can safely dereference it without checking ref()
	$config->{$CONFIG_PROPERTIES_KEY} = { enable => 0 } unless ref($config->{$CONFIG_PROPERTIES_KEY}) eq 'HASH';
}

# --------------------------------------------------
# _valid_type
#
# Determine whether a string is a
#     recognised schema field type accepted
#     by the generator.
#
# Entry:      $type - the type string to validate.
#             May be undef.
#
# Exit:       Returns 1 if the type is known,
#             0 if the type is unknown or undef.
#
# Side effects: None.
#
# Notes:      The lookup hash is declared with
#             'state' so it is built only once per
#             process rather than on every call —
#             important since _valid_type is called
#             in a loop over all input parameters.
#
#             'int' and 'bool' are accepted as
#             aliases for 'integer' and 'boolean'
#             respectively, for compatibility with
#             schemas generated by external tools
#             that use the shorter forms.
# --------------------------------------------------
sub _valid_type {
	my $type = $_[0];

	# Undef is never a valid type
	return 0 unless defined($type);

	# Build the lookup table once and cache it for
	# the lifetime of the process via 'state'
	state %VALID = map { $_ => 1 } qw(
		string boolean integer number float
		hashref arrayref object int bool
	);

	return($VALID{$type} // 0);
}

# --------------------------------------------------
# _validate_module
#
# Purpose:    Check whether the module named in a
#             schema can be found in @INC during
#             test generation. Optionally also
#             attempts to load it if the
#             GENERATOR_VALIDATE_LOAD environment
#             variable is set.
#
# Entry:      $module      - the module name to
#                            check. If undef or
#                            empty, returns 1
#                            immediately (builtin
#                            functions need no
#                            module).
#             $schema_file - path to the schema
#                            file, used in warning
#                            messages only.
#
# Exit:       Returns 1 if the module was found
#             (and loaded, if validation was
#             requested).
#             Returns 0 if the module was not
#             found or failed to load — this is
#             non-fatal; generation continues.
#             Returns 1 immediately for undef or
#             empty $module.
#
# Side effects: Prints to STDERR when TEST_VERBOSE
#               or GENERATOR_VERBOSE is set.
#               Carps (non-fatally) when the module
#               cannot be found or loaded.
#               May attempt to load the module into
#               the current process when
#               GENERATOR_VALIDATE_LOAD is set —
#               this can have side effects depending
#               on the module.
#
# Notes:      Not finding a module during generation
#             is intentionally non-fatal — the module
#             may be available on the target machine
#             even if not on the generation machine.
#             Verbose output goes to STDERR via
#             print rather than carp since it is
#             informational, not a warning.
# --------------------------------------------------
sub _validate_module {
	my ($module, $schema_file) = @_;

	# Builtin functions have no module to validate
	return 1 unless $module;

	# Check whether the module is findable in @INC
	my $mod_info = check_install(module => $module);

	if($schema_file && !$mod_info) {
		# Non-fatal — emit a single consolidated warning so
		# the caller sees one message rather than four
		carp(
			"Module '$module' not found in \@INC during generation.\n" .
			"  Config file: $schema_file\n" .
			"  This is OK if the module will be available when tests run.\n" .
			'  If unexpected, check your module name and installation.'
		);
		return 0;
	}

	# Check once and reuse — avoids evaluating two env vars twice
	my $verbose = $ENV{$ENV_TEST_VERBOSE} || $ENV{$ENV_GENERATOR_VERBOSE};

	if($verbose) {
		print STDERR "Found module '$module' at: $mod_info->{'file'}\n",
			'  Version: ', ($mod_info->{'version'} || 'unknown'), "\n";
	}

	# Optional load validation — disabled by default because
	# loading a module can have side effects (e.g. BEGIN blocks,
	# database connections, file I/O) that are undesirable
	# during generation
	if($ENV{$ENV_VALIDATE_LOAD}) {
		my $loaded = can_load(modules => { $module => undef }, verbose => 0);

		if(!$loaded) {
			my $err = $Module::Load::Conditional::ERROR || 'unknown error';
			carp(
				"Module '$module' found but failed to load: $err\n" .
				'  This might indicate a broken installation or missing dependencies.'
			);
			return 0;
		}

		if($verbose) {
			print STDERR "Successfully loaded module '$module'\n";
		}
	}

	return 1;
}

=head2 render_fallback

Render any Perl value into a compact Perl source-code string using
L<Data::Dumper>. Used as a catch-all when no more specific renderer
applies.

    my $code = render_fallback({ key => 'value' });
    # returns: "{'key' => 'value'}"

=head3 Arguments

=over 4

=item * C<$v>

Any Perl value, including undef, scalars, refs, and blessed objects.

=back

=head3 Returns

A string of Perl source code that reproduces the value when evaluated.
Returns the string C<'undef'> when C<$v> is undef.

=head3 Side effects

Temporarily sets C<$Data::Dumper::Terse> and C<$Data::Dumper::Indent>
to produce compact single-line output. Both are restored on return via
C<local>.

=head3 Notes

The output is always a single line with no trailing newline. Suitable
for embedding in generated test code where readability is secondary to
correctness.

=head3 API specification

=head4 input

    { v => { type => SCALAR|REF, optional => 1 } }

=head4 output

    { type => SCALAR }

=cut

sub render_fallback {
	my $v = $_[0];

	# Handle undef explicitly rather than letting Dumper produce
	# 'undef' without the localised settings applied
	return 'undef' unless defined $v;

	# Use Terse+Indent=0 to produce compact single-line output
	# suitable for embedding in generated test code
	local $Data::Dumper::Terse  = 1;
	local $Data::Dumper::Indent = 0;

	my $s = Dumper($v);

	# Remove trailing newline that Dumper always appends
	chomp $s;
	return $s;
}

=head2 render_hash

Render a two-level hashref (parameter name => spec hashref) into Perl
source code suitable for embedding in a generated test file as the
input specification passed to L<Params::Validate::Strict>.

    my $code = render_hash(\%input);

=head3 Arguments

=over 4

=item * C<$href>

A hashref whose values are themselves hashrefs containing field
specifications. Keys whose values are not hashrefs are skipped with
a warning.

=back

=head3 Returns

A string of comma-separated Perl source-code lines, one per key, of
the form:

    'key' => { subkey => value, ... }

Returns an empty string if C<$href> is undef, empty, or not a hashref.

=head3 Side effects

None. Does not modify C<$href>.

=head3 Notes

The C<matches> and C<nomatch> sub-keys are treated specially — their
values are compiled to C<Regexp> objects via C<eval { qr/.../ }> and
then rendered using C<perl_quote> so they appear as C<qr{...}> in the
generated test. This prevents unmatched bracket characters in the
pattern from causing compilation failures.

Other sub-keys are rendered via C<perl_quote>.

=head3 API specification

=head4 input

    { href => { type => HASHREF, optional => 1 } }

=head4 output

    { type => SCALAR }

=cut

sub render_hash {
	my $href = $_[0];

	# Return empty string for absent or non-hash input — callers
	# treat '' as "no input specification" in the generated test
	return '' unless $href && ref($href) eq 'HASH';

	my @lines;

	for my $k (sort keys %{$href}) {
		my $def = $href->{$k};

		# Handle scalar shorthand — 'arg1: string' is equivalent to
		# 'arg1: { type: string }' and is explicitly supported by the
		# validation layer in _validate_input_params
		unless(defined($def) && ref($def) eq 'HASH') {
			if(defined($def) && !ref($def) && _valid_type($def)) {
				# Expand scalar type shorthand to a full spec hashref
				$def = { type => $def };
			} else {
				carp "render_hash: skipping key '$k' — value is not a hashref or recognised type string";
				next;
			}
		}

		my @pairs;

		for my $subk (sort keys %{$def}) {
			# Skip undef sub-values — they contribute nothing to the spec
			next unless defined $def->{$subk};

			# Validate that reference types are ones we can render —
			# nested hashrefs are not yet supported
			if(ref($def->{$subk})) {
				unless((ref($def->{$subk}) eq 'ARRAY') ||
				       (ref($def->{$subk}) eq 'Regexp')) {
					croak(
						__PACKAGE__,
						": $subk is a nested element, not yet supported (",
						ref($def->{$subk}), ')'
					);
				}
			}

			# matches and nomatch values must be Regexp objects in the
			# generated test — compile raw strings safely via eval so
			# patterns containing [ or \ don't cause compile failures
			if(($subk eq $KEY_MATCHES) || ($subk eq $KEY_NOMATCH)) {
				my $re = ref($def->{$subk}) eq 'Regexp'
					? $def->{$subk}
					: eval { qr/$def->{$subk}/ };
				if($@ || !defined($re)) {
					carp "render_hash: invalid $subk pattern '$def->{$subk}': $@";
					next;
				}
				push @pairs, "$subk => " . perl_quote($re);
			} else {
				# All other sub-keys are rendered via perl_quote which
				# handles scalars, arrayrefs, and Regexp objects correctly
				push @pairs, "$subk => " . perl_quote($def->{$subk});
			}
		}

		# Use "\t" rather than a literal tab for clarity and grep-ability
		push @lines, "\t" . perl_quote($k) . ' => { ' . join(', ', @pairs) . ' }';
	}

	return join(",\n", @lines);
}

=head2 render_args_hash

Render a flat hashref into a Perl source-code argument list of the
form C<'key' => value, ...>, suitable for embedding in a function call
in a generated test file.

    my $code = render_args_hash({ type => 'string', min => 1 });
    # returns: "'min' => 1, 'type' => 'string'"

=head3 Arguments

=over 4

=item * C<$href>

A flat hashref of key-value pairs. Values may be scalars, arrayrefs,
or Regexp objects — all are handled by C<perl_quote>.

=back

=head3 Returns

A comma-separated string of C<key => value> pairs sorted by key.
Returns an empty string if C<$href> is undef, empty, or not a hashref.

=head3 Side effects

None.

=head3 Notes

Keys and values are both rendered via C<perl_quote>. In particular,
C<Regexp> values are rendered as C<qr{...}> which is correct for
L<Params::Validate::Strict> and L<Return::Set> schema arguments in
the generated test.

=head3 API specification

=head4 input

    { href => { type => HASHREF, optional => 1 } }

=head4 output

    { type => SCALAR }

=cut

sub render_args_hash {
	my $href = $_[0];

	# Return empty string for absent or non-hash input
	return '' unless $href && ref($href) eq 'HASH';

	# Sort keys for deterministic output across runs — important for
	# generated test files that are committed to version control
	my @pairs = map {
		perl_quote($_) . ' => ' . perl_quote($href->{$_})
	} sort keys %{$href};

	return join(', ', @pairs);
}

=head2 render_arrayref_map

Render a hashref whose values are arrayrefs into a Perl source-code
fragment suitable for use as a hash literal in a generated test file.

    my $code = render_arrayref_map({ name => ['', 'a' x 100] });

=head3 Arguments

=over 4

=item * C<$href>

A hashref whose values are arrayrefs. Keys whose values are not
arrayrefs are silently skipped.

=back

=head3 Returns

A comma-separated string of C<'key' => [ val, ... ]> entries, one per
qualifying key, sorted alphabetically. Returns the string C<'()'> if
C<$href> is undef, empty, or not a hashref — this produces an empty
hash assignment in the generated test rather than a syntax error.

=head3 Side effects

None.

=head3 Notes

Array element values are rendered via C<perl_quote> which handles
scalars, arrayrefs, and Regexp objects. Non-arrayref values are
skipped without warning — this is intentional since callers may pass
mixed-value hashes and only want the arrayref entries rendered.

=head3 API specification

=head4 input

    { href => { type => HASHREF, optional => 1 } }

=head4 output

    { type => SCALAR }

=cut

sub render_arrayref_map {
	my $href = $_[0];

	# Return '()' rather than '' so callers get a valid empty hash
	# literal rather than a syntax error in the generated test
	return '()' unless $href && ref($href) eq 'HASH';

	my @entries;

	for my $k (sort keys %{$href}) {
		my $aref = $href->{$k};

		# Skip non-arrayref values — mixed hashes are allowed by callers
		next unless ref($aref) eq 'ARRAY';

		# Render each array element via perl_quote so strings are
		# properly quoted and numbers are left unquoted
		my $vals = join(', ', map { perl_quote($_) } @{$aref});

		# Use "\t" rather than a literal tab for clarity
		push @entries, "\t" . perl_quote($k) . " => [ $vals ]";
	}

	return join(",\n", @entries);
}

# --------------------------------------------------
# _has_positions
#
# Purpose:    Determine whether any field in an input
#             spec hashref declares a positional argument
#             via the 'position' key.
#
# Entry:      $input_spec - the input section of a parsed
#             schema, expected to be a hashref whose values
#             are themselves hashrefs containing field specs.
#             May be undef or a non-hash ref.
#
# Exit:       Returns 1 if any field has a defined
#             'position' key, 0 otherwise.
#
# Side effects: None.
#
# Notes:      Returns 0 immediately for undef or non-hash
#             input rather than throwing — callers use the
#             return value as a boolean and do not expect
#             exceptions from this function.
# --------------------------------------------------
sub _has_positions {
	my $input_spec = $_[0];

	# Guard against undef or non-hash input — keys %$undef would throw
	return 0 unless defined($input_spec) && ref($input_spec) eq 'HASH';

	for my $field (keys %{$input_spec}) {
		# Only examine fields whose spec is a hashref — scalar specs
		# (e.g. input: { type: string }) cannot have positions
		next unless ref($input_spec->{$field}) eq 'HASH';

		# Return immediately on first match — no need to scan further
		return 1 if defined $input_spec->{$field}{position};
	}

	# No positional arguments found in any field
	return 0;
}

# --------------------------------------------------
# q_wrap
#
# Purpose:    Wrap a string in the most readable
#             q{} form that does not require escaping,
#             falling back to single-quoted form with
#             escaped apostrophes if no delimiter is
#             available.
#
# Entry:      $s - the string to wrap. May be undef.
# Exit:       Returns a Perl source-code fragment that
#             evaluates to the original string value,
#             or the string 'undef' if $s is undef.
#
# Side effects: None.
#
# Notes:      index() returns -1 when not found and
#             any value >= 0 when found, including 0
#             for a delimiter at the start of the
#             string. We compare against $INDEX_NOT_FOUND
#             to make this boundary explicit and to
#             prevent off-by-one mutation survivors.
#             See GitHub issue #1.
# --------------------------------------------------
sub q_wrap {
	my $s = $_[0];

	# Return empty string for undef — this function is a low-level
	# string quoter only. Callers that need the Perl literal 'undef'
	# for undefined values should use perl_quote() instead, which
	# handles the undef -> 'undef' semantic conversion correctly.
	# Returning '' here preserves the original behaviour and avoids
	# injecting the bare word 'undef' into contexts that expect a
	# quoted string value.
	return "''" unless defined $s;

	# Try bracket-form q{} delimiters first — most readable
	for my $p (@Q_BRACKET_PAIRS) {
		my ($l, $r) = @{$p};

		# Only use this bracket pair if neither bracket
		# appears in the string — both must be checked
		return "q$l$s$r" unless $s =~ /\Q$l\E|\Q$r\E/;
	}

	# Try single-character delimiters in preference order
	for my $d (@Q_SINGLE_DELIMITERS) {
		# index() returns $INDEX_NOT_FOUND (-1) when not found.
		# Must use != $INDEX_NOT_FOUND rather than > 0 since
		# the delimiter may legitimately appear at position 0
		return "q$d$s$d" if index($s, $d) == $INDEX_NOT_FOUND;
	}

	# Last resort — single-quoted string with escaped apostrophes
	(my $esc = $s) =~ s/'/\\'/g;
	return "'$esc'";
}

# --------------------------------------------------
# perl_sq
#
# Purpose:    Escape a string for safe inclusion
#             inside a single-quoted Perl string
#             literal in generated test code.
#
# Entry:      $s - the string to escape.
# Exit:       Returns the escaped string, or an
#             empty string if $s is undef.
#
# Side effects: None.
#
# Notes:      NUL byte replacement produces the
#             two-character sequence \0 which is
#             only correct when the result is used
#             inside a double-quoted string context
#             in the generated test.
#
#             The \b substitution (backspace) is
#             intentionally omitted — in Perl regex
#             context \b means word boundary, not
#             backspace, so substituting it here
#             would corrupt strings containing word
#             boundaries.
# --------------------------------------------------
sub perl_sq {
	my $s = $_[0];

	# Return empty string for undef — callers that need
	# 'undef' literal should use perl_quote instead
	return '' unless defined $s;

	# Escape backslashes first so later substitutions
	# don't double-escape already-escaped sequences
	$s =~ s/\\/\\\\/g;

	# Escape apostrophes so they don't terminate the
	# surrounding single-quoted string literal
	$s =~ s/'/\\'/g;

	# Escape common control characters to their
	# printable two-character escape sequences
	$s =~ s/\n/\\n/g;
	$s =~ s/\r/\\r/g;
	$s =~ s/\t/\\t/g;
	$s =~ s/\f/\\f/g;

	# Replace NUL bytes with \0 — valid only in
	# double-quoted string context in generated code
	$s =~ s/\0/\\0/g;

	return $s;
}

# --------------------------------------------------
# perl_quote
#
# Purpose:    Convert a Perl value into a source-code
#             fragment that reproduces that value when
#             evaluated in a generated test file.
#
# Entry:      $v - the value to quote. May be undef,
#             a scalar, an arrayref, a Regexp, or any
#             other reference type.
#
# Exit:       Returns a string of Perl source code.
#             Undef produces the literal 'undef'.
#             Numbers are returned unquoted.
#             Strings are returned single-quoted via
#             perl_sq(). Arrays are recursively quoted.
#             Regexps are rendered as qr{...}.
#             Other refs fall through to render_fallback.
#
# Side effects: None.
#
# Notes:      The boolean string literals 'true' and
#             'false' are converted to Perl boolean
#             constants !!1 and !!0 respectively so
#             that YAML boolean values round-trip
#             correctly into generated tests.
# --------------------------------------------------
sub perl_quote {
	my $v = $_[0];

	# Undef produces the Perl literal 'undef'
	return 'undef' unless defined $v;

	# Convert YAML boolean string literals to Perl
	# boolean constants so they survive round-tripping
	return '!!1' if $v eq 'true';
	return '!!0' if $v eq 'false';

	if(ref($v)) {
		# Recursively quote each element of an arrayref
		if(ref($v) eq 'ARRAY') {
			my @quoted_v = map { perl_quote($_) } @{$v};
			return '[ ' . join(', ', @quoted_v) . ' ]';
		}

		# Render Regexp objects as qr{} with modifiers
		if(ref($v) eq 'Regexp') {
			my ($pat, $mods) = regexp_pattern($v);
			my $re = "qr{$pat}";

			# Append modifiers (e.g. 'i', 'x') if present
			$re .= $mods if $mods;
			return $re;
		}

		# Hashrefs and other reference types fall through
		# to render_fallback which uses Data::Dumper
		return render_fallback($v);
	}

	# Numeric values are emitted unquoted so the generated
	# test performs numeric rather than string comparison
	return looks_like_number($v) ? $v : "'" . perl_sq($v) . "'";
}

# --------------------------------------------------
# _generate_transform_properties
#
# Convert a hashref of transform
#     specifications into an arrayref of
#     LectroTest property definition hashrefs,
#     one per transform. Each hashref contains
#     all the information needed by
#     _render_properties to emit a runnable
#     Test::LectroTest property block.
#
# Entry:      $transforms  - hashref of transform name
#                            => transform spec, as
#                            loaded from the schema.
#             $function    - name of the function under
#                            test.
#             $module      - module name, or undef for
#                            builtin functions.
#             $input       - the top-level input spec
#                            hashref from the schema
#                            (used for position sorting).
#             $config      - the normalised config
#                            hashref, used to read
#                            properties.trials.
#             $new         - defined if the function is
#                            an object method; the value
#                            is not used here since
#                            property tests always
#                            construct a fresh object
#                            via new_ok() with no args.
#                            Presence vs absence is the
#                            only signal used.
#
# Exit:       Returns an arrayref of property hashrefs.
#             Returns an empty arrayref if no transforms
#             produce any testable properties.
#             Never returns undef.
#
# Side effects: None. Does not modify any argument.
#
# Notes:      Transforms whose input is the string
#             'undef' or whose input spec is not a
#             hashref are silently skipped — they
#             represent error-case transforms that have
#             no meaningful generator.
#
#             The 'WARN' vs 'WARNS' distinction in
#             _STATUS: the schema convention uses
#             'WARNS' throughout. This function checks
#             for 'WARNS' to match that convention.
# --------------------------------------------------
sub _generate_transform_properties {
	my ($transforms, $function, $module, $input, $config, $new) = @_;

	my @properties;

	for my $transform_name (sort keys %{$transforms}) {
		my $transform   = $transforms->{$transform_name};

		my $input_spec  = $transform->{input};

		# Guard: skip transforms with no input or with the
		# YAML scalar 'undef' as their input — these have no
		# generator and cannot produce meaningful properties
		if(!defined($input_spec) ||
		   (!ref($input_spec) && $input_spec eq 'undef')) {
			next;
		}

		# Guard: skip transforms whose input is not a hashref —
		# must come before the helper calls below so we never
		# pass a non-hash to _detect_transform_properties or
		# _process_custom_properties
		next unless ref($input_spec) eq 'HASH';

		# Default output spec to empty hash so _STATUS lookups
		# below are always safe regardless of schema content
		my $output_spec = $transform->{output} // {};

		# Detect automatic properties from the transform spec
		# (range constraints, type preservation, definedness)
		my @detected_props = _detect_transform_properties(
			$transform_name,
			$input_spec,
			$output_spec
		);

		# Process any custom properties defined in the schema
		my @custom_props = ();
		if(exists($transform->{properties}) &&
		   ref($transform->{properties}) eq 'ARRAY') {
			@custom_props = _process_custom_properties(
				$transform->{properties},
				$function,
				$module,
				$input_spec,
				$output_spec,
				$new
			);
		}

		# Combine auto-detected and custom properties into one list
		my @all_props = (@detected_props, @custom_props);

		# Skip this transform if no properties were produced —
		# nothing useful to render into the generated test
		next unless @all_props;

		# Build the LectroTest generator specification string,
		# one entry per input field that has a generator
		my @generators;
		my @var_names;

		for my $field (sort keys %{$input_spec}) {
			my $spec = $input_spec->{$field};

			# Skip non-hashref field specs — scalar types
			# like 'string' have no generator sub-structure
			next unless ref($spec) eq 'HASH';

			my $gen = _schema_to_lectrotest_generator($field, $spec);
			if(defined($gen) && length($gen)) {
				push @generators, $gen;
				push @var_names, $field;
			}
		}

		my $gen_spec = join(', ', @generators);

		# Build the call expression for the function under test.
		# Note: property tests always construct a fresh object
		# via new_ok() with no constructor arguments, regardless
		# of what $new holds in the caller — the intent here is
		# to test the method in isolation, not with specific
		# construction state.
		my $call_code;
		if($module && defined($new)) {
			# OO mode — construct a fresh object for each trial
			$call_code  = "my \$obj = new_ok('$module');";
			$call_code .= "\$obj->$function";
		} elsif($module && $module ne $MODULE_BUILTIN) {
			# Functional mode with a named module
			$call_code = "$module\::$function";
		} else {
			# Builtin or unqualified function call
			$call_code = $function;
		}

		# Build the argument list, respecting positional order
		# if the input spec declares positions
		my @args;
		if(_has_positions($input_spec)) {
			# Sort fields by declared position so the generated
			# call passes arguments in the correct order
			my @sorted = sort {
				$input_spec->{$a}{position} <=>
				$input_spec->{$b}{position}
			} keys %{$input_spec};
			@args = map { "\$$_" } @sorted;
		} else {
			# No positions — use alphabetical order from @var_names
			@args = map { "\$$_" } @var_names;
		}

		my $args_str = join(', ', @args);

		# Concatenate all property check expressions with &&
		# so the generated property block passes only when
		# every check holds
		my @checks = map { $_->{code} } @all_props;
		my $property_checks = join(" &&\n\t", @checks);

		# Determine expected behaviour from output _STATUS.
		# Note: the schema convention uses 'WARNS' not 'WARN'
		my $should_die  = ($output_spec->{'_STATUS'} // '') eq 'DIES';
		my $should_warn = ($output_spec->{'_STATUS'} // '') eq 'WARNS';

		push @properties, {
			name             => $transform_name,
			generator_spec   => $gen_spec,
			call_code        => "$call_code($args_str)",
			property_checks  => $property_checks,
			should_die       => $should_die,
			should_warn      => $should_warn,
			trials           => $config->{'properties'}{'trials'} // DEFAULT_PROPERTY_TRIALS,
		};
	}

	return \@properties;
}

# --------------------------------------------------
# _get_semantic_generators
#
# Return a hashref of named semantic
#     generator definitions for use in
#     LectroTest property-based tests.
#     Each entry contains a 'code' key
#     holding a Gen {} block string and a
#     'description' key for documentation
#     and validation messages.
#
# Entry:      None.
#
# Exit:       Returns a hashref keyed by semantic
#             type name. Each value is a hashref
#             with 'code' and 'description' keys.
#
# Side effects: None.
#
# Notes:      The returned hashref is built fresh
#             on every call — callers that need it
#             repeatedly should cache the result.
#             The 'code' strings are multi-line
#             Gen {} blocks; callers are responsible
#             for compressing whitespace before
#             embedding them in generated test files.
# --------------------------------------------------
sub _get_semantic_generators {
	return {
		email => {
			code => q{
				Gen {
					my $len = 5 + int(rand(10));
					my @addr;
					my @tlds = qw(com org net edu gov io co uk de fr);

					for(my $i = 0; $i < $len; $i++) {
						push @addr, pack('c', (int(rand 26))+97);
					}
					push @addr, '@';
					$len = 5 + int(rand(10));
					for(my $i = 0; $i < $len; $i++) {
						push @addr, pack('c', (int(rand 26))+97);
					}
					push @addr, '.';
					$len = rand($#tlds+1);
					push @addr, $tlds[$len];
					return join('', @addr);
				}
			},
			description => 'Valid email addresses',
		},

		url => {
			code => q{
				Gen {
					my @schemes = qw(http https);
					my @tlds = qw(com org net io);
					my $scheme = $schemes[int(rand(@schemes))];
					my $domain = join('', map { ('a'..'z')[int(rand(26))] } 1..(5 + int(rand(10))));
					my $tld = $tlds[int(rand(@tlds))];
					my $path = join('', map { ('a'..'z', '0'..'9', '-', '_')[int(rand(38))] } 1..int(rand(20)));

					return "$scheme://$domain.$tld" . ($path ? "/$path" : '');
				}
			},
			description => 'Valid HTTP/HTTPS URLs',
		},

		uuid => {
			code => q{
				Gen {
					require UUID::Tiny;
					UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_V4());
				}
			},
			description => 'Valid UUIDv4 identifiers',
		},

		phone_us => {
			code => q{
				Gen {
					my $area = 200 + int(rand(800));
					my $exchange = 200 + int(rand(800));
					my $subscriber = int(rand(10000));
					sprintf('%03d-%03d-%04d', $area, $exchange, $subscriber);
				}
			},
			description => 'US phone numbers (XXX-XXX-XXXX format)',
		},

		phone_e164 => {
			code => q{
				Gen {
					my $country = 1 + int(rand(999));
					my $area = 100 + int(rand(900));
					my $number = int(rand(10000000));
					sprintf('+%d%03d%07d', $country, $area, $number);
				}
			},
			description => 'E.164 international phone numbers',
		},

		ipv4 => {
			code => q{
				Gen {
					join('.', map { int(rand(256)) } 1..4);
				}
			},
			description => 'IPv4 addresses',
		},

		ipv6 => {
			code => q{
				Gen {
					join(':', map { sprintf('%04x', int(rand(0x10000))) } 1..8);
				}
			},
			description => 'IPv6 addresses',
		},

		username => {
			code => q{
				Gen {
					my $len = 3 + int(rand(13));
					my @chars = ('a'..'z', '0'..'9', '_', '-');
					my $first = ('a'..'z')[int(rand(26))];
					$first . join('', map { $chars[int(rand(@chars))] } 1..($len-1));
				}
			},
			description => 'Valid usernames (alphanumeric with _ and -)',
		},

		slug => {
			code => q{
				Gen {
					my @words = qw(quick brown fox jumps over lazy dog hello world test data);
					my $count = 1 + int(rand(4));
					join('-', map { $words[int(rand(@words))] } 1..$count);
				}
			},
			description => 'URL slugs (lowercase words separated by hyphens)',
		},

		hex_color => {
			code => q{
				Gen {
					sprintf('#%06x', int(rand(0x1000000)));
				}
			},
			description => 'Hex color codes (#RRGGBB)',
		},

		iso_date => {
			code => q{
				Gen {
					my $year = 2000 + int(rand(25));
					my $month = 1 + int(rand(12));
					my $day = 1 + int(rand(28));
					sprintf('%04d-%02d-%02d', $year, $month, $day);
				}
			},
			description => 'ISO 8601 date format (YYYY-MM-DD)',
		},

		iso_datetime => {
			code => q{
				Gen {
					my $year = 2000 + int(rand(25));
					my $month = 1 + int(rand(12));
					my $day = 1 + int(rand(28));
					my $hour = int(rand(24));
					my $minute = int(rand(60));
					my $second = int(rand(60));
					sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ',
						$year, $month, $day, $hour, $minute, $second);
				}
			},
			description => 'ISO 8601 datetime format (YYYY-MM-DDTHH:MM:SSZ)',
		},

		semver => {
			code => q{
				Gen {
					my $major = int(rand(10));
					my $minor = int(rand(20));
					my $patch = int(rand(50));
					"$major.$minor.$patch";
				}
			},
			description => 'Semantic version strings (major.minor.patch)',
		},

		jwt => {
			code => q{
				Gen {
					my @chars = ('A'..'Z', 'a'..'z', '0'..'9', '-', '_');
					my $header    = join('', map { $chars[int(rand(@chars))] } 1..20);
					my $payload   = join('', map { $chars[int(rand(@chars))] } 1..40);
					my $signature = join('', map { $chars[int(rand(@chars))] } 1..30);
					"$header.$payload.$signature";
				}
			},
			description => 'JWT-like tokens (base64url format)',
		},

		json => {
			code => q{
				Gen {
					my @keys = qw(id name value status count);
					my $key = $keys[int(rand(@keys))];
					my $value = 1 + int(rand(1000));
					qq({"$key":$value});
				}
			},
			description => 'Simple JSON objects',
		},

		base64 => {
			code => q{
				Gen {
					my @chars = ('A'..'Z', 'a'..'z', '0'..'9', '+', '/');
					my $len = 12 + int(rand(20));
					my $str = join('', map { $chars[int(rand(@chars))] } 1..$len);
					$str .= '=' x (4 - ($len % 4)) if $len % 4;
					$str;
				}
			},
			description => 'Base64-encoded strings',
		},

		md5 => {
			code => q{
				Gen {
					join('', map { sprintf('%x', int(rand(16))) } 1..32);
				}
			},
			description => 'MD5 hashes (32 hex characters)',
		},

		sha256 => {
			code => q{
				Gen {
					join('', map { sprintf('%x', int(rand(16))) } 1..64);
				}
			},
			description => 'SHA-256 hashes (64 hex characters)',
		},

		unix_timestamp => {
			code => q{
				Gen {
					time;
				}
			},
			description => 'Unix timestamps (seconds since epoch)',
		},
	};
}

# --------------------------------------------------
# _get_builtin_properties
#
# Purpose:    Return a hashref of named built-in
#             property templates that can be
#             referenced by name in a transform's
#             'properties' list in the schema.
#             Each entry contains a 'description'
#             string, a 'code_template' coderef, and
#             an 'applicable_to' arrayref.
#
# Entry:      None.
#
# Exit:       Returns a hashref keyed by property
#             name. Each value is a hashref with
#             'description', 'code_template', and
#             'applicable_to' keys.
#
# Side effects: None.
#
# Notes:      'applicable_to' lists the types for
#             which each property is meaningful. It
#             is stored for documentation purposes
#             and potential future filtering — it is
#             not currently enforced by any caller.
#
#             Each 'code_template' coderef receives
#             three arguments: ($function, $call_code,
#             $input_vars). Most templates use only
#             $call_code; $function and $input_vars
#             are provided for templates that need
#             them (e.g. idempotent, length_preserved,
#             preserves_keys).
#
#             'monotonic_increasing' has been
#             intentionally omitted. A correct
#             implementation requires calling the
#             function twice with ordered inputs,
#             which the current single-call property
#             framework does not support. A
#             placeholder that unconditionally returns
#             true would give false confidence and has
#             therefore been removed.
# --------------------------------------------------
sub _get_builtin_properties {
	return {
		idempotent => {
			description   => 'Function is idempotent: f(f(x)) == f(x)',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;

				# String comparison works for all scalar types in Perl —
				# numeric values stringify consistently for eq
				return "do { my \$tmp = $call_code; \$result eq \$tmp }";
			},
			applicable_to => ['all'],
		},

		non_negative => {
			description   => 'Result is always non-negative',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result >= 0';
			},
			applicable_to => ['number', 'integer', 'float'],
		},

		positive => {
			description   => 'Result is always positive (> 0)',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result > 0';
			},
			applicable_to => ['number', 'integer', 'float'],
		},

		non_empty => {
			description   => 'Result is never empty',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return 'length($result) > 0';
			},
			applicable_to => ['string'],
		},

		length_preserved => {
			description   => 'Output length equals input length',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				my $first_var = $input_vars->[0];
				return "length(\$result) == length(\$$first_var)";
			},
			applicable_to => ['string'],
		},

		uppercase => {
			description   => 'Result is all uppercase',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result eq uc($result)';
			},
			applicable_to => ['string'],
		},

		lowercase => {
			description   => 'Result is all lowercase',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result eq lc($result)';
			},
			applicable_to => ['string'],
		},

		trimmed => {
			description   => 'Result has no leading or trailing whitespace',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result !~ /^\s/ && $result !~ /\s$/';
			},
			applicable_to => ['string'],
		},

		sorted_ascending => {
			description   => 'Array is sorted in ascending order',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return 'do { my @arr = @$result; my $sorted = 1; ' .
					'for my $i (1..$#arr) { $sorted = 0 if $arr[$i] < $arr[$i-1]; } ' .
					'$sorted }';
			},
			applicable_to => ['arrayref'],
		},

		sorted_descending => {
			description   => 'Array is sorted in descending order',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return 'do { my @arr = @$result; my $sorted = 1; ' .
					'for my $i (1..$#arr) { $sorted = 0 if $arr[$i] > $arr[$i-1]; } ' .
					'$sorted }';
			},
			applicable_to => ['arrayref'],
		},

		unique_elements => {
			description   => 'Array has no duplicate elements',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return 'do { my @arr = @$result; my %seen; !grep { $seen{$_}++ } @arr }';
			},
			applicable_to => ['arrayref'],
		},

		preserves_keys => {
			description   => 'Hash has same keys as input',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				my $first_var = $input_vars->[0];
				return 'do { my @in  = sort keys %{$' . $first_var . '}; ' .
					'my @out = sort keys %$result; ' .
					'join(",", @in) eq join(",", @out) }';
			},
			applicable_to => ['hashref'],
		},
	};
}

# --------------------------------------------------
# _schema_to_lectrotest_generator
#
# Purpose:    Convert a single schema field spec
#             hashref into a LectroTest generator
#             declaration string of the form
#             '$field <- Generator(...)'.
#             Used to build the ##[ ... ]## generator
#             block inside a Property definition.
#
# Entry:      $field_name - the parameter name as it
#                           will appear in the
#                           generated test code.
#             $spec       - hashref containing at
#                           minimum a 'type' key.
#                           May also contain 'min',
#                           'max', 'semantic', and
#                           'matches' keys depending
#                           on type.
#
# Exit:       Returns a string of the form
#             '$field <- Generator(...)' on success.
#             Returns undef if the spec is not a
#             hashref or if range constraints are
#             invalid (min >= max for numeric types).
#             Returns a String generator with a carp
#             warning for unknown types.
#
# Side effects: Carps on unknown semantic types,
#               invalid numeric ranges, and unknown
#               field types.
#
# Notes:      Semantic generators are checked first
#             for string fields and take precedence
#             over the regular string generator.
#             The $input_spec parameter in the type-
#             detection helpers is reserved for future
#             use and is currently unused.
# --------------------------------------------------
sub _schema_to_lectrotest_generator {
	my ($field_name, $spec) = @_;

	# Guard: must be a hashref to dereference safely
	return unless defined($spec) && ref($spec) eq 'HASH';

	# Default to string when no type is declared
	my $type = $spec->{'type'} || $DEFAULT_FIELD_TYPE;

	# --------------------------------------------------
	# Semantic generators take precedence for string
	# fields — they produce realistic domain-specific
	# values rather than random character sequences
	# --------------------------------------------------
	if($type eq 'string' && defined($spec->{'semantic'})) {
		my $semantic_type = $spec->{'semantic'};
		my $generators    = _get_semantic_generators();

		if(exists($generators->{$semantic_type})) {
			my $gen_code = $generators->{$semantic_type}{'code'};

			# Compress the multi-line generator code into a
			# single line for embedding in the ##[ ]## block
			$gen_code =~ s/^\s+//;
			$gen_code =~ s/\s+$//;
			$gen_code =~ s/\n\s+/ /g;

			return "$field_name <- $gen_code";
		} else {
			carp "Unknown semantic type '$semantic_type', " .
				"falling back to regular string generator";
			# Fall through to regular string generation below
		}
	}

	# --------------------------------------------------
	# Integer generator
	# --------------------------------------------------
	if($type eq 'integer') {
		my $min = $spec->{'min'};
		my $max = $spec->{'max'};

		if(!defined($min) && !defined($max)) {
			# Unconstrained — use LectroTest's built-in Int
			return "$field_name <- Int";
		} elsif(!defined($min)) {
			# Only max defined — generate 0 to max
			return "$field_name <- Int(sized => sub { int(rand($max + 1)) })";
		} elsif(!defined($max)) {
			# Only min defined — generate min to min + range
			return "$field_name <- Int(sized => sub { $min + int(rand($DEFAULT_GENERATOR_RANGE)) })";
		} else {
			# Both defined — generate within [min, max]
			my $range = $max - $min;
			return "$field_name <- Int(sized => sub { $min + int(rand($range + 1)) })";
		}
	}

	# --------------------------------------------------
	# Float / number generator
	# --------------------------------------------------
	if($type eq 'number' || $type eq 'float') {
		my $min = $spec->{'min'};
		my $max = $spec->{'max'};

		if(!defined($min) && !defined($max)) {
			# Unconstrained — symmetric range around zero
			return "$field_name <- Float(sized => sub { rand($DEFAULT_GENERATOR_RANGE) - $DEFAULT_GENERATOR_RANGE / 2 })";

		} elsif(!defined($min)) {
			# Only max defined — choose range based on sign of max
			if($max == $ZERO_BOUNDARY) {
				# max=0: negative numbers only
				return "$field_name <- Float(sized => sub { -rand($DEFAULT_GENERATOR_RANGE) })";
			} elsif($max > $ZERO_BOUNDARY) {
				# Positive max: generate 0 to max
				return "$field_name <- Float(sized => sub { rand($max) })";
			} else {
				# Negative max: generate from (max - range) to max
				return "$field_name <- Float(sized => sub { ($max - $DEFAULT_GENERATOR_RANGE) + rand($DEFAULT_GENERATOR_RANGE + $max) })";
			}

		} elsif(!defined($max)) {
			# Only min defined — choose range based on sign of min
			if($min == $ZERO_BOUNDARY) {
				# min=0: positive numbers only
				return "$field_name <- Float(sized => sub { rand($DEFAULT_GENERATOR_RANGE) })";
			} elsif($min > $ZERO_BOUNDARY) {
				# Positive min: generate min to min + range
				return "$field_name <- Float(sized => sub { $min + rand($DEFAULT_GENERATOR_RANGE) })";
			} else {
				# Negative min: generate from min to min + range
				return "$field_name <- Float(sized => sub { $min + rand(-$min + $DEFAULT_GENERATOR_RANGE) })";
			}

		} else {
			# Both min and max defined — validate then generate
			my $range = $max - $min;
			if($range <= $ZERO_BOUNDARY) {
				carp "Invalid range for '$field_name': min=$min, max=$max";
				# Return undef rather than emitting a degenerate
				# generator that would silently produce wrong values
				return;
			}
			return "$field_name <- Float(sized => sub { $min + rand($range) })";
		}
	}

	# --------------------------------------------------
	# String generator
	# --------------------------------------------------
	if($type eq 'string') {
		my $min_len = $spec->{'min'} // 0;
		my $max_len = $spec->{'max'} // $DEFAULT_MAX_STRING_LEN;

		# If a regex pattern is declared, delegate to
		# Data::Random::String::Matches for pattern-aware generation
		if(defined($spec->{'matches'})) {
			my $pattern = $spec->{'matches'};

			if(defined($spec->{'max'})) {
				return "$field_name <- Gen { Data::Random::String::Matches->create_random_string({ regex => qr/$pattern/, length => $spec->{'max'} }) }";
			} elsif(defined($spec->{'min'})) {
				return "$field_name <- Gen { Data::Random::String::Matches->create_random_string({ regex => qr/$pattern/, length => $spec->{'min'} }) }";
			} else {
				return "$field_name <- Gen { Data::Random::String::Matches->create_random_string({ regex => qr/$pattern/ }) }";
			}
		}

		return "$field_name <- String(length => [$min_len, $max_len])";
	}

	# --------------------------------------------------
	# Boolean generator
	# --------------------------------------------------
	if($type eq 'boolean') {
		return "$field_name <- Bool";
	}

	# --------------------------------------------------
	# Arrayref generator
	# --------------------------------------------------
	if($type eq 'arrayref') {
		my $min_size = $spec->{'min'} // 0;
		my $max_size = $spec->{'max'} // $DEFAULT_MAX_COLLECTION_SIZE;
		return "$field_name <- List(Int, length => [$min_size, $max_size])";
	}

	# --------------------------------------------------
	# Hashref generator
	# LectroTest has no built-in Hash generator so we
	# use Elements over a pre-built list of hashrefs
	# --------------------------------------------------
	if($type eq 'hashref') {
		my $min_keys = $spec->{'min'} // 0;
		my $max_keys = $spec->{'max'} // $DEFAULT_MAX_COLLECTION_SIZE;
		return "$field_name <- Elements(map { my \%h; for (1..\$_) { \$h{'key'.\$_} = \$_ }; \\\%h } $min_keys..$max_keys)";
	}

	# --------------------------------------------------
	# Unknown type — fall back to String with a warning
	# --------------------------------------------------
	carp "Unknown type '$type' for '$field_name' LectroTest generator, using String";
	return "$field_name <- String";
}

# --------------------------------------------------
# _is_numeric_transform
#
# Determine whether a transform's output
#     spec declares a numeric type, indicating
#     that numeric range properties should be
#     generated for it.
#
# Entry:      $input_spec  - the transform's input
#                            spec hashref. Currently
#                            unused; reserved for
#                            future input-type checks.
#             $output_spec - the transform's output
#                            spec hashref.
#
# Exit:       Returns 1 if the output type is one of
#             'number', 'integer', or 'float'.
#             Returns 0 otherwise.
#
# Side effects: None.
# --------------------------------------------------
sub _is_numeric_transform {
	my ($input_spec, $output_spec) = @_;

	# $input_spec is currently unused — reserved for future
	# input-side type checking when detecting mixed transforms
	my $out_type = ($output_spec // {})->{'type'} // '';

	return($out_type eq 'number' || $out_type eq 'integer' || $out_type eq 'float');
}

# --------------------------------------------------
# _is_string_transform
#
# Purpose:    Determine whether a transform's output
#             spec declares a string type, indicating
#             that string length and pattern properties
#             should be generated for it.
#
# Entry:      $input_spec  - the transform's input
#                            spec hashref. Currently
#                            unused; reserved for
#                            future input-type checks.
#             $output_spec - the transform's output
#                            spec hashref.
#
# Exit:       Returns 1 if the output type is 'string'.
#             Returns 0 otherwise.
#
# Side effects: None.
# --------------------------------------------------
sub _is_string_transform {
	my ($input_spec, $output_spec) = @_;

	# $input_spec is currently unused — reserved for future
	# input-side type checking when detecting mixed transforms
	my $out_type = ($output_spec // {})->{'type'} // '';

	return($out_type eq 'string');
}

# --------------------------------------------------
# _same_type
#
# Purpose:    Determine whether the dominant type of
#             a transform's input and output specs
#             match, indicating that type-preservation
#             properties are meaningful.
#
# Entry:      $input_spec  - the transform's input
#                            spec hashref, or a nested
#                            multi-field hashref.
#             $output_spec - the transform's output
#                            spec hashref.
#
# Exit:       Returns 1 if the dominant input and
#             output types are identical strings.
#             Returns 0 otherwise.
#
# Side effects: None.
#
# Notes:      Uses _get_dominant_type for both sides.
#             For multi-field input specs, dominant
#             type is the type of the first field
#             encountered — this is a simplification.
#             TODO: extend to handle mixed-type inputs
#             by checking all fields, not just the
#             first one found.
# --------------------------------------------------
sub _same_type {
	my ($input_spec, $output_spec) = @_;

	# Guard: treat missing specs as untyped — two untyped
	# specs both default to $DEFAULT_FIELD_TYPE and would
	# compare equal, which is intentionally conservative
	my $in_type  = _get_dominant_type($input_spec  // {});
	my $out_type = _get_dominant_type($output_spec // {});

	return($in_type eq $out_type);
}

# --------------------------------------------------
# _get_dominant_type
#
# Purpose:    Extract the most representative type
#             string from a spec hashref. For flat
#             output specs this is simply the 'type'
#             key. For multi-field input specs it is
#             the type of the first sub-field found
#             that declares one.
#
# Entry:      $spec - a spec hashref. May be a flat
#                     output spec ({ type => '...' })
#                     or a multi-field input spec
#                     ({ field => { type => '...' } }).
#                     May be undef or empty.
#
# Exit:       Returns a type string. Returns
#             $DEFAULT_FIELD_TYPE ('string') if no
#             type can be determined.
#
# Side effects: None.
# --------------------------------------------------
sub _get_dominant_type {
	my $spec = $_[0];

	# Guard: return default for undef or non-hash input
	return $DEFAULT_FIELD_TYPE
		unless defined($spec) && ref($spec) eq 'HASH';

	# Flat spec — type declared directly
	return $spec->{'type'} if defined($spec->{'type'});

	# Multi-field spec — return the type of the first
	# sub-field that declares one
	for my $field (keys %{$spec}) {
		next unless ref($spec->{$field}) eq 'HASH';
		return $spec->{$field}{'type'}
			if defined($spec->{$field}{'type'});
	}

	# No type found anywhere — return the safe default
	return $DEFAULT_FIELD_TYPE;
}

# --------------------------------------------------
# _render_properties
#
# Purpose:    Render an arrayref of property definition
#             hashrefs (as produced by
#             _generate_transform_properties) into a
#             string of Perl source code suitable for
#             embedding in a generated test file.
#             The output uses Test::LectroTest::Compat
#             to run each property as a holds() check.
#
# Entry:      $properties - arrayref of property
#             hashrefs, each containing: name,
#             generator_spec, call_code,
#             property_checks, should_die,
#             should_warn, trials.
#             May be undef or an empty arrayref.
#
# Exit:       Returns a string of Perl source code.
#             Returns an empty string if $properties
#             is undef, not an arrayref, or empty.
#
# Side effects: None.
#
# Notes:      The generated code uses 4-space
#             indentation deliberately — this is the
#             indentation style of the generated test
#             file, not of this module. Tabs are used
#             in this module's own source; spaces are
#             emitted into generated output for
#             readability of the produced test files.
# --------------------------------------------------
sub _render_properties {
	my $properties = $_[0];

	# Return empty string for absent or non-array input —
	# callers treat '' as no property block to emit
	return '' unless defined($properties) && ref($properties) eq 'ARRAY';
	return '' unless @{$properties};

	my $code = "use_ok('Test::LectroTest::Compat');\n\n";

	for my $prop (@{$properties}) {
		# Emit a labelled Property block for each transform property
		$code .= "# Transform property: $prop->{'name'}\n";
		$code .= "my \$$prop->{'name'} = Property {\n";
		$code .= "    ##[ $prop->{'generator_spec'} ]##\n";
		$code .= "    \n";
		$code .= "    my \$result = eval { $prop->{'call_code'} };\n";

		if($prop->{'should_die'}) {
			# For transforms that expect death, pass if the
			# eval caught an exception
			$code .= "    my \$died = defined(\$\@) && \$\@;\n";
			$code .= "    \$died;\n";
		} else {
			# For normal transforms, pass only if no exception
			# was thrown and all property checks hold
			$code .= "    my \$error = \$\@;\n";
			$code .= "    \n";
			$code .= "    !\$error && (\n";
			$code .= "        $prop->{'property_checks'}\n";
			$code .= "    );\n";
		}

		$code .= "}, name => '$prop->{'name'}', trials => $prop->{'trials'};\n\n";
		$code .= "holds(\$$prop->{'name'});\n";
	}

	return $code;
}

# --------------------------------------------------
# _detect_transform_properties
#
# Purpose:    Automatically derive a list of testable
#             LectroTest property hashrefs from a
#             transform's input and output specs.
#             Detects numeric range constraints, exact
#             value matches, string length constraints,
#             type preservation, and definedness.
#
# Entry:      $transform_name - string name of the
#                               transform, used for
#                               heuristic matching
#                               (e.g. 'positive').
#             $input_spec     - the transform's input
#                               hashref, or the string
#                               'undef'.
#             $output_spec    - the transform's output
#                               hashref, or undef if
#                               absent.
#
# Exit:       Returns a list of property hashrefs,
#             each containing 'name' and 'code' keys.
#             Returns an empty list if no properties
#             can be detected or if $input_spec is
#             undef or the string 'undef'.
#
# Side effects: None.
#
# Notes:      The 'positive' heuristic checks the
#             transform name case-insensitively against
#             $TRANSFORM_POSITIVE_PATTERN and adds a
#             non-negative constraint if matched.
#             This is intentionally a rough heuristic
#             rather than a precise semantic check.
# --------------------------------------------------
sub _detect_transform_properties {
	my ($transform_name, $input_spec, $output_spec) = @_;

	my @properties;

	# Guard: skip undef input and the YAML scalar 'undef'
	return @properties unless defined($input_spec);
	return @properties if(!ref($input_spec) && $input_spec eq 'undef');

	# Default output spec to empty hash so all key lookups
	# below are safe regardless of what the schema provides
	$output_spec //= {};

	# --------------------------------------------------
	# Property 1: Output range constraints (numeric)
	# --------------------------------------------------
	if(_is_numeric_transform($input_spec, $output_spec)) {
		if(defined($output_spec->{'min'})) {
			my $min = $output_spec->{'min'};
			push @properties, {
				name => 'min_constraint',
				code => "defined(\$result) && looks_like_number(\$result) && \$result >= $min",
			};
		}

		if(defined($output_spec->{'max'})) {
			my $max = $output_spec->{'max'};
			push @properties, {
				name => 'max_constraint',
				code => "defined(\$result) && looks_like_number(\$result) && \$result <= $max",
			};
		}

		# Heuristic: transforms named 'positive' (case-insensitive)
		# imply a non-negative result constraint
		if($transform_name =~ /$TRANSFORM_POSITIVE_PATTERN/i) {
			push @properties, {
				name => 'non_negative',
				code => "defined(\$result) && looks_like_number(\$result) && \$result >= 0",
			};
		}
	}

	# --------------------------------------------------
	# Property 2: Specific value output
	# --------------------------------------------------
	if(defined($output_spec->{'value'})) {
		my $expected = $output_spec->{'value'};

		# Numeric refs use == for comparison; scalars use eq
		# via perl_quote to produce the correct quoted literal
		push @properties, {
			name => 'exact_value',
			code => ref($expected)
				? "\$result == $expected"
				: "\$result eq " . perl_quote($expected),
		};
	}

	# --------------------------------------------------
	# Property 3: String length constraints
	# --------------------------------------------------
	if(_is_string_transform($input_spec, $output_spec)) {
		if(defined($output_spec->{'min'})) {
			push @properties, {
				name => 'min_length',
				code => "length(\$result) >= $output_spec->{'min'}",
			};
		}

		if(defined($output_spec->{'max'})) {
			push @properties, {
				name => 'max_length',
				code => "length(\$result) <= $output_spec->{'max'}",
			};
		}

		if(defined($output_spec->{'matches'})) {
			my $pattern = $output_spec->{'matches'};
			push @properties, {
				name => 'pattern_match',
				code => "\$result =~ qr/$pattern/",
			};
		}
	}

	# --------------------------------------------------
	# Property 4: Type preservation
	# --------------------------------------------------
	if(_same_type($input_spec, $output_spec)) {
		my $type = _get_dominant_type($output_spec);

		# Only emit a numeric_type check for numeric types —
		# string and other types have no equivalent simple check
		if($type eq 'number' || $type eq 'integer' || $type eq 'float') {
			push @properties, {
				name => 'numeric_type',
				code => 'looks_like_number($result)',
			};
		}
	}

	# --------------------------------------------------
	# Property 5: Definedness
	# --------------------------------------------------
	# Emit a defined() check for all transforms except those
	# whose output type is explicitly 'undef' — those are
	# expected to return nothing
	unless(($output_spec->{'type'} // '') eq 'undef') {
		push @properties, {
			name => 'defined',
			code => 'defined($result)',
		};
	}

	return @properties;
}

# --------------------------------------------------
# _process_custom_properties
#
# Purpose:    Process the 'properties' array from a
#             transform definition, resolving each
#             entry to either a named builtin property
#             (looked up from _get_builtin_properties)
#             or a custom property with inline code.
#
# Entry:      $properties_spec - arrayref of property
#                                definitions from the
#                                schema. Each element
#                                is either a string
#                                (builtin name) or a
#                                hashref with 'name'
#                                and 'code' fields.
#             $function        - name of the function
#                                under test.
#             $module          - module name, or undef
#                                for builtins.
#             $input_spec      - the transform's input
#                                spec hashref.
#             $output_spec     - the transform's output
#                                spec hashref.
#             $new             - defined if the function
#                                is an OO method; value
#                                is not used, only
#                                presence is checked.
#
# Exit:       Returns a list of property hashrefs,
#             each containing 'name', 'code', and
#             'description' keys.
#             Invalid or unrecognised entries are
#             skipped with a carp warning.
#
# Side effects: Carps on unrecognised builtin names,
#               missing code fields, and invalid
#               property definition types.
#
# Notes:      The sixth argument is $new (the OO
#             constructor signal), not the full schema
#             hashref. It is used only to determine
#             whether to emit OO-style call code for
#             builtin property templates.
# --------------------------------------------------
sub _process_custom_properties {
	my ($properties_spec, $function, $module, $input_spec, $output_spec, $new) = @_;

	my @properties;
	my $builtin_properties = _get_builtin_properties();

	for my $prop_def (@{$properties_spec}) {
		my $prop_name;
		my $prop_code;
		my $prop_desc;

		if(!ref($prop_def)) {
			# Plain string — look up as a named builtin property
			$prop_name = $prop_def;

			unless(exists($builtin_properties->{$prop_name})) {
				carp "Unknown built-in property '$prop_name', skipping";
				next;
			}

			my $builtin = $builtin_properties->{$prop_name};

			# Build the argument list, respecting positional order
			my @var_names = sort keys %{$input_spec};
			my @args;
			if(_has_positions($input_spec)) {
				my @sorted = sort { $input_spec->{$a}{'position'} <=> $input_spec->{$b}{'position'} } @var_names;
				@args = map { "\$$_" } @sorted;
			} else {
				@args = map { "\$$_" } @var_names;
			}

			# Build the call expression for the builtin template.
			# $new here is the raw OO signal from the caller —
			# defined means OO mode, undef means functional
			my $call_code;
			if($module && defined($new)) {
				# OO mode — fresh object per trial
				$call_code  = "my \$obj = new_ok('$module');";
				$call_code .= "\$obj->$function";
			} elsif($module && $module ne $MODULE_BUILTIN) {
				# Functional mode with a named module
				$call_code = "$module\::$function";
			} else {
				# Builtin or unqualified function call
				$call_code = $function;
			}
			$call_code .= '(' . join(', ', @args) . ')';

			# Instantiate the builtin's code template with the
			# call expression and input variable list
			$prop_code = $builtin->{'code_template'}->($function, $call_code, \@var_names);
			$prop_desc = $builtin->{'description'};

		} elsif(ref($prop_def) eq 'HASH') {
			# Hashref — custom property with inline Perl code
			$prop_name = $prop_def->{'name'} || 'custom_property';
			$prop_code = $prop_def->{'code'};
			$prop_desc = $prop_def->{'description'} || "Custom property: $prop_name";

			unless($prop_code) {
				carp "Custom property '$prop_name' missing 'code' field, skipping";
				next;
			}

			# Sanity-check: code must contain at least a variable
			# reference or a word character to be meaningful
			unless($prop_code =~ /\$/ || $prop_code =~ /\w+/) {
				carp "Custom property '$prop_name' code looks invalid: $prop_code";
				next;
			}

		} else {
			# Neither string nor hashref — unrecognised definition type
			carp 'Invalid property definition: ', render_fallback($prop_def);
			next;
		}

		push @properties, {
			name        => $prop_name,
			code        => $prop_code,
			description => $prop_desc,
		};
	}

	return @properties;
}

=head1 NOTES

C<seed> and C<iterations> really should be within C<config>.

=head1 SEE ALSO

=over 4

=item * L<Test Coverage Report|https://nigelhorne.github.io/App-Test-Generator/coverage/>

=item * L<App::Test::Generator::Template> - Template of the file of tests created by C<App::Test::Generator>

=item * L<App::Test::Generator::SchemaExtractor> - Create schemas from Perl programs

=item * L<Params::Validate::Strict>: Schema Definition

=item * L<Params::Get>: Input validation

=item * L<Return::Set>: Output validation

=item * L<Test::LectroTest>

=item * L<Test::Most>

=item * L<YAML::XS>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created with the
assistance of AI.

=head1 SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc App::Test::Generator

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/App-Test-Generator>

=item * GitHub

L<https://github.com/nigelhorne/App-Test-Generator>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/App-Test-Generator>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=App-Test-Generator>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=App::Test::Generator>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

1;
