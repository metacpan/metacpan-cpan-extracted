# NAME

CXC::Exporter::Util - Tagged Based Exporting

# VERSION

version 0.13

# SYNOPSIS

In the exporting code:

    package My::Exporter;
    use CXC::Exporter::Util ':constants';

    use parent 'Exporter' # or Exporter::Tiny

    # install sets of constants, with automatically generated
    # enumerating functions
    install_CONSTANTS( {
          DETECTORS => {
              ACIS => 'ACIS',
              HRC  => 'HRC',
          },

          AGGREGATES => {
              ALL  => 'all',
              NONE => 'none',
              ANY  => 'any',
          },
      } );

    # install some functions
    install_EXPORTS(
              { fruit => [ 'tomato', 'apple' ],
                nut   => [ 'almond', 'walnut' ],
              } );

In importing code:

    use My::Exporter   # import ...
     ':fruit',         # the 'fruit' functions
     ':detector',      # the 'detector' functions
     'DETECTORS'       # the function enumerating the DETECTORS constants  values
     'DETECTORS_NAMES' # the function enumerating the DETECTORS constants' names
     ;

    # print the DETECTORS constants' values;
    say $_ for DETECTORS;

    # print the DETECTORS constants' names;
    say $_ for DETECTORS_NAMES;

# DESCRIPTION

`CXC::Exporter::Util` provides _tag-centric_ utilities for modules
which export symbols.  It doesn't provide exporting services; its sole
purpose is to manipulate the data structures used by exporting modules
which follow the API provided by Perl's core [Exporter](https://metacpan.org/pod/Exporter) module
(e.g. [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny)).

In particular, it treats `%EXPORT_TAGS` as the definitive source for
information about exportable symbols and uses it to generate
`@EXPORT_OK` and `@EXPORT`.  Consolidation of symbol information in
one place avoids errors of omission.

## Exporting Symbols

At it simplest, the exporting module calls ["install\_EXPORTS"](#install_exports) with a
hash specifying tags and their symbols sets, e.g.,

    package My::Exporter;
    use CXC::Exporter::Util;

    use parent 'Exporter'; # or your favorite compatible exporter

    install_EXPORTS(
              { fruit => [ 'tomato', 'apple' ],
                nut   => [ 'almond', 'walnut' ],
              } );

    sub tomato {...}
    sub apple  {...}
    sub almond {...}
    sub walnut {...}

An importing module could use this via

    use My::ExportingModule ':fruit'; # import tomato, apple
    use My::ExportingModule ':nut';   # import almond, walnut
    use My::ExportingModule ':all';   # import tomato, apple,
                                      #        almond, walnut,

For more complicated setups, `%EXPORT_TAGS` may be specified first:

    package My::ExportingModule;
    use CXC::Exporter::Util;

    use parent 'Exporter';
    our %EXPORT_TAGS = ( tag => [ 'Symbol1', 'Symbol2' ] );
    install_EXPORTS;

`install_EXPORTS` may be called multiple times

## Exporting Constants

`CXC::Exporter::Util` provides additional support for creating,
organizing and installing constants via ["install\_CONSTANTS"](#install_constants).
Constants are created via Perl's [constant](https://metacpan.org/pod/constant) pragma.

["install\_CONSTANTS"](#install_constants) is passed sets of constants grouped by tags,
e.g.:

    use CXC::Export::Util ':constants';

    install_CONSTANTS( {
          DETECTORS => {
              ACIS => 'ACIS',
              HRC  => 'HRC',
          },

          AGGREGATES => {
              ALL  => 'all',
              NONE => 'none',
              ANY  => 'any',
          },
     });

     # A call to install_EXPORTS (with or without arguments) must follow
     # install_CONSTANTS;
     install_EXPORTS;

This results in the definition of

- the constant functions, i.e.,

        ACIS HRC ALL NONE ANY

    returning their specified values,

- functions enumerating the constants' values, i.e.

        DETECTORS -> ( 'ACIS', 'HRC' )
        AGGGREGATES -> ( 'all', 'none', 'any' )

- functions enumerating the constants' names, i.e.

        DETECTORS_NAMES -> ( 'ACIS', 'HRC' )
        AGGGREGATES_NAMES -> ( 'ALL', 'NONE', 'ANY' )

The enumerating functions are useful for generating enumerated types
via e.g. [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny):

    Enum[ DETECTORS ]

or iterating:

    say $_ for DETECTORS;

`install_CONSTANTS` may be called multiple times. If the constants
are used later in the module for other purposes, constant definition
should be done in a [BEGIN](https://metacpan.org/pod/BEGIN) block:

    BEGIN {
        install_CONSTANTS( {
            CCD => {nCCDColumns  => 1024, minCCDColumn => 0,},
        } );
    }

    install_CONSTANTS( {
        CCD => {
            maxCCDColumn => minCCDColumn + nCCDColumns - 1,
        } }
    );

    install_EXPORTS;

For more complex situations, the lower level ["install\_constant\_tag"](#install_constant_tag)
and ["install\_constant\_func"](#install_constant_func) routines may be useful.

## UI Helpers

_Note_: These subroutines are available only if [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny) is
installed.

The UI Helper routines make it easier to expose constants' names to
users and convert them to constant values.  For example, say the
constants are for colors,

    install_CONSTANTS( { COLORS =>
                           { RED => 0xFF0000, YELLOW_GREEN => 0x00FFFF } } );

and the application provides a `--color` command line option.  The
application can accept lower-case, user-friendly representations of the
constant names and convert them back to constant values.

Each helper takes the constant tag name (as used by
["install\_CONSTANTS"](#install_constants) or ["install\_constant\_tag"](#install_constant_tag)) and an optional
`$prefix`, which strips a common literal constant-name prefix before
aliases are generated. For example, with a prefix of `COLOR`,
`COLOR_YELLOW_GREEN` is exposed as `yellow_green` and
`yellow-green`.

["ui\_list\_constants"](#ui_list_constants) returns a list of accepted human-friendly aliases
for the constants' names.

The UI can use these to provide the user with values for `--color`, e.g.

    if ( $opt{color} eq '-list' ) {
      say join( "\n", ui_list_constants( 'colors' ) );
      exit (0);
    }

or as parameters for [Type::Tiny::Enum](https://metacpan.org/pod/Type%3A%3ATiny%3A%3AEnum).

["ui\_coerce\_constant"](#ui_coerce_constant) and ["ui\_assert\_coerce\_constant"](#ui_assert_coerce_constant) match the
passed constant name alias to the constant value.  They differ in that
["ui\_coerce\_constant"](#ui_coerce_constant) returns the original passed name if there is
no match, while ["ui\_assert\_coerce\_constant"](#ui_assert_coerce_constant) throws an exception.

To make these helpers available to users of a constants module, import
the `ui_helpers` tag from `CXC::Exporter::Util` into that module:

    package My::Constants;
    use parent 'Exporter::Tiny';
    use CXC::Exporter::Util ':constants', ':ui_helpers';

    install_CONSTANTS( { COLORS =>
                           { RED => 0xFF0000, YELLOW_GREEN => 0x00FFFF } } );
    install_EXPORTS;

This adds a `ui_helpers` export tag to `My::Constants`.  Users of
`My::Constants` may then import all of the UI helpers with

    use My::Constants ':ui_helpers';

or import them individually.

# SUBROUTINES

## install\_EXPORTS

    install_EXPORTS( [\%export_tags], [$package], [\%options]  );

Populate `$package`'s `@EXPORT` and `@EXPORT_OK` arrays based upon
`%EXPORT_TAGS` and `%export_tags`.

If not specified,  `$package` defaults to the caller's package.

Available Options:

- overwrite => \[Boolean\]

    If the `overwrite` option is true, the contents of `%export_tags`
    will overwrite `%EXPORT_TAGS` in `$package`, otherwise
    `%export_tags` is merged into `%EXPORT_TAGS`.

    Note that overwriting will remove the tags and symbols installed into
    `%EXPORT_TAGS` by previous calls to ["install\_CONSTANTS"](#install_constants).

    This defaults to false.

- package => \[Package Name\]

    This provides another means of indicating which package to install into.
    Setting this overrides the optional `$package` argument.

- all => \[Boolean | 'auto' \]

    This determines whether ["install\_EXPORTS"](#install_exports) creates an `all` tag
    based on the contents of `%EXPORT_TAGS` in `$package`.  Some exporters, such as
    [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny) and [Sub::Exporter](https://metacpan.org/pod/Sub%3A%3AExporter) automatically handle the `all`
    tag, but Perl's default [Exporter](https://metacpan.org/pod/Exporter) does not.

    If set to `auto` (the default), it will install the `all` tag if
    `$package` is _not_ a subclass of [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny).

    (At present I don't know how to determine if [Sub::Exporter](https://metacpan.org/pod/Sub%3A%3AExporter) is used).

This routine does the following in `$package` based upon
the contents of `$package`'s `%EXPORT_TAGS` hash:

- Copy the symbol names in  `$EXPORT_TAGS{default}` into `@EXPORT`.
- Copy the symbol names in all of `%EXPORT_TAGS` into `@EXPORT_OK`.
- Create an `all` tag which includes all of the symbols in
`%EXPORT_TAGS`.
- Create a `ui_helper` tag if requested (See ["UI Helpers"](#ui-helpers)).

## install\_CONSTANTS

    install_CONSTANTS( @specs, ?$package  );

Create sets of constants and make them available for export in
`$package`.

If not specified,  `$package` defaults to the caller's package.

The passed `@specs` arguments are either hashrefs or arrayrefs and
contain one or more set specifications.  A set specification
consists of a unique identifier and a list of name-value pairs,
specified either as a hash or an array.  For example,

    @spec = ( { $id1 => \%set1, $id2 => \@set2 },
              [ $id3 => \%set3, $id4 => \@set4 ],
            );

The identifier is used to create an export tag for the set, as
well as to name enumerating functions returning constant's names and values.
The individual `$id`, `$set` pairs are passed to ["install\_constant\_tag"](#install_constant_tag);
see that function for more information on how the identifiers are used.

A call to ["install\_EXPORTS"](#install_exports) _must_ be made after the last call to
`install_CONSTANTS` or

- The constants won't be added to the exports.
- The enumerating functions won't be created.

["install\_CONSTANTS"](#install_constants) may be called more than once to add symbols to a tag,
but don't split those calls across a call to ["install\_EXPORTS"](#install_exports).

In other words,

    # DON'T DO THIS, IT'LL THROW
    install_CONSTANTS( { Foo => { bar => 1 } } );
    install_EXPORTS;
    install_CONSTANTS( { Foo => { baz => 1 } } );
    install_EXPORTS;

    # DO THIS
    install_CONSTANTS( { Foo => { bar => 1 } } );
    install_CONSTANTS( { Foo => { baz => 1 } } );
    install_EXPORTS;

Each call to ["install\_EXPORTS"](#install_exports) installs the enumerating functions for
sets modified since the last call to it, and each enumerating function
can only be added once.

## install\_constant\_tag

Create and install constant functions for a set of constants.  Called either
as

- install\_constant\_tag( \\@names, $constants, \[$package\] )

    where **@names** contains

        $tag,
        $fn_values, # optional name of function returning constants' values
        $fn_names,  # optional name of function returning constants' names

    and, if not specified,

        $fn_values //= uc($tag);
        $fn_names //= $fn_values . '_NAMES';

- install\_constant\_tag( $fn\_values, $constants, \[$package\] )

    where

        $tag = lc($fn_values);
        $fn_names = $fn_values . '_NAMES';

where

- **$tag**

    is the name of the tag representing the set of constants

- `$fn_values`

    is the name of the function which will return a list of the constants' values

- `$fn_names`

    is the name of the function which will return a list of the constants' names

- `$constants`

    specifies the constants' names and values, as
    either a hashref or an arrayref containing _name_ - _value_ pairs.

- `$package`

    is the name of the package (the eventual exporter) into
    which the constants will be installed. It defaults to the package of
    the caller.

["install\_constant\_tag"](#install_constant_tag) will

1. use Perl's [constant](https://metacpan.org/pod/constant) pragma to create a function named _name_
returning _value_ for each _name_-_value_ pair in `$constants`.

    The functions are installed in `$package` and their names appended to
    the symbols in `%EXPORT_TAGS` with export tag `$tag`.  If `$constants`
    is an arrayref they are appended in the ordered specified in the array,
    otherwise they are appended in random order.

2. Add a hook so that the next time ["install\_EXPORTS"](#install_exports) is called, Perl's
[constant](https://metacpan.org/pod/constant) pragma will be used to create

    - an enumerating function named `$fn_values` which returns a list of
    the _values_ of the constants associated with `$tag`, in the order
    they were added to `$EXPORT_TAGS{$tag}`.
    - an enumerating function named `$fn_names` which returns a list of
    the _names_ of the constants associated with `$tag`, in the order
    they were added to `$EXPORT_TAGS{$tag}`.

    These enumerating functions are added to the symbols in
    `%EXPORT_TAGS` tagged with `contant_funcs`.

    Just as you shouldn't interleave calls to ["install\_CONSTANTS"](#install_constants) for a
    single tag with calls to ["install\_EXPORTS"](#install_exports), don't interleave calls
    to ["install\_constant\_tag"](#install_constant_tag) with calls to ["install\_EXPORTS"](#install_exports).

For example, after

    $id = 'AGGREGATES';
    $constants = { ALL => 'all', NONE => 'none', ANY => 'any' };
    install_constant_tag( $id, $constants );
    install_EXPORTS:

1. The constant functions, `ALL`, `NONE`, `ANY` will be created and
installed in the calling package.

    A new element will be added to `%EXPORT_TAGS` with an export tag of `aggregates`.

        $EXPORT_TAGS{aggregates} = [ 'ALL', 'NONE', 'ANY ];

2. A function named `AGGREGATES` will be created and installed in the
calling package. `AGGREGATES` will return the values

        'all', 'none', 'any'

    (in a random order, as `$constants` is a hashref).

    `AGGREGATES` will be added to the symbols tagged by `constant_funcs` in `%EXPORT_TAGS`

3. A function named `AGGREGATES_NAMES` will be created and installed in the
calling package. `AGGREGATES_NAMES` will return the values

        'ALL', 'NONE', 'ANY'

    (in a random order, as `$constants` is a hashref).

    `AGGREGATES_NAMES` will be added to the symbols tagged by `constant_name_funcs` in `%EXPORT_TAGS`

After this, a package importing from `$package` can

- import the constant functions `ALL`, `NONE`, `ANY` via the `aggregate` tag:

        use Package ':aggregate';

- import the enumerating function `AGGREGATES` directly, via

        use Package 'AGGREGATES';

- import `AGGREGATES` via the `constant_funcs` tag:

        use Package ':constant_funcs';

As mentioned above, if the first argument to ["install\_constant\_tag"](#install_constant_tag) is an
arrayref, `$tag`, `$fn_values`, and `$fn_names` may be specified directly. For example,

    $id = [ 'Critters', 'Animals', 'Animal_names' ];
    $constants = { HORSE => 'horse', GOAT   => 'goat' };
    install_constant_tag( $id, $constants );

will create the export tag `Critters` for the `GOAT` and `HORSE`
constant functions, an enumerating function called `Animals` returning

    ( 'horse', 'goat' )

and  a function called `Animal_names` returning

    ( 'HORSE', 'GOAT')

`install_constant_tag` uses ["install\_constant\_func"](#install_constant_func) to create and install
the constant functions which return the constant values.

Because of when enumerating functions are created, all enumerating functions
associated with a set will return all of the set's values, regardless of when
the function was specified.  For example,

    install_constant_tag( 'TAG', { HIGH => 'high' }  );
    install_constant_tag( [ 'TAG', 'ATAG' ], { LOW => 'low' } );

will create functions `TAG` and `ATAG` which both return `high`, `low`.

## install\_constant\_func( $name, \\@values, $caller )

This routine does the following in `$package`, which defaults to the
caller's package.

1. Create a constant subroutine named `$name` which returns `@values`;
2. Adds `$name` to the `constant_funcs` tag in `%EXPORT_TAGS`.

For example, after calling

    install_constant_func( 'AGGREGATES', [ 'all', 'none', 'any' ]  );

1. The function `AGGREGATES` will return `all`, `none`, `any`.
2. A package importing from `$package` can import the `AGGREGATE`
constant function via the `constant_funcs` tag:

        use Package ':constant_funcs';

    or directly

        use Package 'AGGREGATES';

## ui\_list\_constants

    @names = ui_list_constants( $tag, ?$prefix );

Returns a list of accepted names for the constants with the given
`$tag`.  These names are lower-case alternatives with underscores
preserved and with underscores translated to hyphens.  The optional
`$prefix` strips a common literal constant-name prefix before aliases
are generated.

## ui\_coerce\_constant

    $value = ui_coerce_constant( $name, $tag, ?$prefix );

Maps an accepted constant name alias (see ["ui\_list\_constants"](#ui_list_constants)) to
the constant's value, returning unknown values unchanged.

## ui\_assert\_coerce\_constant

    $value = ui_assert_coerce_constant( $name, $tag, ?$prefix );

Performs the same coercion as ["ui\_coerce\_constant"](#ui_coerce_constant), but throws an
exception for unknown values.

# EXPORTS

**CXC::Exporter::Util** supports the following export tags

- all _DEPRECATED_

        install_EXPORTS
        install_CONSTANTS
        install_constant_tag
        install_constant_func

    Use of the `all` tag is deprecated. Due to backwards compatibility
    issues, it does not actually import all of **CXC::Exporter::Util**'s
    symbols.  Use the other tags instead.

- default, exports

        install_EXPORTS

    These are synonymous:

        use CXC::Exporter::Util;
        use CXC::Exporter::Util ':default';
        use CXC::Exporter::Util ':exports';

- constants

        install_EXPORTS
        install_CONSTANTS

- utils

        install_constant_tag
        install_constant_func

- ui\_helpers

        ui_list_constants
        ui_coerce_constant
        ui_assert_coerce_constant

# BUGS AND INCOMPATIBILITIES

- No attempt is made to complain if enumerating functions' names clash
with constant function names.
- [namespace::clean](https://metacpan.org/pod/namespace%3A%3Aclean)

    The ["UI Helpers"](#ui-helpers) routines are exported into your module, and are
    made available for import by users of your module when they request
    them directly or via the `ui_helpers` tag.

    When your module uses [namespace::clean](https://metacpan.org/pod/namespace%3A%3Aclean), it's important not to scrub
    the UI helpers from your module's namespace.  For example,

        package Broken {
          use parent 'Exporter::Tiny';
          use CXC::Exporter::Util ':constants', ':ui_helpers';
          use namespace::clean;
          ...
        }

        package Use::Broken {
          use Foo ':ui_helpers';
        }

    will fail because the UI helpers have been removed from `Broken`'s
    namespace, while this works:

        package Working {
          use parent 'Exporter::Tiny';
          use CXC::Exporter::Util ':constants';
          use namespace::clean;
          use CXC::Exporter::Util ':ui_helpers';

          ...
        }

        package Use::Working {
          use Foo ':ui_helpers';
        }

# EXAMPLES

- Alternate constant generation modules.

    To use an alternate constant generation function bypass
    ["install\_CONSTANTS"](#install_constants) and load things manually.

    For example,  using [enum](https://metacpan.org/pod/enum):

        package My::Exporter;

        use CXC::Exporter::Util ':all';

        our @DaysOfWeek;
        BEGIN{ @DaysOfWeek = qw( Sun Mon Tue Wed Thu Fri Sat ) }
        use enum @DaysOfWeek;
        use constant DaysOfWeek => map { &$_ } @DaysOfWeek;
        install_EXPORTS( { days_of_week => \@DaysOfWeek,
                           constant_funcs => [ 'DaysOfWeek' ],
                          });

    and then

        use My::Exporter -days_of_week;

        say Sun | Mon;

- Using a constant in the exporting module

    When a constant is used in an exporting module (to create another constant, for example),
    it's tempting to do something like this:

        # DON'T DO THIS
        %CCD = ( minCCDColumn => 0, nCCDColumns = 1024 );
        $CCD{maxCCDColumn} = $CCD{minCCDColumn} + $CCD{nCCDColumns} - 1;
        install_CONSTANTS( { CCD => \%CCD } );
        install_EXPORTS;

    Not only is this noisy code, if the hash keys are mistyped, there's an
    error, which is exactly what constants are supposed to avoid.

    Instead, create an initial set of constants in a BEGIN block, which
    will make them available for the rest of the code:

        BEGIN {
            install_CONSTANTS( {
                CCD => {nCCDColumns  => 1024, minCCDColumn => 0,},
            } );
        }

        install_CONSTANTS( {
            CCD => {
                maxCCDColumn => minCCDColumn + nCCDColumns - 1,
            } }
        );

        install_EXPORTS;

    A bit more verbose, but it uses the generated constant functions and
    avoids errors.

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-cxc-exporter-util@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Exporter-Util](https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Exporter-Util)

## Source

Source is available at

    https://codeberg.org/CXC-Optics/p5-CXC-Exporter-Util

and may be cloned from

    https://codeberg.org/CXC-Optics/p5-CXC-Exporter-Util.git

# SEE ALSO

Please see those modules/websites for more information related to this module.

- [Exporter](https://metacpan.org/pod/Exporter)
- [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny)
- [Exporter::Almighty](https://metacpan.org/pod/Exporter%3A%3AAlmighty)

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
