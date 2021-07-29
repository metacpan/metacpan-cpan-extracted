# PROPERTY FILES

Property files contain definitions for properties. This module uses an
augmented version of the properties as used in e.g. Java.

In general, each line of the file defines one property.

    version: 1
    foo.bar = blech
    foo.xxx = yyy
    foo.xxx = "yyy"
    foo.xxx = 'yyy'

The latter three settings for `foo.xxx` are equivalent.

Whitespace has no significance. A colon `:` may be used instead of
`=`. Lines that are blank or empty, and lines that start with `#`
are ignored.

Property _names_ consist of one or more identifiers (series of
letters and digits) separated by periods.

Valid values are a plain text (whitespace, but not trailing, allowed),
a single-quoted string, or a double-quoted string. Single-quoted
strings allow embedded single-quotes by escaping them with a backslash
`\`. Double-quoted strings allow common escapes like `\n`, `\t`,
`\7`, `\x1f` and `\x{20cd}`.

Note that in plain text backslashes are taken literally. The following
alternatives yield the same results:

    foo = a'\nb
    foo = 'a\'\nb'
    foo = "a'\\nb"

**IMPORTANT:** All values are strings. These three are equivalent:

    foo = 1
    foo = "1"
    foo = '1'

and so are these:

    foo = Hello World!
    foo = "Hello World!"
    foo = 'Hello World!'

Quotes are required when you want leading and/or trailing whitespace.
Also, the value `null` is special so if you want to use this as a string
it needs to be quoted.

Single quotes defer expansion, see ["Expansion"](#expansion) below.

## Context

When several properties with a common prefix must be set, they can be
grouped in a _context_:

    foo {
       bar = blech
       xxx = "yyy"
       zzz = 'zyzzy'
    }

Contexts may be nested.

## Arrays

When a property has a number of sub-properties with keys that are
consecutive numbers starting at `0`, it may be considered as an
array. This is only relevant when using the data() method to retrieve
a Perl data structure from the set of properties.

    list {
       0 = aap
       1 = noot
       2 = mies
    }

When retrieved using data(), this returns the Perl structure

    [ "aap", "noot", "mies" ]

For convenience, arrays can be input in several more concise ways:

    list = [ aap noot mies ]
    list = [ aap
             noot
             mies ]

The opening bracket must be followed by one or more values. This will
currently not work:

    list = [
             aap
             noot
             mies ]

## Includes

Property files can include other property files:

    include "myprops.prp"

All properties that are read from the file are entered in the current
context. E.g.,

    foo {
      include "myprops.prp"
    }

will enter all the properties from the file with an additional `foo.`
prefix.

## Expansion

Property values can be anything. The value will be _expanded_ before
being assigned to the property unless it is placed between single
quotes `''`.

Expansion means:

- A tilde `~` in what looks like a file name will be replaced by the
value of `${HOME}`.
- If the value contains `${`_name_`}`, _name_ is first looked up in the
current environment. If an environment variable _name_ can be found,
its value is substituted.

    If no suitable environment variable exists, _name_ is looked up as a
    property and, if it exists and has a non-empty value, this value is
    substituted.

    Otherwise, the `${`_name_`}` part is removed.

    Note that if a property is referred as `${.`_name_}`, _name_ is
    looked up in the current context only.

    **Important:** Property lookup is case insensitive.

- If the value contains `${`_name_`:`_value_`}`, _name_ is looked up as
described above. If, however, no suitable value can be found, _value_
is substituted.

Expansion is delayed if single quotes are used around the value.

    x = 1
    a = ${x}
    b = "${x}"
    c = '${x}'
    x = 2

Now `a` and `b` will be `'1'`, but `c` will be `'2'`.

Substitution is handled by [String::Interpolate::Named](https://metacpan.org/pod/String%3A%3AInterpolate%3A%3ANamed). See its
documentation for more power.

In addition, you can test for a property being defined (not null) by
appending a `?` to its name.

    result = ${x?|${x|value|empty}|null}

This will yield `value` if `x` is not null and not empty, `empty`
if not null and empty, and `null` if not defined or defined as null.

