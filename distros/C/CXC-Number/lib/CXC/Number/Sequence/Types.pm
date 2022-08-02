package CXC::Number::Sequence::Types;

# ABSTRACT: Type::Tiny types for CXC::Number::Sequence

use strict;
use warnings;

our $VERSION = '0.08';

use Math::BigInt upgrade => 'Math::BigFloat';
use Math::BigFloat;
use Type::Utils -all;
use Types::Standard qw[ Num Int Enum Tuple Any InstanceOf Dict ArrayRef Value ];
use Types::Common::Numeric qw[ PositiveNum PositiveOrZeroNum PositiveInt ];

use Type::Library -base, -declare => qw(
  Alignment
  Sequence
  Spacing
  Ratio
);

BEGIN { extends( "CXC::Number::Types" ) }













declare Alignment, as Tuple [ BigNum, BigPositiveOrZeroNum ],
  where { $_->[1] < 1 },
  coercion => 1;

coerce Alignment,
  from Num,
  via { [ Math::BigFloat->new( $_ ), Math::BigFloat->new( 0.5 ) ] };








declare Sequence, as ArrayRef [ BigNum, 2 ], where {
    my $arr = $_;
    $arr->[$_] < $arr->[ $_ + 1 ] || return for 0 .. ( $arr->@* - 2 );
    1;
}, message {
    ArrayRef( [ BigNum, 2 ] )->validate( $_ )
      or
      "Must be an array of monotonically increasing numbers with at lest two elements"
}, coercion => 1;








declare Spacing, as BigNum,
  where { $_ != 0 },
  message { BigNum->validate( $_ ) or "Must be a non-zero number" },
  coercion => 1;








declare Ratio, as BigNum,
  where { $_ > 0 && $_ != 1 },
  message { BigNum->validate( $_ ) or "$_ must be > 0 && != 1." },
  coercion => 1;

#
# This file is part of CXC-Number
#
# This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory bignum

=head1 NAME

CXC::Number::Sequence::Types - Type::Tiny types for CXC::Number::Sequence

=head1 VERSION

version 0.08

=head1 TYPES

=head2 Alignment

A Tuple containing two elements, the first of which is a C<BigNum>,
the second of which is a C<BigNum> in the range [0,1).

=head2 Sequence

A array of numbers with at lest two members which is sorted by increasing value

=head2 Spacing

A non-zero BigNum

=head2 Ratio

A positive number greater than 1.

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-number@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number

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
