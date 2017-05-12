#!perl -T

use Test::More tests => 4;

# test some normal short/long checksums, and check boundary conditions (00, ff)

BEGIN {
	my %CHECKSUMS = (
		'a40300df000680010901e000'
			=> '09',
		'a40300d98000'
			=> '00',
		'a40300ee002d80014204010e4a656e6e69666572204b6e617070020b4c617920497420446f776e8605244f3634458803317578'
			=> 'ff',
		'a40300a9005680019e0301244f726c616e646f20547261666669632f54616d706120696e20756e6465722034206d696e02244f726c616e646f20547261666669632f54616d706120696e20756e6465722034206d696e86042a4f524c'
			=> 'd2',
	);

	require Audio::Radio::Sirius;

	my $tuner = new Audio::Radio::Sirius;

	foreach $sum (keys %CHECKSUMS) {
		my $rawsum = pack ('H*', $sum);
		my $rawcalc = $tuner->_checksum($rawsum);
		my $calc = unpack('H*', $rawcalc);
		my $expected = $CHECKSUMS{$sum};

		is ($calc, $expected);
	}
		
}

