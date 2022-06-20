---
title: Defining commands hierarchy
layout: default
---

# Defining commands hierarchy

The hierarchy in [App::Easer][] is defined with pointers *from parent to
children*, not the other way around. This might seem *more complicated*
than it should be, but it's a precise design decision:

- any hierarchy error can be solved with a single configuration before
  shipping the application ("develop time");
- this arrangement makes it easier to only load and parse what's
  strictly needed ("run time").

Doing the other way around (i.e. children pointing back to parents)
would require to analyze the whole command hierarchy to figure out the
relationships, although for each invocation only one specific path in
the tree is needed. This makes the whole system less efficient at
runtime, in the face of an easier develop-time interface that can be
easily addressed.

## Explicit children

The key `children` in a (sub-)command specification allows listing the
*children* of that (sub-)command in a reference to an array:

```perl
my $app = {
    commands => {
        MAIN => {
            children => [qw< foo bar >],
            ...
        },
        foo => {
            children => [qw< baz >],
            ...
        },
        bar => {
            children => 0,
            ...
        }
    }
};
```

In the example above:

- the *main* command at the higher level has two explicit sub-commands
  `foo` and `bar`;
- sub-command `foo` has one explicit sub-sub-command `baz`;
- sub-command `bar` has no explicit sub-sub-commands.

We stress the word **explicit** because, depending on the configuration,
there might be *implicit* children sub-commands added to each of them
(see [Implicit children](#implicit-children)).

By default, the strings in the array must be the same as the keys in the
`commands` sub-hash. See section [Specification from
module](#specification-from-module) for alternatives.

## Naming commands

The names of the children in the `children` array are conventional and
only refer to the key in the `commands` hash. In the following example,
the *externally visible* command is `foo`, not `the command foo, yay!`,
while this latter string is only used for internally resolving the
relationship between this command and its parent `MAIN`:

```perl
my $app = {
    commands => {
        MAIN => {
            children => ['the command foo, yay!'], # internal resolution
            ...
        },
        'the command foo, yay!' => {
            supports => ['foo'],  # externally visible name
            ...
        },
    },
};
```

In particular, `supports` allows putting additional aliases, which can
be handy if shortcuts or other case alternatives are considered useful:

```perl
my $app = {
    commands => {
        'the command foo, yay!' => {
            supports => [qw< foo Foo FOO f >],
            ...
        },
    },
};
```

## Implicit children

In addition to the [Explicit children](#explicit-children),
[App::Easer][] tries to add two child sub-commands by default, i.e.
`help` and `commands`.

While this is a normally desirable behaviour for *intermediate*
commands, it might get in the way for *leaf* commands, especially if
they are supposed to accept additional parameters that might be confused
for children.

For this reason, option `auto-leaves` *disables* the generation of these
implicit sub-commands when no other child is present (i.e. the command
is a *leaf* from an *explicit* point of view). This option `auto-leaves`
is set by default as of version `0.007002` but it can be turned off
explicitly.

Beyond the value of `auto-leaves`, it is also possible to explicitly
mark a command as a leaf by setting the boolean option `leaf`:

```perl
my $app = {
    commands => {
        MAIN => { ... },
        foo => {
            leaf => 1,
            ...
        },
    },
};
```

This will disable the generation of implicit children too.

Note that this *does not* mean that there's no `help` or `commands`
available for leaves, just that they are not sub-commands. In other
terms, if sub-command `whatever` is a leaf command, these would work as
expected:

```
shell$ myapp help whatever
...

shell$ myapp commands whatever
...
```

It is possible to disable the generation of part of all of these
automatic children `help` and `commands`:

- setting option `auto-children` (at the highest `configuration` level)
  to a false value (it is set to a true value by default). This option
  is actually more than a purely boolean one, though: it is also
  possible to set it to a list of sub-commands (inside an array
  reference) that will be added to all commands that would normally get
  `help` and `commands` (thus acting as an *allow list*);
- setting option 'no-auto' (at the command level) to the `*` string or
  pointing to an anonymous array of string, each representing an
  automatic child to *remove* (acting as a *deny list*).

Example:

```perl
my $app = {
    configuration => {
        'auto-children' => ['help'], # don't bother with "commands"
        ...
    },
    commands => {
        MAIN => {
            children => [qw< foo bar commands >], # well... actually...
        },
        foo => {
            'no-auto' => '*',
            ...
        },
        bar => {
            'no-auto' => ['help'],
            ...
        }
    },
};
```

In this example:

- the only automatically added child command is `help` (via option
  `auto-children`);
- the `MAIN` command gets the `commands` sub-command too, although
  explicitly and not implicitly;
- the `foo` command gets nothing, because `no-auto` filters out *every*
  implicitly generated sub-command;
- the `bar` command gets nothing as well, because its `no-auto` filters
  out the `help` command, which is also the only one that is set.

## Specification from module

By default, all specifications for (sub-)commands are supposed to be
contained in the input hash/JSON specification for the whole
application. It is possible, though, to put the specification of one or
more sub-commands inside a different module, to keep the specification
and the implementation close to each other, setting the configuration
`specfetch` to `+SpecFromHashOrModule`:

```perl
my $app = {
    configuration => { specfetch => '+SpecFromHashOrModule' },
    commands => {
        MAIN => {
            children => [qw< MyApp::Foo MyApp::Bar#specification baz  >],
            ...
        },
        baz => { ... },
    }
};
```

In the example above:

- commands `MAIN` and `baz` are defined directly in the hash, like it
  happens by default;
- the definition for sub-command `MyApp::Foo` can be found in module
  `MyApp::Foo`, calling its function `spec` that is supposed to return a
  hash reference with the specification of the command. The name `spec`
  is a default, conventional value;
- the definition for sub-command `MyApp::Bar#specification` can be found
  in module `MyApp::Bar`, calling its function `specification`. In this
  case we have an explicit indication of which function should be called
  to get the hash reference with the sub-command specification.

When `specfetch` is set to `+SpecFromHashOrModule`, the child name is
expanded as described above only if the specific string is missing as a
key inside the `commands` sub hash. In other terms, in the following
example no external module will be loaded to figure out the
specification for child `Some::Foo#whatever`, because the specification
is already available in `commands`:

```perl
my $app = {
    configuration => { specfetch => '+SpecFromHashOrModule' },
    commands => {
        MAIN => {
            children => [qw< Some::Foo#whatever  >],
            ...
        },
        'Some::Foo#whatever' => { ... },
    }
};
```

It might be even adviseable to use this name structure, actually: it
allows starting with a compact application definition, while allowing
for an easy split at a later time if this is the main goal.

## Dispatch: vague relationships

[App::Easer][] supports providing an *executable* associated to key
`dispatch`, in order to completely override the child search mechanism:

```perl
my $app = {
    commands => {
        MAIN => {
            children => [qw< foo bar baz >],
            dispatch => \&random_child,
            ...
        },
        foo => { ... },
        bar => { ... },
        baz => { ... },
    },
};

# ...

sub random_child ($app, $spec, $args) {
    my @children = $spec->{chidren}->@*;
    return $children[rand @children];
}
```

The example above is a bit crude but shows that the
`dispatch`-associated function is supposed to return the name of a
command. The example uses `children` to choose from, but it can actually
be any valid command:

```perl
my $app = {
    commands => {
        MAIN => {
            children => [qw< bar baz >],
            dispatch => sub { return 'foo' }, # not a child, but OK!
            ...
        },
        foo => { ... },
        bar => { ... },
        baz => { ... },
    },
};
```

It is possible for `dispatch` to return `undef`. In this case, no other
command will be selected, but the (intermediate) command's own `execute`
slot will be considered instead, as a form of *auto-dispatching*.

If option `dispatch` is actually needed... this is probably a failure in
[App::Easer][]'s model.

## Marking a favourite child

It's not fair of parents to have preferences, but sub-commands don't
bother and parent commands can indeed have a preference.

As an example, an intermediate command `sql` might have two
sub-commands `select` and `delete`:


```
$ myapp sql select foo bar and baz

$ myapp sql delete baz
```

If command `select` is the mostly used one, it might be interesting to
just skip writing it completely, with the following interface:

```
# alias for myapp sql select foo bar and baz
$ myapp sql foo bar and baz
```

This is possible by marking a *fallback* child, in case the search for a
child does not produce a result. It's possible to specify a *fallback*
in several ways:

- `fallback-to`: sets the name of the child directly;
- `fallback-to-default`: sets the name of the child to be the same as
  `default-child`;
- `fallback`: points to an *executable* that allows getting back the
  name of a *fallback* child.

In the latter case, the signature of the executable is as follows:

```perl
sub my_fallback ($app, $spec, $args) { ... }
```

where:

- `$app` is the global object tracking the application;
- `$spec` is the specification of the command;
- `$args` are command-line arguments.

The configuratio built so far from parents are all available in array
`$app->{configs}`; `$app->{configs}[-1]` is the one from the command
itself, which will be the parent of the command that is returned.

It is possible for `fallback-to` and `fallback` to return `undef`. In
this case, no child will be selected, but the (intermediate) command's
own `execute` slot will be considered instead, as a form of
*auto-dispatching*.


## Marking a default child

When an intermediate command is called without additional command-line
arguments... it's usually a strange situation, at least if intermediate
commands are supposed to be *intermediate-only*.

To cope with this possibility, [App::Easer][] allows setting
`default-child`, either at the higher `configuration` level, or inside a
single command's specification.

By default, the string `help` will be considered, pointing to the
associated sub-command. This means that invoking an intermediate command
will, by default, print the help for that intermediate command.

[App::Easer]: https://metacpan.org/pod/App::Easer
[Installing Perl Modules]: https://github.polettix.it/ETOOBUSY/2020/01/04/installing-perl-modules/
[Perl]: https://www.perl.org/
[App::FatPacker]: https://metacpan.org/pod/App::FatPacker
[latest]: https://raw.githubusercontent.com/polettix/App-Easer/main/lib/App/Easer.pm
[download]: {{ '/assets/template.pl' | prepend: site.baseurl }}
