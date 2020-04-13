# NAME

Data::Dumper::AutoEncode::AsDumper - Dump encoded data with Dumper()

# SYNOPSIS

    use utf8;
    use Data::Dumper::AutoEncode::AsDumper;

    $data = {
        русский  => 'доверяй, но проверяй',
        i中文    => '也許你的生活很有趣',
        Ελληνικά => 'ἓν οἶδα ὅτι οὐδὲν οἶδα',
    };

    say 'proverbs', Dumper $data;

# DESCRIPTION

This package implements a wrapper around the excellent module
[Data::Dumper::AutoEncode](https://metacpan.org/pod/Data%3A%3ADumper%3A%3AAutoEncode), which provides a function (`eDumper`) to
output encoded data with [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper). If you use this module
instead, you can still use `Dumper $data` in your code, but the output
will be encoded.

## CONCISION

The following `Data::Dumper` options are set:

    $Data::Dumper::Indent        = 1;
    $Data::Dumper::Quotekeys     = 0;
    $Data::Dumper::Sortkeys      = 1;
    $Data::Dumper::Terse         = 1;
    $Data::Dumper::Trailingcomma = 1;

# EXPORTED FUNCTION

**Dumper(LIST)**

This module exports one function, `Dumper`. It works just like the
original, except that output is encoded, by default to `utf8`.

If you want to change the encoding, set the global:

    $Data::Dumper::AutoEncode::ENCODING = 'CP932';

## EXPORTS TO SUBCLASSES BY DEFAULT

This module uses the excellent [Import::Into](https://metacpan.org/pod/Import%3A%3AInto) so that any subclass
of a class that uses it will import the `Dumper` function.

You can turn this behaviour off by setting the global:

    $Data::Dumper::AutoEncode::AsDumper:ImportInto = 0;

# SEE ALSO

[Data::Dumper::AutoEncode](https://metacpan.org/pod/Data%3A%3ADumper%3A%3AAutoEncode), [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 13:

    Non-ASCII character seen before =encoding in 'русский'. Assuming UTF-8
