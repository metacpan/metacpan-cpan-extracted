# AGENTS.md - Datafile::Hash.pm Development Guide

This document provides guidelines for agentic coding agents operating in this repository.

## Build Commands

```bash
# Initial setup
perl Makefile.PL

# Build the distribution
make

# Run all tests
make test

# Run a single test file
prove t/00-load.t
prove t/01-hash-flat.t
perl -Ilib t/01-hash-flat.t

# Run tests with verbose output
prove -v t/
make test TEST_VERBOSE=1

# Install the module
make install

# Clean build artifacts
make clean
```

## Code Style Guidelines

### General Principles

- **Minimal dependencies**: This is a pure-Perl distribution. Do not add external dependencies.
- **Perl minimum version**: 5.014 (enforced in all files with `use 5.014;`)
- **No comments unless requested**: Only add comments when they explain non-obvious logic.
- **Consistent error handling**: Functions return `(0, \@errors)` on I/O errors, never `die` during normal operations.

### Imports and Pragmas

Always include these at the top of every Perl file:

```perl
use strict;
use warnings;
use 5.010;
```

For modules exporting functions:

```perl
use Exporter 'import';
use Carp;

our @EXPORT_OK = qw(function1 function2);
our $VERSION   = '1.05';
```

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Packages | PascalCase | `Datafile::Hash` |
| Public functions | snake_case | `readhash`, `writehash` |
| Private helpers | Leading underscore + snake_case | `_trim`, `_parse_ini_section` |
| Variables | snake_case | `$entry_count`, `$group_level` |
| Constants | UPPER_SNAKE_CASE | `MAX_BUFFER_SIZE` |

### Function Signatures and Parameters

- Use positional parameters, not signatures module
- Destructure at the start of functions:

```perl
sub readhash {
    my ($filename, $hashref, $opts) = @_;
    $opts //= {};

    my $delim = $opts->{delimiter} // '=';
    my $verbose = $opts->{verbose} // 0;
    # ...
}
```

### Return Value Patterns

All read/write functions follow this signature:

```perl
# Returns: ($count, \@messages, \%groups_seen)
my ($entry_count, $msgs, $groups) = readhash($file, \%config, \%opts);

# On error:
return (0, ["WARNING: cannot open '$filename': $!"]);
```

### Error Handling

- I/O errors: Return `(0, [error_message])` instead of dying
- Programming errors: Use `croak` with lowercase package prefix:

```perl
croak "datafile::hash::readhash: 'hash' parameter must be a HASH reference";
```

### File Operations

- Always use UTF-8 encoding layer:

```perl
open(my $fh, '<:encoding(UTF-8)', $filename)
    or return (0, ["WARNING: cannot open '$filename': $!"]);
```

- Atomic writes with temp file + rename:

```perl
my $tmp = "$filename.tmp";
open(my $fh, '>:encoding(UTF-8):crlf', $tmp)
    or return (0, ["ERROR: cannot open '$tmp' for writing: $!"]);
# ... write to $tmp ...
close $fh or return (0, ["ERROR: failed to close '$tmp': $!"]);
rename $tmp, $filename
    or return (0, ["ERROR: failed to rename '$tmp' to '$filename': $!"]);
```

### POD Documentation

All public functions must have POD `=head2` sections with:

```perl
=head2 function_name($param1, $param2)

Description of what the function does.

Returns:
  ($return_value, \@messages)

$return_value - description
\@messages    - arrayref of informational/warning messages
```

### Option Handling

- Options hash: Accept as optional hashref, default to `{}`
- Use `//` (defined-or) for defaults:

```perl
my $delim = $opts->{delimiter} // '=';
my $verbose = $opts->{verbose} // 0;
```

### Verbose Messaging

When `$verbose` is enabled, push formatted messages to `@messages`:

```perl
push @messages, "- entry count: $entry_count\n" if $verbose;
push @messages, "# opts: " . join(", ", map { "$_=$opts->{$_}" } sort keys %$opts) . "\n" if $verbose;
```

### Helper Subroutines

Place private helpers at the bottom of the file before `1;`:

```perl
# Helper to trim whitespace
sub _trim {
    my ($value, $do_trim) = @_;
    return $value unless $do_trim && defined $value;
    $value =~ s/^\s+|\s+$//g;
    return $value;
}
```

### Test Files

- Location: `t/` directory
- Framework: Test::More
- Pattern: Create temp data files, run functions, use `is()`/`cmp_deeply()`, cleanup

```perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use Datafile::Hash qw(readhash);

my $test_file = "$Bin/data/test.ini";
# ... create test data ...
my ($rc, $msgs) = readhash($test_file, \%config, {});
is($rc, 5, "Read 5 entries");
# ... cleanup ...
done_testing;
```

### INI Parsing

Parse section headers with nested group support:

```perl
if ($line =~ /^\[(.+)\]\s*$/) {
    my $header = $1;
    my @parts = split /\./, $header;
    # Handle nested sections...
}
```

### Key Files

| File | Purpose |
|------|---------|
| `lib/Datafile/Hash.pm` | Key-value and INI-style config files |
| `Makefile.PL` | Build configuration (ExtUtils::MakeMaker) |
| `t/*.t` | Test suite (hash-related tests) |

### Module Entry Point

The module exports functions separately:

```perl
use Datafile::Hash qw(readhash writehash);
```
