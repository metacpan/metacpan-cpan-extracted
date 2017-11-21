package Algorithm::AM::BigInt;
use strict;
use warnings;
our $VERSION = '3.11';
# ABSTRACT: Helper functions for AM big integers
use Exporter::Easy (
    OK => ['bigcmp']
);

#pod =head1 SYNOPSIS
#pod
#pod  use Algorithm::AM::BigInt 'bigcmp';
#pod  # get some big integers from Algorithm::AM::Result
#pod  my ($a, $b);
#pod  bigcmp($a, $b);
#pod
#pod =head1 DESCRIPTION
#pod
#pod AM uses custom 128-bit unsigned integers in its XS code, and these
#pod numbers cannot be treated normally in Perl code. This package provides
#pod some helper functions for working with these numbers.
#pod
#pod =head2 DETAILS
#pod
#pod Under the hood, the big integers used by AM are scalars with the
#pod following fields:
#pod
#pod =over
#pod
#pod =item NV
#pod
#pod This is an inexact double representation of the integer value.
#pod
#pod =item PV
#pod
#pod This is an exact string representation of the integer value.
#pod
#pod =back
#pod
#pod Operations on the floating-point representation will necessarily have a
#pod small amount of error, so exact calculation or comparison requires
#pod referencing the string field. The number field is still useful in
#pod printing reports; for example, using C<printf>, where precision can
#pod be specified.
#pod
#pod Currently, the only provided helper function is for comparison of
#pod two big integers.
#pod
#pod =head2 C<bigcmp>
#pod
#pod Compares two big integers, returning 1, 0, or -1 depending on whether
#pod the first argument is greater than, equal to, or less than the second
#pod argument.
#pod
#pod =cut
sub bigcmp {
    my($a,$b) = @_;
    return (length($a) <=> length($b)) || ($a cmp $b);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::AM::BigInt - Helper functions for AM big integers

=head1 VERSION

version 3.11

=head1 SYNOPSIS

 use Algorithm::AM::BigInt 'bigcmp';
 # get some big integers from Algorithm::AM::Result
 my ($a, $b);
 bigcmp($a, $b);

=head1 DESCRIPTION

AM uses custom 128-bit unsigned integers in its XS code, and these
numbers cannot be treated normally in Perl code. This package provides
some helper functions for working with these numbers.

=head2 DETAILS

Under the hood, the big integers used by AM are scalars with the
following fields:

=over

=item NV

This is an inexact double representation of the integer value.

=item PV

This is an exact string representation of the integer value.

=back

Operations on the floating-point representation will necessarily have a
small amount of error, so exact calculation or comparison requires
referencing the string field. The number field is still useful in
printing reports; for example, using C<printf>, where precision can
be specified.

Currently, the only provided helper function is for comparison of
two big integers.

=head2 C<bigcmp>

Compares two big integers, returning 1, 0, or -1 depending on whether
the first argument is greater than, equal to, or less than the second
argument.

=head1 AUTHOR

Theron Stanford <shixilun@yahoo.com>, Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Royal Skousen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
