# NAME

Code::Quality - use static analysis to compute a "code quality" metric for a program

# SYNOPSIS

```perl
use v5.20;
use Code::Quality;
# code to test (required)
my $code = ...;
# reference code to compare against (optional)
my $reference = ...;

my $warnings =
  analyse_code
    code => $code,
    reference => $reference,
    language => 'C';
if (defined $warnings) {
  my $stars = star_rating_of_warnings $warnings;
  say "Program is rated $stars stars"; # 3 is best, 1 is worst
  my @errors = grep { $_->[0] eq 'error' } @$warnings;
  if (@errors > 0) {
    say 'Found ', scalar @errors, ' errors';
    say "First error:  $errors[0][1]";
  }
} else {
  say 'Failed to analyse code';
}
```

# DESCRIPTION

Code::Quality runs a series of tests on a piece of source code to
compute a code quality metric. Each test returns a possibly empty list
of warnings, that is potential issues present in the source code. This
list of warnings can then be turned into a star rating: 3 stars for
good code, 2 stars for acceptable code, and 1 stars for dubious code.

## Warnings

A warning is an arrayref `[type, message, row, column]`, where
the first two entries are mandatory and the last two can be either
both present or both absent.
The type is one of `qw/error warning info/`.

Four-element warnings correspond to ACE code editor annotations.
Two-element warnings apply to the entire document, not a specific
place in the code.

## Tests

A test is a function that takes key-value arguments:

**test\_something**(code => _$code_, language => _$language_, \[reference => _$reference_\])

Here _$code_ is the code to be tested, _$language_ is the
programming language, and _$reference_ is an optional reference
source code to compare _$code_ against.

Each test returns undef if the test failed (for example, if the test
cannot be applied to this programming language), and an arrayref of
warnings otherwise.

Most tests have several configurable parameters, which come from
global variables. The documentation of each test mentions the global
variables that affect its operations. `local` can be used to run a
test with special configuration once, without affecting other code:

```perl
{
  local $Code::Quality::bla_threshold = 5;
  test_bla code => $code, language => 'C';
}
```

### test\_lines

This test counts non-empty lines in both the code and the reference.
If the code is significantly longer than the reference, it returns a warning.
If the code is much longer, it returns an error.
Otherwise it returns an empty arrayref.

The thresholds for raising a warning/error are available in the source
code, see global variables `@short_code_criteria` and
`@long_code_criteria`.

This test fails if no reference is provided, but is language-agnostic

### test\_clang\_tidy

This test runs the
[clang-tidy](https://clang.llvm.org/extra/clang-tidy/) static analyser
on the code and returns all warnings found.

The clang-tidy checks in use are determined by two global variables,
each of which is a list of globs such as `modernize-*`. The checks in
`@clang_tidy_warnings` produce warnings, while the checks in
`@clang_tidy_errors` produce errors. There is also a hash
`%clang_tidy_check_options` which contains configuration for the
checks.

This test does not require a reference, but is limited to languages
that clang-tidy understands. This is controlled by the global variable
`%extension_of_language`, which contains file extensions for the
supported languages.

### analyse\_code

**analyse\_code** runs every test above on the code, producing a
combined list of warnings. It fails (returns undef) if all tests fail.
The tests run by **analyse\_code** are those in the global variable
`@all_tests`, which is a list of coderefs.

## Star rating

**star\_rating\_of\_warnings**(_$warnings_) is a subroutine that takes
the output of a test and computes the star rating as an integer. The
rating is undef if the test failed, 1 if the test returned at least
one error, 2 if the test returned at least one warning but no errors,
and 3 otherwise. So a program gets 3 stars if it only raises
informational messages, or no messages at all.

# EXPORT

By default only **analyse\_code** and **star\_rating\_of\_warnings** are exported.

The other tests can be exported on request.

# AUTHOR

Marius Gavrilescu, <marius@ieval.ro>

# COPYRIGHT AND LICENSE

Copyright (C) 2019 by Wellcode PB SRL

Code::Quality is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Code::Quality is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with Code::Quality. If not, see
[https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).
