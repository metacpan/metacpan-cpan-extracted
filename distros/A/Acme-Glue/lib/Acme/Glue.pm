package Acme::Glue;

use utf8;
use strict;
use warnings;

$Acme::Glue::VERSION = "2019.08";

=encoding utf8

=head1 NAME

Acme::Glue - A placeholder module for code accompanying a Perl photo project

=head1 VERSION

2019.08

=head1 DESCRIPTION

Acme::Glue is the companion Perl module for a Perl photo project, the idea
for the photo project is to have each photo include a small snippet of code.
The code does not have to be Perl, it just has to be something you're quite
fond of for whatever reason

=head1 SNIPPETS

Here are the snippets that accompany the photo project

=head2 LEEJO

    # transform an array of hashes into an array of arrays where each array
    # contains the values from the hash sorted by the original hash keys or
    # the passed order of columns (hash slicing)
    my @field_data = $column_order
        ? map { [ @$_{ @{ $column_order } } ] } @{ $data }
        : map { [ @$_{sort keys %$_} ] } @{ $data };


=head1 THANKS

Thanks to all who contributed a snippet

=head1 SEE ALSO

L<https://leejo.github.io/projects/>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/acme-glue

All photos © Lee Johnson

=cut

1;
