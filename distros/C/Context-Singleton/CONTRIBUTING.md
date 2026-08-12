
# Coding style

Some rules I found improves efficiency of code base maintenace I'm able
to write down.

## Indentation

### Indent with tabs

Indentation is a value without unit. It's up to developer to setup their
environment as they like - most of current editors allows you to configure
tab width.

### Align with spaces

Tabs are allowed only at the beginning of line.

## Naming

### DoNotUseCamelCaseNeitherForModuleNames

### Express intention not implementation

### Use common leading verbs to signal trait of function/method

#### arrange

Prepare test case context.

Related: expect

#### build

Create entity for internal use (eg: property builder).

#### create

Create entity for external use (such function is exposed as public API)

#### ensure

Verify named state

#### establish

Search for an instance or create new one when it doesn't exist yet.

Related: find, search

#### exclude

Transform source so provided data are excluded.
(behaves like `grep false`

Related: include

#### expect

Build expectation describing tested test case result.

Related: arrange

#### find

Search for an instance or throw an exception instead of reaturning
empty result.

Related: establish, search

#### filter

Do not use.

Related: include, exclude

#### get

Do not use for any method except those related to external domains
providing GET entrypoint (eg: HTTP request)

#### include

Transform source so only provided data are included
(behaves like `grep true`

Related: exclude

#### search

Read as: _try to find_

Search for an instance or return empty result (or undef)

# AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

# COPYRIGHT AND LICENSE

This file is part of L<Context::Singleton> distribution.
