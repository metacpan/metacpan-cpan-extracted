# NAME

Acme::Glue - A placeholder module for code accompanying a Perl photo project

# VERSION

2019.08

# DESCRIPTION

Acme::Glue is the companion Perl module for a Perl photo project, the idea
for the photo project is to have each photo include a small snippet of code.
The code does not have to be Perl, it just has to be something you're quite
fond of for whatever reason

# SNIPPETS

Here are the snippets that accompany the photo project

## LEEJO

    # transform an array of hashes into an array of arrays where each array
    # contains the values from the hash sorted by the original hash keys or
    # the passed order of columns (hash slicing)
    my @field_data = $column_order
        ? map { [ @$_{ @{ $column_order } } ] } @{ $data }
        : map { [ @$_{sort keys %$_} ] } @{ $data };

# THANKS

Thanks to all who contributed a snippet

# SEE ALSO

[https://leejo.github.io/projects/](https://leejo.github.io/projects/)

# AUTHOR

Lee Johnson - `leejo@cpan.org`

# LICENCE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/acme-glue

All photos © Lee Johnson
