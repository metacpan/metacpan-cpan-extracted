package CXC::Number::Grid::Range;

# ABSTRACT: Helper class to track Ranges

use v5.28;

use Moo;
use experimental 'signatures';

use namespace::clean;

our $VERSION = '0.12';

use overload
  fallback => 0,
  bool     => sub { 1 },
  '""'     => \&to_string,
  '.'      => \&concatenate;







has layer => ( is => 'ro' );







has include => ( is => 'ro' );







has lb => ( is => 'ro' );







has ub => ( is => 'ro' );






around BUILDARGS => sub ( $orig, $class, @args ) {

    my %args = ref $args[0] ? $args[0]->%* : @args;

    @args{ 'layer', 'include' } = delete( $args{value} )->@*
      if defined $args{value};

    return $class->$orig( \%args );
};















sub to_string ( $self, $ =, $ = ) {
    my $ub      = $self->ub      // 'undef';
    my $lb      = $self->lb      // 'undef';
    my $layer   = $self->layer   // 'undef';
    my $include = $self->include // 'undef';
    "( $lb, $ub ) => { layer => $layer, include => $include }";
}















sub concatenate ( $self, $other, $swap = 0 ) {
    my $str = $self->to_string;
    return $swap ? $other . $str : $str . $other;
}










sub value ( $self ) {
    return [ $self->layer, $self->include ];
}

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory ub

=head1 NAME

CXC::Number::Grid::Range - Helper class to track Ranges

=head1 VERSION

version 0.12

=head1 DESCRIPTION

A utility class to manage Ranges when doing bin manipulations with trees.

=head1 OBJECT ATTRIBUTES

=head2 layer

The grid layer id

=head2 include

Whether this range is included or excluded.

=head2 lb

The inclusive range lower bound

=head2 ub

The exclusive range upper bound

=head1 METHODS

=head2 to_string

  $string = $self->to_string

Return a string representation of the range.

=head2 concatenate

  $string = $range->concatenate( $thing, $swap=false )

Concatenate the stringified version of $range with $thing.

Set C<$swap> to true if the order should be reversed.

=head2 value

  [ $layer, $include ] = $range->value;

Return an arrayref containing the layer id and the include value for
the range.

=head1 OVERLOAD

=head2 ""

Stringification is overloaded via the L</to_string> method.

=head2 .

Concatenation is overloaded via the L</concatenate> method.

=head1 INTERNALS

=for Pod::Coverage BUILDARGS

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
