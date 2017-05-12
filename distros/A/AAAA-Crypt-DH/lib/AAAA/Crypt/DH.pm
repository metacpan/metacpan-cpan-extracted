package AAAA::Crypt::DH;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.06';

qq[Making Crypt::DH installable];

__END__

=head1 NAME

AAAA::Crypt::DH - making Crypt::DH installable

=head1 SYNOPSIS

  # in Makefile.PL

  requires 'AAAA::Crypt::DH';

=head1 DESCRIPTION

AAAA::Crypt::DH is a L<Task> distribution that makes sure that either
L<Math::BigInt::GMP> or L<Math::BigInt::Pari> are installed so that
L<Crypt::DH> works at a speed approaching reasonable.

If you have a dependency on L<Crypt::DH> add AAAA::Crypt::DH as an
additional dependency and one of the above Math libs will be installed
before L<Crypt::DH>.

Why the C<'AAAA'>? Well, L<CPAN> and L<CPANPLUS> install prereqs sorted
alphabetically, the C<'AAAA'> ensures that this prereq is installed before
L<Crypt::DH>. Simples.

=head1 AUTHOR

Chris C<BinGOs> Williams

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Crypt::DH::GMP>

L<Math::BigInt::GMP>

L<Math::BigInt::Pari>

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Crypt-DH>

L<http://cpanratings.perl.org/dist/Crypt-DH>

=cut
