# NAME

App::Prove::Plugin::CumulativeTimer - A prove plugin to display cumulative elapsed time of tests.

# SYNOPSIS

    $ prove -PCumulativeTimer tests

    # [14:22:52] tests/test1.t .. ok     2052 ms ( 0.00 usr  0.00 sys +  0.04 cusr  0.01 csys =  0.05 CPU)
    # [14:22:54] tests/test2.t .. ok     2111 ms ( 0.01 usr  0.00 sys +  0.08 cusr  0.02 csys =  0.11 CPU)

    # When you don't use this plugin, elapsed time of tests/tes2.t is not cumulative.
    $ prove --timer tests

    # [14:22:31] tests/test1.t .. ok     2049 ms ( 0.00 usr  0.00 sys +  0.04 cusr  0.01 csys =  0.05 CPU)
    # [14:22:33] tests/test2.t .. ok       60 ms ( 0.01 usr  0.00 sys +  0.05 cusr  0.01 csys =  0.07 CPU)

# DESCRIPTION

App::Prove::Plugin::CumulativeTimer is a prove plugin to display cumulative elapsed time of tests.

This plugin replaces elaped time of --timer option with cumulative elapsed time.

\--timer option is always set when you load this plugin.

# LICENSE

Copyright (C) Masahiro Iuchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Iuchi <masahiro.iuchi@gmail.com>
