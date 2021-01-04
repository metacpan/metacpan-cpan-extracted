# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Crypt-X509-CRL.t'
use Test::More tests => 13;
BEGIN { use_ok('Crypt::X509::CRL') }
$crl = loadcrl('t/crl.crl');
is( length $crl, 8422, 'crl file loaded' );
$decoded = Crypt::X509::CRL->new( crl => $crl );
ok( defined $decoded, 'new() returned something' );
ok( $decoded->isa('Crypt::X509::CRL'), 'and it\'s the right class' );
is( $decoded->error, undef, 'decode successful' );
is( $decoded->this_update, 1167652147, 'this_update got parsed' );
is( $decoded->next_update, 1167716947, 'next_update got parsed' );
is( $decoded->crl_number, 1711, 'crl_number got parsed' );
is( join( ',', reverse @{ $decoded->Issuer } ), 'OU=US Treasury Public CA,OU=Certification Authorities,OU=Department of the Treasury,O=U.S. Government,C=US', 'Issuer parsed' );
is( $decoded->signature_length, 2048, 'signtuare length parsed' );
is( $decoded->signature_algorithm, '1.2.840.113549.1.1.5', 'OID parsed' );
is( $decoded->SigEncAlg, 'RSA', 'Signature encryption parsed' );
is( $decoded->SigHashAlg, 'SHA1', 'Signature hash parsed' );

sub loadcrl {
	my $file = shift;
	open FILE, $file || die "cannot load test certificate" . $file . "\n";
	binmode FILE;    # HELLO Windows, dont fuss with this
	my $holdTerminator = $/;
	undef $/;        # using slurp mode to read the DER-encoded binary certificate
	my $crl = <FILE>;
	$/ = $holdTerminator;
	close FILE;
	return $crl;
}
