#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils qw(shuffle);
use Path::Class qw(file);
use Scalar::Util qw(looks_like_number);

use Bio::MUST::Core::Constants qw(:seqids);
use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(cmp_store);

my $class = 'Bio::MUST::Core::IdMapper';

my @exp_long_ids = (
    'Arabidopsis halleri_81970@78182999',
    'Arabidopsis halleri_81971@184160101',
    'Arabidopsis halleri_81971@184160085',
    'Arabidopsis halleri_81971@184160086',
    'Arabidopsis halleri_63677@63056225',
    'Arabidopsis lyrata_81972@297836718',
    'Arabidopsis thaliana_3702@19071218',
    'Arabidopsis thaliana_3702@15224717',
    'Noccaea caerulescens_107243@326416416',
    'Arabidopsis lyrata_81972@297852380',
);

my @exp_abbr_ids = ( qw(seq1 seq2 seq3 seq4 seq5 seq6 seq7 seq8 seq9 seq10) );

{
    my $infile = file('test', 'AhHMA4_mapper.idm');
    my $mapper = $class->load($infile);
    isa_ok $mapper, $class, $infile;
    is $mapper->count_comments, 1, 'read expected number of comments';
    is $mapper->count_long_ids, 10, 'read expected number of long_ids';
    is $mapper->count_abbr_ids, 10, 'read expected number of abbr_ids';
    is $mapper->header, <<'EOT', 'got expected header';
# simple test id mapper
#
EOT
    is_deeply $mapper->long_ids, \@exp_long_ids,
        'got expected long_ids from .idm file';
    is_deeply $mapper->abbr_ids, \@exp_abbr_ids,
        'got expected abbr_ids from .idm file';

    cmp_store(
        obj => $mapper, method => 'store',
        file => 'AhHMA4_mapper.idm',
        test => 'wrote expected .idm file',
    );

    my @order = shuffle (0..9);
    for my $i (@order) {
        my $exp_long_id = $exp_long_ids[$i];
        my $exp_abbr_id = $exp_abbr_ids[$i];

        my $long_id = $mapper->long_id_for($exp_abbr_id);
        my $abbr_id = $mapper->abbr_id_for($exp_long_id);

        is $exp_long_id, $long_id, "got expected long_id for index $i";
        is $exp_abbr_id, $abbr_id, "got expected abbr_id for index $i";
    }

    # check auto SeqId-isation from id lists
    my @gis = map { $_->gi } $mapper->all_long_seq_ids;
    ok( (List::AllUtils::all { looks_like_number $_ } @gis),
        'got expected GIs from long SeqIds' );

    # check alternative file formats
    cmp_store(
        obj => $mapper, method => 'store',
        file => 'AhHMA4_mapper.alt',
        test => 'wrote expected .alt idm file',
        args => { sep => " , ", header => 0 },
    );

    my $altfile = file('test', 'AhHMA4_mapper.alt');
    my $alt_mapper = $class->load($altfile, { sep => qr{\s,\s}xms } );

    # check loading by rewriting and comparing to original infile
    $alt_mapper->add_comment($mapper->all_comments);
    cmp_store(
        obj => $alt_mapper, method => 'store',
        file => 'AhHMA4_mapper.idm',
        test => 'loaded (and wrote) expected .alt idm file',
    );
}

{
    # check creation of new mappers
    my $infile = file('test', 'AhHMA4_mapper.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);

    my $std_mapper = $ali->std_mapper;
    is_deeply $std_mapper->abbr_ids, \@exp_abbr_ids,
        'got expected std abbr_ids';

    my $prefix = 'lcl|seq';
    my @lcl_abbr_ids = map { $prefix . $_ } (1..10);
    my $lcl_mapper = $ali->std_mapper($prefix);
    is_deeply $lcl_mapper->abbr_ids, \@lcl_abbr_ids,
        'got expected prefixed abbr_ids';

    my @acc_abbr_ids = map { my ($acc) = m/@(.*)/xms; $acc } @exp_long_ids;
    my $acc_mapper = $ali->acc_mapper;
    is_deeply $acc_mapper->abbr_ids, \@acc_abbr_ids,
        'got expected accession-based abbr_ids';

    my @long_len_ids = map {
        $_->full_id . '@' . $_->nomiss_seq_len
    } $ali->all_seqs;
    my $len_mapper = $ali->len_mapper;
    is_deeply $len_mapper->long_ids, \@long_len_ids,
        'got expected len-appended long_ids';

    # check id switching
    $ali->shorten_ids($acc_mapper);
    is_deeply [ map { $_->full_id } $ali->all_seq_ids ], \@acc_abbr_ids,
        'switched to expected accession-based abbr_ids';
    $ali->restore_ids($acc_mapper);
    is_deeply [ map { $_->full_id } $ali->all_seq_ids ], \@exp_long_ids,
        'switched back to expected long_ids';
}

my @ids2abbr = (
    [ 'DEFAULT (ENSEMBL)', $DEF_ID, [
        ['ACYPI28767-PA pep:novel supercontig:Acyr_1.0:EQ119961:2798:9259:1 gene:ACYPI28767 transcript:ACYPI28767-RA',
            'org|ACYPI28767-PA'],
        ['CPIJ019846-PA pep:known supercontig:CpipJ1:supercont3.2110:10032:10597:-1 gene:CPIJ019846 transcript:CPIJ019846-RA',
            'org|CPIJ019846-PA'],
        ['ENSAMEP00000003151 pep:known_by_projection scaffold:ailMel1:GL193041.1:400442:403556:-1 gene:ENSAMEG00000003001 transcript:ENSAMET00000003281 gene_biotype:protein_coding transcript_biotype:protein_coding',
            'org|ENSAMEP00000003151'],
        ['ENSCHOP00000000003 pep:known_by_projection genescaffold:choHof1:GeneScaffold_8035:182:57328:-1 gene:ENSCHOG00000000002 transcript:ENSCHOT00000000003 gene_biotype:protein_coding transcript_biotype:protein_coding',
            'org|ENSCHOP00000000003'],
        ['FOXG,10826P0 pep:known chromosome:FO2:1:1027:1292:-1 gene:FOXG_10826 transcript:FOXG_10826T0',
            'org|FOXG_10826P0'],
        ['LmjF.01.0010:pep pep:known chromosome:ASM272v2:1:3704:4702:-1 gene:LmjF.01.0010 transcript:LmjF.01.0010:mRNA',
            'org|LmjF.01.0010_pep'],
        ['PAC:15698531 pep:known scaffold:Aqu1:Contig3:18:206:-1 gene:Aqu1.200003 transcript:PAC:15698531',
            'org|PAC_15698531'],
        ['rna;EHI_147990-1 pep:known supercontig:JCVI-ESG2-1.0:DS571146:834:1412:1 gene:EHI_147990 transcript:rna_EHI_147990-1',
            'org|rna_EHI_147990-1'],
    ] ],
    [ 'GI (NCBI)', $GI_ID, [
        ['gi|209883096|ref|XP_002142971.1| phosphoglycerate mutase family protein [Cryptosporidium muris RN66]',
            'org|209883096'],
        ['gi|319738218|emb|CBJ17994.1| ATPase subunit 9 [Ectocarpus siliculosus]',
            'org|319738218'],
        ['gi|584810|sp|Q08807.1|ATPB_GALSU RecName: Full=ATP synthase subunit beta, chloroplastic; AltName: Full=ATP synthase F1 sector subunit beta; AltName: Full=F-ATPase subunit beta',
            'org|584810'],
        ['gi|422295929|gb|EKU23228.1| hypothetical protein NGA_2121520, partial [Nannochloropsis gaditana CCMP526]',
            'org|422295929'],
        ['gi|403377567|gb|EJY88781.1| TPR Domain containing protein [Oxytricha trifallax]',
            'org|403377567'],
        ['gi|295414108|ref|XP_002785983.1| DEAD box ATP-dependent RNA helicase, putative [Perkinsus marinus ATCC 50983]',
            'org|295414108'],
    ] ],
    [ 'GNL (NCBI)', $GNL_ID, [
        ['gnl|est|Cvel7',
            'org|Cvel7'],
        ['gnl|est|Lden47',
            'org|Lden47'],
        ['gnl|est|Omar268',
            'org|Omar268'],
        ['gnl|est|Pols3578',
            'org|Pols3578'],
        ['gnl|est|Pmin1',
            'org|Pmin1'],
        ['gnl|est|Vbra1277',
            'org|Vbra1277'],
    ] ],
    [ 'JGI', $JGI_ID, [
        ['jgi|Aplke1|70648|estExt_Genewise1.C_180001',
            'org|70648'],
        ['jgi|Auran1|71405',
            'org|71405'],
        ['jgi|Capca1|4622|fgenesh1_pm.C_scaffold_534000001',
            'org|4622'],
        ['jgi|Chlvu1|70242|fgeneshCV_pg.C_scaffold_1000001',
            'org|70242'],
        ['jgi|Dicpu1|146457|GID1.0037146',
            'org|146457'],
        ['jgi|Guith1|98901|au.1_g3',
            'org|98901'],
        ['jgi|Helro1|158299',
            'org|158299'],
        ['jgi|Phyca11|532085|estExt2_fgenesh1_pg.C_PHYCAscaffold_40001',
            'org|532085'],
        ['jgi|Psemu1|293870|fgenesh1_pm.2_#_1',
            'org|293870'],
    ] ],
    [ 'PAC (PHYTOZOME)', $PAC_ID, [
        ['61229|PACid:27385636',
            'org|27385636'],
        ['Aquca_023_00143.1|PACid:22022986',
            'org|22022986'],
        ['evm.model.supercontig_0.1|PACid:16403802',
            'org|16403802'],
        ['g18373.t1|PACid:27562759',
            'org|27562759'],
        ['mrna13067.1-v1.0-hybrid|PACid:27243847',
            'org|27243847'],
    ] ],
);

{
    for my $exp_row (@ids2abbr) {
        my ($type, $regex, $ids_ref) = @{ $exp_row };
        my $list = Bio::MUST::Core::IdList->new(
            ids => [ map { $_->[0] } @{ $ids_ref } ]
        );
        my $mapper = $list->regex_mapper( 'org|', $regex );
        is_deeply $mapper->abbr_ids, [ map { $_->[1] } @{ $ids_ref } ],
            "got expected $type abbr_ids";
    }
}

my @long2abbr_org_ids = (
    ['Arabidopsis halleri_63677@63056225',    '63677|63056225'  ],
    ['Arabidopsis lyrata_81972@297836718',    '81972|297836718' ],
    ['Arabidopsis thaliana_3702@19071218',    '3702|19071218'   ],
    ['Arabidopsis thaliana_3702@15224717',    '3702|15224717'   ],
    ['Noccaea caerulescens_107243@326416416', '107243|326416416'],
    ['Arabidopsis lyrata@297852380',          'Alyr|297852380'  ],
    ['Arabidopsis halleri@ABB29495.1',        'Ahal|ABB29495.1' ],
    ['Arabidopsis halleri_halleri@78182999',  'Ahha|78182999'   ],
);

my $org_mapper = $class->new(
    long_ids => [
        'Arabidopsis halleri_63677',
        'Arabidopsis halleri_halleri',
        'Arabidopsis halleri',
        'Arabidopsis lyrata_81972',
        'Arabidopsis lyrata',
        'Arabidopsis thaliana_3702',
        'Noccaea caerulescens_107243',
    ],
    abbr_ids => [
        '63677',
        'Ahha',
        'Ahal',
        '81972',
        'Alyr',
        '3702',
        '107243',
    ]
);

my @long_org_ids = map { $_->[0] } @long2abbr_org_ids;
my @abbr_org_ids = map { $_->[1] } @long2abbr_org_ids;

{
    my $list = Bio::MUST::Core::IdList->new( ids => \@long_org_ids );
    my $id_mapper = $list->org_mapper_from_long_ids($org_mapper);
    cmp_deeply $id_mapper->long_ids, \@long_org_ids,
        'got expected org_mapper long_ids from long_ids';
    cmp_deeply $id_mapper->abbr_ids, \@abbr_org_ids,
        'got expected org_mapper abbr_ids from long_ids';
}

{
    my $list = Bio::MUST::Core::IdList->new( ids => \@abbr_org_ids );
    my $id_mapper = $list->org_mapper_from_abbr_ids($org_mapper);
    cmp_deeply $id_mapper->long_ids, \@long_org_ids,
        'got expected org_mapper long_ids from abbr_ids';
    cmp_deeply $id_mapper->abbr_ids, \@abbr_org_ids,
        'got expected org_mapper abbr_ids from abbr_ids';
}

my %exp_family_for = (
    'Chlamydomonas reinhardtii@1' => 'aox1',
    'Chlorella vulgaris@2'        => 'aox2',
    'Dunaliella salina@3'         => 'aox3',
);

{   # quick test to check auto-handling of underscore in valid ids
    my $infile = file('test', 'underscores.idm');
    my $mapper = $class->load($infile);
    while (my ($key, $exp_fam) = each %exp_family_for) {
        my $got_fam = Bio::MUST::Core::SeqId->new(
            full_id => $mapper->long_id_for($key)
        )->family;
        cmp_ok $got_fam, 'eq', $exp_fam, "got expected family for: $key";
    }
}

done_testing;
