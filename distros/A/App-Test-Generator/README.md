# NAME

App::Test::Generator - Generate fuzz and corpus-driven test harnesses

# VERSION

        Version 0.12

# SYNOPSIS

From the command line:

    fuzz-harness-generator t/conf/add.yml > t/add_fuzz.t

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
produces a ready-to-run `.t` test script using [Test::Most](https://metacpan.org/pod/Test%3A%3AMost).

It reads configuration files in any format
(including Perl `.conf` with `our` variables, though this format will be deprecated in a future release)
and optional YAML corpus files,
and generates a [Test::Most](https://metacpan.org/pod/Test%3A%3AMost)-based fuzzing harness combining:

- Randomized fuzzing of inputs (with edge cases)
- Optional static corpus tests from Perl `%cases` or YAML file (`yaml_cases` key)
- Functional or OO mode (via `$new`)
- Reproducible runs via `$seed` and configurable iterations via `$iterations`

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

- `number`, `integer`

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

# CONFIGURATION

The configuration file is either a file that can be read by [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction) or a **trusted input** Perl file that should set variables with `our`.

The documentation here covers the old trusted input style input, but that will go away so you are recommended to use
[Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction) files.
Example: the generator expects your config to use `our %input`, `our $function`, etc.

Recognized items:

- `%input` - input params with keys => type/optional specs:

    When using named parameters

        input:
          name:
            type: string
            optional: false
          age:
            type: integer
            optional: true

    Supported basic types used by the fuzzer: `string`, `integer`, `number`, `boolean`, `arrayref`, `hashref`.
    (You can add more types; they will default to `undef` unless extended.)

    For routines with one unnamed parameter

        input:
          type: string

    Currently, routines with more than one unnamed parameter are not supported.

    The keyword `undef` is used to indicate that the `function` takes no arguments.

- `%output` - output param types for Return::Set checking:

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
          arg1: string

        output: undef

    The keyword `undef` is used to indicate that the `function` returns nothing.

- `%transforms` - list of transformations from input sets to output sets

    TO BE IMPLEMENTED.

    It takes a list of subsets of the input and output definitions,
    and verifies that data from each input subset is correctly transformed into data from the matching output subset.

    This is a draft definition of the schema.

        ---
        module: builtin
        function: abs
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

    If the output hash contains the key \_STATUS, and if that key is set to DIES,
    the routine should die with the given arguments; otherwise, it should live.
    If it's set to WARNS,
    the routine should warn with the given arguments.

    The keyword `undef` is used to indicate that the `function` returns nothing.

- `$module` - module name (optional).

    Using the reserved word `builtin` means you're testing a Perl builtin function.

    If omitted, the generator will guess from the config filename:
    `My-Widget.conf` -> `My::Widget`.

- `$function` - function/method to test (defaults to `run`).
- `$new` - optional hashref of args to pass to the module's constructor (object mode):

        new:
          api_key: ABC123
          verbose: true

    To ensure `new()` is called with no arguments, you still need to define new, thus:

        module: MyModule
        function: my_function

        new:

    For the legacy Perl variable syntax, use the empty string:

        our $new = '';

- `%cases` - optional Perl static corpus, when the output is a simple string (expected => \[ args... \]):

    Maps the expected output string to the input and \_STATUS

        cases:
          ok:
            input: ping
            status: OK
          error:
            input: ""
            status: DIES

- `$yaml_cases` - optional path to a YAML file with the same shape as `%cases`.
- `$seed` - optional integer. When provided, the generated `t/fuzz.t` will call `srand($seed)` so fuzz runs are reproducible.
- `$iterations` - optional integer controlling how many fuzz iterations to perform (default 50).
- `%edge_cases` - optional hash mapping of extra values to inject:

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

- `%type_edge_cases` - optional hash mapping types to arrayrefs of extra values to try for any field of that type:

            our %type_edge_cases = (
                    string => [ '', ' ', "\t", "\n", "\0", 'long' x 1024, chr(0x1F600) ],
                    number => [ 0, 1.0, -1.0, 1e308, -1e308, 1e-308, -1e-308, 'NaN', 'Infinity' ],
                    integer => [ 0, 1, -1, 2**31-1, -(2**31), 2**63-1, -(2**63) ],
            );

- `%config` - optional hash of configuration.

    The current supported variables are

    - `test_nuls`, inject NUL bytes into strings (default: 1)
    - `test_undef`, test with undefined value (default: 1)
    - `test_empty`, test with empty strings (default: 1)
    - `dedup`, fuzzing can create duplicate tests, go some way to remove duplicates (default: 1)

# EXAMPLES

## Math::Simple::add()

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

## Adding YAML file to generate tests

OO fuzz + YAML corpus + edge cases:

        our %input = ( query => { type => 'string' } );
        our %output = ( type => 'string' );
        our $function = 'search';
        our $new = { api_key => 'ABC123' };
        our $yaml_cases = 't/corpus.yml';
        our %edge_cases = ( query => [ '', '    ', '<script>' ] );
        our %type_edge_cases = ( string => [ \"\\0", "\x{FFFD}" ] );
        our $seed = 999;

### YAML Corpus Example (t/corpus.yml)

A YAML mapping of expected -> args array:

        "success":
          - "Alice"
          - 30
        "failure":
          - "Bob"

## Example with arrayref + hashref

    our %input = (
      tags => { type => 'arrayref', optional => 1 },
      config => { type => 'hashref' },
    );
    our %output = ( type => 'hashref' );

## Example with memberof

    our %input = (
        status => { type => 'string', memberof => [ 'ok', 'error', 'pending' ] },
    );
    our %output = ( type => 'string' );
    our %config = ( test_nuls => 0, test_undef => 1 );

This will generate fuzz cases for 'ok', 'error', 'pending', and one invalid string that should die.

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
        runs-on: ubuntu-latest

        steps:
          - uses: actions/checkout@v5

          - name: Set up Perl
            uses: shogo82148/actions-setup-perl@v1
            with:
              perl-version: '5.42'

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

# OUTPUT

By default, writes `t/fuzz.t`.
The generated test:

- Seeds RND (if configured) for reproducible fuzz runs
- Uses edge cases (per-field and per-type) with configurable probability
- Runs `$iterations` fuzz cases plus appended edge-case runs
- Validates inputs with Params::Get / Params::Validate::Strict
- Validates outputs with [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)
- Runs static `is(... )` corpus tests from Perl and/or YAML corpus

# NOTES

- The legacy format conf file must use `our` declarations so variables are visible to the generator via `require`.

# SEE ALSO

- [https://nigelhorne.github.io/App-Test-Generator/coverage/](https://nigelhorne.github.io/App-Test-Generator/coverage/): Test Coverage Report
- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict): Schema Definition
- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet): Input validation
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet): Output validation
- [Test::Most](https://metacpan.org/pod/Test%3A%3AMost), [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS)

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

Portions of this module's design and documentation were created with the
assistance of [ChatGPT](https://openai.com/) (GPT-5), with final curation
and authorship by Nigel Horne.
