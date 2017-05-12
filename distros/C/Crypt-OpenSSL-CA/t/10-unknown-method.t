#!perl -w

=head1 NAME

10-unknown-method.t - Calls an undefined method in
L<Crypt::OpenSSL::CA> and checks that the error message is not
misleading (as it used to be)

=cut

use Test::More "no_plan";

use_ok "Crypt::OpenSSL::CA";

eval {
    Crypt::OpenSSL::CA::X509->barf_me_harder;
};
like($@, qr/^Can't locate/);
