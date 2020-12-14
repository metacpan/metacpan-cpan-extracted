# NAME

Const::Exporter - Declare constants for export.

# VERSION

version v1.0.0

# SYNOPSIS

Define a constants module:

```perl
package MyApp::Constants;

our $zoo => 1234;

use Const::Exporter

   tag_a => [                  # use MyApp::Constants /:tag_a/;
      'foo'  => 1,             # exports "foo"
      '$bar' => 2,             # exports "$bar"
      '@baz' => [qw/ a b c /], # exports "@baz"
      '%bo'  => { a => 1 },    # exports "%bo"
   ],

   tag_b => [                  # use MyApp::Constants /:tag_b/;
      'foo',                   # exports "foo" (same as from ":tag_a")
      '$zoo',                  # exports "$zoo" (as defined above)
   ];

# `use Const::Exporter` can be specified multiple times

use Const::Exporter

   tag_b => [                 # we can add symbols to ":tab_b"
      'moo' => $bar,          # exports "moo" (same value as "$bar")
   ],

   enums => [

     [qw/ goo gab gub /] => 0, # exports enumerated symbols, from 0..2

   ],

   default => [qw/ foo $bar /]; # exported by default
```

and use that module:

```perl
package MyApp;

use MyApp::Constants qw/ $zoo :tag_a /;

...
```

## Dynamically Creating Constants

You may also import a predefined hash of constants for exporting dynamically:

```perl
use Const::Exporter;

my %myconstants = (
       'foo'  => 1,
       '$bar' => 2,
       '@baz' => [qw/ a b c /],
       '%bo'  => { a => 1 },
);

# ... do stuff

Const::Exporter->import(
     constants => [%myconstants],        # define constants for exporting
     default   => [ keys %myconstants ], # export everything in %myconstants by default
);
```

# DESCRIPTION

This module allows you to declare constants that can be exported to
other modules.

To declare constants, simply group then into export tags:

```perl
package MyApp::Constants;

use Const::Exporter

  tag_a => [
     'foo' => 1,
     'bar' => 2,
  ],

  tag_b => [
     'baz' => 3,
     'bar',
  ],

  default => [
     'foo',
  ];
```

Constants in the `default` tag are exported by default (that is, they
are added to the `@EXPORTS` array).

When a constant is already defined in a previous tag, then no value is
specified for it. (For example, `bar` in `tab_b` above.)  If you do
give a value, [Const::Exporter](https://metacpan.org/pod/Const::Exporter) will assume it's another symbol.

Your module can include multiple calls to `use Const::Exporter`, so
that you can reference constants in other expressions, e.g.

```perl
use Const::Exporter

  tag => [
      '$zero' => 0,
  ];

use Const::Exporter

  tag => [
      '$one' => 1 + $zero,
  ];
```

or even something more complex:

```perl
use Const::Exporter

   http_ports => [
      'HTTP'     => 80,
      'HTTP_ALT' => 8080,
      'HTTPS'    => 443,
   ];

use Const::Exporter

   http_ports => [
      '@HTTP_PORTS' => [ HTTP, HTTP_ALT, HTTPS ],
   ];
```

Constants can include traditional [constant](https://metacpan.org/pod/constant) symbols, as well as
scalars, arrays or hashes.

Constants can include values defined elsewhere in the code, e.g.

```perl
our $foo;

BEGIN {
   $foo = calculate_value_for_constant();
}

use Const::Exporter

  tag => [ '$foo' ];
```

Note that this will make the symbol read-only. You don't need to
explicitly declare it as such.

Enumerated constants are also supported:

```perl
use Const::Exporter

  tag => [

    [qw/ foo bar baz /] => 1,

  ];
```

will define the symbols `foo` (1), `bar` (2) and `baz` (3).

You can also specify a list of numbers, if you want to skip values:

```perl
use Const::Exporter

  tag => [

    [qw/ foo bar baz /] => [1, 4],

  ];
```

will define the symbols `foo` (1), `bar` (4) and `baz` (5).

You can even specify string values:

```perl
use Const::Exporter

  tag => [

    [qw/ foo bar baz /] => [qw/ feh meh neh /],

  ];
```

however, this is equivalent to

```perl
use Const::Exporter

  tag => [
    'foo' => 'feh',
    'bar' => 'meh',
    'baz' => 'neh',
  ];
```

Objects are also supported,

```perl
use Const::Exporter

 tag => [
   '$foo' => Something->new( 123 ),
 ];
```

## Mixing POD with Tags

The following code is a syntax error, at least with some versions of
Perl:

```perl
use Const::Exporter

=head2 a

=cut

  a => [ foo => 1 ],

=head2 b

=cut

  b => [ bar => 2 ];
```

If you want to mix POD with your declarations, use multiple use lines,
e.g.

```perl
=head2 a

=cut

use Const::Exporter
  a => [ foo => 1 ];

=head2 b

=cut

use Const::Exporter
  b => [ bar => 2 ];
```

## Export Tags

By default, all symbols are exportable (in `@EXPORT_OK`.)

The `:default` tag is the same as not specifying any exports.

The `:all` tag exports all symbols.

# KNOWN ISSUES

## Support for older Perl versions

This module requires Perl v5.10 or newer.

Pull requests to support older versions of Perl are welcome. See
["SOURCE"](#source).

## Exporting Functions

[Const::Exporter](https://metacpan.org/pod/Const::Exporter) is not intended for use with modules that also
export functions.

There are workarounds that you can use, such as getting
[Const::Exporter](https://metacpan.org/pod/Const::Exporter) to export your functions, or munging `@EXPORT`
etc. separately, but these are not supported and changes in the
future my break our code.

# SEE ALSO

See [Exporter](https://metacpan.org/pod/Exporter) for a discussion of export tags.

## Similar Modules

- [Exporter::Constants](https://metacpan.org/pod/Exporter::Constants)

    This module only allows you to declare function symbol constants, akin
    to the [constant](https://metacpan.org/pod/constant) module, without tags.

- [Constant::Exporter](https://metacpan.org/pod/Constant::Exporter)

    This module only allows you to declare function symbol constants, akin
    to the [constant](https://metacpan.org/pod/constant) module, although you can specify tags.

- [Constant::Export::Lazy](https://metacpan.org/pod/Constant::Export::Lazy)

    This module only allows you to declare function symbol constants, akin
    to the [constant](https://metacpan.org/pod/constant) module by defining functions that are only called
    as needed.  The interface is rather complex.

- [Const::Fast::Exporter](https://metacpan.org/pod/Const::Fast::Exporter)

    This module will export all constants declared in the package's
    namespace.

# SOURCE

The development version is on github at [https://github.com/robrwo/Const-Exporter](https://github.com/robrwo/Const-Exporter)
and may be cloned from [git://github.com/robrwo/Const-Exporter.git](git://github.com/robrwo/Const-Exporter.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Const-Exporter/issues](https://github.com/robrwo/Const-Exporter/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTOR

B. Estrade <estrabd@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
