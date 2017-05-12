#!/usr/bin/perl -wT
use strict;

# Import useful testing functions
use Test::More tests => 6;


# Make sure module is loadable
BEGIN { use_ok( 'Acme::DRM', qw(secureXOR) ); };

require_ok( 'Acme::DRM' );

# Now try to use secureXOR
my $sampleASCII = 'This is my song it has a beat it is so cool LOLLERS!';
my $sampleBIN   = pack('C*', 0x23, 0xc9, 0xa2, 0x55, 0xaa, 0xfe, 0xde, 0xad);

my $encASCII = secureXOR( $sampleASCII );
my $encBIN   = secureXOR( $sampleBIN );

# Make sure the encoded string is of the same length as the input
is( length( $encASCII ), length( $sampleASCII ),
	'Encoded ASCII should be same length as sample',
);
is( length ($encBIN ), length( $sampleBIN ),
	'Encoded BIN should be same length as sample',
);

# Make sure the encoded data is all nulls
like( $encASCII, qr/^\0*$/,
	'Encoded ASCII should be all nulls',
);
like( $encBIN,   qr/^\0*$/,
	'Encoded BIN should be all nulls',
);

