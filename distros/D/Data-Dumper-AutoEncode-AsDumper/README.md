# NAME

Data::Dumper::AutoEncode::AsDumper - Concise, encoded data dumping with Dumper(), everywhere

# SYNOPSIS

    use utf8;
    use Data::Dumper::AutoEncode::AsDumper;

    $data = {
        русский  => 'доверяй, но проверяй',
        i中文    => '也許你的生活很有趣',
        Ελληνικά => 'ἓν οἶδα ὅτι οὐδὲν οἶδα',
    };

    say 'proverbs', Dumper $data; # output encode to utf8

# DESCRIPTION

    L<Data::Dumper> decodes data before dumping it, making it unreadable
    for humans. This module exports the C<Dumper> function, but the
    dumped output is encoded.

# EXPORTED FUNCTION

- **Dumper(LIST)**

    This module exports one function, `Dumper`. It works just like the
    original, except that output is encoded, by default to `utf8`.

    If you want to change the encoding, set the global:

        $Data::Dumper::AutoEncode::ENCODING = 'CP932';

# WHY USE THIS MODULE?

This package implements a thin wrapper around the excellent module
[Data::Dumper::AutoEncode](https://metacpan.org/pod/Data%3A%3ADumper%3A%3AAutoEncode). Reasons to use this instead include:

- **Convenience**

    If you use this module you can just call `Dumper` as you normally
    would if you used [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper), rather than having to call
    [Data::Dumper::AutoEncode::eDumper](https://metacpan.org/pod/Data%3A%3ADumper%3A%3AAutoEncode#METHOD).
    Any existing code will continue to work, with better output.

    _(Note: You can now obtain the same behaviour by using an import
    option with [Data::Dumper::AutoEncode](https://metacpan.org/pod/Data%3A%3ADumper%3A%3AAutoEncode), but that was not implemented
    when this module was first released.)_

- **Concision**

    The following `Data::Dumper` options are set:

        $Data::Dumper::Indent        = 1;
        $Data::Dumper::Quotekeys     = 0;
        $Data::Dumper::Sortkeys      = 1;
        $Data::Dumper::Terse         = 1;
        $Data::Dumper::Trailingcomma = 1;

- **Exports to main package by default**

    This module uses the excellent [Import::Into](https://metacpan.org/pod/Import%3A%3AInto) so that the `Dumper`
    function will be imported into the caller's `main` package, no matter
    where the module is loaded.

    To turn off this behaviour, set the global in a `BEGIN` block before
    loading the module:

        $Data::Dumper::AutoEncode::AsDumper::NoImportInto = 1;

# ACKNOWLEDGEMENTS

Dai Okabayashi ([BAYASHI](https://metacpan.org/author/BAYASHI))

Graham Knop ([HAARG](https://metacpan.org/author/HAARG))

Gurusamy Sarathy ([GSAR](https://metacpan.org/author/GSAR)) ( and Sawyer X ([XSAWYERX](https://metacpan.org/author/XSAWYERX)) )

Slaven Rezić ([SREZIC](https://metacpan.org/author/SREZIC))

[CPAN Testers](http://cpantesters.org/)

[All the dzil contributors](http://dzil.org/)

[Athanasius](https://perlmonks.org/?node=Athanasius)

I stand on the shoulders of giants ...

# SEE ALSO

[Data::Dumper::AutoEncode](https://metacpan.org/pod/Data%3A%3ADumper%3A%3AAutoEncode), [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)
