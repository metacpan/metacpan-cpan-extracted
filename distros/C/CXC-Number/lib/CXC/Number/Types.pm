package CXC::Number::Types;

# ABSTRACT: Type::Tiny types for CXC::Number

use strict;
use warnings;

our $VERSION = '0.05';

use Math::BigInt upgrade => 'Math::BigFloat';
use Math::BigFloat;
use Type::Utils;
use Types::Standard qw[ Num Int InstanceOf  ];
use Types::Common::Numeric qw[ PositiveNum PositiveOrZeroNum PositiveInt ];

use Type::Library -base, -declare => qw(
  BigInt
  BigNum
  BigPositiveInt
  BigPositiveNum
  BigPositiveOrZeroNum
);





class_type BigNum,
  {
    class => 'Math::BigFloat',
    message { 'Not a number or a Math::BigFloat' },
  };

coerce BigNum,
  from Num,
  via {
      my $bignum = Math::BigFloat->new( $_ );
      $bignum->is_nan ? $_ : $bignum;
};





declare BigPositiveNum,
  as BigNum,
  where { $_ > 0 },
  message { BigNum->validate( $_ ) or "$_ is not greater than zero" },
  coercion => 1;

coerce BigPositiveNum,
  from PositiveNum,
  via { Math::BigFloat->new( $_ ) };





declare BigPositiveOrZeroNum,
  as BigNum,
  where { $_ >= 0 },
  message {
    BigNum->validate( $_ )
      or "$_ is not greater than or equal to zero"
}, coercion => 1;





coerce BigPositiveOrZeroNum,
  from PositiveOrZeroNum,
  via { Math::BigFloat->new( $_ ) };





declare BigInt,
  as( InstanceOf ['Math::BigInt'] | InstanceOf ['Math::BigFloat'] ),
  where { $_->is_int() }, message {
    'Not an integer or a Math::BigInt'
  };

coerce BigInt,
  from Int,
  via {
    Math::BigInt->new( $_ );
};







declare BigPositiveInt,
  as BigInt,
  where { $_ > 0 },
  message { BigInt->validate( $_ ) or "$_ is not greater than zero" },
  coercion => 1;

coerce BigPositiveInt,
  from PositiveInt,
  via { Math::BigFloat->new( $_ ) };


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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory BigInt BigNum
BigPositiveInt BigPositiveNum BigPositiveOrZeroNum BigPositiveZeroNum

=head1 NAME

CXC::Number::Types - Type::Tiny types for CXC::Number

=head1 VERSION

version 0.05

=head1 TYPES

=head2 BigNum

=head2 BigPositiveNum

=head2 BigPositiveZeroNum

=head2 BigPositiveOrZeroNum

=head2 BigInt

=head2 BigPositiveInt

A BigInt > 0.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number> or by email
to L<bug-cxc-number@rt.cpan.org|mailto:bug-cxc-number@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

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
