package CXC::Number::Grid::Types;

# ABSTRACT: Type::Tiny types for CXC::Number::Grid

use v5.28;
use strict;
use warnings;

our $VERSION = '0.13';

use Math::BigInt upgrade => 'Math::BigFloat';
use Math::BigFloat;
use List::Util 'all';
use Type::Utils '-all';
use Types::Standard        qw[ CycleTuple Num Int Enum Tuple Any InstanceOf Dict ArrayRef Value ];
use Types::Common::Numeric qw[ PositiveNum PositiveOrZeroNum PositiveInt ];

use Type::Library -base, -declare => qw(
  BinEdges
  BinBounds
  Spacing
  MonotonicallyIncreasingArrayOfBigNums
);

BEGIN { extends 'CXC::Number::Types' }







declare BinEdges, as ArrayRef [ BigNum, 2 ], where {
    my $arr = $_;
    $arr->[$_] < $arr->[ $_ + 1 ] || return for 0 .. ( $arr->@* - 2 );
    1;
}, message {
    ArrayRef( [ BigNum, 2 ] )->validate( $_ )
      or 'Must be an array of monotonically increasing numbers with at lest two elements'
}, coercion => 1;

coerce BinEdges, from InstanceOf ['CXC::Number::Sequence'], via { $_->bignum->elements }
;

declare BinBounds, as CycleTuple [ BigNum, BigNum ], where {
    return unless $_->@*;
    my $lval = $_->[0];
    my $ub   = 0;         # this gets toggled between true and false
    return all {
        ( my $_lval, $lval ) = ( $lval, $_ );
        ( my $_ub,   $ub )   = ( $ub,   1 - $ub );    # save ub flag and toggle it for next round.
        $_ub ? $_ > $_lval : $_ >= $_lval;
    } $_->@*;
}, message {
    # it's either
    # 1. not pairs,
    # 2. not pairs of numbers,
    # 3. not sorted
    !eval { CycleTuple( [ BigNum, BigNum ] )->assert_coerce( $_ ); $_->@* }
      ? 'Must be non-empty array of numbers with an even number of elements'
      : 'The elements in the array must be in ascending order';
}, coercion => 1;

1;

#
# This file is part of CXC-Number
#
# This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory BinEdges

=head1 NAME

CXC::Number::Grid::Types - Type::Tiny types for CXC::Number::Grid

=head1 VERSION

version 0.13

=head1 TYPES

=head2 BinEdges

A array of numbers with at lest two members which is sorted by increasing value

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-number@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-number

and may be cloned from

  https://gitlab.com/djerius/cxc-number.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Number|CXC::Number>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
