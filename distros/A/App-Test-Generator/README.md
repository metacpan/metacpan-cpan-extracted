# NAME

App::Test::Generator - Generate fuzz and corpus-driven test harnesses

# VERSION

Version 0.20

# SYNOPSIS

From the command line:

    fuzz-harness-generator -r t/conf/add.yml

    extract-schemas bin/extract-schemas lib/Sample/Module.pm; fuzz-harness-generator -r schemas/greet.yaml

From Perl:

    use App::Test::Generator qw(generate);

    # Generate to STDOUT
    App::Test::Generator::generate("t/conf/add.yml");

    # Generate directly to a file
    App::Test::Generator::generate('t/conf/add.yml', 't/add_fuzz.t');

# OVERVIEW

This module takes a formal input/output specification for a routine or
method and automatically generates test cases. In effect, it allows you
to easily add comprehensive black-box tests in addition to the more
common white-box tests that are typically written for CPAN modules and other
subroutines.

The generated tests combine:

- Random fuzzing based on input types
- Deterministic edge cases for min/max constraints
- Static corpus tests defined in Perl or YAML

This approach strengthens your test suite by probing both expected and
unexpected inputs, helping you to catch boundary errors, invalid data
handling, and regressions without manually writing every case.

# DESCRIPTION

This module implements the logic behind [fuzz-harness-generator](https://metacpan.org/pod/fuzz-harness-generator).
It parses configuration files (fuzz and/or corpus YAML), and
produces a ready-to-run `.t` test script to run through `prove`.

It reads configuration files in any format,
and optional YAML corpus files.
All of the examples in this documentation are in `YAML` format,
other formats may not work as they aren't so heavily tested.
It then generates a [Test::Most](https://metacpan.org/pod/Test%3A%3AMost)-based fuzzing harness combining:

- Randomized fuzzing of inputs (with edge cases)
- Optional static corpus tests from Perl `%cases` or YAML file (`yaml_cases` key)
- Functional or OO mode (via `$new`)
- Reproducible runs via `$seed` and configurable iterations via `$iterations`

# CONFIGURATION

The configuration file,
for each set of tests to be produced,
is a file containing a schema that can be read by [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction).

## SCHEMA

The schema is split into several sections.

### `%input` - input params with keys => type/optional specs

When using named parameters

    input:
      name:
        type: string
        optional: false
      age:
        type: integer
        optional: true

Supported basic types used by the fuzzer: `string`, `integer`, `float`, `number`, `boolean`, `arrayref`, `hashref`.
See also [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict).
You can add more custom types using properties.

For routines with one unnamed parameter

    input:
      type: string

For routines with more than one named parameter, use the `position` keyword.

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

The keyword `undef` is used to indicate that the `function` takes no arguments.

### `%output` - output param types for [Return::Set](https://metacpan.org/pod/Return%3A%3ASet) checking

    output:
      type: string

If the output hash contains the key \_STATUS, and if that key is set to DIES,
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

The keyword `undef` is used to indicate that the `function` returns nothing.

### `%config` - optional hash of configuration.

The current supported variables are

- `test_nuls`, inject NUL bytes into strings (default: 1)
- `test_undef`, test with undefined value (default: 1)
- `test_empty`, test with empty strings (default: 1)
- `test_non_ascii`, test with strings that contain non ascii characters (default: 1)
- `dedup`, fuzzing can create duplicate tests, go some way to remove duplicates (default: 1)
- `properties`, enable [Test::LectroTest](https://metacpan.org/pod/Test%3A%3ALectroTest) Property tests (default: 0)

### `%transforms` - list of transformations from input sets to output sets

Transforms allow you to define how input data should be transformed into output data.
This is useful for testing functions that convert between formats, normalize data,
or apply business logic transformations on a set of data to different set of data.
It takes a list of subsets of the input and output definitions,
and verifies that data from each input subset is correctly transformed into data from the matching output subset.

#### Transform Validation Rules

For each transform:

- 1. Generate test cases using the transform's input schema
- 2. Call the function with those inputs
- 3. Validate the output matches the transform's output schema
- 4. If output has a specific 'value', check exact match
- 5. If output has constraints (min/max), validate within bounds

#### Example 1

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

If the output hash contains the key \_STATUS, and if that key is set to DIES,
the routine should die with the given arguments; otherwise, it should live.
If it's set to WARNS, the routine should warn with the given arguments.

The keyword `undef` is used to indicate that the `function` returns nothing.

#### Example 2

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

### `$module`

The name of the module (optional).

Using the reserved word `builtin` means you're testing a Perl builtin function.

If omitted, the generator will guess from the config filename:
`My-Widget.conf` -> `My::Widget`.

### `$function`

The function/method to test.

This defaults to `run`.

### `%new`

An optional hashref of args to pass to the module's constructor.

    new:
      api_key: ABC123
      verbose: true

To ensure `new()` is called with no arguments, you still need to define new, thus:

    module: MyModule
    function: my_function

    new:

### `%cases`

An optional Perl static corpus, when the output is a simple string (expected => \[ args... \]).

Maps the expected output string to the input and \_STATUS

    cases:
      ok:
        input: ping
        _STATUS: OK
      error:
        input: ""
        _STATUS: DIES

### `$yaml_cases` - optional path to a YAML file with the same shape as `%cases`.

### `$seed`

An optional integer.
When provided, the generated `t/fuzz.t` will call `srand($seed)` so fuzz runs are reproducible.

### `$iterations`

An optional integer controlling how many fuzz iterations to perform (default 50).

### `%edge_cases`

An optional hash mapping of extra values to inject.

        # Two named parameters
        edge_cases:
                name: [ '', 'a' x 1024, \"\x{263A}" ]
                age: [ -1, 0, 99999999 ]

        # Takes a string input
        edge_cases: [ 'foo', 'bar' ]

Values can be strings or numbers; strings will be properly quoted.
Note that this only works with routines that take named parameters.

### `%type_edge_cases`

An optional hash mapping types to arrayrefs of extra values to try for any field of that type:

        type_edge_cases:
                string: [ '', ' ', "\t", "\n", "\0", 'long' x 1024, chr(0x1F600) ]
                number: [ 0, 1.0, -1.0, 1e308, -1e308, 1e-308, -1e-308, 'NaN', 'Infinity' ]
                integer: [ 0, 1, -1, 2**31-1, -(2**31), 2**63-1, -(2**63) ]

### `%edge_case_array`

Specify edge case values for routines that accept a single unnamed parameter.
This is specifically designed for simple functions that take one argument without a parameter name.
These edge cases supplement the normal random string generation, ensuring specific problematic values are always tested.
During fuzzing iterations, there's a 40% probability that a test case will use a value from edge\_case\_array instead of randomly generated data.

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

### Semantic Data Generators

For property-based testing with [Test::LectroTest](https://metacpan.org/pod/Test%3A%3ALectroTest),
you can use semantic generators to create realistic test data.
Fuzz testing support for `semantic` entries is being developed.

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

#### Available Semantic Types

- `email` - Valid email addresses (user@domain.tld)
- `url` - HTTP/HTTPS URLs
- `uuid` - UUIDv4 identifiers
- `phone_us` - US phone numbers (XXX-XXX-XXXX)
- `phone_e164` - International E.164 format (+XXXXXXXXXXXX)
- `ipv4` - IPv4 addresses (0.0.0.0 - 255.255.255.255)
- `ipv6` - IPv6 addresses
- `username` - Alphanumeric usernames with \_ and -
- `slug` - URL slugs (lowercase-with-hyphens)
- `hex_color` - Hex color codes (#RRGGBB)
- `iso_date` - ISO 8601 dates (YYYY-MM-DD)
- `iso_datetime` - ISO 8601 datetimes (YYYY-MM-DDTHH:MM:SSZ)
- `semver` - Semantic version strings (major.minor.patch)
- `jwt` - JWT-like tokens (base64url format)
- `json` - Simple JSON objects
- `base64` - Base64-encoded strings
- `md5` - MD5 hashes (32 hex chars)
- `sha256` - SHA-256 hashes (64 hex chars)

## EDGE CASE GENERATION

In addition to purely random fuzz cases, the harness generates
deterministic edge cases for parameters that declare `min`, `max` or `len` in their schema definitions.

For each constraint, three edge cases are added:

- Just inside the allowable range

    This case should succeed, since it lies strictly within the bounds.

- Exactly on the boundary

    This case should succeed, since it meets the constraint exactly.

- Just outside the boundary

    This case is annotated with `_STATUS = 'DIES'` in the corpus and
    should cause the harness to fail validation or croak.

Supported constraint types:

- `number`, `integer`, `float`

    Uses numeric values one below, equal to, and one above the boundary.

- `string`

    Uses strings of lengths one below, equal to, and one above the boundary.

- `arrayref`

    Uses references to arrays of with the number of elements one below, equal to, and one above the boundary.

- `hashref`

    Uses hashes with key counts one below, equal to, and one above the
    boundary (`min` = minimum number of keys, `max` = maximum number
    of keys).

- `memberof` - arrayref of allowed values for a parameter

    This example is for a routine called `input()` that takes two arguments: `status` and `level`.
    `status` is a string that must have the value `ok`, `error` or `pending`.
    The `level` argument is an integer that must be one of `1`, `5` or `111`.

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
    and at least one value outside the list (which should die or `croak`, `_STATUS = 'DIES'`).
    This works for strings, integers, and numbers.

- `boolean` - automatic boundary tests for boolean fields

        input:
          flag:
            type: boolean

    The generator will automatically create test cases for 0 and 1; true and false; off and on, and values that should trigger `_STATUS = 'DIES'`.

These edge cases are inserted automatically, in addition to the random
fuzzing inputs, so each run will reliably probe boundary conditions
without relying solely on randomness.

# EXAMPLES

See the files in `t/conf` for examples.

## Adding Scheduled fuzz Testing with GitHub Actions to Your Code

To automatically create and run tests on a regular basis on GitHub Actions,
you need to create a configuration file for each method and subroutine that you're testing,
and a GitHub Actions configuration file.

This example takes you through testing the online\_render method of [HTML::Genealogy::Map](https://metacpan.org/pod/HTML%3A%3AGenealogy%3A%3AMap).

### t/conf/online\_render.yml

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

### .github/actions/fuzz.t

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

## Fuzz Testing your CPAN Module

Running fuzz tests when you run `make test` in your CPAN module.

Create a directory &lt;t/conf> which contains the schemas.

Then create this file as &lt;t/fuzz.t>:

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

                  if(-f $filepath) {      # Check if it's a regular file
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

## Property-Based Testing with Transforms

The generator can create property-based tests using [Test::LectroTest](https://metacpan.org/pod/Test%3A%3ALectroTest) when the
`properties` configuration option is enabled.
This provides more comprehensive
testing by automatically generating thousands of test cases and verifying that
mathematical properties hold across all inputs.

### Basic Property-Based Transform Example

Here's a complete example testing the `abs` builtin function:

**t/conf/abs.yml**:

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

- Enables property-based testing with 1000 trials per property
- Defines two transforms: one for positive numbers, one for negative
- Automatically generates properties that verify `abs()` always returns non-negative numbers

Generate the test:

    fuzz-harness-generator t/conf/abs.yml > t/abs_property.t

The generated test will include:

- Traditional edge-case tests for boundary conditions
- Random fuzzing with 50 iterations (or as configured)
- Property-based tests that verify the transforms with 1000 trials each

### What Properties Are Tested?

The generator automatically detects and tests these properties based on your transform specifications:

- **Range constraints** - If output has `min` or `max`, verifies results stay within bounds
- **Type preservation** - Ensures numeric inputs produce numeric outputs
- **Definedness** - Verifies the function doesn't return `undef` unexpectedly
- **Specific values** - If output specifies a `value`, checks exact equality

For the `abs` example above, the generated properties verify:

    # For the "positive" transform:
    - Given a positive number, abs() returns >= 0
    - The result is a valid number
    - The result is defined

    # For the "negative" transform:
    - Given a negative number, abs() returns >= 0
    - The result is a valid number
    - The result is defined

### Advanced Example: String Normalization

Here's a more complex example testing a string normalization function:

**t/conf/normalize.yml**:

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

- Preserves empty strings (`empty_preserved` transform)
- Collapses multiple spaces into single spaces (`single_space` transform)
- Maintains length constraints (`length_bounded` transform)

### Interpreting Property Test Results

When property-based tests run, you'll see output like:

    ok 123 - negative property holds (1000 trials)
    ok 124 - positive property holds (1000 trials)

If a property fails, Test::LectroTest will attempt to find the minimal failing
case and display it:

    not ok 123 - positive property holds (47 trials)
    # Property failed
    # Reason: counterexample found

This helps you quickly identify edge cases that your function doesn't handle correctly.

### Configuration Options for Property-Based Testing

In the `config` section:

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

### When to Use Property-Based Testing

Property-based testing with transforms is particularly useful for:

- Mathematical functions (`abs`, `sqrt`, `min`, `max`, etc.)
- Data transformations (encoding, normalization, sanitization)
- Parsers and formatters
- Functions with clear input-output relationships
- Code that should satisfy mathematical properties (commutativity, associativity, idempotence)

### Requirements

Property-based testing requires [Test::LectroTest](https://metacpan.org/pod/Test%3A%3ALectroTest) to be installed:

    cpanm Test::LectroTest

If not installed, the generated tests will automatically skip the property-based
portion with a message.

### Testing Email Validation

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

### Combining Semantic with Regex

You can combine semantic generators with regex validation:

    input:
      corporate_email:
        type: string
        semantic: email
        matches: '@company\.com$'

The semantic generator creates realistic emails, and the regex ensures they match your domain.

### Custom Properties for Transforms

You can define additional properties that should hold for your transforms beyond
the automatically detected ones.

#### Using Built-in Properties

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

- `idempotent` - Function is idempotent: f(f(x)) == f(x)
- `non_negative` - Result is always >= 0
- `positive` - Result is always > 0
- `non_empty` - String result is never empty
- `length_preserved` - Output length equals input length
- `uppercase` - Result is all uppercase
- `lowercase` - Result is all lowercase
- `trimmed` - No leading/trailing whitespace
- `sorted_ascending` - Array is sorted ascending
- `sorted_descending` - Array is sorted descending
- `unique_elements` - Array has no duplicates
- `preserves_keys` - Hash has same keys as input

#### Custom Property Code

Custom properties allows the definition additional invariants and relationships that should hold for their transforms,
beyond what's auto-detected.
For example:

- Idempotence: f(f(x)) == f(x)
- Commutativity: f(x, y) == f(y, x)
- Associativity: f(f(x, y), z) == f(x, f(y, z))
- Inverse relationships: decode(encode(x)) == x
- Domain-specific invariants: Custom business logic

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

- `$result` - The function's return value
- Input variables - All input parameters (e.g., `$text`, `$number`)
- The function itself - Can call it again for idempotence checks

#### Combining Auto-detected and Custom Properties

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

## GENERATED OUTPUT

The generated test:

- Seeds RND (if configured) for reproducible fuzz runs
- Uses edge cases (per-field and per-type) with configurable probability
- Runs `$iterations` fuzz cases plus appended edge-case runs
- Validates inputs with Params::Get / Params::Validate::Strict
- Validates outputs with [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)
- Runs static `is(... )` corpus tests from Perl and/or YAML corpus
- Runs [Test::LectroTest](https://metacpan.org/pod/Test%3A%3ALectroTest) tests

# METHODS

    generate($schema_file, $test_file)

Takes a schema file and produces a test file (or STDOUT).

## \_generate\_transform\_properties

Converts transform specifications into LectroTest property definitions.

## \_process\_custom\_properties

Processes custom property definitions from the schema.

## \_detect\_transform\_properties

Automatically detects testable properties from transform input/output specs.

## \_get\_semantic\_generators

Returns a hash of built-in semantic generators for common data types.

## \_get\_builtin\_properties

Returns a hash of built-in property templates that can be applied to transforms.

## \_schema\_to\_lectrotest\_generator

Converts a schema field spec to a LectroTest generator string.

## Helper functions for type detection

## \_render\_properties

Renders property definitions into Perl code for the template.

# NOTES

`seed` and `iterations` really should be within `config`.

# SEE ALSO

- [https://nigelhorne.github.io/App-Test-Generator/coverage/](https://nigelhorne.github.io/App-Test-Generator/coverage/): Test Coverage Report
- [App::Test::Generator::Template](https://metacpan.org/pod/App%3A%3ATest%3A%3AGenerator%3A%3ATemplate) - Template of the file of tests created by `App::Test::Generator`
- [App::Test::Generator::SchemaExtractor](https://metacpan.org/pod/App%3A%3ATest%3A%3AGenerator%3A%3ASchemaExtractor) - Project to create schemas from Perl programs
- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict): Schema Definition
- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet): Input validation
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet): Output validation
- [Test::LectroTest](https://metacpan.org/pod/Test%3A%3ALectroTest)
- [Test::Most](https://metacpan.org/pod/Test%3A%3AMost)
- [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS)

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

Portions of this module's initial design and documentation were created with the
assistance of AI.
