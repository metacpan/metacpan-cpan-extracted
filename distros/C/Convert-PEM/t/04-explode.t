use strict;
use Test::More tests => 4;

use Convert::PEM;

my $pem = Convert::PEM->new(
    'Name' => 'TEST OBJECT',
    'ASN'  => q(
        TestObject SEQUENCE {
            int INTEGER
        }
    )
);

isa_ok( $pem, 'Convert::PEM' );

my %pemhash = (
    'Object'  => 'TEST OBJECT',
    'Content' => 'Simple test content that is long enough to wrap in base64.',
    'Headers' =>
        [ [ 'A' => 'Alpha' ], [ 'B' => 'Bravo' ], [ 'C' => 'Charlie' ] ],
);

my $pemData = $pem->implode( %pemhash );

my $pemUnix = my $pemDos = my $pemOldMac = $pemData;
$pemUnix   =~ s/\r\n|\n|\r/\n/g;
$pemDos    =~ s/\r\n|\n|\r/\r\n/g;
$pemOldMac =~ s/\r\n|\n|\r/\r/g;

my $explodeUnix   = $pem->explode( $pemUnix );
is_deeply( $explodeUnix, \%pemhash, "explode with unix line break" );

my $explodeDos    = $pem->explode( $pemDos );
is_deeply( $explodeDos, \%pemhash, "explode with dos line break" );

my $explodeOldMac = $pem->explode( $pemOldMac );
is_deeply( $explodeOldMac, \%pemhash, "explode with old mac line break" );
