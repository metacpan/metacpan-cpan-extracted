use strict;
use Test::More;

my $class = 'CACertOrg::CA';
use_ok( $class );
can_ok( $class, qw(SSL_ca_file) );

my $ca_file = CACertOrg::CA::SSL_ca_file();
diag "File is <$ca_file>";
ok( -e $ca_file, 'CA file exists' );

ok( open(my $fh, "<", $ca_file), 'Can open CA file' );

my $data = do { local $/; <$fh> };
like( $data, qr/-----BEGIN CERTIFICATE-----/, 'Found certificate start' ); 

done_testing();
