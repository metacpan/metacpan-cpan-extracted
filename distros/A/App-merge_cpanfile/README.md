# NAME

App::merge\_cpanfile - Merge multiple cpanfile into one

# SYNOPSIS

    cat core.cpanfile
    # requires 'Carp';
    cat sub.cpanfile
    # requires 'LWP::UserAgent';
    merge-cpanfile core.cpanfile sub.cpanfile
    # requires 'Carp';
    # requires 'LWP::UserAgent';

# DESCRIPTION

App::merge\_cpanfile merges multiple cpanfile into one cpanfile.

It's handy way to manage dependencies of private modules same as published CPAN modules'.

# LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

aereal <aereal@aereal.org>
