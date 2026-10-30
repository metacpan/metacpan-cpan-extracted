# CLI::Simple 2.4.0 Release Notes

## Overview

Release 2.4.0 introduces pluggable option providers, allowing CLI
applications to obtain option values from multiple sources without
implementing repetitive retrieval and precedence logic in each
application.

Providers are implemented as reusable Role::Tiny roles and registered
in precedence order. CLI::Simple coordinates resolution of options
not supplied on the command line, allowing applications to access
their options through the same generated accessors regardless of
where the values originated.

This release also migrates the PAUSE publishing workflow to a
CPAN::Maker::Bootstrapper role.

---

## Option Providers

The primary feature of this release is the new `use_options` class
method and its companion `resolve_option_providers`, which together
implement a named, ordered mechanism for supplying option values from
external sources such as configuration files, credential stores, or
environment lookups.

### Registering Providers: `use_options`

Providers are registered at the class level before construction:

```perl
MyApp->use_options(
    aws => { 'MyApp::Role::AWSConfig' => [qw(region bucket)] },
    db  => { 'MyApp::Role::DBConfig'  => [qw(dsn username password)] },
);
```

Each provider is identified by a short lowercase name and maps to a
single `Role::Tiny` role class paired with the list of option names
that role is expected to supply. `use_options` immediately applies the
role to the calling class via `Role::Tiny->apply_roles_to_package`.

The option list identifies the application options that a provider is
eligible to resolve. An empty array reference (`[]`) indicates that
the provider may resolve any application option declared through
`option_specs` or `extra_options`.

The provider is responsible for translating application option names
into whatever naming convention its underlying source requires.
For example, an application option named `foo` could be resolved
from a configuration entry named `FOO_TASTIC`.

Registration order is preserved and determines resolution precedence
among providers. Multiple providers may register the same option.
The first provider to resolve that option takes precedence, and
subsequent providers are asked only for options that remain
unresolved.

`use_options` croaks on:

- an odd number of arguments;
- a provider name that does not match `[a-z][a-z0-9_]*`;
- a duplicate provider name for the class;
- a definition that does not map exactly one role to an option list;
- an option list that is not an array reference.

### Resolution Protocol: `resolve_option_providers`

`resolve_option_providers` is called automatically from `new()` after
command-line parsing and before `init_defaults`. For each registered
provider, in registration order:

1. Options already supplied on the command line or resolved by a
   prior provider are skipped.
2. If the provider's option list is empty, all eligible accessors
   not yet resolved are requested.
3. The optional hook `_${name}_init` is called if the class provides
   it.
4. `_${name}_resolve` is called with the list of unresolved option
   names it should supply.
5. The resolver must return a hash reference. Any key not in the
   requested list causes a croak. Returned values are applied via
   `set()` and marked resolved.

An option is considered resolved when its name exists as a key in the
hash reference returned by the provider. The value itself need not be
defined. Values such as `undef`, `0`, and the empty string are valid
resolved values.

To leave an option unresolved, the provider must omit its key from
the returned hash reference. Subsequent providers may then attempt
to resolve it.

Before invoking a provider's resolver, CLI::Simple determines which
of its registered options remain unresolved. If no eligible options
remain, the provider is skipped entirely.

When unresolved options remain, CLI::Simple invokes the provider's
optional initialization method before calling its resolver. This
allows providers to defer expensive operations, such as opening
database connections or initializing external service clients,
until their values are actually needed.

### Precedence

The resolution order is:

1. Command-line arguments (highest priority)
2. Provider results, in registration order
3. `default_options` from the constructor (lowest priority)

This means a value explicitly supplied by the user on the command line
cannot be overwritten by a provider, and a value supplied by an
earlier-registered provider will not be overwritten by a later one or
by `init_defaults`.

### `init_defaults` Change

`init_defaults` now accepts a `$resolved` hash reference. It skips
any option whose key appears in `$resolved`, preventing
provider-supplied values from being replaced by constructor defaults.
Existing applications that do not register option providers retain
their previous default-option behavior.

---

## Documentation

The POD section previously titled "Not a Framework" has been replaced
with a description of the two supported usage paths: single-module
applications and role-based applications. This better reflects the
current capabilities of the module.

---

## Test Coverage

Two new test files accompany this release:

- `t/07-option-providers.t` — covers `use_options` registration:
  valid and invalid provider names, duplicate detection, odd-argument
  errors, invalid definition structures, and non-array option lists.
- `t/08-option-provider-resolution.t` — covers
  `resolve_option_providers`: provider supplies values for unresolved
  options, command-line options take precedence, a provider returning
  an unrequested option croaks, an empty option list causes all
  eligible accessors to be offered, and the optional `_init` hook is
  called when present.

---

## Build and Release Workflow

- `.includes/publish.mk` has been deleted and replaced by the role
  `.roles/CPAN-Maker-Bootstrapper-Role-PAUSEUpload/`, which provides
  `role.mk` and `role.yml`. PAUSE upload behavior is now delivered as
  a bootstrapper role rather than a standalone make fragment.

---

### Backward Compatibility

Option providers are entirely opt-in. Applications that do not call
`use_options()` retain their existing command-line parsing, accessor
generation, and default-option behavior.

Existing applications do not need to change their option specifications,
command definitions, or initialization methods to use CLI::Simple
2.4.0.

---
