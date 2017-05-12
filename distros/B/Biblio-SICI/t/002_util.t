
use strict;
use warnings;

use Test::More;

use Biblio::SICI::Util qw( calculate_check_char titleCode_from_title );

my $i = 0;

$i = 1;
foreach (
	[ '0066-4200(1990)25<>1.0.TX;2-S',                'S' ],
	[ '0095-4403(199502/03)21:3<>1.0.TX;2-Z',         'Z' ],
	[ '1234-5679(1996)<::INS-023456>3.0.CO;2-#',      '#' ],
	[ '0361-526X(2011)17:3/4<60-61:AAAAAA>2.0.ZU;2-', '0' ],
	)
{
	my $cc = calculate_check_char( $_->[0] );
	is( $cc, $_->[1], 'calculate check char (subtest ' . $i++ . ')' );
}

$i = 1;
foreach (
	[ 'Information Age Avatars',                                                 'IAA' ],
	[ 'The Integrity of Digital Information; Mechanics and Definitional Issues', 'TIODIM' ],
	[ 'Quality: Theory and Practice',                                            'QTAP' ],
	[ 'A.D.A.M: The Inside Story',                                               'ATIS' ],
	[ 'ABC FlowCharter 4.0 Charts New Territory',                                'AF4CNT' ],
	[ 'Library Programs Face $34.7 Million in Rescissions',                      'LPF$MI' ],
	[ 'Boyz II Men, Adam jockeys for no. 1',                                     'BIMAJF' ],
	)
{
	my $tc = titleCode_from_title( $_->[0] );
	is( $tc, $_->[1], 'derive correct title code (subtest ' . $i++ . ')' );
}

done_testing();

