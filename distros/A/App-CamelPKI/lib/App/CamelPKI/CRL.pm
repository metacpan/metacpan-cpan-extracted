#!perl -w

package App::CamelPKI::CRL;
use strict;

=head1 NAME

B<App::CamelPKI::CRL> - Model for X509 Certificate Revocation List (CRL) in
Camel-PKI

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  use App::CamelPKI::CRL;

  my $cert = parse App::CamelPKI::CRL($pemstring, -format => "PEM");

  my $derstring = $cert->serialize(-format => "DER");

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

Instances from this class are immuables and modelize CRLs, no
matter these CRLs are issued by App-PKI or not.

=cut

use base "App::CamelPKI::PEM";

sub _marker { "X509 CRL" }

=head2 is_member($certificate)

Returns a value true if and only if $certificate, a
L<App::CamelPKI::Certificate> instance, is member of the CRL.

=cut

sub is_member {
    my ($self, $certificate) = @_;
    use IPC::Run;

    my $in = $self->serialize(-format => "DER");
    my ($dump, $err);
    IPC::Run::run([qw(openssl crl -inform der -noout -text)],
                  \$in, \$dump, \$err);
    die $err if $?;

    my ($serial) = $certificate->get_serial =~ m/^0x(.*)$/;
    $serial = uc($serial);

    return ($dump =~ m/Serial Number: $serial/);
}

=begin internals

=cut

require My::Tests::Below unless caller;
1;

__END__

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use File::Slurp;
use App::CamelPKI::Test qw(test_CRL %test_rootca_certs %test_public_keys
                      %test_keys_plaintext);
use App::CamelPKI::Certificate;
use Crypt::OpenSSL::CA;

test "round trip" => sub {
    my $crl = test_CRL("rsa1024");
    is(App::CamelPKI::CRL->parse($crl)->serialize(),
       $crl, "round trip");
};

test "->is_member" => sub {
    my $crlpem = test_CRL("rsa1024", -members => [ "0x42abcdef" ]);
    my $crl = App::CamelPKI::CRL->parse($crlpem);
    ok(! $crl->is_member(App::CamelPKI::Certificate
                         ->parse($test_rootca_certs{"rsa1024"})));
    my $cert = Crypt::OpenSSL::CA::X509->new
        (Crypt::OpenSSL::CA::PublicKey->parse_RSA
         ($test_public_keys{"rsa1024"}));
    $cert->set_serial("0x42abcdef");
    ok($crl->is_member
       (App::CamelPKI::Certificate->parse
        ($cert->sign(Crypt::OpenSSL::CA::PrivateKey->parse
                     ($test_keys_plaintext{"rsa1024"}),
                     "sha256"))));
};

=end internals

=cut
