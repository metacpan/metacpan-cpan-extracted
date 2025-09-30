# NAME

App::Test::Generator - Generate fuzz and corpus-driven test harnesses

# SYNOPSIS

From the command line:

    fuzz-harness-generator t/conf/add.conf > t/add_fuzz.t

From Perl:

    use App::Test::Generator qw(generate);

    # Generate to STDOUT
    App::Test::Generator::generate("t/conf/add.conf");

    # Generate directly to a file
    App::Test::Generator::generate("t/conf/add.conf", "t/add_fuzz.t");

# OVERVIEW

This module takes a formal input/output specification for a routine or
method and automatically generates test cases. In effect, it allows you
to easily add comprehensive black-box tests in addition to the more
common white-box tests typically written for CPAN modules and other
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

It reads configuration files (Perl `.conf` with `our` variables,
and optional YAML corpus files), and generates a [Test::Most](https://metacpan.org/pod/Test%3A%3AMost)-based
fuzzing harness in `t/fuzz.t`.

Generates `t/fuzz.t` combining:

- Randomized fuzzing of inputs (with edge cases)
- Optional static corpus tests from Perl `%cases` or YAML file (`yaml_cases` key)
- Functional or OO mode (via `$new`)
- Reproducible runs via `$seed` and configurable iterations via `$iterations`

## EDGE CASE GENERATION

In addition to purely random fuzz cases, the harness generates
deterministic edge cases for parameters that declare `min`, `max`,
`len`, or `len` in their schema definitions.

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

    Uses strings of lengths one below, equal to, and one above the boundary
    (minimum length = `len`, maximum length = `len`).

- `arrayref`

    Uses references to arrays of lengths one below, equal to, and one above the boundary
    (minimum length = `len`, maximum length = `len`).

- `hashref`

    Uses hashes with key counts one below, equal to, and one above the
    boundary (`min` = minimum number of keys, `max` = maximum number
    of keys).

- `memberof` - optional arrayref of allowed values for a parameter:

        our %input = (
            status => { type => 'string', memberof => [ 'ok', 'error', 'pending' ] },
            level => { type => 'integer', memberof => [ 1, 2, 3 ] },
        );

    The generator will automatically create test cases for each allowed value (inside the member list),
    and at least one value outside the list (which should die, `_STATUS = 'DIES'`).
    This works for strings, integers, and numbers.

- `boolean` - automatic boundary tests for boolean fields

        our %input = (
            flag => { type => 'boolean' },
        );

    The generator will automatically create test cases for 0 and 1, and optionally invalid values that should trigger `_STATUS = 'DIES'`.

These edge cases are inserted automatically, in addition to the random
fuzzing inputs, so each run will reliably probe boundary conditions
without relying solely on randomness.

# CONFIGURATION

The configuration file is a Perl file that should set variables with `our`.
Example: the generator expects your config to use `our %input`, `our $function`, etc.

Recognized items:

- `%input` - input params with keys => type/optional specs:

            our %input = (
                    name => { type => 'string', optional => 0 },
                    age => { type => 'integer', optional => 1 },
            );

    Supported basic types used by the fuzzer: `string`, `integer`, `number`, `boolean`, `arrayref`, `hashref`.
    (You can add more types; they will default to `undef` unless extended.)

- `%output` - output param types for Return::Set checking:

            our %output = (
                    type => 'string'
            );

    If the output hash contains the key \_STATUS, and if that key is set to DIES,
    the routine should die with the given arguments; otherwise, it should live.
    If it's set to WARNS,
    the routine should warn with the given arguments

- `$module` - module name (optional).

    If omitted, the generator will guess from the config filename:
    `My-Widget.conf` -> `My::Widget`.

- `$function` - function/method to test (defaults to `run`).
- `$new` - optional hashref of args to pass to the module's constructor (object mode):

            our $new = { api_key => 'ABC123', verbose => 1 };

    To ensure new is called with no arguments, you still need to defined new, thus:

        our $new = '';

- `%cases` - optional Perl static corpus (expected => \[ args... \]):

        our %cases = (
          'ok'   => [ 'ping' ],
          'error'=> [ '' ],
        );

- `$yaml_cases` - optional path to a YAML file with the same shape as `%cases`.
- `$seed` - optional integer. When provided, the generated `t/fuzz.t` will call `srand($seed)` so fuzz runs are reproducible.
- `$iterations` - optional integer controlling how many fuzz iterations to perform (default 50).
- `%edge_cases` - optional hash mapping parameter names to arrayrefs of extra values to inject:

            our %edge_cases = (
                    name => [ '', 'a' x 1024, \"\x{263A}" ],
                    age  => [ -1, 0, 99999999 ],
            );

    (Values can be strings or numbers; strings will be properly quoted.)

- `%type_edge_cases` - optional hash mapping types to arrayrefs of extra values to try for any field of that type:

            our %type_edge_cases = (
                    string  => [ '', ' ', "\t", "\n", "\0", 'long' x 1024, chr(0x1F600) ],
                    number  => [ 0, 1.0, -1.0, 1e308, -1e308, 1e-308, -1e-308, 'NaN', 'Infinity' ],
                    integer => [ 0, 1, -1, 2**31-1, -(2**31), 2**63-1, -(2**63) ],
            );

# EXAMPLES

## Math::Simple::add()

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
      tags   => { type => 'arrayref', optional => 1 },
      config => { type => 'hashref' },
    );
    our %output = ( type => 'hashref' );

## Example with memberof

    our %input = (
        status => { type => 'string', memberof => [ 'ok', 'error', 'pending' ] },
    );
    our %output = ( type => 'string' );

This will generate fuzz cases for 'ok', 'error', 'pending', and one invalid string that should die.

# OUTPUT

By default, writes `t/fuzz.t`.
The generated test:

- Seeds RNG (if configured) for reproducible fuzz runs
- Uses edge cases (per-field and per-type) with configurable probability
- Runs `$iterations` fuzz cases plus appended edge-case runs
- Validates inputs with Params::Get / Params::Validate::Strict
- Validates outputs with [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)
- Runs static `is(... )` corpus tests from Perl and/or YAML corpus

# NOTES

\- The conf file must use `our` declarations so variables are visible to the generator via `require`.
\- Use `srand($seed)` replay to reproduce failing cases. When you get a failure, re-run generator with the same `$seed` to reproduce.

# SEE ALSO

- Test coverage report: [https://nigelhorne.github.io/App-Test-Generator/coverage/](https://nigelhorne.github.io/App-Test-Generator/coverage/)
- [Test::Most](https://metacpan.org/pod/Test%3A%3AMost), [Params::Get](https://metacpan.org/pod/Params%3A%3AGet), [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict), [Return::Set](https://metacpan.org/pod/Return%3A%3ASet), [YAML::XS](https://metacpan.org/pod/YAML%3A%3AXS)

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

Portions of this module's design and documentation were created with the
assistance of [ChatGPT](https://openai.com/) (GPT-5), with final curation
and authorship by Nigel Horne.
