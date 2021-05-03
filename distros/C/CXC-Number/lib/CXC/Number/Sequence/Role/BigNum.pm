package CXC::Number::Sequence::Role::BigNum;

# ABSTRACT: Role to return Math::BigFloats from Sequences

use feature ':5.24';

use Moo::Role;

our $VERSION = '0.05';

use experimental 'signatures';
use namespace::clean;

sub _convert ( $self, $bignum ) {
    require Ref::Util;

    return Ref::Util::is_plain_arrayref( $bignum )
      ? [ map { $_->copy } $bignum->@* ]
      : $bignum->copy;
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

CXC::Number::Sequence::Role::BigNum - Role to return Math::BigFloats from Sequences

=head1 VERSION

version 0.05

=head1 SYNOPSIS

   my $obj = CXC::Number::Sequence->build( $class, %options)->elements => \@elements );
   Moo::Role->apply_role_to_object( $obj, 'CXC::Number::Sequence::Role::BigNum' );

=head1 DESCRIPTION

A L<Moo> role providing a C<_convert> method which returns copies of the
passed L<Math::BigFloat> arrays and scalars.

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

=item *

L<CXC::Number::Sequence|CXC::Number::Sequence>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
