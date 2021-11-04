#!perl -w

=head1 NAME

10-unknown-method.t - Calls an undefined method in
L<Crypt::OpenSSL::CA> and checks that the error message is not
misleading (as it used to be)

=cut

use Test2::V0;

use Crypt::OpenSSL::CA;

eval {
    Crypt::OpenSSL::CA::X509->barf_me_harder;
};
like($@, qr/^Can't locate/);

done_testing;
