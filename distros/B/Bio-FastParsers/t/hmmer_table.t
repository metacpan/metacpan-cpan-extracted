#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::FastParsers;


my $class = 'Bio::FastParsers::Hmmer::Table';

check_hits(
    file('test', 'hmmer1.tblout'), [
        [ 'gi|108800580|ref|YP_640777.1|', undef, 'min_ldgh_0', undef, 7.5e-194, 649.8, 0, 1e-193, 649.4, 0, 1.2, 1, 0, 0, 1, 1, 1, 1, 'glutamate dehydrogenase [Mycobacterium sp. MCS]' ],
        [ 'gi|212635599|ref|YP_002312124.1|', undef, 'min_ldgh_0', undef, 1.1e-193, 649.2, 0, 1.6e-193, 648.7, 0, 1.2, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Shewanella piezotolerans WP3]' ],
        [ 'gi|386852345|ref|YP_006270358.1|', undef, 'min_ldgh_0', undef, 2.2e-192, 644.9, 0, 2.9e-192, 644.5, 0, 1.1, 1, 0, 0, 1, 1, 1, 1, 'glutamate dehydrogenase [Actinoplanes sp. SE50/110]' ],
        [ 'gi|397679080|ref|YP_006520615.1|', undef, 'min_ldgh_0', undef, 1.6e-191, 642.1, 0, 2.2e-191, 641.7, 0, 1.2, 1, 0, 0, 1, 1, 1, 1, 'NAD-specific glutamate dehydrogenase [Mycobacterium massiliense str. GO 06]' ],
        [ 'gi|307545639|ref|YP_003898118.1|', undef, 'min_ldgh_0', undef, 1.7e-189, 635.5, 0, 2.3e-189, 635, 0, 1.2, 1, 0, 0, 1, 1, 1, 1, 'glutamate dehydrogenase [Halomonas elongata DSM 2581]' ],
        [ 'gi|331698565|ref|YP_004334804.1|', undef, 'min_ldgh_0', undef, 5.3e-186, 623.9, 0, 6.9e-186, 623.5, 0, 1.1, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Pseudonocardia dioxanivorans CB1190]' ],
        [ 'gi|300788662|ref|YP_003768953.1|', undef, 'min_ldgh_0', undef, 2.3e-184, 618.5, 0, 3.1e-184, 618.1, 0, 1.1, 1, 0, 0, 1, 1, 1, 1, 'glutamate dehydrogenase [Amycolatopsis mediterranei U32]' ],
        [ 'gi|331699726|ref|YP_004335965.1|', undef, 'min_ldgh_0', undef, 4.5e-182, 611, 0, 6e-182, 610.6, 0, 1.2, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Pseudonocardia dioxanivorans CB1190]' ],
        [ 'gi|291280293|ref|YP_003497128.1|', undef, 'min_ldgh_0', undef, 4.9e-182, 610.9, 0.3, 7.5e-182, 610.2, 0.2, 1.3, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Deferribacter desulfuricans SSM1]' ],
        [ 'gi|313672694|ref|YP_004050805.1|', undef, 'min_ldgh_0', undef, 2.3e-181, 608.6, 1.1, 3.9e-181, 607.9, 0.8, 1.4, 1, 0, 0, 1, 1, 1, 1, 'nad-glutamate dehydrogenase [Calditerrivibrio nitroreducens DSM 19672]' ],
        [ 'gi|311112498|ref|YP_003983720.1|', undef, 'min_ldgh_0', undef, 6.3e-179, 600.6, 0, 8.6e-179, 600.2, 0, 1.2, 1, 0, 0, 1, 1, 1, 1, 'NAD(+)-dependent glutamate dehydrogenase [Rothia dentocariosa ATCC 17931]' ],
        [ 'gi|379738248|ref|YP_005331754.1|', undef, 'min_ldgh_0', undef, 3.5e-178, 598.2, 0, 4.6e-178, 597.8, 0, 1.1, 1, 0, 0, 1, 1, 1, 1, 'glutamate dehydrogenase (NAD) [Blastococcus saxobsidens DD2]' ],
        [ 'gi|189184775|ref|YP_001938560.1|', undef, 'min_ldgh_0', undef, 9.6e-177, 593.4, 0.3, 1.5e-176, 592.8, 0.2, 1.3, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Orientia tsutsugamushi str. Ikeda]' ],
        [ 'gi|336323808|ref|YP_004603775.1|', undef, 'min_ldgh_0', undef, 2.7e-175, 588.7, 0.3, 4.5e-175, 587.9, 0.2, 1.3, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Flexistipes sinusarabici DSM 4947]' ],
        [ 'gi|317051032|ref|YP_004112148.1|', undef, 'min_ldgh_0', undef, 1.7e-173, 582.7, 0, 2.7e-173, 582.1, 0, 1.2, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Desulfurispirillum indicum S5]' ],
        [ 'gi|291286780|ref|YP_003503596.1|', undef, 'min_ldgh_0', undef, 3.6e-171, 575.1, 1.3, 5.2e-171, 574.5, 0.9, 1.2, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Denitrovibrio acetiphilus DSM 12809]' ],
        [ 'gi|297622634|ref|YP_003704068.1|', undef, 'min_ldgh_0', undef, 9.4e-170, 570.4, 0, 1.3e-169, 570, 0, 1.1, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Truepera radiovictrix DSM 17093]' ],
        [ 'gi|397680606|ref|YP_006522141.1|', undef, 'min_ldgh_0', undef, 9.7e-164, 550.6, 0, 1.3e-163, 550.2, 0, 1.1, 1, 0, 0, 1, 1, 1, 1, 'NAD-specific glutamate dehydrogenase [Mycobacterium massiliense str. GO 06]' ],
        [ 'gi|256371090|ref|YP_003108914.1|', undef, 'min_ldgh_0', undef, 1.3e-152, 513.9, 0, 1.8e-152, 513.5, 0, 1.1, 1, 0, 0, 1, 1, 1, 1, 'NAD-glutamate dehydrogenase [Acidimicrobium ferrooxidans DSM 10331]' ],
        [ 'gi|397678659|ref|YP_006520194.1|', undef, 'min_ldgh_0', undef, 1.8e-150, 506.9, 0, 2.3e-150, 506.5, 0, 1.1, 1, 0, 0, 1, 1, 1, 1, 'NAD-specific glutamate dehydrogenase [Mycobacterium massiliense str. GO 06]' ],
        [ 'gi|152991375|ref|YP_001357097.1|', undef, 'min_ldgh_0', undef, 1.1e-126, 428.5, 0.5, 1.5e-126, 428, 0.3, 1.2, 1, 0, 0, 1, 1, 1, 1, 'hypothetical protein NIS_1634 [Nitratiruptor sp. SB155-2]' ],
        [ 'gi|338174599|ref|YP_004651409.1|', undef, 'min_ldgh_0', undef, 7.7e-79, 270.8, 0, 5.1e-78, 268.1, 0, 2, 1, 1, 0, 1, 1, 1, 1, 'NAD-specific glutamate dehydrogenase [Parachlamydia acanthamoebae UV-7]' ],
        [ 'gi|297621849|ref|YP_003709986.1|', undef, 'min_ldgh_0', undef, 1.6e-77, 266.5, 0, 1.1e-76, 263.8, 0, 1.9, 1, 1, 0, 1, 1, 1, 1, 'NAD-specific glutamate dehydrogenase [Waddlia chondrophila WSU 86-1044]' ],
        [ 'gi|338732432|ref|YP_004670905.1|', undef, 'min_ldgh_0', undef, 2.6e-75, 259.2, 0, 1.1e-74, 257.1, 0, 1.8, 1, 1, 0, 1, 1, 1, 1, 'glutamate dehydrogenase [Simkania negevensis Z]' ],
        [ 'gi|46447130|ref|YP_008495.1|', undef, 'min_ldgh_0', undef, 6.8e-72, 247.9, 0, 5.1e-71, 245.1, 0, 2, 1, 1, 0, 1, 1, 1, 1, 'eucaryotic NAD-specific glutamate dehydrogenase [Candidatus Protochlamydia amoebophila UWE25]' ],
        [ 'gi|317152954|ref|YP_004121002.1|', undef, 'min_ldgh_0', undef, 9.4e-71, 244.2, 0, 4.1e-70, 242.1, 0, 1.9, 1, 1, 0, 1, 1, 1, 1, 'Glu/Leu/Phe/Val dehydrogenase [Desulfovibrio aespoeensis Aspo-2]' ],
        [ 'gi|269798606|ref|YP_003312506.1|', undef, 'min_ldgh_0', undef, 1.3e-13, 55.9, 0.1, 0.0026, 21.9, 0, 3.1, 1, 1, 2, 3, 3, 3, 3, 'Glu/Leu/Phe/Val dehydrogenase [Veillonella parvula DSM 2008]' ],
        [ 'gi|212223303|ref|YP_002306539.1|', undef, 'min_ldgh_0', undef, 1.7e-13, 55.5, 0, 5.7e-06, 30.7, 0, 2.8, 1, 1, 1, 2, 2, 2, 2, 'glutamate dehydrogenase [Thermococcus onnurineus NA1]' ],
        [ 'gi|347756732|ref|YP_004864295.1|', undef, 'min_ldgh_0', undef, 4.7e-13, 54.1, 0, 0.00015, 26.1, 0, 3, 1, 1, 1, 2, 2, 2, 2, 'glutamate dehydrogenase/leucine dehydrogenase [Candidatus Chloracidobacterium thermophilum B]' ],
        [ 'gi|320106503|ref|YP_004182093.1|', undef, 'min_ldgh_0', undef, 4.8e-13, 54, 0.2, 2e-05, 28.9, 0, 3, 2, 1, 0, 2, 2, 2, 2, 'Glu/Leu/Phe/Val dehydrogenase [Terriglobus saanensis SP1PR4]' ],
        [ 'gi|163856805|ref|YP_001631103.1|', undef, 'min_ldgh_0', undef, 8.2e-13, 53.3, 1.6, 8.2e-05, 26.9, 0, 3, 2, 1, 0, 2, 2, 2, 2, 'glutamate dehydrogenase [Bordetella petrii DSM 12804]' ],
        [ 'gi|239616704|ref|YP_002940026.1|', undef, 'min_ldgh_0', undef, 3.2e-12, 51.3, 0.1, 0.00011, 26.5, 0, 2.9, 1, 1, 1, 2, 2, 2, 2, 'Glu/Leu/Phe/Val dehydrogenase [Kosmotoga olearia TBF 19.5.1]' ],
        [ 'gi|374309752|ref|YP_005056182.1|', undef, 'min_ldgh_0', undef, 7.5e-12, 50.1, 0.1, 0.0014, 22.8, 0, 3, 2, 1, 0, 2, 2, 2, 2, 'glutamate dehydrogenase [Granulicella mallensis MP5ACTX8]' ],
        [ 'gi|374309752|ref|YP_005056182.1|', undef, 'min_ldgh_0', undef, 7.5e-12, 50.1, 0.1, 0.0014, 22.8, 0, 3, 2, 1, 0, 2, 2, 2, 2, 'glutamate dehydrogenase [Granulicella mallensis MP5ACTX8]' ],
        [ 'gi|225849260|ref|YP_002729424.1|', undef, 'min_ldgh_0', undef, 9.2e-12, 49.8, 0, 5e-05, 27.6, 0, 2.2, 2, 0, 0, 2, 2, 2, 2, 'glutamate dehydrogenase (GDH) [Sulfurihydrogenibium azorense Az-Fu1]' ],
        [ 'gi|390958601|ref|YP_006422358.1|', undef, 'min_ldgh_0', undef, 9.6e-12, 49.7, 0.1, 5.7e-06, 30.7, 0, 3.1, 2, 1, 0, 2, 2, 2, 2, 'glutamate dehydrogenase/leucine dehydrogenase [Terriglobus roseus DSM 18391]' ],
        [ 'gi|269925921|ref|YP_003322544.1|', undef, 'min_ldgh_0', undef, 1.1e-11, 49.5, 0.2, 0.0047, 21.1, 0.1, 3.1, 2, 1, 0, 2, 2, 2, 2, 'Glu/Leu/Phe/Val dehydrogenase [Thermobaculum terrenum ATCC BAA-798]' ],
        [ 'gi|338731112|ref|YP_004660504.1|', undef, 'min_ldgh_0', undef, 4.5e-11, 47.6, 0, 3.6e-05, 28.1, 0, 2.4, 3, 0, 0, 3, 3, 3, 2, 'Glu/Leu/Phe/Val dehydrogenase [Thermotoga thermarum DSM 5069]' ],    ]
);

check_hits(
    file('test', 'hmmer2.tblout'), [
        [ 'gnl|Kpas|254571883',          undef, 'OGMCL19658-ATG-mt', undef, 1e-60, 207.5, 1.4, 1.2e-60, 207.3, 0.9, 1.1, 1, 0, 0, 1, 1, 1, 1, undef ],
        [ 'gnl|Scer|YPR020W',            undef, 'OGMCL19658-ATG-mt', undef, 3.4e-53, 183.2, 1.6, 3.8e-53, 183.1, 1.1, 1, 1, 0, 0, 1, 1, 1, 1, undef ],
        [ 'gnl|Btau|ENSBTAP00000009643', undef, 'OGMCL19658-ATG-mt', undef, 1.3e-46, 162, 0.1, 1.5e-46, 161.8, 0.1, 1, 1, 0, 0, 1, 1, 1, 1, undef ],
        [ 'gnl|Btau|ENSBTAP00000047566', undef, 'OGMCL19658-ATG-mt', undef, 3.8e-46, 160.5, 0.1, 4.3e-46, 160.4, 0.1, 1, 1, 0, 0, 1, 1, 1, 1, undef ],
        [ 'gnl|Btau|ENSBTAP00000048915', undef, 'OGMCL19658-ATG-mt', undef, 9.3e-46, 159.3, 0.3, 1.1e-45, 159.1, 0.2, 1, 1, 0, 0, 1, 1, 1, 1, undef ],
        [ 'gnl|Hsap|ENSP00000300688',    undef, 'OGMCL19658-ATG-mt', undef, 2.3e-45, 158, 0.2, 2.6e-45, 157.8, 0.1, 1, 1, 0, 0, 1, 1, 1, 1, undef ],
        [ 'gnl|Hsap|ENSP00000421076',    undef, 'OGMCL19658-ATG-mt', undef, 1.2e-35, 126.7, 0.1, 1.4e-35, 126.4, 0, 1.1, 1, 0, 0, 1, 1, 1, 1, undef ],
        [ 'gnl|Hsap|ENSP00000434865',    undef, 'OGMCL19658-ATG-mt', undef, 2.1e-25, 93.6, 1, 2.5e-25, 93.3, 0.7, 1, 1, 0, 0, 1, 1, 1, 1, undef ],
        [ 'gnl|Cmer|CMN078C',            undef, 'OGMCL19658-ATG-mt', undef, 0.028, 19, 0, 0.033, 18.7, 0, 1.2, 1, 0, 0, 1, 1, 1, 0, undef ],
        [ 'gnl|MRCC|59954',              undef, 'OGMCL19658-ATG-mt', undef, 0.086, 17.4, 0.1, 0.095, 17.3, 0, 1.4, 1, 1, 0, 1, 1, 1, 0, undef ],
        [ 'gnl|Atha|AT2G19680.1',        undef, 'OGMCL19658-ATG-mt', undef, 0.13, 16.8, 0.4, 0.29, 15.7, 0.3, 1.7, 1, 1, 0, 1, 1, 1, 0, undef ],
        [ 'gnl|Atha|AT2G19680.2',        undef, 'OGMCL19658-ATG-mt', undef, 0.13, 16.8, 0.4, 0.29, 15.7, 0.3, 1.7, 1, 1, 0, 1, 1, 1, 0, undef ],
        [ 'gnl|Dpur|89350',              undef, 'OGMCL19658-ATG-mt', undef, 0.22, 16.1, 0, 0.26, 15.9, 0, 1.1, 1, 0, 0, 1, 1, 1, 0, undef ],
        [ 'gnl|Atha|AT4G26210.1',        undef, 'OGMCL19658-ATG-mt', undef, 0.75, 14.4, 0.2, 1.8, 13.1, 0.1, 1.8, 1, 1, 0, 1, 1, 1, 0, undef ],
        [ 'gnl|Atha|AT4G26210.2',        undef, 'OGMCL19658-ATG-mt', undef, 0.75, 14.4, 0.2, 1.8, 13.1, 0.1, 1.8, 1, 1, 0, 1, 1, 1, 0, undef ],
        [ 'gnl|Tthe|3695.m00116',        undef, 'OGMCL19658-ATG-mt', undef, 1.9, 13.1, 0.9, 2.6, 12.6, 0.5, 1.5, 1, 1, 0, 1, 1, 1, 0, undef ],
        [ 'gnl|Ngru|58080',              undef, 'OGMCL19658-ATG-mt', undef, 2.3, 12.8, 0.8, 4.5, 11.9, 0.6, 1.7, 1, 1, 0, 1, 1, 1, 0, undef ],
        [ 'gnl|Tthe|3686.m00004',        undef, 'OGMCL19658-ATG-mt', undef, 2.4, 12.8, 1.2, 14, 10.3, 0.3, 2.5, 1, 1, 1, 2, 2, 2, 0, undef ],
        [ 'gnl|Ngru|70261',              undef, 'OGMCL19658-ATG-mt', undef, 2.5, 12.7, 0.1, 5.3, 11.6, 0.1, 1.6, 2, 0, 0, 2, 2, 2, 0, undef ],
        [ 'gnl|Crei|Cre02.g105950.t1.1', undef, 'OGMCL19658-ATG-mt', undef, 2.7, 12.6, 0.1, 3.1, 12.4, 0.1, 1.2, 1, 0, 0, 1, 1, 1, 0, undef ],
    ]
);


sub check_hits {
    my $infile = shift;
    my $exp_hits_ref = shift;

    my @methods = qw(
        target_name target_accession
         query_name query_accession
                 evalue          score          bias
        best_dom_evalue best_dom_score best_dom_bias
        exp reg clu ov env dom rep inc
    );

    ok my $report = $class->new( file => $infile ), 'Hmmer::Table constructor';
    isa_ok $report, $class, $infile;

    my $n = 0;
    while (my $hit = $report->next_hit) {
        ok $hit, 'Hmmer::Table::Hit constructor';
        isa_ok $hit, $class . '::Hit';
        cmp_deeply [ map { $hit->$_ } @methods, 'target_description' ],
            shift @{ $exp_hits_ref },
            'got expected values for all methods for hit-' . $n++
        ;
    }

    return;
}

done_testing;
