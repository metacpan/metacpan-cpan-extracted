# NAME

Clean::Eval - Run code under `eval` without leaking `$@` and get a rich
error object back on failure.

# DESCRIPTION

Perl's built-in `eval` is the standard way to trap exceptions, but it has two
long-standing ergonomic problems:

- It modifies the global `$@`, which can be clobbered by destructors or other
code running during stack unwind, leading to lost or corrupted error messages.
- The return value of `eval` can be ambiguous: a successful eval that
legitimately returns a false value is indistinguishable from a failure unless
you check `$@`.

`Clean::Eval` wraps `eval` in a way that avoids both problems. It localizes
`$@` so the caller's copy is never touched and always returns a blessed
result object that is overloaded for boolean and string context. The object
is true on success and false on failure regardless of what the wrapped code
returned, so a single `if` check is enough to distinguish the two.

On success the block form also stashes the block's return value (taken in
scalar context) in an `out` field on the object, so the typical pattern is:

    if (my $ev = clean_eval { get_message() }) {
        $msg = $ev->out;
    }
    else {
        die $ev;        # stringifies to the trapped error
    }

Both a block form (`clean_eval { ... }`) and a string form
(`clean_string_eval $code`) are provided. The string form rewrites `#line`
information so that any error reports the file and line of the caller, not an
anonymous `(eval N)`. The string form does **not** capture a return value -
see ["clean\_string\_eval"](#clean_string_eval).

# SYNOPSIS

    use Clean::Eval qw/clean_eval clean_string_eval last_error/;

    # Block form - object is always returned; bool overload picks
    # success vs failure; on success ->out holds the block's scalar
    # return value.
    my $msg;
    if (my $ev = clean_eval { get_message() }) {
        $msg = $ev->out;
    }
    else {
        die $ev;        # stringifies to trapped error
    }

    # Or, branchless:
    my $ev = clean_eval { risky() };
    die "Failed: $ev\n  at $ev->{file} line $ev->{line}\n" unless $ev;
    my $result = $ev->out;

    # String form - same overloaded object, but no ->out is ever set
    # (see "clean_string_eval" below). No need to add a trailing "; 1"
    # - it is appended for you.
    my $ev = clean_string_eval 'use SomeOptionalModule';
    warn "Optional dep missing: $ev\n" unless $ev;

    # Retrieve the most recent failure from anywhere
    my $last = last_error();

# EXPORTS

Nothing is exported by default. The three functions below may be imported
individually using [Importer](https://metacpan.org/pod/Importer)-style syntax:

    use Clean::Eval qw/clean_eval clean_string_eval last_error/;

- $ev = clean\_eval { BLOCK }

    Run `BLOCK` under `eval`. Always returns a `Clean::Eval` result object
    (see ["RESULT OBJECT"](#result-object)). `$@` in the caller's scope is not touched.

    On success the block's return value is captured **in scalar context** and
    stored in the object's `out` field. Scalar context is forced because the
    object is a scalar-context-only carrier - capturing a list there would
    require API choices (arrayref? flatten?) that would surprise callers. If
    you need list-context results, assign to an outer `my @list` from inside
    the block:

        my @rows;
        my $ev = clean_eval { @rows = fetch_rows() };
        die $ev unless $ev;

    On failure the `out` key is **not present** on the object and the `error`,
    `package`, `file`, and `line` keys are populated instead.

    The prototype is `(&)`, so the block form works without a leading `sub`.

- $ev = clean\_string\_eval $STRING

    Run `$STRING` as Perl code under `eval`. Always returns a `Clean::Eval`
    result object. `$@` in the caller's scope is not touched.

    **Unlike the block form, the string form never captures a return value.**
    The `out` field is always absent on the result object, even on success.
    This is because the body of a string eval is not necessarily a value-
    producing expression: it might be defining a subroutine, opening a
    `BEGIN`/`INIT`/`END` block, declaring a package, loading a module via
    `use`, or otherwise producing something that has no meaningful "scalar
    return value" to record. Trying to capture and stash a result in those
    cases would just be misleading. If you need a value out of string eval'd
    code, write to an outer `our` package variable from inside the string,
    or use `clean_eval { eval $string }` and capture the result yourself.

    A `#line` directive is prepended to `$STRING` using the caller's filename
    and line number, so any error or warning produced by the eval'd code refers
    to the source location of the `clean_string_eval` call rather than to an
    anonymous eval string.

    A trailing `; 1` is also appended to `$STRING`, so you do not need to
    remember the usual `eval "...; 1"` success guard - success is recorded on
    the result object regardless of what the final statement in `$STRING`
    evaluates to. Including the `; 1` yourself is harmless.

    The prototype is `($)`, so a single scalar argument is taken.

- $err = last\_error()

    Return the result object of the most recent **failure** produced by
    `clean_eval` or `clean_string_eval` anywhere in the program, or `undef`
    if no failure has been recorded yet. Successful calls do **not** reset this
    slot. Useful for code paths that discarded the result object or want to
    inspect a previous failure after the fact.

    **Caveat:** `last_error` is a global slot and is subject to the same class
    of bug that makes raw `$@` fragile. If a `DESTROY` method (or anything
    else running during stack unwind) calls `clean_eval` or
    `clean_string_eval` and that inner call fails, it will overwrite the
    global and the error you actually cared about will be lost. `last_error`
    is a convenience, not a guarantee - the only robust way to inspect a
    particular failure is to capture the result object of
    `clean_eval`/`clean_string_eval` directly at the call site and keep it
    in a lexical of your own.

# RESULT OBJECT

Both `clean_eval` and `clean_string_eval` always return a blessed hashref
of class `Clean::Eval`. It overloads boolean and stringification context:

- Boolean context: true on success, false on failure. This is computed from
the `ok` field, so a successful eval whose block legitimately returned a
false value is still distinguishable from a failure.
- String context: the trapped error message on failure (the value `$@` had
inside the eval), or the empty string on success. This lets you write
`die $ev` on a failure without having to dig out a field.

The object is a plain hashref with the following keys. Which keys are
present depends on whether the eval succeeded:

- ok

    Always present. `1` on success, `0` on failure.

- out

    **Present only on success, and only for the block form.** Holds the block's
    return value, taken in scalar context. Absent (the key does not `exists`
    at all) on failure, and absent for `clean_string_eval` in all cases.

- error

    **Present only on failure.** The trapped error message (string or object,
    whatever was `die`'d).

- package

    The package the call was made from. Always present.

- file

    The file the call was made from. Always present.

- line

    The line the call was made from. Always present.

Convenience accessors `ok`, `out`, and `error` return the corresponding
fields. `to_string` returns the same string the `""` overload yields.

# WHY NOT JUST USE `eval`?

You can, but you have to be careful. The idiomatic safe pattern looks like:

    my $ok = eval { ...; 1 };
    if (!$ok) {
        my $err = $@;
        ...
    }

This is correct but verbose, and the `; 1` trailer is easy to forget. The
`$@` variable is also famously fragile: destructors that run during stack
unwind can call `eval` themselves and reset it before you read it. Localizing
`$@` the way `Clean::Eval` does avoids that class of bug entirely.

# PITFALLS

## `my $ev = clean_eval { ... } or die "$ev"` does not work

This looks natural but contains a subtle bug. A lexical introduced by
`my` is **not** in scope until the statement that declared it has
finished, so the `$ev` referenced by `die "$ev"` is a different,
package-global `$ev` (which is `undef`):

    use Clean::Eval qw/clean_eval/;

    # WRONG - $ev inside the die is the package global, not the lexical;
    # the die fires (clean_eval returned a false-overloaded object) but
    # with an empty message.
    my $ev = clean_eval { die "foo" } or die "$ev";

Declare the lexical on its own statement first so it is in scope by the
time the `or die` runs:

    use Clean::Eval qw/clean_eval/;

    # CORRECT - $ev refers to the lexical in both spots
    my $ev;
    $ev = clean_eval { die "foo" } or die "$ev";

Or split the check off into its own statement, which has the same effect:

    use Clean::Eval qw/clean_eval/;

    my $ev = clean_eval { die "foo" };
    die "$ev" unless $ev;

The reliable rule: do not reference a `my`-declared variable in the same
statement that declares it. Running with `use warnings` will diagnose
this with `"Name main::ev used only once: possible typo"`.

## The block's return value is taken in scalar context

`clean_eval` stashes the block's return value in `$ev->out`, but
it does so in **scalar context**. A block that returns a list will be
collapsed to the last element (or to the list count, depending on the
expression):

    use Clean::Eval qw/clean_eval/;

    my $ev = clean_eval { (1, 2, 3) };
    # $ev->out is 3, not [1, 2, 3]

If you need a list result, write to an outer lexical from inside the
block:

    my @rows;
    my $ev = clean_eval { @rows = fetch_rows() };
    die $ev unless $ev;
    # use @rows here

Scalar context is forced deliberately - the `out` field is a single
scalar slot, and silently picking a list-handling convention would
surprise callers.

## `clean_string_eval` never sets `out`

The string form never records a return value, even on success. A string
eval may be defining subs, opening `BEGIN`/`END` blocks, loading
modules, or otherwise doing things with no meaningful scalar result. If
you need a value back from a string eval, write to an `our` package
variable from inside the string, or wrap a real `eval $str` inside a
`clean_eval` block and capture from there.

## `clean_string_eval` does not see the caller's lexicals

With a raw `eval $string`, the eval'd code can see any `my` variables
in the surrounding scope. `clean_string_eval` cannot: the string is
eval'd inside this module, so the caller's lexicals are out of reach.
Only package globals are visible.

    use Clean::Eval qw/clean_string_eval/;

    my $x = 42;
    my $ret = clean_string_eval 'print $x';
    # $ret is an error: "Global symbol $x requires explicit package name"
    # (or, without strict, $x is just an unrelated undef global)

    our $y = 42;
    clean_string_eval 'print $y';   # prints 42 - $y is a package global

If you need to feed values in, pass them through globals you control or
through the environment, or build a closure and use `clean_eval` with a
block instead.

## `return` inside the block returns from the block, not the caller

The block passed to `clean_eval` is an anonymous subroutine. A `return`
inside it returns from that anonymous subroutine - not from the
enclosing named sub - and `clean_eval` still gets control back and
returns `1` for success.

    sub do_work {
        my $ok = clean_eval {
            return if $skip;     # returns from the block only
            risky_thing();
        };
        return 0 unless $ok;
        ...
    }

This matches the behavior of plain `eval { ... }`.

## Cannot pass a coderef variable with block syntax

The `(&)` prototype makes `clean_eval` parse a literal block; it will
not accept a coderef in scalar variable form:

    my $cref = sub { die "foo" };
    clean_eval $cref;          # syntax error / wrong parse

Workarounds:

    clean_eval(\&named_sub);   # named sub via \&
    clean_eval { $cref->() };  # wrap in a literal block
    &Clean::Eval::clean_eval($cref);   # bypass the prototype

# SEE ALSO

[Try::Tiny](https://metacpan.org/pod/Try%3A%3ATiny), [Syntax::Keyword::Try](https://metacpan.org/pod/Syntax%3A%3AKeyword%3A%3ATry), [Feature::Compat::Try](https://metacpan.org/pod/Feature%3A%3ACompat%3A%3ATry).

# SOURCE

The source code repository for Clean-Eval can be found at
`https://github.com/exodist/Clean-Eval/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2026 Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
