# NAME

App::Prove::Plugin::RandomSeed - A prove plugin to get/set random seed of shuffled test.

# SYNOPSIS

    # Get random seed and always set --shuffle option.
    $ prove -PRandomSeed

    # Set random seed and always set --shuffle option.
    $ prove -PRandomSeed=3470738367

# DESCRIPTION

App::Prove::Plugin::RandomSeed is a prove plugin to get/set random seed of shuffled test.

This is useful for the investigation of failed test with --shuffle option.

\--shuffle option is always set when you load this plugin.

# LICENSE

Copyright (C) Masahiro Iuchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Iuchi <masahiro.iuchi@gmail.com>
