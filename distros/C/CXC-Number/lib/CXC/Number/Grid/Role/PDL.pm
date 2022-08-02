package CXC::Number::Grid::Role::PDL;

# ABSTRACT: Role to return PDL objects

use feature ':5.24';
use PDL::Lite ();

use Moo::Role;

use experimental 'signatures';
use namespace::clean;

our $VERSION = '0.08';

sub _convert ( $self, $bignum ) {
    require Ref::Util;

    return Ref::Util::is_plain_arrayref( $bignum )
      ? PDL->pdl( [ map { $_->numify } $bignum->@* ] )
      : $bignum->numify;
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::Number::Grid::Role::PDL - Role to return PDL objects

=head1 VERSION

version 0.08

=head1 SYNOPSIS

   my $obj = CXC::Number::Grid->new( edges => \@edges );
   Moo::Role->apply_role_to_object( $obj, 'CXC::Number::Grid::Role::PDL' );

=head1 DESCRIPTION

A L<Moo> role providing a C<_convert> method which returns passed
L<Math::BigFloat> arrays as piddles and passed L<Math::BigFloat> scalars as Perl numbers.

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

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
