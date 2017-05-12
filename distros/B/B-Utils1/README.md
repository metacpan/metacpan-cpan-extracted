# NAME

B::Utils1 - Helper functions for op tree manipulation

# VERSION

1.05

# SYNOPSIS

    use B::Utils1;

# OP METHODS

- `$op->oldname`

    Returns the name of the op, even if it is currently optimized to null.
    This helps you understand the structure of the op tree.

- `$op->kids`

    Returns an array of all this op's non-null children, in order.

- `$op->parent`

    Returns the parent node in the op tree, if possible. Currently
    "possible" means "if the tree has already been optimized"; that is, if
    we're during a `CHECK` block. (and hence, if we have valid `next`
    pointers.)

    In the future, it may be possible to search for the parent before we
    have the `next` pointers in place, but it'll take me a while to
    figure out how to do that.

    Warning: Since 5.21.2 B comes with it's own version of B::OP::parent
    which returns either B::NULL or the real parent when ccflags contains
    \-DPERL\_OP\_PARENT.
    We patch away this broken B::OP::parent and return again undef if no parent
    exists. Note that [B::Utils](https://metacpan.org/pod/B::Utils) returns B::NULL instead.

- `$op->ancestors`

    Returns all parents of this node, recursively. The list is ordered
    from younger/closer parents to older/farther parents.

- `$op->descendants`

    Returns all children of this node, recursively. The list is unordered.

- `$op->siblings`

    Returns all younger siblings of this node. The list is ordered from
    younger/closer siblings to older/farther siblings.

- `$op->previous`

    Like ` $op->next `, but not quite.

- `$op->stringify`

    Returns a nice stringification of an opcode.

- `$op->as_opgrep_pattern(%options)`

    From the op tree it is called on, `as_opgrep_pattern()`
    generates a data structure suitable for use as a condition pattern
    for the `opgrep()` function described below in detail.
    _Beware_: When using such generated patterns, there may be
    false positives: The pattern will most likely not match _only_
    the op tree it was generated from since by default, not all properties
    of the op are reproduced.

    You can control which properties of the op to include in the pattern
    by passing named arguments. The default behaviour is as if you
    passed in the following options:

        my $pattern = $op->as_opgrep_pattern(
          attributes          => [qw(name flags)],
          max_recursion_depth => undef,
        );

    So obviously, you can set `max_recursion_depth` to a number to
    limit the maximum depth of recursion into the op tree. Setting
    it to `0` will limit the dump to the current op.

    `attributes` is a list of attributes to include in the produced
    pattern. The attributes that can be checked against in this way
    are:

        name targ type seq flags private pmflags pmpermflags.

# EXPORTABLE FUNCTIONS

- `all_starts`
- `all_roots`

    Returns a hash of all of the starting ops or root ops of optrees, keyed
    to subroutine name; the optree for main program is simply keyed to `__MAIN__`.

    **Note**: Certain "dangerous" stashes are not scanned for subroutines:
    the list of such stashes can be found in
    `@B::Utils1::bad_stashes`. Feel free to examine and/or modify this to
    suit your needs. The intention is that a simple program which uses no
    modules other than `B` and `B::Utils1` would show no addition
    symbols.

    This does **not** return the details of ops in anonymous subroutines
    compiled at compile time. For instance, given

        $a = sub { ... };

    the subroutine will not appear in the hash. This is just as well,
    since they're anonymous... If you want to get at them, use...

- `anon_subs`

    This returns an array of hash references. Each element has the keys
    "start" and "root". These are the starting and root ops of all of the
    anonymous subroutines in the program.

- `recalc_sub_cache`

    If PL\_sub\_generation has changed or you have some other reason to want
    to force the re-examination of the optrees, everywhere, call this
    function.

- `walkoptree_simple($op, \&callback, [$data])`

    The `B` module provides various functions to walk the op tree, but
    they're all rather difficult to use, requiring you to inject methods
    into the `B::OP` class. This is a very simple op tree walker with
    more expected semantics.

    All the `walk` functions set `$B::Utils1::file`, `$B::Utils::line`,
    and `$B::Utils1::sub` to the appropriate values of file, line number,
    and sub name in the program being examined.
    Sets `$B::Utils::trace_removed` when the nextstate COPs that contained
    that line was optimized away. Such lines won't normally be
    step-able or breakpoint-able in a debugger without special work.

- `walkoptree_filtered($op, \&filter, \&callback, [$data])`

    This is much the same as `walkoptree_simple`, but will only call the
    callback if the `filter` returns true. The `filter` is passed the
    op in question as a parameter; the `opgrep` function is fantastic
    for building your own filters.

- `walkallops_simple(\&callback, [$data])`

    This combines `walkoptree_simple` with `all_roots` and `anon_subs`
    to examine every op in the program. `$B::Utils1::sub` is set to the
    subroutine name if you're in a subroutine, `__MAIN__` if you're in
    the main program and `__ANON__` if you're in an anonymous subroutine.

- `walkallops_filtered(\&filter, \&callback, [$data])`

    Same as above, but filtered.

- `opgrep(\%conditions, @ops)`

    Returns the ops which meet the given conditions. The conditions should
    be specified like this:

        @barewords = opgrep(
                            { name => "const", private => OPpCONST_BARE },
                            @ops
                           );

    where the first argument to `opgrep()` is the condition to be matched against the
    op structure. We'll henceforth refer to it as an op-pattern.

    You can specify alternation by giving an arrayref of values:

        @svs = opgrep ( { name => ["padsv", "gvsv"] }, @ops)

    And you can specify inversion by making the first element of the
    arrayref a "!". (Hint: if you want to say "anything", say "not
    nothing": `["!"]`)

    You may also specify the conditions to be matched in nearby ops as nested patterns.

        walkallops_filtered(
            sub { opgrep( {name => "exec",
                           next => {
                                     name    => "nextstate",
                                     sibling => { name => [qw(! exit warn die)] }
                                   }
                          }, @_)},
            sub {
                  carp("Statement unlikely to be reached");
                  carp("\t(Maybe you meant system() when you said exec()?)\n");
            }
        )

    Get that?

    Here are the things that can be tested in this way:

            name targ type seq flags private pmflags pmpermflags
            first other last sibling next pmreplroot pmreplstart pmnext

    Additionally, you can use the `kids` keyword with an array reference
    to match the result of a call to `$op->kids()`. An example use is
    given in the documentation for `op_or` below.

    For debugging, you can have many properties of an op that is currently being
    matched against a given condition dumped to STDERR
    by specifying `dump =` 1> in the condition's hash reference.

    If you match a complex condition against an op tree, you may want to extract
    a specific piece of information from the tree if the condition matches.
    This normally entails manually walking the tree a second time down to
    the op you wish to extract, investigate or modify. Since this is tedious
    duplication of code and information, you can specify a special property
    in the pattern of the op you wish to extract to capture the sub-op
    of interest. Example:

        my ($result) = opgrep(
          { name => "exec",
            next => { name    => "nextstate",
                      sibling => { name => [qw(! exit warn die)]
                                   capture => "notreached",
                                 },
                    }
          },
          $root_op
        );

        if ($result) {
          my $name = $result->{notreached}->name; # result is *not* the root op
          carp("Statement unlikely to be reached (op name: $name)");
          carp("\t(Maybe you meant system() when you said exec()?)\n");
        }

    While the above is a terribly contrived example, consider the win for a
    deeply nested pattern or worse yet, a pattern with many disjunctions.
    If a `capture` property is found anywhere in
    the op pattern, `opgrep()` returns an unblessed hash reference on success
    instead of the tested op. You can tell them apart using [Scalar::Util](https://metacpan.org/pod/Scalar::Util)'s
    `blessed()`. That hash reference contains all captured ops plus the
    tested root up as the hash entry `$result->{op}`. Note that you cannot
    use this feature with `walkoptree_filtered` since that function was
    specifically documented to pass the tested op itself to the callback.

    You cannot capture disjunctions, but that doesn't really make sense anyway.

- `opgrep( \@conditions, @ops )`

    Same as above, except that you don't have to chain the conditions
    yourself.  If you pass an array-ref, opgrep will chain the conditions
    for you using `next`.
    The conditions can either be strings (taken as op-names), or
    hash-refs, with the same testable conditions as given above.

- `op_or( @conditions )`

    Unlike the chaining of conditions done by `opgrep` itself if there are multiple
    conditions, this function creates a disjunction (`$cond1 || $cond2 || ...`) of
    the conditions and returns a structure (hash reference) that can be passed to
    opgrep as a single condition.

    Example:

        my $sub_structure = {
          name => 'helem',
          first => { name => 'rv2hv', },
          'last' => { name => 'const', },
        };

        my @ops = opgrep( {
            name => 'leavesub',
            first => {
              name => 'lineseq',
              kids => [,
                { name => 'nextstate', },
                op_or(
                  {
                    name => 'return',
                    first => { name => 'pushmark' },
                    last => $sub_structure,
                  },
                  $sub_structure,
                ),
              ],
            },
        }, $op_obj );

    This example matches the code in a typical simplest-possible
    accessor method (albeit not down to the last bit):

        sub get_foo { $_[0]->{foo} }

    But by adding an alternation
    we can also match optional op layers. In this case, we optionally
    match a return statement, so the following implementation is also
    recognized:

        sub get_foo { return $_[0]->{foo} }

    Essentially, this is syntactic sugar for the following structure
    recognized by `opgrep()`:

        { disjunction => [@conditions] }

- `carp(@args)`
- `croak(@args)`

    Warn and die, respectively, from the perspective of the position of
    the op in the program. Sounds complicated, but it's exactly the kind
    of error reporting you expect when you're grovelling through an op
    tree.

- `dl_load_flags 1`

    Override [DynaLoader](https://metacpan.org/pod/DynaLoader) default to force global loading.

## EXPORT

None by default.

## XS EXPORT

This modules uses [ExtUtils::Depends](https://metacpan.org/pod/ExtUtils::Depends) to export some useful functions
for XS modules to use.  To use those, include in your Makefile.PL:

    my $pkg = ExtUtils::Depends->new("Your::XSModule", "B::Utils1");
    WriteMakefile(
      ... # your normal makefile flags
      $pkg->get_makefile_vars,
    );

Your XS module can now include `BUtils1.h`.  To see
document for the functions provided, use:

    perldoc -m B::Utils1::Install::BUtils.h

# INSTALLATION

To install this module, you may want to run the following commands:

    perl Makefile.PL
    make test
    sudo make install

# AUTHOR

Maintained by Reini Urban `rurban@cpan.org`.

Originally written by Simon Cozens, `simon@cpan.org` as B::Utils.

Previously maintained by Joshua ben Jore, `jjore@cpan.org` and Karen
Etheridge as B::Utils.

Contributions from Mattia Barbon, Jim Cromie, Steffen Mueller, and
Chia-liang Kao, Alexandr Ciornii.

# LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# SEE ALSO

[B::Utils](https://metacpan.org/pod/B::Utils), [B](https://metacpan.org/pod/B), [B::Generate](https://metacpan.org/pod/B::Generate).
