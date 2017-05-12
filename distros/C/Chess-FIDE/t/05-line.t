#!perl

use strict;
use warnings;

use Chess::FIDE;
use Test::More tests => 7;

my $fide = Chess::FIDE->new();
my @tests = (
	{
		header => 'ID number Name                              TitlFed  Mar11 GamesBorn  Flag',
		input => ' 4158814  Andreikin, Dmitry                 g   RUS  2686    9  1990  ',
		output => {
			'fed' => 'RUS',
			'surname' => 'Andreikin',
			'flag' => '',
			'fidename' => 'Andreikin, Dmitry',
			'srtng' => '2686',
			'tit' => 'g',
			'bday' => '1990',
			'sgm' => '9',
			'givenname' => 'Dmitry',
			'name' => 'Dmitry Andreikin',
			'id' => '4158814'
		},
	},
	{
		header => 'ID number Name                              TitlFed  Mar11 GamesBorn  Flag',
		input => '10206612  A K M, Sourab                         BAN  1714    0        ',
		output => {
			fed => 'BAN',
			surname => 'A K M',
			flag => '',
			fidename => 'A K M, Sourab',
			srtng => 1714,
			tit => '',
			bday => '',
			sgm => 0,
			givenname => 'Sourab',
			name => 'Sourab A K M',
			id => 10206612,
		},
	},
	{
		header => 'ID number Name                              TitlFed  Mar11 GamesBorn  Flag',
		input => ' 5080444  A, Sohita                             IND  1447    0  1995  wi',
		output => {
			fed => 'IND',
			surname => 'A',
			flag => 'wi',
			fidename => 'A, Sohita',
			srtng => 1447,
			tit => '',
			bday => 1995,
			sgm => 0,
			givenname => 'Sohita',
			name => 'Sohita A',
			id => 5080444,
		},
	},
	{
		header => 'ID Number      Name                                                         Fed Sex Tit  WTit OTit           SRtng SGm SK RRtng RGm Rk BRtng BGm BK B-day Flag',
		input => '10207538       A E M, Doshtagir                                             BAN M                            1840  0   40 1836  0   20 1860  0   20 1974      ',
		output => {
			'surname' => 'A E M',
			'srtng' => '1840',
			'id' => '10207538',
			'bgm' => '0',
			'sgm' => '0',
			'flag' => '',
			'fed' => 'BAN',
			'sk' => '40',
			'givenname' => 'Doshtagir',
			'fidename' => 'A E M, Doshtagir',
			'tit' => '',
			'rrtng' => '1836',
			'wtit' => '',
			'bk' => '20',
			'sex' => 'M',
			'name' => 'Doshtagir A E M',
			'rk' => '20',
			'bday' => '1974',
			'rgm' => '0',
			'brtng' => '1860',
			'otit' => ''
		},
	},
	{
		header => 'ID Number      Name                                                         Fed Sex Tit  WTit OTit           SRtng SGm SK RRtng RGm Rk BRtng BGm BK B-day Flag',
		input => '7704658                                                                     TTO M                                                                   0000',
		output => {
			'tit' => '',
			'otit' => '',
			'flag' => '',
			'bk' => '',
			'bday' => '0000',
			'rgm' => '',
			'srtng' => '',
			'wtit' => '',
			'brtng' => '',
			'rrtng' => '',
			'sgm' => '',
			'name' => '',
			'bgm' => '',
			'sk' => '',
			'rk' => '',
			'id' => '7704658',
			'sex' => 'M',
			'fed' => 'TTO'
		},
	},
	{
		header => 'ID Number      Name                                                         Fed Sex Tit  WTit OTit           SRtng SGm SK RRtng RGm Rk BRtng BGm BK B-day Flag',
		input => '5031605        A, Akshaya                                                   IND F                            2014  0   20                           1994  wi',
		output => {
			'fidename' => 'A, Akshaya',
			'id' => '5031605',
			'srtng' => '2014',
			'bk' => '',
			'bday' => '1994',
			'wtit' => '',
			'sex' => 'F',
			'givenname' => 'Akshaya',
			'brtng' => '',
			'rgm' => '',
			'sk' => '20',
			'rk' => '',
			'fed' => 'IND',
			'bgm' => '',
			'surname' => 'A',
			'name' => 'Akshaya A',
			'sgm' => '0',
			'rrtng' => '',
			'tit' => '',
			'flag' => 'wi',
			'otit' => ''
		},
	},
	{
		header => 'ID Number      Name                                                         Fed Sex Tit  WTit OTit           SRtng SGm SK RRtng RGm Rk BRtng BGm BK B-day Flag',
		input => '1701991        Aaberg, Anton                                                SWE M   IM                       2393  0   10                           1972',
		output => {
			'fidename' => 'Aaberg, Anton',
			'id' => '1701991',
			'srtng' => '2393',
			'bk' => '',
			'bday' => 1972,
			'wtit' => '',
			'sex' => 'M',
			'givenname' => 'Anton',
			'brtng' => '',
			'rgm' => '',
			'sk' => 10,
			'rk' => '',
			'fed' => 'SWE',
			'bgm' => '',
			'surname' => 'Aaberg',
			'name' => 'Anton Aaberg',
			'sgm' => 0,
			'rrtng' => '',
			'tit' => 'IM',
			'flag' => '',
			'otit' => ''
		},
	},
);
for my $test (@tests) {
	$fide->{meta} = {};
	$fide->parseHeader($test->{header});
	my $line = $test->{input};
	my %info = $fide->parseLine($line);
	is_deeply(\%info, $test->{output}, "id $info{id} parsed correctly");
}
