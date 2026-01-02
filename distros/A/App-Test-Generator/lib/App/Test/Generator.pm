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
use Params::Validate::Strict;
use Scalar::Util qw(looks_like_number);
use Template;
use YAML::XS qw(LoadFile);

use Exporter 'import';

our @EXPORT_OK = qw(generate);

our $VERSION = '0.25';

use constant {
	DEFAULT_ITERATIONS => 50,
	DEFAULT_PROPERTY_TRIALS => 1000
};

use constant CONFIG_TYPES => ('test_nuls', 'test_undef', 'test_empty', 'test_non_ascii', 'dedup', 'properties');

=head1 NAME

App::Test::Generator - Generate fuzz and corpus-driven test harnesses from test schemas

=head1 VERSION

Version 0.25

=head1 SYNOPSIS

From the command line:

  # Takes the formal definition of a routine, creates tests against that routine, and runs the test
  fuzz-harness-generator -r t/conf/add.yml

  # Attempt to create a formal definition from a routine package, then run tests against that formal definition
  # This is the holy grail of automatic test generation, just by looking at the source code
  extract-schemas bin/extract-schemas lib/Sample/Module.pm && fuzz-harness-generator -r schemas/greet.yaml

From Perl:

  use App::Test::Generator qw(generate);

  # Generate to STDOUT
  App::Test::Generator::generate("t/conf/add.yml");

  # Generate directly to a file
  App::Test::Generator::generate('t/conf/add.yml', 't/add_fuzz.t');

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

=item * C<test_nuls>, inject NUL bytes into strings (default: 1)

With this test enabled, the function is expected to die when a NUL byte is passed in.

=item * C<test_undef>, test with undefined value (default: 1)

=item * C<test_empty>, test with empty strings (default: 1)

=item * C<test_non_ascii>, test with strings that contain non ascii characters (default: 1)

=item * C<dedup>, fuzzing can create duplicate tests, go some way to remove duplicates (default: 1)

=item * C<properties>, enable L<Test::LectroTest> Property tests (default: 0)

=back

All values default to C<true>.

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

An optional integer controlling how many fuzz iterations to perform (default 50).

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
  iterations: 50

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

=item * Random fuzzing with 50 iterations (or as configured)

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

  generate($schema_file, $test_file)

Takes a schema file and produces a test file (or STDOUT).

=cut

sub generate
{
	if($_[0] && ($_[0] eq __PACKAGE__)) {
		shift;
	}

	my $args = $_[0];

	my ($schema_file, $test_file, $schema);
	# Globals loaded from the user's conf (all optional except function maybe)
	my (%input, %output, %config, $module, $function, $new, %cases, $yaml_cases, %transforms);
	my ($seed, $iterations);
	my (%edge_cases, @edge_case_array, %type_edge_cases);

	@edge_case_array = ();

	if(ref($args) || defined($_[2])) {
		# Modern API
		my $params = Params::Validate::Strict::validate_strict({
			args => Params::Get::get_params(undef, \@_),
			schema => {
				input_file => { type => 'string', optional => 1 },
				output_file => { type => 'string', optional => 1 },
				schema => { type => 'hashref', optional => 1 },
				quiet => { type => 'boolean', optional => 1 },	# Not yet used
			}
		});
		if($params->{'input_file'}) {
			$schema_file = $params->{'input_file'};
		} elsif($params->{'schema'}) {
			$schema = $params->{'schema'};
		} else {
			croak(__PACKAGE__, ': Usage: generate(input_file|schema [, output_file]');
		}
		$test_file = $params->{'output_file'};
	} else {
		# Legacy API
		($schema_file, $test_file) = ($_[0], $_[1]);
		if(defined($schema_file)) {
			$schema = _load_schema($schema_file);
			if(!defined($schema)) {
				croak "Failed to load schema from $schema_file";
			}
		} else {
			croak 'Usage: generate(schema_file [, outfile])';
		}
	}

	# Parse the schema file and load into our structures
	%input = %{_load_schema_section($schema, 'input', $schema_file)};
	%output = %{_load_schema_section($schema, 'output', $schema_file)};
	%transforms = %{_load_schema_section($schema, 'transforms', $schema_file)};

	%cases = %{$schema->{cases}} if(exists($schema->{cases}));
	%edge_cases = %{$schema->{edge_cases}} if(exists($schema->{edge_cases}));
	%type_edge_cases = %{$schema->{type_edge_cases}} if(exists($schema->{type_edge_cases}));

	$module = $schema->{module} if(exists($schema->{module}));
	$function = $schema->{function} if(exists($schema->{function}));
	if(exists($schema->{new})) {
		$new = defined($schema->{'new'}) ? $schema->{new} : '_UNDEF';
	}
	$yaml_cases = $schema->{yaml_cases} if(exists($schema->{yaml_cases}));
	$seed = $schema->{seed} if(exists($schema->{seed}));
	$iterations = $schema->{iterations} if(exists($schema->{iterations}));

	@edge_case_array = @{$schema->{edge_case_array}} if(exists($schema->{edge_case_array}));
	_validate_config($schema);

	%config = %{$schema->{config}} if(exists($schema->{config}));

	# Handle the various possible boolean settings for config values
	# Note that the default for everything is true
	foreach my $field (CONFIG_TYPES) {
		next if($field eq 'properties');	# Not a boolean
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
	if(!$module) {
		if($schema_file) {
			($module = basename($schema_file)) =~ s/\.(conf|pl|pm|yml|yaml)$//;
			$module =~ s/-/::/g;
		}
	} elsif($module eq 'builtin') {
		undef $module;
	}

	if($module && ($module ne 'builtin')) {
		_validate_module($module, $schema_file)
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

	# Dedup the edge cases
	my %seen;
	@edge_case_array = grep {
		my $key = defined($_) ? (Scalar::Util::looks_like_number($_) ? "N:$_" : "S:$_") : 'U';
		!$seen{$key}++;
	} @edge_case_array;

	# Sort the edge cases to keep it consitent across runs
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

	# $self->_log(
		# 'EDGE CASES: ' . join(', ',
			# map { defined($_) ? $_ : 'undef' } @edge_case_array
		# )
	# );

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

	# Setup / call code (always load module)
	my $setup_code = ($module) ? "BEGIN { use_ok('$module') }" : '';
	my $call_code;	# Code to call the function being test when used with named arguments
	my $position_code;	# Code to call the function being test when used with position arguments
	if(defined($new)) {
		# keep use_ok regardless (user found earlier issue)
		if($new_code eq '') {
			$setup_code .= "\nmy \$obj = new_ok('$module');";
		} else {
			$setup_code .= "\nmy \$obj = new_ok('$module' => [ { $new_code } ] );";
		}
		$call_code = "\$result = \$obj->$function(\$input);";
		if($output{'returns_self'}) {
			$call_code .= "ok(\$result eq \$obj, \"$function returns self\")";
		}
		$position_code = "(\$result = scalar(\@alist) == 1) ? \$obj->$function(\$alist[0]) : (scalar(\@alist) == 0) ? \$obj->$function() : \$obj->$function(\@alist);";
	} elsif(defined($module) && length($module)) {
		if($function eq 'new') {
			$call_code = "\$result = ${module}\->$function(\$input);";
			$position_code = "(\$result = scalar(\@alist) == 1) ? ${module}\->$function(\$alist[0]) : (scalar(\@alist) == 0) ? ${module}\->$function() : ${module}\->$function(\@alist);";
		} else {
			$call_code = "\$result = ${module}::$function(\$input);";
			$position_code = "(\$result = scalar(\@alist) == 1) ? ${module}::$function(\$alist[0]) : (scalar(\@alist) == 0) ? ${module}::$function() : ${module}::$function(\@alist);";
		}
	} else {
		$call_code = "\$result = $function(\$input);";
		$position_code = "\$result = $function(\@alist);";
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
			if(($input_str eq 'undef') && (!$config{'test_undefs'})) {
				carp('corpus case set to undef, yet test_undefs is not set in config');
			}
			if ($new) {
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
					if($output{'type'} eq 'boolean') {
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
					$corpus_code .= "dies_ok { $module\::$function($input_str) } " .
						"'Corpus $expected dies';\n";
				} elsif($status eq 'WARNS') {
					$corpus_code .= "warnings_exist { $module\::$function($input_str) } qr/./, " .
						"'Corpus $expected warns';\n";
				} else {
					my $desc = sprintf("$function(%s) returns %s",
						perl_quote((ref $inputs eq 'ARRAY') ? (join(', ', map { $_ // '' } @{$inputs})) : $inputs),
						$expected_str
					);
					if($output{'type'} eq 'boolean') {
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
		function => $function,
		iterations_code => int($iterations),
		use_properties => $use_properties,
		transform_properties_code => $transform_properties_code,
		property_trials => $config{properties}{trials} // DEFAULT_PROPERTY_TRIALS,
		module => $module
	};

	my $test;
	$tt->process($template, $vars, \$test) or die $tt->error();

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

# --- Helpers for rendering data structures into Perl code for the generated test ---

sub _load_schema {
	my $schema_file = $_[0];

	if(!-r $schema_file) {
		croak(__PACKAGE__, ": generate($schema_file): $!");
	}

	# --- Load configuration safely (require so config can use 'our' variables) ---
	# FIXME:  would be better to use Config::Abstraction, since requiring the user's config could execute arbitrary code
	# my $abs = $schema_file;
	# $abs = "./$abs" unless $abs =~ m{^/};
	# require $abs;

	if(my $config = Config::Abstraction->new(config_dirs => ['.', ''], config_file => $schema_file)) {
		$config = $config->all();
		if(defined($config->{'$module'}) || defined($config->{'our $module'}) || !defined($config->{'module'})) {
			croak("$schema_file: Loading perl files as configs is no longer supported");
		}
		return $config;
	}
}

sub _load_schema_section
{
	my($schema, $section, $schema_file) = @_;

	if(exists($schema->{$section})) {
		if(ref($schema->{$section}) eq 'HASH') {
			return $schema->{$section};
		} elsif(defined($schema->{$section}) && ($schema->{$section} ne 'undef')) {
			# carp(Dumper($schema));
			if(ref($schema->{$section}) && length($schema->{$section})) {
				croak("$schema_file: $section should be a hash, not ", ref($schema->{$section}));
			} else {
				croak("$schema_file: $section should be a hash, not ", $schema->{$section});
			}
		}
	}
	return {};
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
			croak "Invalid type '$spec->{type}' for parameter '$param'" unless _valid_type($spec->{type});
		} else {
			croak "Invalid type '$spec' for parameter '$param'" unless _valid_type($spec);
		}
	}

	# Check if using positional arguments
	my $has_positions = 0;
	my %positions;

	for my $param (keys %{$config->{input}}) {
		my $spec = $config->{input}{$param};
		if (ref($spec) eq 'HASH' && defined($spec->{position})) {
			$has_positions = 1;
			my $pos = $spec->{position};

			# Validate position is non-negative integer
			croak "Position for '$param' must be a non-negative integer" unless $pos =~ /^\d+$/;

			# Check for duplicate positions
			croak "Duplicate position $pos for parameters '$positions{$pos}' and '$param'" if exists $positions{$pos};

			$positions{$pos} = $param;
		}
	}

	# If using positions, all params must have positions
	if ($has_positions) {
		for my $param (keys %{$config->{input}}) {
			my $spec = $config->{input}{$param};
			unless (ref($spec) eq 'HASH' && defined($spec->{position})) {
				croak "Parameter '$param' missing position (all params must have positions if any do)";
			}
		}

		# Check for gaps in positions (0, 1, 3 - missing 2)
		my @sorted = sort { $a <=> $b } keys %positions;
		for my $i (0..$#sorted) {
			if ($sorted[$i] != $i) {
				carp "Warning: Position sequence has gaps (positions: @sorted)";
				last;
			}
		}
	}

	# Validate input types
	my $semantic_generators = _get_semantic_generators();
	for my $param (keys %{$config->{input}}) {
		my $spec = $config->{input}{$param};
		if(ref($spec) eq 'HASH') {
			if(defined($spec->{semantic})) {
				my $semantic = $spec->{semantic};
				unless (exists $semantic_generators->{$semantic}) {
					carp "Warning: Unknown semantic type '$semantic' for parameter '$param'. Available types: ",
						join(', ', sort keys %$semantic_generators);
				}
			}
			if($spec->{'enum'} && $spec->{'memberof'}) {
				croak "$param: has both enum and memberof";
			}
		}
	}

	# Validate custom properties in transforms
	if (exists $config->{transforms} && ref($config->{transforms}) eq 'HASH') {
		my $builtin_props = _get_builtin_properties();

		for my $transform_name (keys %{$config->{transforms}}) {
			my $transform = $config->{transforms}{$transform_name};

			if (exists $transform->{properties}) {
				unless (ref($transform->{properties}) eq 'ARRAY') {
					croak "Transform '$transform_name': properties must be an array";
				}

				for my $prop (@{$transform->{properties}}) {
					if (!ref($prop)) {
						# Check if builtin exists
						unless (exists $builtin_props->{$prop}) {
							carp "Transform '$transform_name': unknown built-in property '$prop'. Available: ",
								join(', ', sort keys %$builtin_props);
						}
					}
					elsif (ref($prop) eq 'HASH') {
						# Validate custom property structure
						unless ($prop->{name} && $prop->{code}) {
							croak "Transform '$transform_name': custom properties must have 'name' and 'code' fields";
						}
					}
					else {
						croak "Transform '$transform_name': invalid property definition";
					}
				}
			}
		}
	}

	# Validate the config variables, checking that they are ones we know
	foreach my ($k, $v) (%{$config->{'config'}}) {
		if(!grep { $_ eq $k } (CONFIG_TYPES) ) {
			croak "unknown config setting $k";
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
		($type eq 'hashref') ||
		($type eq 'arrayref') ||
		($type eq 'object'));
}

sub _validate_module {
	my ($module, $schema_file) = @_;

	return 1 unless $module;	# No module to validate (builtin functions)

	# Check if the module can be found
	my $mod_info = check_install(module => $module);

	if($schema_file && !$mod_info) {
		# Module not found - this is just a warning, not an error
		# The module might not be installed on the generation machine
		# but could be on the test machine
		carp("Warning: Module '$module' not found in \@INC during generation.");
		carp("  Config file: $schema_file");
		carp("  This is OK if the module will be available when tests run.");
		carp('  If this is unexpected, check your module name and installation.');
		return 0;	# Not found, but not fatal
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
			carp('  This might indicate a broken installation or missing dependencies.');
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
		my $def = $href->{$k} // {};
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
sub q_wrap
{
	my $s = $_[0];

	return "''" if(!defined($s));

	for my $p ( ['{','}'], ['(',')'], ['[',']'], ['<','>'] ) {
		my ($l, $r) = @$p;
		return "q$l$s$r" unless $s =~ /\Q$l\E|\Q$r\E/;
	}
	for my $d ('~', '!', '%', '^', '=', '+', ':', ',', ';', '|', '/', '#') {
		return "q$d$s$d" unless index($s, $d) >= 0;
	}
	(my $esc = $s) =~ s/'/\\'/g;
	return "'$esc'";
}

=head2 _generate_transform_properties

Converts transform specifications into LectroTest property definitions.

=cut

sub _generate_transform_properties {
	my ($transforms, $function, $module, $input, $config, $new) = @_;

	my @properties;

	for my $transform_name (sort keys %$transforms) {
		my $transform = $transforms->{$transform_name};

		my $input_spec = $transform->{input};
		my $output_spec = $transform->{output};

		# Skip if input is 'undef'
		if (!ref($input_spec) && $input_spec eq 'undef') {
			next;
		}

		# Detect automatic properties from the transform spec
		my @detected_props = _detect_transform_properties(
			$transform_name,
			$input_spec,
			$output_spec
		);

		# Process custom properties from schema
		my @custom_props = ();
		if (exists $transform->{properties} && ref($transform->{properties}) eq 'ARRAY') {
			@custom_props = _process_custom_properties(
				$transform->{properties},
				$function,
				$module,
				$input_spec,
				$output_spec,
				$new
			);
		}

		# Combine detected and custom properties
		my @all_props = (@detected_props, @custom_props);

		# Skip if no properties detected or defined
		next unless @all_props;

		# Build LectroTest generator specification
		my @generators;
		my @var_names;

		for my $field (sort keys %$input_spec) {
			my $spec = $input_spec->{$field};
			next unless ref($spec) eq 'HASH';

			my $gen = _schema_to_lectrotest_generator($field, $spec);
			push @generators, $gen;
			push @var_names, $field;
		}

		my $gen_spec = join(', ', @generators);

		# Build the call code
		my $call_code;
		if ($module) {
			# $call_code = "$module\::$function";
			$call_code = "$module->$function";
		} else {
			$call_code = $function;
		}

		# Build argument list (respect positions if defined)
		my @args;
		if (_has_positions($input_spec)) {
			my @sorted = sort {
				$input_spec->{$a}{position} <=> $input_spec->{$b}{position}
			} keys %$input_spec;
			@args = map { "\$$_" } @sorted;
		} else {
			@args = map { "\$$_" } @var_names;
		}
		my $args_str = join(', ', @args);

		# Build property checks
		my @checks = map { $_->{code} } @all_props;
		my $property_checks = join(" &&\n\t", @checks);

		# Handle _STATUS in output
		my $should_die = ($output_spec->{_STATUS} // '') eq 'DIES';

		push @properties, {
			name => $transform_name,
			generator_spec => $gen_spec,
			call_code => "$call_code($args_str)",
			property_checks => $property_checks,
			should_die => $should_die,
			trials => $config->{properties}{trials} // DEFAULT_PROPERTY_TRIALS,
		};
	}

	return \@properties;
}

=head2 _process_custom_properties

Processes custom property definitions from the schema.

=cut

sub _process_custom_properties {
	my ($properties_spec, $function, $module, $input_spec, $output_spec, $schema) = @_;

	my @properties;
	my $builtin_properties = _get_builtin_properties();
	my $new = defined($schema->{'new'}) ? $schema->{new} : '_UNDEF';

	for my $prop_def (@$properties_spec) {
		my $prop_name;
		my $prop_code;
		my $prop_desc;

		if (!ref($prop_def)) {
			# Simple string - lookup builtin property
			$prop_name = $prop_def;

			if (exists $builtin_properties->{$prop_name}) {
				my $builtin = $builtin_properties->{$prop_name};

				# Get input variable names
				my @var_names = sort keys %$input_spec;

				# Build call code
				my $call_code;
				# Check if this is OO mode
				if($module && defined($new)) {
					$call_code = "my \$obj = new_ok('$module');";
					$call_code .= "\$obj->$function";	# Method call
				} elsif($module && $module ne 'builtin') {
					$call_code = "$module\::$function";	# Function call
				} else {
					$call_code = $function;	# Builtin
				}

				# Build args
				my @args;
				if (_has_positions($input_spec)) {
					my @sorted = sort {
						$input_spec->{$a}{position} <=> $input_spec->{$b}{position}
					} @var_names;
					@args = map { "\$$_" } @sorted;
				} else {
					@args = map { "\$$_" } @var_names;
				}
				$call_code .= '(' . join(', ', @args) . ')';

				# Generate property code from template
				$prop_code = $builtin->{code_template}->($function, $call_code, \@var_names);
				$prop_desc = $builtin->{description};
			} else {
				carp "Unknown built-in property '$prop_name', skipping";
				next;
			}
		} elsif (ref($prop_def) eq 'HASH') {
			# Custom property with code
			$prop_name = $prop_def->{name} || 'custom_property';
			$prop_code = $prop_def->{code};
			$prop_desc = $prop_def->{description} || "Custom property: $prop_name";

			unless ($prop_code) {
				carp "Custom property '$prop_name' missing 'code' field, skipping";
				next;
			}

			# Validate that the code looks reasonable
			unless ($prop_code =~ /\$/ || $prop_code =~ /\w+/) {
				carp "Custom property '$prop_name' code looks invalid: $prop_code";
				next;
			}
		}
		else {
			carp 'Invalid property definition: ', Dumper($prop_def);
			next;
		}

		push @properties, {
			name => $prop_name,
			code => $prop_code,
			description => $prop_desc,
		};
	}

	return @properties;
}

=head2 _detect_transform_properties

Automatically detects testable properties from transform input/output specs.

=cut

sub _detect_transform_properties {
	my ($transform_name, $input_spec, $output_spec) = @_;

	my @properties;

	# Skip if input is 'undef'
	return @properties if (!ref($input_spec) && $input_spec eq 'undef');

	# Property 1: Output range constraints (numeric)
	if (_is_numeric_transform($input_spec, $output_spec)) {
		if (defined $output_spec->{min}) {
			my $min = $output_spec->{min};
			push @properties, {
				name => 'min_constraint',
				code => "\$result >= $min"
			};
		}

		if (defined $output_spec->{max}) {
			my $max = $output_spec->{max};
			push @properties, {
				name => 'max_constraint',
				code => "\$result <= $max"
			};
		}

		# For transforms, add idempotence check where appropriate
		# e.g., abs(abs(x)) == abs(x)
		if ($transform_name =~ /positive/i) {
			push @properties, {
				name => 'non_negative',
				code => "\$result >= 0"
			};
		}
	}

	# Property 2: Specific value output
	if (defined $output_spec->{value}) {
		my $expected = $output_spec->{value};
		push @properties, {
			name => 'exact_value',
			code => "\$result == $expected"
		};
	}

	# Property 3: String length constraints
	if (_is_string_transform($input_spec, $output_spec)) {
		if (defined $output_spec->{min}) {
			push @properties, {
				name => 'min_length',
				code => "length(\$result) >= $output_spec->{min}"
			};
		}

		if (defined $output_spec->{max}) {
			push @properties, {
				name => 'max_length',
				code => "length(\$result) <= $output_spec->{max}"
			};
		}

		if (defined $output_spec->{matches}) {
			my $pattern = $output_spec->{matches};
			push @properties, {
				name => 'pattern_match',
				code => "\$result =~ qr/$pattern/"
			};
		}
	}

	# Property 4: Type preservation
	if (_same_type($input_spec, $output_spec)) {
		my $type = _get_dominant_type($output_spec);

		if ($type eq 'number' || $type eq 'integer' || $type eq 'float') {
			push @properties, {
				name => 'numeric_type',
				code => "looks_like_number(\$result)"
			};
		}
	}

	# Property 5: Definedness (unless output can be undef)
	unless (($output_spec->{type} // '') eq 'undef') {
		push @properties, {
			name => 'defined',
			code => "defined(\$result)"
		};
	}

	return @properties;
}

=head2 _get_semantic_generators

Returns a hash of built-in semantic generators for common data types.

=cut

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
					sprintf('%08x-%04x-%04x-%04x-%012x',
						int(rand(0xffffffff)),
						int(rand(0xffff)),
						(int(rand(0xffff)) & 0x0fff) | 0x4000,
						(int(rand(0xffff)) & 0x3fff) | 0x8000,
						int(rand(0x1000000000000))
					);
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
					my $header = join('', map { $chars[int(rand(@chars))] } 1..20);
					my $payload = join('', map { $chars[int(rand(@chars))] } 1..40);
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
			}
		},
	};
}

=head2 _get_builtin_properties

Returns a hash of built-in property templates that can be applied to transforms.

=cut

sub _get_builtin_properties {
	return {
		idempotent => {
			description => 'Function is idempotent: f(f(x)) == f(x)',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				# Use string comparison - works for all types in Perl
				return "do { my \$tmp = $call_code; \$result eq \$tmp }";
			},
			applicable_to => ['all'],
		},

		non_negative => {
			description => 'Result is always non-negative',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result >= 0';
			},
			applicable_to => ['number', 'integer', 'float'],
		},

		positive => {
			description => 'Result is always positive (> 0)',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result > 0';
			},
			applicable_to => ['number', 'integer', 'float'],
		},

		non_empty => {
			description => 'Result is never empty',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return 'length($result) > 0';
			},
			applicable_to => ['string'],
		},

		length_preserved => {
			description => 'Output length equals input length',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				my $first_var = $input_vars->[0];
				return "length(\$result) == length(\$$first_var)";
			},
			applicable_to => ['string'],
		},

		uppercase => {
			description => 'Result is all uppercase',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result eq uc($result)';
			},
			applicable_to => ['string'],
		},

		lowercase => {
			description => 'Result is all lowercase',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result eq lc($result)';
			},
			applicable_to => ['string'],
		},

		trimmed => {
			description => 'Result has no leading/trailing whitespace',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return '$result !~ /^\s/ && $result !~ /\s$/';
			},
			applicable_to => ['string'],
		},

		sorted_ascending => {
			description => 'Array is sorted in ascending order',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return 'do { my @arr = @$result; my $sorted = 1; for my $i (1..$#arr) { $sorted = 0 if $arr[$i] < $arr[$i-1]; } $sorted }';
			},
			applicable_to => ['arrayref'],
		},

		sorted_descending => {
			description => 'Array is sorted in descending order',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return 'do { my @arr = @$result; my $sorted = 1; for my $i (1..$#arr) { $sorted = 0 if $arr[$i] > $arr[$i-1]; } $sorted }';
			},
			applicable_to => ['arrayref'],
		},

		unique_elements => {
			description => 'Array has no duplicate elements',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				return 'do { my @arr = @$result; my %seen; !grep { $seen{$_}++ } @arr }';
			},
			applicable_to => ['arrayref'],
		},

		preserves_keys => {
			description => 'Hash has same keys as input',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				my $first_var = $input_vars->[0];
				return 'do { my @in = sort keys %{$' . $first_var . '}; my @out = sort keys %$result; join(",", @in) eq join(",", @out) }';
			},
			applicable_to => ['hashref'],
		},

		monotonic_increasing => {
			description => 'For x <= y, f(x) <= f(y)',
			code_template => sub {
				my ($function, $call_code, $input_vars) = @_;
				# This would need multiple inputs - complex
				return '1';	# Placeholder
			},
			applicable_to => ['number', 'integer'],
		},
	};
}

=head2 _schema_to_lectrotest_generator

Converts a schema field spec to a LectroTest generator string.

=cut

sub _schema_to_lectrotest_generator {
	my ($field_name, $spec) = @_;

	my $type = $spec->{type} || 'string';

	# Check for semantic generator first
	if ($type eq 'string' && defined $spec->{semantic}) {
		my $semantic_type = $spec->{semantic};
		my $generators = _get_semantic_generators();

		if (exists $generators->{$semantic_type}) {
			my $gen_code = $generators->{$semantic_type}{code};
			# Remove leading/trailing whitespace and compress
			$gen_code =~ s/^\s+//;
			$gen_code =~ s/\s+$//;
			$gen_code =~ s/\n\s+/ /g;
			return "$field_name <- $gen_code";
		} else {
			carp "Unknown semantic type '$semantic_type', falling back to regular string generator";
			# Fall through to regular string generation
		}
	}

	if ($type eq 'integer') {
		my $min = $spec->{min};
		my $max = $spec->{max};

		if (!defined($min) && !defined($max)) {
			return "$field_name <- Int";
		} elsif (!defined($min)) {
			return "$field_name <- Int(sized => sub { int(rand($max + 1)) })";
		} elsif (!defined($max)) {
			return "$field_name <- Int(sized => sub { $min + int(rand(1000)) })";
		} else {
			my $range = $max - $min;
			return "$field_name <- Int(sized => sub { $min + int(rand($range + 1)) })";
		}
	}
	elsif ($type eq 'number' || $type eq 'float') {
		my $min = $spec->{min};
		my $max = $spec->{max};

		if (!defined($min) && !defined($max)) {
			# No constraints - full range
			return "$field_name <- Float(sized => sub { rand(1000) - 500 })";
		} elsif (!defined($min)) {
			# Only max defined
			if ($max == 0) {
				# max=0 means negative numbers only
				return "$field_name <- Float(sized => sub { -rand(1000) })";
			} elsif ($max > 0) {
				# Positive max, generate 0 to max
				return "$field_name <- Float(sized => sub { rand($max) })";
			} else {
				# Negative max, generate from some negative to max
				return "$field_name <- Float(sized => sub { ($max - 1000) + rand(1000 + $max) })";
			}
		} elsif (!defined($max)) {
			# Only min defined
			if ($min == 0) {
				# min=0 means positive numbers only
				return "$field_name <- Float(sized => sub { rand(1000) })";
			} elsif ($min > 0) {
				# Positive min
				return "$field_name <- Float(sized => sub { $min + rand(1000) })";
			} else {
				# Negative min
				return "$field_name <- Float(sized => sub { $min + rand(-$min + 1000) })";
			}
		} else {
			# Both min and max defined
			my $range = $max - $min;
			if ($range <= 0) {
				carp "Invalid range: min=$min, max=$max";
				return "$field_name <- Float(sized => sub { $min })";
			}
			return "$field_name <- Float(sized => sub { $min + rand($range) })";
		}
	}
	elsif ($type eq 'string') {
		my $min_len = $spec->{min} // 0;
		my $max_len = $spec->{max} // 100;

		# Handle regex patterns
		if (defined $spec->{matches}) {
			my $pattern = $spec->{matches};

			# Build generator using Data::Random::String::Matches
			if (defined $spec->{max}) {
				return "$field_name <- Gen { Data::Random::String::Matches->create_random_string({ regex => qr/$pattern/, length => $spec->{max} }) }";
			} elsif (defined $spec->{min}) {
				return "$field_name <- Gen { Data::Random::String::Matches->create_random_string({ regex => qr/$pattern/, length => $spec->{min} }) }";
			} else {
				return "$field_name <- Gen { Data::Random::String::Matches->create_random_string({ regex => qr/$pattern/ }) }";
			}
		}

		return "$field_name <- String(length => [$min_len, $max_len])";
	} elsif ($type eq 'boolean') {
		return "$field_name <- Bool";
	}
	elsif ($type eq 'arrayref') {
		my $min_size = $spec->{min} // 0;
		my $max_size = $spec->{max} // 10;
		return "$field_name <- List(Int, length => [$min_size, $max_size])";
	}
	elsif ($type eq 'hashref') {
		# LectroTest doesn't have built-in Hash, use custom generator
		my $min_keys = $spec->{min} // 0;
		my $max_keys = $spec->{max} // 10;
		return "$field_name <- Elements(map { my \%h; for (1..\$_) { \$h{'key'.\$_} = \$_ }; \\\%h } $min_keys..$max_keys)";
	}
	else {
		carp "Unknown type '$type' for LectroTest generator, using String";
		return "$field_name <- String";
	}
}

=head2 Helper functions for type detection

=cut

sub _is_numeric_transform {
	my ($input_spec, $output_spec) = @_;

	my $out_type = $output_spec->{type} // '';
	return $out_type eq 'number' || $out_type eq 'integer' || $out_type eq 'float';
}

sub _is_string_transform {
	my ($input_spec, $output_spec) = @_;

	my $out_type = $output_spec->{type} // '';
	return $out_type eq 'string';
}

sub _same_type {
	my ($input_spec, $output_spec) = @_;

	# Simplified - would need more sophisticated logic for multiple inputs
	my $in_type = _get_dominant_type($input_spec);
	my $out_type = _get_dominant_type($output_spec);

	return $in_type eq $out_type;
}

sub _get_dominant_type {
	my $spec = $_[0];

	return $spec->{type} if defined $spec->{type};

	# For multi-field specs, return the first type found
	for my $field (keys %$spec) {
		next unless ref($spec->{$field}) eq 'HASH';
		return $spec->{$field}{type} if defined $spec->{$field}{type};
	}

	return 'string';	# Default
}

sub _has_positions {
	my $spec = $_[0];

	for my $field (keys %$spec) {
		next unless ref($spec->{$field}) eq 'HASH';
		return 1 if defined $spec->{$field}{position};
	}

	return 0;
}

=head2 _render_properties

Renders property definitions into Perl code for the template.

=cut

sub _render_properties {
	my $properties = $_[0];

	my $code = "use_ok('Test::LectroTest::Compat');\n\n";

	for my $prop (@$properties) {
		$code .= "# Transform property: $prop->{name}\n";
		$code .= "my \$$prop->{name} = Property {\n";
		$code .= "    ##[ $prop->{generator_spec} ]##\n";
		$code .= "    \n";
		$code .= "    my \$result = eval { $prop->{call_code} };\n";

		if ($prop->{should_die}) {
			$code .= "    my \$died = defined(\$\@) && \$\@;\n";
			$code .= "    \$died;\n";
		} else {
			$code .= "    my \$error = \$\@;\n";
			# $code .= "    diag(\"\$$prop->{name} -> \$error; \") if(\$ENV{'TEST_VERBOSE'});\n";
			$code .= "    \n";
			$code .= "    !\$error && (\n";
			$code .= "        $prop->{property_checks}\n";
			$code .= "    );\n";
		}

		$code .= "}, name => '$prop->{name}', trials => $prop->{trials};\n\n";

		$code .= "holds(\$$prop->{name});\n";
	}

	return $code;
}

1;

=head1 NOTES

C<seed> and C<iterations> really should be within C<config>.

=head1 SEE ALSO

=over 4

=item * L<https://nigelhorne.github.io/App-Test-Generator/coverage/>: Test Coverage Report

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

=cut

__END__
