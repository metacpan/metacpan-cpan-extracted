#!perl
use 5.006;
use strict;
use warnings;
use Test::More qw(no_plan);

use_ok( 'Crypt::X509::CRL' );

my $crl;
my $decoded;

# Load a known good CRL
open FH, "t/good.crl";
binmode FH;
$crl = undef;
while ( <FH> ) {
    $crl .= $_;
}
close FH;

note ("Test a known good CRL");
$decoded = undef;
$decoded = Crypt::X509::CRL->new( crl => $crl );
ok ( ! $decoded->error() );

# Load a known bad CRL
open FH, "t/bad.crl";
binmode FH;
$crl = undef;
while ( <FH> ) {
    $crl .= $_;
}
close FH;

note ("Test a known bad CRL");
$decoded = undef;
$decoded = Crypt::X509::CRL->new( crl => $crl );
ok ( $decoded->error() );
