use strict;
use warnings;

package DBIx::SearchBuilder::Util;
use base 'Exporter';

our @EXPORT_OK = qw(
    sorted_values
);

=head1 NAME

DBIx::SearchBuilder::Util - Utility and convenience functions for DBIx::SearchBuilder

=head1 SYNOPSIS

    use DBIx::SearchBuilder::Util qw( sorted_values );  # or other function you want

=head1 EXPORTED FUNCTIONS

=head2 sorted_values

Takes a hash or hashref and returns the values sorted by their respective keys.

Equivalent to

    map { $hash{$_} } sort keys %hash

but far more convenient.

=cut

sub sorted_values {
    my $hash = @_ == 1 ? $_[0] : { @_ };
    return map { $hash->{$_} } sort keys %$hash;
}

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Best Practical Solutions, LLC.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
