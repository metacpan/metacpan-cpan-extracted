# NAME

CXC::Data::Visitor - Invoke a callback on every element at every level of a data structure.

# VERSION

version 0.12

# SYNOPSIS

    use CXC::Data::Visitor 'visit', 'RESULT_CONTINUE';
    
    my %root = (
        fruit => {
            berry  => 'purple',
            apples => [ 'fuji', 'macoun' ],
        } );
    
    visit(
        \%root,
        sub ( $kydx, $vref, @ ) {
            $vref->$* = 'blue' if $kydx eq 'berry';
            return RESULT_CONTINUE;
        } );
    
    say $root{fruit}{berry}

results in

    blue

# DESCRIPTION

**CXC::Data::Visitor::visit** performs a depth-first traversal of a data
structure, invoking a provided callback subroutine on elements in the
structure.

## Features

- The type of element passed to the callback (containers, terminal
elements) can be selected.
- The order of traversal at a given depth (i.e. within a container's
elements) may be customized.
- The callback can modify the traversal process.
- The complete path from the structure to an element (both the ancestor
containers and the keys and indexes required to traverse the path) is
available to the callback.
- Cycles are detected upon traversing a container a second time in a
depth first search, and the resultant action may be specified.
- Objects are treated as terminal elements and are not traversed.
- Containers that can be reached multiple times without cycling are visited once per parent.

## Overview

`visit` recursively traverses the container, `$root`, calling the
passed subroutine, `$callback` on each element, `$element`, which
is allowed by the ["visit"](#visit) option.

The traversal is depth-first, e.g. if `$element` is a
container, `$callback` is called on it and then its contents before
processing `$element`'s siblings.

Each container's contents are traversed in sorted order.  For hashes,
this is alphabetical, for arrays, numerical. (This may be
changed with the ["key\_sort"](#key_sort) and ["idx\_sort"](#idx_sort) options).

For example, the default traversal order for the structure in the ["SYNOPSIS"](#synopsis) is

    +-------------------------+-----------------------+-----+
    | path                    | value                 | idx |
    +-------------------------+-----------------------+-----+
    | $root{fruit}            | \$root{fruit}         | 0   |
    | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   |
    | $root{fruit}{apples}[0] | fuji                  | 0   |
    | $root{fruit}{apples}[1] | macoun                | 1   |
    | $root{fruit}{berry}     | purple                | 1   |
    +-------------------------+-----------------------+-----+

Containers that can be reached multiple times without cycling, e.g.

    %hash = ( a => { b => 1 }, );
    $hash{c} = $hash{a};

are visited once per parent, e.g.

    {a}, {a}{b}
    {c}, {c}{b}

`$callback`'s return value indicates how `visit` should proceed (see
["Traversal Directives"](#traversal-directives)).  The simplest directive is to continue
traversal; additional directives abort the traversal,
abort descent into a container, revisit the current container
immediately, revisit a container after its contents are visited,
and other obscure combinations.

# USAGE

`visit` has the following signature:

    ( $completed, $context, $metadata ) = visit( $root, $callback, %options )

The two mandatory arguments are `$root`, a reference to either a
hash or an array, and `$callback`, a reference to a subroutine which
will be invoked on visited elements. By default `$callback` is invoked on
`$root`'s elements, not on `$root` itself; use the ["VISIT\_ROOT"](#visit_root)
flag change this.

- **$completed**  => _Boolean_

    _true_ if all elements were visited, _false_ if
    **$callback** requested a premature return.

- **$context**

    The variable of the same name passed to **$callback**; see the ["context"](#context) option.

- **$metadata** => _hash_

    collected metadata. See ["Metadata"](#metadata).

## Options

`visit` may be passed the following options:

- context _optional_

    Arbitrary data to be passed to ["$callback"](#callback) via the `$context`
    argument. Use it for whatever you'd like.  If not specified, a hash
    will be created.

- cycle => _constant|coderef_

    How cycles within `$root` should be handled.  See ["Cycles"](#cycles).

- visit => _constant_

    Specify elements (by type) which will be passed to `$callback`.  See
    ["Element Filters"](#element-filters)

- key\_sort => _boolean_ | `$coderef`

    The order of keys when traversing hashes.  If _true_ (the default),
    the order is that returned by Perl's `sort` routine.  If _false_,
    it is the order returned that Perl's `keys` routine.

    If a coderef, it is used to sort the keys.  It is called as

        \@sorted_keys = $coderef->( \@unsorted_keys );

- idx\_sort => `$coderef`

    By default array elements are traversed in order of their
    ascending index.  Use ["idx\_sort"](#idx_sort) to specify a subroutine
    which returns them in an alternative order. It is called as

        \@indices = $coderef->( $n );

    where `$n` is the number of elements in the array.

- sort\_keys => _coderef_

    _DEPRECATED_

    An optional coderef which implements a caller specific sort order.  It
    is passed two keys as arguments.  It should return `-1`, `0`, or
    `1` indicating that the sort order of the first argument is less
    than, equal to, or greater than that of the second argument.

- revisit\_limit

    A container may be scanned multiple times during a visit to it.
    This sets the maximum number of times the container is re-scanned
    during a visit before `visit` throws an exception to avoid infinite
    loops.  This limit also applies to ["RESULT\_REVISIT\_ROOT"](#result_revisit_root).

    The defaults is `10`. Set it to `0` to indicate no limit.

## Callback

`visit` invokes `$callback` on selected elements of `$root` (see
["Element Filters"](#element-filters)). `$callback` is invoked as

    $directive = $callback->( $kydx, $vref, $context, \%metadata );

The arguments passed to `$callback` are:

- **$kydx**

    The location (key or index) of the element in its parent
    container. This will be undefined when `$callback` is invoked on
    `$root` (see ["VISIT\_ROOT"](#visit_root)).

- **$vref**

    A reference to the element.  Use **$vref->$\*** to extract or modify
    the element's value.  Do not cache this value; the full path to the
    element is provided via the ["$metadata"](#metadata) argument.

- **$context**

    A reference to data reserved for use by `$callback`. See the
    ["context"](#context) option.

- **$metadata**

    A hash of state information used to keep track of progress. While
    primarily of use by `visit`, some may be of interest to `$callback`.
    See ["Metadata"](#metadata)

## Traversal Directives

["$callback"](#callback) must return a constant (see ["EXPORTS"](#exports))
indicating what `visit` should do next.  Not all constants
are allowed in all contexts in which `$callback` is invoked;
see ["Calling Contexts and Allowed Traversal Directives"](#calling-contexts-and-allowed-traversal-directives).

### Single Directives

- RESULT\_CONTINUE

    Visit the next element in the parent container.

        +-------------------------+-----------------------+-----+
        | path                    | value                 | idx |
        +-------------------------+-----------------------+-----+
        | $root{fruit}            | \$root{fruit}         | 0   |
        | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   |
        | $root{fruit}{apples}[0] | fuji                  | 0   |
        | $root{fruit}{apples}[1] | macoun                | 1   |
        | $root{fruit}{berry}     | purple                | 1   |
        +-------------------------+-----------------------+-----+

- RESULT\_RETURN

    Return immediately to the caller of `visit`.

- RESULT\_STOP\_DESCENT

    If the current element is a hash or array, do not visit its contents,
    and visit the next element in the parent container.

    If the element is not a container, the next element in the container
    will be visited (just as with ["RESULT\_CONTINUE"](#result_continue)).

    For example, If `RESULT_STOP_DESCENT` is returned when
    `$root{fruit}{apples}` is traversed, the traversal would look like
    this:

        +----------------------+-----------------------+-----+
        | path                 | value                 | idx |
        +----------------------+-----------------------+-----+
        | $root{fruit}         | \$root{fruit}         | 0   |
        | $root{fruit}{apples} | \$root{fruit}{apples} | 0   |
        | $root{fruit}{berry}  | purple                | 1   |
        +----------------------+-----------------------+-----+

- RESULT\_REVISIT\_CONTENTS

    Do not visit the next element in the parent container. restart with
    the first element in the container.  The order of elements is
    determined when the container is visited, so starts within a visit
    will have the same order.

    For example, if `RESULT_REVISIT_CONTENTS` is returned the
    first time `$root{fruit}{apples}[0]` is traversed, the
    traversal would look like this:

        +-------------------------+-----------------------+-----+-------+
        | path                    | value                 | idx | visit |
        +-------------------------+-----------------------+-----+-------+
        | $root{fruit}            | \$root{fruit}         | 0   | 1     |
        | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   | 1     |
        | $root{fruit}{apples}[0] | fuji                  | 0   | 1     |
        | $root{fruit}{apples}[0] | fuji                  | 0   | 2     |
        | $root{fruit}{apples}[1] | macoun                | 1   | 2     |
        | $root{fruit}{berry}     | purple                | 1   | 1     |
        +-------------------------+-----------------------+-----+-------+

    To avoid inadvertent infinite loops, the number of revisits
    during a traversal of a container is limited (see ["revisit\_limit"](#revisit_limit)).
    Containers with multiple parents are traversed once per parent; The
    limit is reset for each traversal.

- RESULT\_REVISIT\_ROOT

    Stop processing and re-start at `$root`.
    To avoid inadvertent infinite loops, the number of revisits
    is limited (see ["revisit\_limit"](#revisit_limit)).

- RESULT\_REVISIT\_ELEMENT

    If the current element is not a container, the next element in the
    container will be visited (just as with ["RESULT\_CONTINUE"](#result_continue)).

    If the current element is a container, its contents will be visited,
    and ["$callback"](#callback) will be invoked on it again afterwards.

    During the call to `$callback` on the container prior to visiting
    its contents,

        $metadata->{pass} & PASS_VISIT_ELEMENT

    will be true.  During the followup visit

        $metadata->{pass} & PASS_REVISIT_ELEMENT

    will be true.

    For example, If `RESULT_REVISIT_ELEMENT` is returned when
    `$root{fruit}{apples}` is traversed, the traversal would look like
    this:

        +-------------------------+-----------------------+-----+----------------------+
        | path                    | value                 | idx | pass                 |
        +-------------------------+-----------------------+-----+----------------------+
        | $root{fruit}            | \$root{fruit}         | 0   | PASS_VISIT_ELEMENT   |
        | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   | PASS_VISIT_ELEMENT   |
        | $root{fruit}{apples}[0] | fuji                  | 0   | PASS_VISIT_ELEMENT   |
        | $root{fruit}{apples}[1] | macoun                | 1   | PASS_VISIT_ELEMENT   |
        | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   | PASS_REVISIT_ELEMENT |
        | $root{fruit}{berry}     | purple                | 1   | PASS_VISIT_ELEMENT   |
        +-------------------------+-----------------------+-----+----------------------+

### Mixed Directives

Some directives can be mixed with ["RESULT\_REVISIT\_CONTENTS"](#result_revisit_contents) and
["RESULT\_REVISIT\_ELEMENT"](#result_revisit_element) by performing a binary OR with them.

- RESULT\_STOP\_DESCENT | RESULT\_REVISIT\_CONTENTS

    If the current element is not a container, the next element in the
    container will be visited (just as with ["RESULT\_CONTINUE"](#result_continue)).

    If the current element is a hash or array, do not visit its contents,
    and continue with the next element in the parent container.  For
    non-container elements, continue with the next element in the parent
    container.

    After all of the container's contents have been visited, start
    again with the first element in the container.

    For example, if `RESULT_STOP_DESCENT | RESULT_REVISIT_CONTENTS` is
    returned when `$root{fruit}{apples}` is traversed when
    `$metadata-`{visit} ==1>, the traversal would look like

        +----------------------+-----------------------+-----+-------+
        | path                 | value                 | idx | visit |
        +----------------------+-----------------------+-----+-------+
        | $root{fruit}         | \$root{fruit}         | 0   | 1     |
        | $root{fruit}{apples} | \$root{fruit}{apples} | 0   | 1     |
        | $root{fruit}{berry}  | purple                | 1   | 1     |
        | $root{fruit}{apples} | \$root{fruit}{apples} | 0   | 2     |
        | $root{fruit}{berry}  | purple                | 1   | 2     |
        +----------------------+-----------------------+-----+-------+

- RESULT\_CONTINUE | RESULT\_REVISIT\_CONTENTS

    Visit the remaining elements in the parent container, then start again
    with the first element in the container.

    For example, if `RESULT_CONTINUE | RESULT_REVISIT_CONTENTS` is
    returned when `$callback` is first passed
    `$root{fruit}{apples}[0]`, the traversal would look like

        +-------------------------+-----------------------+-----+-------+
        | path                    | value                 | idx | visit |
        +-------------------------+-----------------------+-----+-------+
        | $root{fruit}            | \$root{fruit}         | 0   | 1     |
        | $root{fruit}{apples}    | \$root{fruit}{apples} | 0   | 1     |
        | $root{fruit}{apples}[0] | fuji                  | 0   | 1     |
        | $root{fruit}{apples}[1] | macoun                | 1   | 1     |
        | $root{fruit}{apples}[0] | fuji                  | 0   | 2     |
        | $root{fruit}{apples}[1] | macoun                | 1   | 2     |
        | $root{fruit}{berry}     | purple                | 1   | 1     |
        +-------------------------+-----------------------+-----+-------+

## Calling Contexts and Allowed Traversal Directives

`$callback`'s allowed return value depends upon the context it is
called in.  `$callback` may be called on an element multiple times
during different stages of traversal.

### When invoked on an element during a scan of its parent container

- The `pass` metadata attribute is set to `PASS_VISIT_ELEMENT`
- `$callback` must return one of

        RESULT_REVISIT_CONTENTS
        RESULT_RETURN
        RESULT_CONTINUE

        RESULT_CONTINUE | RESULT_REVISIT_CONTENTS
        RESULT_STOP_DESCENT | RESULT_REVISIT_CONTENTS
        RESULT_CONTINUE | RESULT_REVISIT_ELEMENT

### When invoked on a container immediately after its contents have been visited

See ["RESULT\_REVISIT\_ELEMENT"](#result_revisit_element).

- The `pass` metadata attribute is set to `PASS_REVISIT_ELEMENT`
- `$callback` must return one of

        RESULT_RETURN
        RESULT_CONTINUE
        RESULT_REVISIT_CONTENTS
        RESULT_CONTINUE | RESULT_REVISIT_CONTENTS

### When invoked on `$root` before its contents have been visited

See ["VISIT\_ROOT"](#visit_root).

- The `pass` metadata attribute is set to `PASS_VISIT_ELEMENT`
- `$callback` must return one of

        RESULT_CONTINUE
        RESULT_CONTINUE | RESULT_REVISIT_ELEMENT
        RESULT_RETURN
        RESULT_REVISIT_ROOT
        RESULT_STOP_DESCENT

### When invoked on the `$root` immediately after its elements have been visited

See ["VISIT\_ROOT"](#visit_root) and ["RETURN\_REVISIT\_ELEMENT"](#return_revisit_element).

- The `pass` metadata attribute is set to `PASS_REVISIT_ELEMENT`
- `$callback` must return one of

        RESULT_RETURN
        RESULT_CONTINUE

## Metadata

`$callback` is passed a hash of state information (`$metadata`) kept
by **CXC::Data::Visitor::visit**, some of which may be of interest to
the callback:

`$metadata` has the following entries:

- **container**

    A reference to the hash or array which contains the element being visited.

- **path**

    An array which contains the path (keys and indices) used to arrive
    at the current element from **$root**.

- **ancestors**

    An array containing references to the ancestor containers of the
    current element.

- **pass**

    A constant indicating the current visit pass of an element.
    See ["RESULT\_REVISIT\_ELEMENT"](#result_revisit_element).

- **visit**

    A unary-based counter indicating the number of times the element's
    container has been scanned and its contents processed in a single
    visit.  This will be greater than `1` if the
    ["RESULT\_REVISIT\_CONTENTS"](#result_revisit_contents) directive has been applied. It is _not_
    the number of times that the element has been visited, as scans may be
    interrupted and restarted.

- **idx**

    A zero-based index indicating the order of the element in its container.
    Ordering depends upon how container elements are sorted; see
    ["key\_sort"](#key_sort) and ["idx\_sort"](#idx_sort).

## Element Filters

The parts of the structure that will trigger a callback.  Note that
by default the passed top level structure, `$root` is _not_
passed to the callback.  See ["VISIT\_ROOT"](#visit_root).

See ["EXPORTS"](#exports) to import the constants.

- VISIT\_CONTAINER

    Invoke ["$callback"](#callback) on containers (either hashes or arrays).  For
    example, the elements in the following structure

        $root = { a => { b => 1, c => [ 2, 3 ] } }

    passed to ["$callback"](#callback) are:

        a => {...}  # $root->{a}
        c => [...]  # $root->{c}

- VISIT\_ARRAY
- VISIT\_HASH

    Only visit containers of the given type.

- VISIT\_LEAF

    Invoke ["$callback"](#callback) on terminal (leaf) elements.  For example, the
    elements in the following structure

        $root = { a => { b => 1, c => [ 2, 3 ] } }

    passed to ["$callback"](#callback) are:

        b => 1  # $root->{a}{b}
        0 => 2  # $root->{a}{c}[0]
        1 => 3  # $root->{a}{c}[1]

- VISIT\_ALL

    Invoke ["$callback"](#callback) on all elements except for `$root`.  This is the default.

- VISIT\_ROOT

    Pass `$root` to `$callback`. To filter on one of the other values, pass
    a binary OR of ["VISIT\_ROOT"](#visit_root) and the other filter, e.g.

        VISIT_ROOT | VISIT_LEAF

    Specifying ["VISIT\_ROOT"](#visit_root) on its own is equivalent to

        VISIT_ROOT | VISIT_ALL

## Cycles

- CYCLE\_DIE

    Throw an exception (the default).

- CYCLE\_CONTINUE

    Pretend we haven't seen it before. Will cause stack exhaustion if
    **$callback** does handle this.

- CYCLE\_TRUNCATE

    Truncate before entering the cycle a second time.

- _$coderef_

    Examine the situation and request a particular resolution.
    **$coderef** is called as

        $coderef->( $container, $context, $metadata );

    where **$container** is the hash or array which has already been
    traversed. See below for ["$context"](#context) and ["$metadata"](#metadata).

    **$coderef** should return one of **CYCLE\_DIE**, **CYCLE\_CONTINUE**, or **CYCLE\_TRUNCATE**,
    indicating what should be done.

# EXPORTS

This module uses [Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny), which provides enhanced import
utilities.

## Subroutines

The following subroutine may be imported:

    visit

### Constants

Constants may be imported individually or as groups via tags.  The
available tags and their respective imported symbols are:

- **all**

    Import all symbols.

- **results**

        RESULT_CONTINUE
        RESULT_RETURN
        RESULT_REVISIT_CONTAINER  # deprecated alias for RESULT_REVISIT_CONTENTS
        RESULT_REVISIT_CONTENTS
        RESULT_REVISIT_ELEMENT
        RESULT_REVISIT_ROOT
        RESULT_STOP_DESCENT

- **cycles**

        CYCLE_CONTINUE
        CYCLE_DIE
        CYCLE_TRUNCATE

- **visits**

        VISIT_ALL
        VISIT_CONTAINER
        VISIT_LEAF
        VISIT_ROOT

- **passes**

        PASS_REVISIT_ELEMENT
        PASS_VISIT_ELEMENT

- **constants**

    Import tags `cycles`, `passes`, `results`, `visits`.

# DEPRECATED CONSTRUCTS

- **RESULT\_REVISIT\_CONTAINER** is a deprecated alias for ["RESULT\_REVISIT\_CONTENTS"](#result_revisit_contents).

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-cxc-data-visitor@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Data-Visitor](https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Data-Visitor)

## Source

Source is available at

    https://codeberg.org/CXC-Optics/p5-CXC-Data-Visitor

and may be cloned from

    https://codeberg.org/CXC-Optics/p5-CXC-Data-Visitor.git

# SEE ALSO

Please see those modules/websites for more information related to this module.

- [Data::Rmap](https://metacpan.org/pod/Data%3A%3ARmap)
- [Data::Traverse](https://metacpan.org/pod/Data%3A%3ATraverse)
- [Data::Visitor::Lite](https://metacpan.org/pod/Data%3A%3AVisitor%3A%3ALite)
- [Data::Visitor::Tiny](https://metacpan.org/pod/Data%3A%3AVisitor%3A%3ATiny)
- [Data::Walk](https://metacpan.org/pod/Data%3A%3AWalk)

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
