#! /usr/bin/perl -T

use Test::More tests => 2;

use Bio::GeneDesign;
use Bio::Seq;

use strict;
use warnings;

my $GD = Bio::GeneDesign->new();
$GD->set_organism(-organism_name => "yeast",
                  -table_path => "codon_tables/Standard.ct",
                  -rscu_path => "codon_tables/Saccharomyces_cerevisiae.rscu");

$GD->{conf} = 'blib/GeneDesign/';
$GD->set_restriction_enzymes(-list_path => "enzymes/test");

my $orf = "ATGGACAGATCTTGGAAGCAGAAGCTGAACCGCGACACCGTGAAGCTGACCGAGGTGATGACCTGGA";
$orf .= "GAAGACCCGCCGCTAAATGGTTTTATACTTTAATTAATGCTAATTATTTGCCACCATGCCCACCCGACC";
$orf .= "ACCAAGATCACCGGCAGCAACAACTACCTGAGCCTGATCAGCCTGAACATCAACGGCCTGAACAGCCCC";
$orf .= "ATCAAGCGGCACCGCCTGACCGACTGGCTGCACAAGCAGGACCCCACCTTCTGTTGCCTCCAGGAGACC";
$orf .= "CACCTGCGCGAGAAGGACCGGCACTACCTGCGGGTGAAGGGCTGGAAGACCATCTTTCAGGCCAACGGC";
$orf .= "CTGAAGAAGCAGGCTGGCGTGGCCATCCTGATCAGCGACAAGATCGACTTCCAGCCCAAGGTGATCAAG";
$orf .= "AAGGACAAGGAGGGCCACTTCATCCTGATCAAGGGCAAGATCCTGCAGGAGGAGCTGAGCATTCTGAAC";
$orf .= "ATCTACGCCCCCAACGCCCGCGCCGCCACCTTCATCAAGGACACCCTCGTGAAGCTGAAGGCCCACATC";
$orf .= "GCTCCCCACACCATCATCGTCGGCGACCTGAACACCCCCCTGAGCAGTGA";
my $seqobj = Bio::Seq->new( -seq => $orf, -id => "torf");

#TESTING define_sites
my $rRES = {
    'TspRI' => bless(
        {
            'buffers' => {
                'NEB3'  => '25',
                'NEB1'  => '25',
                'Other' => '',
                'NEB2'  => '50',
                'NEB4'  => '100'
            },
            'palindromy' => 'nonpal',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress' => '0.0024535',
            'score'   => '0.0528',
            'recseq'  => 'CASTGNN',
            'methcpg' => 'indifferent',
            'methdam' => 'indifferent',
            'length'  => 7,
            'temp'    => '65',
            'regex'   => [
                qr/CA[CGS]TG[ABCDGHKMNRSTVWY][ABCDGHKMNRSTVWY]/ix,
                qr/[ABCDGHKMNRSTVWY][ABCDGHKMNRSTVWY]CA[CGS]TG/ix
            ],
            'methdcm'       => 'indifferent',
            'type'          => '3\'',
            '_root_verbose' => 0,
            'id'            => 'TspRI',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            'cutseq'        => 'CASTGNN^',
            'outside_cut'   => 7,
            'inside_cut'    => 0,
            'exclude'       => []
        },
        'Bio::GeneDesign::RestrictionEnzyme'

    ),
    'PspOMI' => bless(
        {
            'buffers' => {
                'NEB3'  => '10',
                'NEB1'  => '25',
                'Other' => '',
                'NEB2'  => '25',
                'NEB4'  => '100'
            },
            'recseq'     => 'GGGCCC',
            'methdam'    => 'indifferent',
            'id'         => 'PspOMI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pal',
            'vendors'    => {
                'N' => 'New England Biolabs',
                'I' => 'SibEnzyme',
                'V' => 'Vivantis'
            },
            'aggress'       => '0.0002659',
            'score'         => '0.02826',
            'length'        => 6,
            'methcpg'       => 'blocked',
            'temp'          => '37',
            'regex'         => [ qr/GGGCCC/ix ],
            'methdcm'       => 'blocked',
            'outside_cut'   => 5,
            'inside_cut'    => 1,
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'G^GGCCC',
            'exclude'       => ['ApaI', 'BaeGI', 'BanII', 'Bsp1286I', 'CviKI', 'HaeIII', 'NlaIV', 'PhoI', 'Sau96I', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BsrI' => bless(
        {
            'buffers' => {
                'NEB3'  => '100',
                'NEB1'  => '0',
                'Other' => '',
                'NEB2'  => '50',
                'NEB4'  => '10'
            },
            'recseq'     => 'ACTGG',
            'methdam'    => 'indifferent',
            'id'         => 'BsrI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0016710',
            'score'         => '0.0464',
            'length'        => 5,
            'methcpg'       => 'indifferent',
            'temp'          => '65',
            'regex'         => [ qr/ACTGG/ix, qr/CCAGT/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '3\'',
            'cutseq'        => 'ACTGG(1/-1)',
            'outside_cut'   => 1,
            'inside_cut'    => -1,
            'exclude'       => ['BmrI']
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'TaqI' => bless(
        {
            'buffers' => {
                'NEB3'  => '100',
                'NEB1'  => '50',
                'Other' => '',
                'NEB2'  => '75',
                'NEB4'  => '100'
            },
            'recseq'     => 'TCGA',
            'methdam'    => 'blocked',
            'staract'    => 1,
            'id'         => 'TaqI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pal',
            'vendors'    => {
                'S' => 'Sigma Aldrich',
                'F' => 'Thermo Scientific Fermentas',
                'N' => 'New England Biolabs',
                'K' => 'Takara',
                'Y' => 'CinnaGen',
                'V' => 'Vivantis',
                'Q' => 'Molecular Biology Resources',
                'M' => 'Roche Applied Science',
                'C' => 'Minotech',
                'J' => 'Nippon Gene Co.',
                'O' => 'Toyobo Technologies',
                'X' => 'EURx',
                'B' => 'Invitrogen',
                'I' => 'SibEnzyme',
                'R' => 'Promega',
                'U' => 'Bangalore Genei'
            },
            'aggress'       => '0.0024947',
            'score'         => '0.0106',
            'length'        => 4,
            'methcpg'       => 'indifferent',
            'temp'          => '65',
            'regex'         => [ qr/TCGA/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'T^CGA',
            'outside_cut'   => 3,
            'inside_cut'    => 1,
            'exclude'       => [ 'AsuII', 'BstBI', 'ClaI','PaeR7I', 'PspXI','SalI', 'XhoI',    ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'AcuI' => bless(
        {
            'buffers' => {
                'NEB3'  => '50',
                'NEB1'  => '50',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'recseq'     => 'CTGAAG',
            'methdam'    => 'indifferent',
            'id'         => 'AcuI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs',
                'I' => 'SibEnzyme'
            },
            'aggress'       => '0.0008247',
            'score'         => '0.1546',
            'length'        => 6,
            'methcpg'       => 'indifferent',
            'temp'          => '37',
            'regex'         => [ qr/CTGAAG/ix, qr/CTTCAG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '3\'',
            'cutseq'        => 'CTGAAG(16/14)',
            'outside_cut'   => 16,
            'inside_cut'    => 14,
            'exclude'       => []
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'AccI' => bless(
        {
            'buffers' => {
                'NEB3'  => '10',
                'NEB1'  => '50',
                'Other' => '',
                'NEB2'  => '50',
                'NEB4'  => '100'
            },
            'recseq'     => 'GTMKAC',
            'methdam'    => 'indifferent',
            'id'         => 'AccI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'S' => 'Sigma Aldrich',
                'O' => 'Toyobo Technologies',
                'J' => 'Nippon Gene Co.',
                'N' => 'New England Biolabs',
                'X' => 'EURx',
                'K' => 'Takara',
                'B' => 'Invitrogen',
                'M' => 'Roche Applied Science',
                'R' => 'Promega',
                'U' => 'Bangalore Genei'
            },
            'aggress'       => '0.0001856',
            'score'         => '0.0528',
            'length'        => 6,
            'methcpg'       => 'blocked',
            'temp'          => '37',
            'regex'         => [ qr/GT[ACM][GKT]AC/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'GT^MKAC',
            'outside_cut'   => 4,
            'inside_cut'    => 2,
            'exclude'       => ['BstZ17I', 'Hpy166II', 'SalI', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'AarI' => bless(
        {
            'buffers' => {
                'NEB3'  => '',
                'NEB1'  => '',
                'Other' => '100',
                'NEB2'  => '',
                'NEB4'  => ''
            },
            'recseq'     => 'CACCTGC',
            'methdam'    => 'indifferent',
            'id'         => 'AarI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'F' => 'Thermo Scientific Fermentas'
            },
            'aggress'       => '0.0002474',
            'score'         => '2.1600',
            'length'        => 7,
            'methcpg'       => 'inhibited',
            'temp'          => '37',
            'regex'         => [ qr/CACCTGC/ix, qr/GCAGGTG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'CACCTGC(4/8)',
            'outside_cut'   => 8,
            'inside_cut'    => 4,
            'exclude'       => ['BfuAI', 'BspMI', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'AciI' => bless(
        {
            'buffers' => {
                'NEB3'  => '100',
                'NEB1'  => '25',
                'Other' => '',
                'NEB2'  => '50',
                'NEB4'  => '50'
            },
            'recseq'     => 'CCGC',
            'methdam'    => 'indifferent',
            'id'         => 'AciI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0106387',
            'score'         => '0.244',
            'length'        => 4,
            'methcpg'       => 'blocked',
            'temp'          => '37',
            'regex'         => [ qr/CCGC/ix, qr/GCGG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'CCGC(-3/-1)',
            'outside_cut'   => -1,
            'inside_cut'    => -3,
            'exclude'       => [ 'BsrBI', 'EciI','FauI', 'NotI', 'SacII',   ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'AhdI' => bless(
        {
            'buffers' => {
                'NEB3'  => '0',
                'NEB1'  => '25',
                'Other' => '',
                'NEB2'  => '75',
                'NEB4'  => '100'
            },
            'recseq'     => 'GACNNNNNGTC',
            'methdam'    => 'indifferent',
            'id'         => 'AhdI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pal',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress' => '0.0001856',
            'score'   => '0.066',
            'length'  => 11,
            'methcpg' => 'inhibited',
            'temp'    => '37',
            'regex'   => [
qr/GAC[ABCDGHKMNRSTVWY][ABCDGHKMNRSTVWY][ABCDGHKMNRSTVWY][ABCDGHKMNRSTVWY][ABCDGHKMNRSTVWY]GTC/ix
            ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => '3\'',
            'cutseq'        => 'GACNNN^NNGTC',
            'onebpoverhang' => 1,
            'outside_cut'   => 6,
            'inside_cut'    => 5,
            'exclude'       => []
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BsmI' => bless(
        {
            'buffers' => {
                'NEB3'  => '75',
                'NEB1'  => '75',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'recseq'     => 'GAATGC',
            'methdam'    => 'indifferent',
            'id'         => 'BsmI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'S' => 'Sigma Aldrich',
                'O' => 'Toyobo Technologies',
                'J' => 'Nippon Gene Co.',
                'M' => 'Roche Applied Science',
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0009484',
            'score'         => '0.0976',
            'length'        => 6,
            'methcpg'       => 'indifferent',
            'temp'          => '65',
            'regex'         => [ qr/GAATGC/ix, qr/GCATTC/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '3\'',
            'cutseq'        => 'GAATGC(1/-1)',
            'outside_cut'   => 1,
            'inside_cut'    => -1,
            'exclude'       => []
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'MscI' => bless(
        {
            'buffers' => {
                'NEB3'  => '75',
                'NEB1'  => '75',
                'Other' => '',
                'NEB2'  => '75',
                'NEB4'  => '100'
            },
            'recseq'     => 'TGGCCA',
            'methdam'    => 'indifferent',
            'id'         => 'MscI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'unknown',
            'vendors'    => {
                'O' => 'Toyobo Technologies',
                'N' => 'New England Biolabs',
                'B' => 'Invitrogen'
            },
            'aggress'       => '0.0003711',
            'score'         => '0.2016',
            'length'        => 6,
            'methcpg'       => 'indifferent',
            'temp'          => '37',
            'regex'         => [ qr/TGGCCA/ix ],
            'methdcm'       => 'blocked',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => 'b',
            'cutseq'        => 'TGG^CCA',
            'exclude'       => ['CviKI', 'EaeI', 'HaeIII', 'PhoI', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BbvCI' => bless(
        {
            'buffers' => {
                'NEB3'  => '10',
                'NEB1'  => '50',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'recseq'     => 'CCTCAGC',
            'methdam'    => 'indifferent',
            'id'         => 'BbvCI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0001443',
            'score'         => '0.464',
            'length'        => 7,
            'methcpg'       => 'inhibited',
            'temp'          => '37',
            'regex'         => [ qr/CCTCAGC/ix, qr/GCTGAGG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'CCTCAGC(-5/-2)',
            'outside_cut'   => -2,
            'inside_cut'    => -5,
            'exclude'       => [ 'Bpu10I', 'BseMII', 'BspCNI', 'DdeI', 'MnlI',  ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'RsaI' => bless(
        {
            'buffers' => {
                'NEB3'  => '50',
                'NEB1'  => '100',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'recseq'     => 'GTAC',
            'methdam'    => 'indifferent',
            'id'         => 'RsaI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'unknown',
            'vendors'    => {
                'S' => 'Sigma Aldrich',
                'F' => 'Thermo Scientific Fermentas',
                'O' => 'Toyobo Technologies',
                'J' => 'Nippon Gene Co.',
                'X' => 'EURx',
                'N' => 'New England Biolabs',
                'Y' => 'CinnaGen',
                'B' => 'Invitrogen',
                'V' => 'Vivantis',
                'Q' => 'Molecular Biology Resources',
                'M' => 'Roche Applied Science',
                'C' => 'Minotech',
                'R' => 'Promega',
                'I' => 'SibEnzyme'
            },
            'aggress'       => '0.0023298',
            'score'         => '0.0424',
            'length'        => 4,
            'methcpg'       => 'blocked',
            'temp'          => '37',
            'regex'         => [ qr/GTAC/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => 'b',
            'cutseq'        => 'GT^AC',
            'exclude'       => ['Acc65I', 'BsiWI', 'BsrGI', 'CviQI', 'KpnI', 'ScaI', 'TatI', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'AatII' => bless(
        {
            'buffers' => {
                'NEB3'  => '50',
                'NEB1'  => '0',
                'Other' => '',
                'NEB2'  => '50',
                'NEB4'  => '100'
            },
            'recseq'     => 'GACGTC',
            'methdam'    => 'indifferent',
            'id'         => 'AatII',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pal',
            'vendors'    => {
                'F' => 'Thermo Scientific Fermentas',
                'O' => 'Toyobo Technologies',
                'M' => 'Roche Applied Science',
                'N' => 'New England Biolabs',
                'K' => 'Takara',
                'R' => 'Promega',
                'V' => 'Vivantis'
            },
            'aggress'       => '0.0002062',
            'score'         => '0.0848',
            'length'        => 6,
            'methcpg'       => 'blocked',
            'temp'          => '37',
            'regex'         => [ qr/GACGTC/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => '3\'',
            'cutseq'        => 'GACGT^C',
            'outside_cut'   => 5,
            'inside_cut'    => 1,
            'exclude'       => ['BsaHI',  'HpyCH4IV','MaeII', 'TaiI', 'ZraI', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BtrI' => bless(
        {
            'buffers' => {
                'NEB3'  => '',
                'NEB1'  => '',
                'Other' => 'O',
                'NEB2'  => '',
                'NEB4'  => ''
            },
            'recseq'     => 'CACGTC',
            'methdam'    => 'indifferent',
            'id'         => 'BtrI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'I' => 'SibEnzyme',
                'V' => 'Vivantis'
            },
            'aggress'       => '0.0003505',
            'score'         => '9.999',
            'length'        => 6,
            'methcpg'       => 'indifferent',
            'temp'          => '60',
            'regex'         => [ qr/CACGTC/ix, qr/GACGTG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => 'b',
            'cutseq'        => 'CACGTC(-3/-3)',
            'exclude'       => [ 'BmgBI', 'HpyCH4IV',  'MaeII', 'TaiI',  ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BmgBI' => bless(
        {
            'buffers' => {
                'NEB3'  => '100',
                'NEB1'  => '0',
                'Other' => '',
                'NEB2'  => '25',
                'NEB4'  => '10'
            },
            'recseq'     => 'CACGTC',
            'methdam'    => 'indifferent',
            'id'         => 'BmgBI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0003505',
            'score'         => '0.232',
            'length'        => 6,
            'methcpg'       => 'blocked',
            'temp'          => '37',
            'regex'         => [ qr/CACGTC/ix, qr/GACGTG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => 'b',
            'cutseq'        => 'CACGTC(-3/-3)',
            'exclude'       => [  'BtrI', 'HpyCH4IV', 'MaeII', 'TaiI', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'PspXI' => bless(
        {
            'buffers' => {
                'NEB3'  => '10',
                'NEB1'  => '0',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'recseq'     => 'VCTCGAGB',
            'methdam'    => 'indifferent',
            'id'         => 'PspXI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pal',
            'vendors'    => {
                'N' => 'New England Biolabs',
                'I' => 'SibEnzyme'
            },
            'aggress'       => '0.0000206',
            'score'         => '0.252',
            'length'        => 8,
            'methcpg'       => 'inhibited',
            'temp'          => '37',
            'regex'         => [ qr/[ACGMRSV]CTCGAG[BCGKSTY]/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'VC^TCGAGB',
            'outside_cut'   => 6,
            'inside_cut'    => 2,
            'exclude'       => [ 'AvaI', 'BsoBI', 'PaeR7I', 'SmlI', 'TaqI',  'XhoI', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'PspGI' => bless(
        {
            'buffers' => {
                'NEB3'  => '50',
                'NEB1'  => '75',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'palindromy' => 'pal',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0000501',
            'score'         => '0.0464',
            'recseq'        => 'CCWGG',
            'methcpg'       => 'indifferent',
            'methdam'       => 'indifferent',
            'length'        => 5,
            'temp'          => '75',
            'regex'         => [ qr/CC[ATW]GG/ix ],
            'methdcm'       => 'blocked',
            'type'          => '5\'',
            '_root_verbose' => 0,
            'id'            => 'PspGI',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            'cutseq'        => '^CCWGG',
            'outside_cut'   => 5,
            'inside_cut'    => 0,
            'exclude'       => ['BssKI', 'BstNI', 'EcoRII', 'PasI', 'ScrFI', 'SexAI', 'StyD4I', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'MlyI' => bless(
        {
            'buffers' => {
                'NEB3'  => '25',
                'NEB1'  => '50',
                'Other' => '',
                'NEB2'  => '50',
                'NEB4'  => '100'
            },
            'recseq'     => 'GAGTC',
            'methdam'    => 'indifferent',
            'id'         => 'MlyI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0012577',
            'score'         => '0.0464',
            'length'        => 5,
            'methcpg'       => 'indifferent',
            'temp'          => '37',
            'regex'         => [ qr/GAGTC/ix, qr/GACTC/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => 'b',
            'cutseq'        => 'GAGTC(5/5)',
            'exclude'       => [ 'HinfI', 'PleI',]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BmtI' => bless(
        {
            'buffers' => {
                'NEB3'  => '25',
                'NEB1'  => '25',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '50'
            },
            'recseq'     => 'GCTAGC',
            'methdam'    => 'indifferent',
            'id'         => 'BmtI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pal',
            'vendors'    => {
                'N' => 'New England Biolabs',
                'I' => 'SibEnzyme',
                'V' => 'Vivantis'
            },
            'aggress'       => '0.0000206',
            'score'         => '0.1546',
            'length'        => 6,
            'methcpg'       => 'indifferent',
            'temp'          => '37',
            'regex'         => [ qr/GCTAGC/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => '3\'',
            'cutseq'        => 'GCTAG^C',
            'outside_cut'   => 5,
            'inside_cut'    => 1,
            'exclude'       => ['BfaI', 'Cac8I', 'MaeI', 'NheI',  ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BsrBI' => bless(
        {
            'buffers' => {
                'NEB3'  => '100',
                'NEB1'  => '50',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'recseq'     => 'CCGCTC',
            'methdam'    => 'indifferent',
            'id'         => 'BsrBI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0003505',
            'score'         => '0.0488',
            'length'        => 6,
            'methcpg'       => 'blocked',
            'temp'          => '37',
            'regex'         => [ qr/CCGCTC/ix, qr/GAGCGG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => 'b',
            'cutseq'        => 'CCGCTC(-3/-3)',
            'exclude'       => [ 'AciI' ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'AlwI' => bless(
        {
            'buffers' => {
                'NEB3'  => '10',
                'NEB1'  => '50',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'recseq'     => 'GGATC',
            'methdam'    => 'blocked',
            'id'         => 'AlwI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0011958',
            'score'         => '0.0976',
            'length'        => 5,
            'methcpg'       => 'indifferent',
            'temp'          => '37',
            'regex'         => [ qr/GGATC/ix, qr/GATCC/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'GGATC(4/5)',
            'onebpoverhang' => 1,
            'outside_cut'   => 5,
            'inside_cut'    => 4,
            'exclude'       => ['BamHI', 'BfuCI', 'DpnI', 'DpnII', 'Sau3AI',]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BtsCI' => bless(
        {
            'buffers' => {
                'NEB3'  => '50',
                'NEB1'  => '50',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0030927',
            'score'         => '0.0252',
            'recseq'        => 'GGATG',
            'methcpg'       => 'indifferent',
            'methdam'       => 'indifferent',
            'length'        => 5,
            'temp'          => '50',
            'regex'         => [ qr/GGATG/ix, qr/CATCC/ix ],
            'methdcm'       => 'indifferent',
            'type'          => '3\'',
            '_root_verbose' => 0,
            'id'            => 'BtsCI',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            'cutseq'        => 'GGATG(2/0)',
            'outside_cut'   => 2,
            'inside_cut'    => 0,
            'exclude'       => ['FokI', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BsrDI' => bless(
        {
            'buffers' => {
                'NEB3'  => '50',
                'NEB1'  => '50',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '75'
            },
            'recseq'     => 'GCAATG',
            'methdam'    => 'indifferent',
            'staract'    => 1,
            'id'         => 'BsrDI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0009072',
            'score'         => '0.232',
            'length'        => 6,
            'methcpg'       => 'indifferent',
            'temp'          => '37',
            'regex'         => [ qr/GCAATG/ix, qr/CATTGC/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '3\'',
            'cutseq'        => 'GCAATG(2/0)',
            'outside_cut'   => 2,
            'inside_cut'    => 0,
            'exclude'       => []
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'NlaIII' => bless(
        {
            'buffers' => {
                'NEB3'  => '25',
                'NEB1'  => '25',
                'Other' => '',
                'NEB2'  => '25',
                'NEB4'  => '100'
            },
            'recseq'     => 'CATG',
            'methdam'    => 'indifferent',
            'id'         => 'NlaIII',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pal',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0040847',
            'score'         => '0.0976',
            'length'        => 4,
            'methcpg'       => 'indifferent',
            'temp'          => '37',
            'regex'         => [ qr/CATG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => '3\'',
            'cutseq'        => 'CATG^',
            'outside_cut'   => 4,
            'inside_cut'    => 0,
            'exclude'       => [ 'BspHI', 'CviAII', 'FatI', 'NcoI', 'NspI', 'PciI', 'SphI', ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BseYI' => bless(
        {
            'buffers' => {
                'NEB3'  => '100',
                'NEB1'  => '10',
                'Other' => '',
                'NEB2'  => '50',
                'NEB4'  => '50'
            },
            'recseq'     => 'CCCAGC',
            'methdam'    => 'indifferent',
            'id'         => 'BseYI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0006598',
            'score'         => '0.488',
            'length'        => 6,
            'methcpg'       => 'blocked',
            'temp'          => '37',
            'regex'         => [ qr/CCCAGC/ix, qr/GCTGGG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'CCCAGC(-5/-1)',
            'outside_cut'   => -1,
            'inside_cut'    => -5,
            'exclude'       => []
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'MseI' => bless(
        {
            'buffers' => {
                'NEB3'  => '75',
                'NEB1'  => '75',
                'Other' => '',
                'NEB2'  => '100',
                'NEB4'  => '100'
            },
            'recseq'     => 'TTAA',
            'methdam'    => 'indifferent',
            'id'         => 'MseI',
            'tempin'     => '65',
            'timein'     => '20',
            'palindromy' => 'pal',
            'vendors'    => {
                'N' => 'New England Biolabs',
                'B' => 'Invitrogen'
            },
            'aggress'       => '0.0040205',
            'score'         => '0.0976',
            'length'        => 4,
            'methcpg'       => 'indifferent',
            'temp'          => '37',
            'regex'         => [ qr/TTAA/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIP',
            'classex'       => qr/   ([A-Z]*)   \^ ([A-Z]*)      /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'T^TAA',
            'outside_cut'   => 3,
            'inside_cut'    => 1,
            'exclude'       => ['AflII', 'AseI', 'DraI', 'HpaI', 'PacI', 'PmeI', 'SwaI']
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'Bpu10I' => bless(
        {
            'buffers' => {
                'NEB3'  => '100',
                'NEB1'  => '10',
                'Other' => '',
                'NEB2'  => '25',
                'NEB4'  => '25'
            },
            'recseq'     => 'CCTNAGC',
            'methdam'    => 'indifferent',
            'staract'    => 1,
            'id'         => 'Bpu10I',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'F' => 'Thermo Scientific Fermentas',
                'N' => 'New England Biolabs',
                'I' => 'SibEnzyme',
                'V' => 'Vivantis'
            },
            'aggress' => '0.0003917',
            'score'   => '0.244',
            'length'  => 7,
            'methcpg' => 'indifferent',
            'temp'    => '37',
            'regex' =>
              [ qr/CCT[ABCDGHKMNRSTVWY]AGC/ix, qr/GCT[ABCDGHKMNRSTVWY]AGG/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '5\'',
            'cutseq'        => 'CCTNAGC(-5/-2)',
            'outside_cut'   => -2,
            'inside_cut'    => -5,
            'exclude'       => [ 'BbvCI', 'DdeI',  ]
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    ),
    'BtsI' => bless(
        {
            'buffers' => {
                'NEB3'  => '50',
                'NEB1'  => '100',
                'Other' => '',
                'NEB2'  => '50',
                'NEB4'  => '100'
            },
            'recseq'     => 'GCAGTG',
            'methdam'    => 'indifferent',
            'id'         => 'BtsI',
            'tempin'     => '80',
            'timein'     => '20',
            'palindromy' => 'pnon',
            'vendors'    => {
                'N' => 'New England Biolabs'
            },
            'aggress'       => '0.0007010',
            'score'         => '0.0976',
            'length'        => 6,
            'methcpg'       => 'indifferent',
            'temp'          => '55',
            'regex'         => [ qr/GCAGTG/ix, qr/CACTGC/ix ],
            'methdcm'       => 'indifferent',
            'class'         => 'IIA',
            'classex'       => qr/\A \w+ \(([\-]*\d+) \/ ([\-]*\d+)\)\Z  /x,
            '_root_verbose' => 0,
            'type'          => '3\'',
            'cutseq'        => 'GCAGTG(2/0)',
            'outside_cut'   => 2,
            'inside_cut'    => 0,
            'exclude'       => []
        },
        'Bio::GeneDesign::RestrictionEnzyme'
    )
};

my $tRES = $GD->enzyme_set;
is_deeply( $tRES, $rRES, "define_sites()" );


#TESTING define_site_status
my @enzes = values %$tRES;
my $rSITE_STATUS = {
          'PspOMI' => 0,
          'TspRI' => 1,
          'BsrI' => 1,
          'TaqI' => 1,
          'AcuI' => 2,
          'AccI' => 0,
          'AarI' => 1,
          'AciI' => 8,
          'AhdI' => 0,
          'BsmI' => 1,
          'BbvCI' => 0,
          'MscI' => 1,
          'RsaI' => 0,
          'AatII' => 0,
          'BtrI' => 0,
          'BmgBI' => 0,
          'PspXI' => 0,
          'MlyI' => 0,
          'PspGI' => 2,
          'BsrBI' => 0,
          'BmtI' => 0,
          'AlwI' => 1,
          'BtsCI' => 2,
          'BsrDI' => 0,
          'BseYI' => 0,
          'NlaIII' => 1,
          'Bpu10I' => 2,
          'MseI' => 2,
          'BtsI' => 1
};
my $tSITE_STATUS = $GD->restriction_status($seqobj);
is_deeply( $tSITE_STATUS, $rSITE_STATUS, "define_site_status()");
