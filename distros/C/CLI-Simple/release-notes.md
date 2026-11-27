# CLI::Simple 2.7.0

## Release Summary

This release adds support for extended command declarations, allowing
command handlers to be specified as hash references with metadata
alongside the traditional code-reference and array-reference forms.

## New Feature: Extended Command Declarations

Prior to this release, commands could only be declared as code
references, `[coderef, log_level]` array references, or string
aliases. Applications that needed to associate additional metadata—
such as a human-readable description—with a command had no structured
place to put that information.

Version 2.7.0 introduces a hash-reference declaration form via the
new `normalize_commands()` method:

```perl
commands => {
  start => {
    command     => \&cmd_start,
    description => 'Start the application',
    log_level   => 'info',
  },
  stop => \&cmd_stop,
  s    => 'start',
},
```

Traditional and extended declarations are freely mixed in the same
`commands` hash. Extended declarations are normalized to the
traditional dispatch forms internally; callers' declarations are not
modified.

Supported attributes are `command` (required code reference),
`description` (optional scalar), and `log_level` (optional scalar).
Unknown attributes, missing or non-CODE handlers, and reference values
for `description` or `log_level` raise an exception during
normalization.

This normalization is exposed as the class method
`normalize_commands($declarations)`, which returns a two-element list:
the normalized dispatch hash and a metadata hash keyed by command
name. See `CLI::Simple` documentation for details.

## Tests

A new test file `t/21-command-normalization.t` covers the
normalization behavior for extended command declarations.

## Internal

Build infrastructure files under `.includes/` were updated by
CPAN::Maker::Bootstrapper.

