package CXC::Number::Sequence;

# ABSTRACT: Numerical Sequence Generation

use feature ':5.24';

use Carp;

use POSIX ();

use CXC::Number::Sequence::Types qw( Sequence );
use CXC::Number::Sequence::Failure -all;
use CXC::Number::Sequence::Utils qw( load_class );

use Moo;

use experimental 'signatures';

our $VERSION = '0.08';

use namespace::clean;

use MooX::StrictConstructor;

# subclass should define
has _raw_elements => (
    is       => 'lazy',
    init_arg => 'elements',
    isa      => Sequence,
    required => 1,
    coerce   => 1,
);


sub _convert ( $self, $bignum ) {
    require Ref::Util;

    return Ref::Util::is_plain_arrayref( $bignum )
      ? [ map { $_->numify } $bignum->@* ]
      : $bignum->numify;
}










sub elements ( $self ) {
    $self->_convert( $self->_raw_elements );
}









sub nelem ( $self ) {
    scalar $self->_raw_elements->@*;
}











sub spacing ( $self ) {
    my $elements = $self->_raw_elements;
    my @spacing  = map { $elements->[$_] - $elements->[ $_ - 1 ] }
      1 .. ( $self->nelem - 1 );
    return $self->_convert( \@spacing );
}









sub min ( $self ) {
    return $self->_convert( $self->_raw_elements->[0] );
}









sub max ( $self ) {
    return $self->_convert( $self->_raw_elements->[-1] );
}



















sub build ( $, $type, %options ) {
    load_class( $type )->new( %options );
}















sub bignum ( $self ) {
    require Moo::Role;
    return Moo::Role->apply_roles_to_object(
        __PACKAGE__->new( elements => $self->_raw_elements ),
        __PACKAGE__ . '::Role::BigNum',
    );
}













sub pdl ( $self ) {
    require Moo::Role;
    return Moo::Role->apply_roles_to_object(
        __PACKAGE__->new( elements => $self->_raw_elements ),
        __PACKAGE__ . '::Role::PDL',
    );
}


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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory nelem bignum pdl

=head1 NAME

CXC::Number::Sequence - Numerical Sequence Generation

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  use CXC::Number::Sequence;

  CXC::Number::Sequence->build( $type, %options );

=head1 DESCRIPTION

This is an entry point for building sequences of numbers.

B<WARNING>

Currently, a sequence is a subclass of C<CXC::Number::Sequence>, but
this may change to a role based relationship.

=head2 Constraints

At present sequences are not lazily built.  This can easily be
accommodated and iterators added.

=head1 CONSTRUCTORS

=head2 build

  $sequence = CXC::Number::Sequence->build( $class, %options );

Construct a sequence of type C<$class>, where C<$class> is a subclass of
B<CXC::Number::Sequence>.  If C<$class> is in the C<CXC::Number::Sequence>
namespace, only the relative class name is required, e.g.

  linear => CXC::Number::Sequence::Linear

(note that C<$class> is converted to I<CamelCase>; input words should be separated by a C<_>).

C<build> will first attempt to load C<$class> in the
C<CXC::Number::Sequence> namespace, and if not present will assume
C<$class> is a full package name.

=head1 METHODS

=head2 elements

  $array_ref = $sequence->elements;

Return the sequence elements as a reference to an array of Perl
numbers.

=head2 nelem

  $nelem = $sequence->nelem;

The number of elements in the sequence.

=head2 spacing

  $spacing = $sequence->spacing;

Return the spacing between elements as a reference to an array of Perl
numbers.

=head2 min

  $min = $sequence->min;

Returns the minimum bound of the sequence as a Perl number.

=head2 max

  $max = $sequence->max;

Returns the maximum bound of the sequence as a Perl number.

=head2 bignum

  $elements = $sequence->bignum->elements;

Returns an object which returns copies of the internal
L<Math::BigFloat> objects for the following methods

  elements -> Array[Math::BigFloat]
  spacing  -> Array[Math::BigFloat]
  min      -> Math::BigFloat
  max      -> Math::BigFloat

=head2 pdl

  $elements = $sequence->pdl->elements;

Returns an object which returns piddles for the following methods

  elements -> piddle
  spacing  -> piddle

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

=item *

L<CXC::Number::Grid|CXC::Number::Grid>

=item *

L<CXC::Number::Sequence::Linear|CXC::Number::Sequence::Linear>

=item *

L<CXC::Number::Sequence::Ratio|CXC::Number::Sequence::Ratio>

=item *

L<CXC::Number::Sequence::Fixed|CXC::Number::Sequence::Fixed>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
