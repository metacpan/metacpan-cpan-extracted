# NAME

Data::Pretty - Data Dump Beautifier

# SYNOPSIS

    use Data::Pretty qw( dump );
    $str = dump(@list);
    @copy_of_list = eval $str;

    # or use it for easy debug printout
    use Data::Pretty; dd localtime;

    use Data::Pretty qw( dump literal );
    my $users = [qw( John Peter )];
    my $ref = { name => literal( '$users->[0]' ) };
    say dump( $ref ); # { name => $users->[0] }

# VERSION

    v0.1.5

# DESCRIPTION

This is a fork from [Data::Dump](https://metacpan.org/pod/Data%3A%3ADump) and a drop-in replacement with the aim at providing the following improvements:

- Avoid long indentation matching the length of a property

    For example, `Data::Dump` would produce

        {
            query => { term => { user => "kimchy" } },
            sort  => [
                         { post_date => { order => "asc" } },
                         "user",
                         { name => "desc" },
                         { age => "desc" },
                         "_score",
                     ],
        }

    whereas, `Data::Pretty` would make it more crisp:

        {
            query => {
                term => { user => "kimchy" },
            },
            sort => [
                {
                    post_date => { order => "asc" },
                },
                "user",
                { name => "desc" },
                { age => "desc" },
                "_score",
            ],
        }

- Break down structure for clarity when necessary

    For example, the following structure with [Data::Dump](https://metacpan.org/pod/Data%3A%3ADump):

        { from => 0, query => { term => { user => "kimchy" } }, size => 10 }

    would become, under `Data::Pretty`:

        {
            from => 0,
            query => {
                term => { user => "kimchy" },
            },
            size => 10,
        }

- Prevent UTF-8 characters from being encoded in hexadecimal.

    `Data::Dump` would encode `ジャック` as `\x{30B8}\x{30E3}\x{30C3}\x{30AF}`, which although correct, is not human readable.

    However, not encoding in hexadecimal UTF-8 strings means that if you print it out, you will need to set the ["binmode" in perlfunc](https://metacpan.org/pod/perlfunc#binmode) to `utf-8`. You can also use [open](https://metacpan.org/pod/open) when printing on the `STDOUT` or `STDERR`:

        use open ':std' => 'utf8';

    You can disable this by setting `$Data::Pretty::SHOW_UTF8` to false.

- Quoting hash keys

    With `Data::Dump`, whenever at least 1 hash key has non alphanumeric characters, it is rightfully surrounded by double quotes, but unfortunately so are all the other hash keys who do not need surrounding double quotes.

    Thus, for example, [Data::Dump](https://metacpan.org/pod/Data%3A%3ADump) would produce:

        {
            query => {
                term => { user => "kimchy" },
            },
            sort => [
                {
                    _geo_distance => {
                        "distance_type" => "sloppy_arc",
                        "mode" => "min",
                        "order" => "asc",
                        "pin.location" => [-70, 40],
                        "unit" => "km",
                    },
                },
            ],
        }

    whereas, `Data::Pretty` would rather produce:

        {
            query => {
                term => { user => "kimchy" },
            },
            sort => [
                {
                    _geo_distance => {
                        distance_type => "sloppy_arc",
                        mode => "min",
                        order => "asc",
                        "pin.location" => [-70, 40],
                        unit => "km",
                    },
                },
            ],
        }

- Specify literal string values

    You can set a literal string value in your data by passing it to the [literal method](#literal). Normally, a string is quoted and its characters within escaped as they need be. If you use `literal`, the value will be used as-is in the dump.

    For example, consider the following 2 examples, one without and the other with using `literal`

        use Data::Dump qw( dump literal );
        my $ref = 
        {
            name => '$users->[0]',
            values => '["some","thing"]',
        };
        say dump( $ref ); # { name => "\$users->[0]", values => "[\"some\",\"thing\"]" }

        my $ref = 
        {
            name => literal( '$users->[0]' ),
            values => literal( '["some","thing"]' ),
        };
        say dump( $ref ); # { name => $users->[0], values => ["some","thing"] }

The rest of this documentation is identical to the original [Data::Dump](https://metacpan.org/pod/Data%3A%3ADump).

This module provide a few functions that traverse their argument and produces a string as its result. The string contains Perl code that, when `eval`ed, produces a deep copy of the original arguments.

The main feature of the module is that it strives to produce output that is easy to read. Example:

    @a = (1, [2, 3], {4 => 5});
    dump(@a);

Produces:

    (1, [2, 3], { 4 => 5 })

If you dump just a little data, it is output on a single line. If you dump data that is more complex or there is a lot of it, line breaks are automatically added to keep it easy to read.

The following functions are provided (only the [dd](#dd) and [ddx](#ddx) functions are exported by default):

# FUNCTIONS

## dd( ... )

## ddx( ... )

These functions will call [dump](#dump) on their argument and print the result to `STDOUT` (actually, it is the currently selected output handle, but `STDOUT` is the default for that).

The difference between them is only that `ddx` will prefix the lines it prints with "# " and mark the first line with the file and line number where it was called. This is meant to be useful for debug printouts of state within programs.

## dump

Returns a string containing a Perl expression. If you pass this string to Perl's built-in eval() function it should return a copy of the arguments you passed to dump().

If you call the function with multiple arguments then the output will be wrapped in parenthesis `( ..., ... )`.

If you call the function with a single argument the output will not have the wrapping.

If you call the function with a single scalar (non-reference) argument it will just return the scalar quoted if needed, but never break it into multiple lines.

If you pass multiple arguments or references to arrays of hashes then the return value might contain line breaks to format it for easier reading. The returned string will never be `\n` terminated, even if contains multiple lines. This allows code like this to place the semicolon in the expected place:

    print '$obj = ', dump($obj), ";\n";

If `dump` is called in void context, then the dump is printed on STDERR and then `\n` terminated.
You might find this useful for quick debug printouts, but the Ldd|/dd> and ["ddx" in ddx](https://metacpan.org/pod/ddx#ddx) functions might be better alternatives
for this.

There is no difference between [dump](#dump) and [pp](#pp), except that [dump](#dump) shares its name with a not-so-useful perl builtin.  Because of this some might want to avoid using that name.

## dumpf( ..., \\&filter )

Short hand for calling the [dump\_filtered](https://metacpan.org/pod/Data%3A%3APretty%3A%3AFiltered#dump_filtered) function of [Data::Pretty::Filtered](https://metacpan.org/pod/Data%3A%3APretty%3A%3AFiltered).

This works like [dump](#dump), but the last argument should be a filter callback function. As objects are visited the filter callback is invoked and it can modify how the objects are dumped.

## literal

This takes a value and marks it as a literal value that will be used as-is in the resulting dump.

For example, consider the following 2 examples, one without and the other with using `literal`

    use Data::Dump qw( dump literal );
    my $ref = 
    {
        name => '$users->[0]',
        values => '["some","thing"]',
    };
    say dump( $ref ); # { name => "\$users->[0]", values => "[\"some\",\"thing\"]" }

    my $ref = 
    {
        name => literal( '$users->[0]' ),
        values => literal( '["some","thing"]' ),
    };
    say dump( $ref ); # { name => $users->[0], values => ["some","thing"] }

## pp

Same as ["dump"](#dump)

## quote( $string )

Returns a quoted version of the provided string.

It differs from `dump($string)` in that it will quote even numbers and not try to come up with clever expressions that might shorten the output. If a non-scalar argument is provided then it's just stringified instead of traversed.

# CONFIGURATION

There are a few global variables that can be set to modify the output generated by the dump functions. It's wise to localize the setting of these.

## `$Data::Pretty::CODE_DEPARSE`

When set to true, which is the default, this will use [B::Deparse](https://metacpan.org/pod/B%3A%3ADeparse), if available, to reproduce the perl code of the anonymous subroutines found. Note that due to perl's internal way of working, the code reproduced might not be exactly the same as the original.

## `$Data::Pretty::INDENT`

This holds the string that's used for indenting multiline data structures. It's default value is `"    "` (four spaces). Set it to `""` to suppress indentation. Setting it to `"| "` makes for nice visuals even if the dump output then fails to be valid Perl.

## `$Data::Pretty::SHOW_UTF8`

When set to true (default), this will show the UTF-8 texts as is and when set to a false value, this will revert to the [Data::Dump](https://metacpan.org/pod/Data%3A%3ADump) original behaviour of showing the text with its characters encoded in hexadecimal. For example, a string like

    ジャック

would be encoded in [Data::Dump](https://metacpan.org/pod/Data%3A%3ADump) as:

    \x{30B8}\x{30E3}\x{30C3}\x{30AF}

## `$Data::Pretty::TRY_BASE64`

How long must a binary string be before we try to use the [base64 encoding](https://metacpan.org/pod/MIME%3A%3ABase64) for the dump output. The default is `50`. Set it to `0` to disable base64 dumps.

# LIMITATIONS

- 1. Core reference

    Code references will be dumped as `sub { ... }`. Thus, `eval`ing them will not reproduce the original routine. The `...`-operator used will also require perl-5.12 or better to be evaled.

- 2. Importing dump

    If you forget to explicitly import the `dump` function, your code will core dump. That's because you just called the builtin [dump](https://metacpan.org/pod/perlfunc#dump) function by accident, which intentionally dumps core. Because of this you can also import the same function as `pp`, mnemonic for "pretty-print".

# SEE ALSO

[Data::Pretty::Filtered](https://metacpan.org/pod/Data%3A%3APretty%3A%3AFiltered), [Data::Pretty::FilterContext](https://metacpan.org/pod/Data%3A%3APretty%3A%3AFilterContext)

[Data::Dump](https://metacpan.org/pod/Data%3A%3ADump), [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)

# CREDITS

Credits to Gisle Aas for the original [Data::Dump](https://metacpan.org/pod/Data%3A%3ADump) version and to Breno G. de Oliveira for maintaining it.

# COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
