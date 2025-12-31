package Array::Join;

# ABSTRACT: performs SQL-like joins on arrays

use v5.20;                          # Require at least Perl 5.20
no warnings 'experimental::signatures';   # Silence “experimental” warnings
use feature 'signatures';           # Turn on the feature
use strict;
use warnings;

use parent 'Exporter';  # inherit all of Exporter's methods

our @EXPORT = qw(join_arrays);

use Mojo::Util qw/dumper/;

use Array::Join::OO;

sub join_arrays {
    return Array::Join::OO->new(@_)->join
}


=head1 NAME

Array::Join - SQL-like joins on Perl arrays (functional interface)

=head1 SYNOPSIS

    use Array::Join;

    my @rows = join_arrays(
        \@left,
        \@right,
        {
            on => [
                sub { $_[0]{id} },
                sub { $_[0]{id} },
            ],
            type  => 'left',
            merge => 'LEFT_PRECEDENT',
        }
    );

=head1 DESCRIPTION

C<Array::Join> provides a simple functional interface for performing
SQL-style joins on two Perl arrays.

It is a thin wrapper around L<Array::Join::OO>, exposing the same
behavior and options without requiring object construction.

=head1 FUNCTIONS

=head2 join_arrays( \@array_a, \@array_b, \%options )

Performs a join between two arrays and returns the joined rows.

This function constructs an internal L<Array::Join::OO> object and
immediately executes the join.

All arguments and options are passed through unchanged.

=head3 Arguments

=over 4

=item * \@array_a

Left-hand array.

=item * \@array_b

Right-hand array.

=item * \%options

Join options. See L<Array::Join::OO/CONSTRUCTOR> for full details.

=back

=head1 OPTIONS

The C<%options> hash supports the same keys as L<Array::Join::OO>:

=over 4

=item * on

=item * type

=item * merge / as

=back

Refer to L<Array::Join::OO> for detailed semantics.

=head1 RETURN VALUE

Returns a list of joined rows. The exact structure of each row depends
on the selected merge strategy.

=head1 ERRORS

Exceptions thrown by L<Array::Join::OO> are propagated unchanged.


=head1 CAVEATS

This release is backwardly incompatible, in the unlilkely event that you used the past, horribly buggy version.

This was built for convenience, not performance. It's never been tested for very large arrays

=head1 SEE ALSO

L<Array::Join::OO>, L<Hash::Merge>

=head2 AUTHOR

Simone Cesano <scesano@cpan.org>

=head2 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
