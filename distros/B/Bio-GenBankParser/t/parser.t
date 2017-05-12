#!perl

use strict;
use warnings;
use Data::Dumper;
use File::Spec::Functions;
use FindBin qw( $Bin );
use Readonly;
use Test::More tests => 19;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

require_ok( 'Bio::GenBankParser' );

{
    my $p    = Bio::GenBankParser->new;
    my $file = catfile( $TEST_DATA_DIR, 'rec.seq' );

    open my $fh, '<', $file or die "Can't read '$file': $!\n";

    local $/ = "//\n";
    my $rec = <$fh>;
    my $gb  = $p->parse( $rec );

    is( $gb->{'ACCESSION'}, 'AB000001', 'Accession' );
    is( $gb->{'DEFINITION'}, 
        'Rhizoctonia solani genes for 18S rRNA, 5.8S rRNA, 28S rRNA, ' .
        'partial and complete sequence, isolate:#1.', 
        'Definition' 
    );
    is( $gb->{'ORGANISM'}, 'Rhizoctonia solani', 'Organism' );
    is( $gb->{'SOURCE'}, 'Rhizoctonia solani', 'Source' );

    is_deeply( 
        $gb->{'CLASSIFICATION'}, 
        [
            'Eukaryota',
            'Fungi',
            'Dikarya',
            'Basidiomycota',
            'Agaricomycotina',
            'Agaricomycetes',
            'Cantharellales',
            'Ceratobasidiaceae',
            'Thanatephorus'
        ],
        'Classification'
    );

    is_deeply( 
        $gb->{'LOCUS'}, 
        {
            'modification_date' => '12-SEP-2002',
            'molecule_type'     => 'DNA linear',
            'sequence_length'   => '660 bp',
            'genbank_division'  => 'PLN',
            'locus_name'        => 'AB000001'
        },
        'Locus'
    );

    is_deeply( $gb->{'KEYWORDS'}, [], 'Keywords' );

    is_deeply( $gb->{'VERSION'}, [ 'AB000001.1', 'GI:1754539' ],  'Version' );

    is_deeply( $gb->{'REFERENCES'},
        [
            {
                'authors' => [
                    'Kuninaga,S.', 'Natsuaki,T.', 'Takeuchi,T.', 'Yokosawa,R.'
                ],
                'number' => '1',
                'title'  => 'Sequence variation of the rDNA ITS regions within and between anastomosis groups in Rhizoctonia solani',
                'note'    => undef,
                'pubmed'  => '9339350',
                'journal' => 'Curr. Genet. 32 (3), 237-243 (1997)',
                'remark'  => undef,
                'consrtm' => undef
            },
            {
                'authors' => [ 'Kuninaga,S.' ],
                'number'  => '2',
                'title'   => 'Direct Submission',
                'note'    => 'bases 1 to 660',
                'pubmed'  => undef,
                'journal' =>
                    'Submitted (19-DEC-1996) Shiro Kuninaga, Health Sciences University of Hokkaido, General Education; 1757 Kanazawa, Tohbetsu, Hokkaido 061-02, Japan (E-mail:kuninaga@hoku-iryo-u.ac.jp, Tel:81-1332-3-1211, Fax:81-1332-3-1276)',
                'remark'  => undef,
                'consrtm' => undef
            }
        ],
        'References'
    );

    my @seq = qw[
        aattttaatgaagagtttggttgtagctggcccattaatttaggcatgtgcacacctttc
        tctttcatcccatacacacctgtgaacttgtgagacagatggggaatttatttattgttt
        ttttttgtaatataaagatgataagtcattgaacccttctgtctactcaactcatataaa
        ctcaatttattttaaaatgaatgtaatggatgtaacgcatctaatactaagtttcaacaa
        cggatctcttggctctcgcatcgatgaagaacgcagcgaaatgcgataagtaatgtgaat
        tgcagaattcagtgaatcatcgaatctttgaacgcaccttgcgctccttggtattccttg
        gagcatgcctgtttgagtatcatgaaatcttcaaaatcaagtcttttgttaattcaattg
        gctttgactttggtattggaggtctttgcagcttcacacctgctcctctttgtacattag
        ctggatctcagtgttatgcttggttccactcagcgtgataagttatctatcgctgaggac
        actgtaaaaaggtggccaaggtaaatgcagatgaaccgcttctaatagtccattgacttg
        gacaatatttttatgatctgatctcaaatcaggtaggactacccgctgaacttaagcata
    ];

    is(
        $gb->{'SEQUENCE'},
        join( '', map { s/\s+//g; $_ } @seq ),
        'Sequence (Origin)'
    );

    is(
        scalar @{ $gb->{'FEATURES'} },
        5,
        'Features',
    );

    my $source = shift @{ $gb->{'FEATURES'} };

    is(
        $source->{'name'},
        'source',
        'Source attribute',
    );

    is(
        $source->{'feature'}{'note'},
        'Organ: Autoregulated shoots; Vector: lambda ZAPII; Double stranded cDNAs were synthesized by the method of Gubler and  Hoffman (1983), using a cDNA synthesis kit (Amersham Life Science Inc.)  and then ligated to an EcoRI adaptor (Amersham). cDNA library was  constructed in lambda ZAPII vector using lambda ZAPII/EcoRI/Gigapack II cloning kit (Stratagene)',
        'Source/note'
    );

    is( 
        $gb->{'BASE_COUNT'}{'a'},
        163,
        'Base count'
    );

    is( 
        $gb->{'BASE_COUNT'}{'others'},
        10,
        'Base count 2'
    );

    is( 
        $gb->{'PROJECT'},
        'GenomeProject:18357',
        'Project'
    );

    my $rec2 = <$fh>;
    my $gb2  = $p->parse( $rec2 );

    is( $gb2->{'LOCUS'}{'locus_name'}, 'YSCPLASM', "Locus is 'YSCPLASM'" );

    my $acc2 = join(' ', qw[
        J01347 L00321 L00322 L00323 L00324 M10185 M11111 M11593
        M14239-M14245 M14253-M14259 M14591-M14598 V01323
        J01347.1 GI:172190
    ]);

    is( 
        join(' ', $gb2->{'ACCESSION'}, @{ $gb2->{'VERSION'} } ), 
        $acc2, 
        "Accession is '$acc2'" 
    );
}
