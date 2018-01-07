#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::FastParsers;


my $class = 'Bio::FastParsers::Hmmer::DomTable';

check_hits(
    file('test', 'hmmer1.domtblout'), [
        [ 'gi|108800580|ref|YP_640777.1|',    undef, 1619, 'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 0, 2018.1, 0, 1, 1, 0, 0, 2017.8, 0, 7, 1592, 17, 1612, 11, 1614, 0.98, 'glutamate dehydrogenase [Mycobacterium sp. MCS]' ],
        [ 'gi|152991375|ref|YP_001357097.1|', undef, 1006, 'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 0, 1056.2, 7.3, 1, 1, 0, 0, 1055.8, 5, 520, 1587, 5, 1002, 1, 1005, 0.97, 'hypothetical protein NIS_1634 [Nitratiruptor sp. SB155-2]' ],
        [ 'gi|338174599|ref|YP_004651409.1|', undef, 1039, 'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 4.2e-268, 898.6, 0, 1, 2, 3.5e-248, 1.1e-244, 821, 0, 353, 1173, 19, 888, 9, 891, 0.97, 'NAD-specific glutamate dehydrogenase [Parachlamydia acanthamoebae UV-7]' ],
        [ 'gi|338174599|ref|YP_004651409.1|', undef, 1039, 'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 4.2e-268, 898.6, 0, 2, 2, 1.9e-23, 5.9e-20, 76.1, 0.1, 1220, 1340, 890, 1014, 887, 1022, 0.94, 'NAD-specific glutamate dehydrogenase [Parachlamydia acanthamoebae UV-7]' ],
        [ 'gi|297621849|ref|YP_003709986.1|', undef, 1021, 'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 9.8e-264, 884.2, 0, 1, 1, 4e-265, 1.2e-261, 877.2, 0, 343, 1341, 18, 1015, 7, 1021, 0.96, 'NAD-specific glutamate dehydrogenase [Waddlia chondrophila WSU 86-1044]' ],
        [ 'gi|302035821|ref|YP_003796143.1|', undef, 419,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 3.1e-07, 34, 0.2, 1, 2, 0.032, 99, 5.8, 0, 936, 1007, 192, 258, 144, 267, 0.81, 'glutamate dehydrogenase [Candidatus Nitrospira defluvii]' ],
        [ 'gi|302035821|ref|YP_003796143.1|', undef, 419,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 3.1e-07, 34, 0.2, 2, 2, 2.4e-08, 7.6e-05, 26, 0, 1107, 1157, 305, 355, 300, 357, 0.95, 'glutamate dehydrogenase [Candidatus Nitrospira defluvii]' ],
        [ 'gi|375012791|ref|YP_004989779.1|', undef, 450,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 3.4, 10.6, 0, 1, 1, 0.0018, 5.5, 9.9, 0, 1114, 1158, 342, 386, 335, 389, 0.95, 'glutamate dehydrogenase/leucine dehydrogenase [Owenweeksia hongkongensis DSM 17368]' ],
        [ 'gi|194334264|ref|YP_002016124.1|', undef, 448,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 3.5, 10.6, 0.2, 1, 1, 0.0016, 4.9, 10.1, 0.1, 1117, 1157, 344, 384, 328, 387, 0.95, 'glutamate dehydrogenase [Prosthecochloris aestuarii DSM 271]' ],
        [ 'gi|182412640|ref|YP_001817706.1|', undef, 447,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 3.6, 10.6, 0, 1, 1, 0.0027, 8.5, 9.3, 0, 1114, 1157, 339, 382, 320, 385, 0.88, 'glutamate dehydrogenase [Opitutus terrae PB90-1]' ],
        [ 'gi|386723488|ref|YP_006189814.1|', undef, 415,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 3.7, 10.5, 0.2, 1, 2, 0.095, 300, 4.2, 0, 907, 963, 160, 215, 144, 222, 0.8, 'glutamate dehydrogenase [Paenibacillus mucilaginosus K02]' ],
        [ 'gi|386723488|ref|YP_006189814.1|', undef, 415,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 3.7, 10.5, 0.2, 2, 2, 0.098, 310, 4.2, 0, 1107, 1157, 301, 351, 292, 352, 0.92, 'glutamate dehydrogenase [Paenibacillus mucilaginosus K02]' ],
        [ 'gi|320108333|ref|YP_004183923.1|', undef, 451,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 3.8, 10.5, 0, 1, 1, 0.0016, 5.1, 10, 0, 894, 963, 94, 163, 83, 164, 0.94, 'carbohydrate-binding protein [Terriglobus saanensis SP1PR4]' ],
        [ 'gi|429220515|ref|YP_007182159.1|', undef, 372,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 5.2, 10, 0.2, 1, 1, 0.0024, 7.4, 9.5, 0.1, 896, 927, 293, 324, 293, 325, 0.97, 'acetylornithine deacetylase/succinyldiaminopimelate desuccinylase-like deacylase [Deinococcus peraridilitoris DSM 19664]' ],
        [ 'gi|320451262|ref|YP_004203358.1|', undef, 419,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 5.4, 10, 0.2, 1, 1, 0.0025, 7.7, 9.5, 0.1, 1109, 1146, 307, 344, 301, 349, 0.9, 'glutamate dehydrogenase [Thermus scotoductus SA-01]' ],
        [ 'gi|116619653|ref|YP_821809.1|',    undef, 310,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 5.5, 9.9, 1.6, 1, 1, 0.0021, 6.6, 9.7, 1.1, 87, 201, 5, 123, 1, 141, 0.83, 'hypothetical protein Acid_0514 [Candidatus Solibacter usitatus Ellin6076]' ],
        [ 'gi|163854726|ref|YP_001629024.1|', undef, 447,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 6.2, 9.8, 0.1, 1, 1, 0.0027, 8.5, 9.3, 0, 1114, 1158, 339, 383, 322, 402, 0.93, 'glutamate dehydrogenase [Bordetella petrii DSM 12804]' ],
        [ 'gi|376290745|ref|YP_005162992.1|', undef, 448,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 6.5, 9.7, 0.1, 1, 1, 0.003, 9.2, 9.2, 0.1, 1116, 1157, 342, 383, 336, 386, 0.94, 'glutamate dehydrogenase [Corynebacterium diphtheriae C7 (beta)]' ],
        [ 'gi|126696846|ref|YP_001091732.1|', undef, 677,  'min_ldh_proteome_1e_SvsL_Large', undef, 1594, 8.7, 9.3, 0, 1, 1, 0.0039, 12, 8.8, 0, 841, 913, 231, 304, 221, 306, 0.81, 'isoamylase [Prochlorococcus marinus str. MIT 9301]' ],
    ]
);

check_hits(
    file('test', 'hmmer2.domtblout'), [
        [ 'gnl|Kpas|254571883',          undef, 144, 'OGMCL19658-ATG-mt', undef, 119, 1e-60, 207.5, 1.4, 1, 1, 5.9e-65, 1.2e-60, 207.3, 0.9, 1, 119, 18, 136, 18, 136, 0.99, undef ],
        [ 'gnl|Scer|YPR020W',            undef, 115, 'OGMCL19658-ATG-mt', undef, 119, 3.4e-53, 183.2, 1.6, 1, 1, 1.8e-57, 3.8e-53, 183.1, 1.1, 1, 119, 1, 115, 1, 115, 0.99, undef ],
        [ 'gnl|Btau|ENSBTAP00000009643', undef, 103, 'OGMCL19658-ATG-mt', undef, 119, 1.3e-46, 162, 0.1, 1, 1, 7.1e-51, 1.5e-46, 161.8, 0.1, 5, 118, 1, 103, 1, 103, 0.99, undef ],
        [ 'gnl|Btau|ENSBTAP00000047566', undef, 103, 'OGMCL19658-ATG-mt', undef, 119, 3.8e-46, 160.5, 0.1, 1, 1, 2e-50, 4.3e-46, 160.4, 0.1, 5, 118, 1, 103, 1, 103, 0.99, undef ],
        [ 'gnl|Btau|ENSBTAP00000048915', undef, 103, 'OGMCL19658-ATG-mt', undef, 119, 9.3e-46, 159.3, 0.3, 1, 1, 5e-50, 1.1e-45, 159.1, 0.2, 5, 118, 1, 103, 1, 103, 0.99, undef ],
        [ 'gnl|Hsap|ENSP00000300688',    undef, 103, 'OGMCL19658-ATG-mt', undef, 119, 2.3e-45, 158, 0.2, 1, 1, 1.2e-49, 2.6e-45, 157.8, 0.1, 5, 118, 1, 103, 1, 103, 0.99, undef ],
        [ 'gnl|Hsap|ENSP00000421076',    undef, 100, 'OGMCL19658-ATG-mt', undef, 119, 1.2e-35, 126.7, 0.1, 1, 1, 6.6e-40, 1.4e-35, 126.4, 0, 5, 115, 1, 100, 1, 100, 0.98, undef ],
        [ 'gnl|Hsap|ENSP00000434865',    undef, 76,  'OGMCL19658-ATG-mt', undef, 119, 2.1e-25, 93.6, 1, 1, 1, 1.2e-29, 2.5e-25, 93.3, 0.7, 5, 87, 1, 72, 1, 74, 0.97, undef ],
        [ 'gnl|Cmer|CMN078C',            undef, 99,  'OGMCL19658-ATG-mt', undef, 119, 0.028, 19, 0, 1, 1, 1.6e-06, 0.033, 18.7, 0, 76, 113, 60, 97, 25, 98, 0.8, undef ],
        [ 'gnl|MRCC|59954',              undef, 123, 'OGMCL19658-ATG-mt', undef, 119, 0.086, 17.4, 0.1, 1, 1, 4.5e-06, 0.095, 17.3, 0, 74, 116, 79, 122, 5, 122, 0.75, undef ],
        [ 'gnl|Atha|AT2G19680.1',        undef, 122, 'OGMCL19658-ATG-mt', undef, 119, 0.13, 16.8, 0.4, 1, 1, 1.4e-05, 0.29, 15.7, 0.3, 13, 111, 2, 114, 1, 121, 0.6, undef ],
        [ 'gnl|Atha|AT2G19680.2',        undef, 122, 'OGMCL19658-ATG-mt', undef, 119, 0.13, 16.8, 0.4, 1, 1, 1.4e-05, 0.29, 15.7, 0.3, 13, 111, 2, 114, 1, 121, 0.6, undef ],
        [ 'gnl|Dpur|89350',              undef, 93,  'OGMCL19658-ATG-mt', undef, 119, 0.22, 16.1, 0, 1, 1, 1.2e-05, 0.26, 15.9, 0, 63, 117, 22, 77, 2, 78, 0.76, undef ],
        [ 'gnl|Atha|AT4G26210.1',        undef, 122, 'OGMCL19658-ATG-mt', undef, 119, 0.75, 14.4, 0.2, 1, 1, 8.6e-05, 1.8, 13.1, 0.1, 45, 111, 41, 114, 1, 121, 0.5, undef ],
        [ 'gnl|Atha|AT4G26210.2',        undef, 122, 'OGMCL19658-ATG-mt', undef, 119, 0.75, 14.4, 0.2, 1, 1, 8.6e-05, 1.8, 13.1, 0.1, 45, 111, 41, 114, 1, 121, 0.5, undef ],
        [ 'gnl|Tthe|3695.m00116',        undef, 159, 'OGMCL19658-ATG-mt', undef, 119, 1.9, 13.1, 0.9, 1, 1, 0.00012, 2.6, 12.6, 0.5, 26, 74, 50, 99, 24, 123, 0.77, undef ],
        [ 'gnl|Ngru|58080',              undef, 142, 'OGMCL19658-ATG-mt', undef, 119, 2.3, 12.8, 0.8, 1, 1, 0.00021, 4.5, 11.9, 0.6, 93, 117, 107, 134, 54, 136, 0.75, undef ],
        [ 'gnl|Tthe|3686.m00004',        undef, 658, 'OGMCL19658-ATG-mt', undef, 119, 2.4, 12.8, 1.2, 1, 2, 0.00066, 14, 10.3, 0.3, 17, 84, 130, 197, 117, 203, 0.76, undef ],
        [ 'gnl|Tthe|3686.m00004',        undef, 658, 'OGMCL19658-ATG-mt', undef, 119, 2.4, 12.8, 1.2, 2, 2, 1.4, 29000, -0.4, 0, 4, 27, 202, 226, 199, 240, 0.76, undef ],
        [ 'gnl|Ngru|70261',              undef, 240, 'OGMCL19658-ATG-mt', undef, 119, 2.5, 12.7, 0.1, 1, 2, 0.00025, 5.3, 11.6, 0.1, 11, 84, 27, 104, 16, 122, 0.79, undef ],
        [ 'gnl|Ngru|70261',              undef, 240, 'OGMCL19658-ATG-mt', undef, 119, 2.5, 12.7, 0.1, 2, 2, 9, 190000, -3, 0, 39, 46, 193, 200, 178, 228, 0.53, undef ],
        [ 'gnl|Crei|Cre02.g105950.t1.1', undef, 94,  'OGMCL19658-ATG-mt', undef, 119, 2.7, 12.6, 0.1, 1, 1, 0.00015, 3.1, 12.4, 0.1, 25, 80, 29, 86, 4, 91, 0.74, undef ],
    ]
);


sub check_hits {
    my $infile = shift;
    my $exp_hits_ref = shift;

    my @methods = qw(
        target_name target_accession tlen
        query_name query_accession qlen
        evalue score bias rank of
        c_evalue i_evalue dom_score dom_bias
        hmm_from hmm_to ali_from ali_to env_from env_to
        acc
    );

    ok my $report = $class->new( file => $infile ),
        'Hmmer::DomTable constructor';
    isa_ok $report, $class, $infile;

    my $n = 0;
    while (my $hit = $report->next_hit) {
        ok $hit, 'Hmmer::DomTable::Hit constructor';
        isa_ok $hit, $class . '::Hit';
        cmp_deeply [ map { $hit->$_ } @methods, 'target_description' ],
            shift @{ $exp_hits_ref },
            'got expected values for all methods for hit-' . $n++
        ;
    }

    return;
}

done_testing;
