#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Bio::MUST::Core;

my $class = 'Bio::MUST::Core::SeqId';

my @valid_ids = (

    [ ('Arabidopsis halleri_81970@78182999') x 2, 0, 0, 0, 0, undef, undef,
        'Arabidopsis', 'halleri', undef, '78182999', undef,
        '81970', undef, undef, undef, undef, undef,
        '78182999', undef, undef, undef,
        'Arabidopsis halleri', 'A. halleri', 'Arabidopsis halleri_81970',
        'Arabidopsis halleri 81970',
        'Arabidopsis halleri 81970',
        'Arabidopsis_halleri_81970@78182999',
        q{'Arabidopsis halleri_81970@78182999'} ],

    [ ('Micromonas sp._296587@255079694') x 2, 0, 0, '1', 0, undef, undef,
        'Micromonas', 'sp.', undef, '255079694', undef,
        '296587', undef, undef, undef, undef, undef,
        '255079694', undef, undef, undef,
        'Micromonas sp.', 'M. sp.', 'Micromonas sp._296587',
        'Micromonas sp. 296587',
        'Micromonas sp. 296587',
        'Micromonas_sp._296587@255079694',
        q{'Micromonas sp._296587@255079694'} ],

    [ ('cp-Arabidopsis halleri_81970@78182999') x 2, 0, 0, 0, 0, 'cp', undef,
        'Arabidopsis', 'halleri', undef, '78182999', undef,
        '81970', undef, undef, undef, undef, undef,
        '78182999', undef, undef, undef,
        'Arabidopsis halleri', 'A. halleri', 'Arabidopsis halleri_81970',
        'Arabidopsis halleri 81970',
        'cp-Arabidopsis halleri 81970',
        'cp-Arabidopsis_halleri_81970@78182999',
        q{'cp-Arabidopsis halleri_81970@78182999'} ],

    [ ('su3-Micromonas sp._296587@255079694') x 2, 0, 0, '1', 0, 'su3', undef,
        'Micromonas', 'sp.', undef, '255079694', undef,
        '296587', undef, undef, undef, undef, undef,
        '255079694', undef, undef, undef,
        'Micromonas sp.', 'M. sp.', 'Micromonas sp._296587',
        'Micromonas sp. 296587',
        'su3-Micromonas sp. 296587',
        'su3-Micromonas_sp._296587@255079694',
        q{'su3-Micromonas sp._296587@255079694'} ],

    [ ('Capsella bursa-pastoris_3719@58003767') x 2, 0, 0, 0, 0, undef, undef,
        'Capsella', 'bursa-pastoris', undef, '58003767', undef,
        '3719', undef, undef, undef, undef, undef,
        '58003767', undef, undef, undef,
        'Capsella bursa-pastoris', 'C. bursa-pastoris', 'Capsella bursa-pastoris_3719',
        'Capsella bursa-pastoris 3719',
        'Capsella bursa-pastoris 3719',
        'Capsella_bursa-pastoris_3719@58003767',
        q{'Capsella bursa-pastoris_3719@58003767'} ],

    [ ('cp-Capsella bursa-pastoris_3719@158513961') x 2, 0, 0, 0, 0, 'cp', undef,
        'Capsella', 'bursa-pastoris', undef, '158513961', undef,
        '3719', undef, undef, undef, undef, undef,
        '158513961', undef, undef, undef,
        'Capsella bursa-pastoris', 'C. bursa-pastoris', 'Capsella bursa-pastoris_3719',
        'Capsella bursa-pastoris 3719',
        'cp-Capsella bursa-pastoris 3719',
        'cp-Capsella_bursa-pastoris_3719@158513961',
        q{'cp-Capsella bursa-pastoris_3719@158513961'} ],

    [ ('Pseudo-nitzschia multiseries_37319@194836') x 2, 0, 0, 0, 0, undef, undef,
        'Pseudo-nitzschia', 'multiseries', undef, '194836', undef,
        '37319', undef, undef, undef, undef, undef,
        '194836', undef, undef, undef,
        'Pseudo-nitzschia multiseries', 'P. multiseries', 'Pseudo-nitzschia multiseries_37319',
        'Pseudo-nitzschia multiseries 37319',
        'Pseudo-nitzschia multiseries 37319',
        'Pseudo-nitzschia_multiseries_37319@194836',
        q{'Pseudo-nitzschia multiseries_37319@194836'} ],

    [ ('cp-Pseudo-nitzschia mannii_587315@111559260') x 2, 0, 0, 0, 0, 'cp', undef,
        'Pseudo-nitzschia', 'mannii', undef, '111559260', undef,
        '587315', undef, undef, undef, undef, undef,
        '111559260', undef, undef, undef,
        'Pseudo-nitzschia mannii', 'P. mannii', 'Pseudo-nitzschia mannii_587315',
        'Pseudo-nitzschia mannii 587315',
        'cp-Pseudo-nitzschia mannii 587315',
        'cp-Pseudo-nitzschia_mannii_587315@111559260',
        q{'cp-Pseudo-nitzschia mannii_587315@111559260'} ],

    [ ('cp-d#Pseudo-nitzschia mannii_587315@111559260') x 2, 0, 0, 0, '1', 'cp', 'd',
        'Pseudo-nitzschia', 'mannii', undef, '111559260', undef,
        '587315', undef, undef, undef, undef, undef,
        '111559260', undef, undef, undef,
        'Pseudo-nitzschia mannii', 'P. mannii', 'Pseudo-nitzschia mannii_587315',
        'Pseudo-nitzschia mannii 587315',
        'cp-Pseudo-nitzschia mannii 587315',
        'cp-d#Pseudo-nitzschia_mannii_587315@111559260',
        q{'cp-d#Pseudo-nitzschia mannii_587315@111559260'} ],

    [ ('nuppct#Vitrella brassicaformis_CCMP3155@ABC1234.1') x 2, 0, 0, 0, 0, undef, 'nuppct',
        'Vitrella', 'brassicaformis', 'CCMP3155', 'ABC1234.1', undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Vitrella brassicaformis', 'V. brassicaformis', 'Vitrella brassicaformis_CCMP3155',
        'Vitrella brassicaformis CCMP3155',
        'Vitrella brassicaformis CCMP3155',
        'nuppct#Vitrella_brassicaformis_CCMP3155@ABC1234.1',
        q{'nuppct#Vitrella brassicaformis_CCMP3155@ABC1234.1'} ],

    [ ('archaeon GW2011_AR10@CP010424') x 2, 0, 0, 0, 0, undef, undef,
        'archaeon', 'GW2011_AR10', undef, 'CP010424', undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'archaeon GW2011_AR10', 'a. GW2011_AR10', 'archaeon GW2011_AR10',
        'archaeon GW2011_AR10',
        'archaeon GW2011_AR10',
        'archaeon_GW2011_AR10@CP010424',
        q{'archaeon GW2011_AR10@CP010424'} ],

    [ ('Nessiteras rhombopteryx@PCR28S') x 2, 0, 0, 0, 0, undef, undef,
        'Nessiteras', 'rhombopteryx', undef, 'PCR28S', undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Nessiteras rhombopteryx', 'N. rhombopteryx', 'Nessiteras rhombopteryx',
        'Nessiteras rhombopteryx',
        'Nessiteras rhombopteryx',
        'Nessiteras_rhombopteryx@PCR28S',
        q{'Nessiteras rhombopteryx@PCR28S'} ],

    [ (q{Nessiteras rhombopteryx_'loch-ness'@PCR28S}) x 2, 0, 0, 0, 0, undef, undef,
        'Nessiteras', 'rhombopteryx', q{'loch-ness'}, 'PCR28S', undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Nessiteras rhombopteryx', 'N. rhombopteryx', q{Nessiteras rhombopteryx_'loch-ness'},
        q{Nessiteras rhombopteryx 'loch-ness'},
        q{Nessiteras rhombopteryx 'loch-ness'},
        q{Nessiteras_rhombopteryx_'loch-ness'@PCR28S},
        q{'Nessiteras rhombopteryx_loch-ness@PCR28S'} ],

    [ ('Arabidopsis halleri@ABB29495.1') x 2, 0, 0, 0, 0, undef, undef,
        'Arabidopsis', 'halleri', undef, 'ABB29495.1', undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Arabidopsis halleri', 'A. halleri', 'Arabidopsis halleri',
        'Arabidopsis halleri',
        'Arabidopsis halleri',
        'Arabidopsis_halleri@ABB29495.1',
        q{'Arabidopsis halleri@ABB29495.1'} ],

    [ ('Arabidopsis halleri_81970@ABB29495.1') x 2, 0, 0, 0, 0, undef, undef,
        'Arabidopsis', 'halleri', undef, 'ABB29495.1', undef,
        '81970', undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Arabidopsis halleri', 'A. halleri', 'Arabidopsis halleri_81970',
        'Arabidopsis halleri 81970',
        'Arabidopsis halleri 81970',
        'Arabidopsis_halleri_81970@ABB29495.1',
        q{'Arabidopsis halleri_81970@ABB29495.1'} ],

    [ ('Arabidopsis halleri_halleri@78182999') x 2, 0, 0, 0, 0, undef, undef,
        'Arabidopsis', 'halleri', 'halleri', '78182999', undef,
        undef, undef, undef, undef, undef, undef,
        '78182999', undef, undef, undef,
        'Arabidopsis halleri', 'A. halleri', 'Arabidopsis halleri_halleri',
        'Arabidopsis halleri halleri',
        'Arabidopsis halleri halleri',
        'Arabidopsis_halleri_halleri@78182999',
        q{'Arabidopsis halleri_halleri@78182999'} ],

    [ ('Arabidopsis halleri_halleri@ABB29495.1') x 2, 0, 0, 0, 0, undef, undef,
        'Arabidopsis', 'halleri', 'halleri', 'ABB29495.1', undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Arabidopsis halleri', 'A. halleri', 'Arabidopsis halleri_halleri',
        'Arabidopsis halleri halleri',
        'Arabidopsis halleri halleri',
        'Arabidopsis_halleri_halleri@ABB29495.1',
        q{'Arabidopsis halleri_halleri@ABB29495.1'} ],

    [ ('Nostoc azollae_0708@298493200') x 2, 0, 0, 0, 0, undef, undef,
        'Nostoc', 'azollae', '0708', '298493200', undef,
        undef, undef, undef, undef, undef, undef,
        '298493200', undef, undef, undef,
        'Nostoc azollae', 'N. azollae', 'Nostoc azollae_0708',
        'Nostoc azollae 0708',
        'Nostoc azollae 0708',
        'Nostoc_azollae_0708@298493200',
        q{'Nostoc azollae_0708@298493200'} ],

    [ ('Anabaena sp._90@19612') x 2, 0, 0, '1', 0, undef, undef,
        'Anabaena', 'sp.', undef, '19612', undef,
        '90', undef, undef, undef, undef, undef,
        '19612', undef, undef, undef,
        'Anabaena sp.', 'A. sp.', 'Anabaena sp._90',
        'Anabaena sp. 90',
        'Anabaena sp. 90',
        'Anabaena_sp._90@19612',
        q{'Anabaena sp._90@19612'} ],

    [ ('c#Oscarella sp._sn2011@OspS50623.H1.1...Parazoanthus_axinellae#NEW#') x 2, 0, '1', '1', '1', undef, 'c',
        'Oscarella', 'sp.', 'sn2011', 'OspS50623.H1.1', 'Parazoanthus_axinellae',
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, 'Parazoanthus axinellae',
        'Oscarella sp.', 'O. sp.', 'Oscarella sp._sn2011',
        'Oscarella sp. sn2011',
        'Oscarella sp. sn2011',
        'c#Oscarella_sp._sn2011@OspS50623.H1.1...Parazoanthus_axinellae#NEW#',
        q{'c#Oscarella sp._sn2011@OspS50623.H1.1...Parazoanthus_axinellae#NEW#'} ],

    [ ('c#Oscarella carmela@Ocar68884.H1.1...Favella_ehrenbergii#NEW#') x 2, 0, '1', 0, '1', undef, 'c',
        'Oscarella', 'carmela', undef, 'Ocar68884.H1.1', 'Favella_ehrenbergii',
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, 'Favella ehrenbergii',
        'Oscarella carmela', 'O. carmela', 'Oscarella carmela',
        'Oscarella carmela',
        'Oscarella carmela',
        'c#Oscarella_carmela@Ocar68884.H1.1...Favella_ehrenbergii#NEW#',
        q{'c#Oscarella carmela@Ocar68884.H1.1...Favella_ehrenbergii#NEW#'} ],

    [ ('Urticina eques@Uequ12160.E.lc#NEW#') x 2, 0, '1', 0, 0, undef, undef,
        'Urticina', 'eques', undef, 'Uequ12160.E.lc', undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Urticina eques', 'U. eques', 'Urticina eques',
        'Urticina eques',
        'Urticina eques',
        'Urticina_eques@Uequ12160.E.lc#NEW#',
        q{'Urticina eques@Uequ12160.E.lc#NEW#'} ],

    [ ('c#Pseudo-nitzschia australis_1024910ABMMETSP0142@CAMNT_0008229771.E.lc...Nostoc_azollae#NEW#') x 2, 0, '1', 0, '1', undef, 'c',
        'Pseudo-nitzschia', 'australis', '1024910ABMMETSP0142', 'CAMNT_0008229771.E.lc', 'Nostoc_azollae',
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, 'Nostoc azollae',
        'Pseudo-nitzschia australis', 'P. australis', 'Pseudo-nitzschia australis_1024910ABMMETSP0142',
        'Pseudo-nitzschia australis 1024910ABMMETSP0142',
        'Pseudo-nitzschia australis 1024910ABMMETSP0142',
        'c#Pseudo-nitzschia_australis_1024910ABMMETSP0142@CAMNT_0008229771.E.lc...Nostoc_azollae#NEW#',
        q{'c#Pseudo-nitzschia australis_1024910ABMMETSP0142@CAMNT_0008229771.E.lc...Nostoc_azollae#NEW#'} ],

    [ ('Micromonas sp._296587@255079694') x 2, 0, 0, '1', 0, undef, undef,
        'Micromonas', 'sp.', undef, '255079694', undef,
        '296587', undef, undef, undef, undef, undef,
        '255079694', undef, undef, undef,
        'Micromonas sp.', 'M. sp.', 'Micromonas sp._296587',
        'Micromonas sp. 296587',
        'Micromonas sp. 296587',
        'Micromonas_sp._296587@255079694',
        q{'Micromonas sp._296587@255079694'} ],

    [ ('Arabidopsis halleri_81970@ABB29495.1') x 2, 0, 0, 0, 0, undef, undef,
        'Arabidopsis', 'halleri', undef, 'ABB29495.1', undef,
        '81970', undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Arabidopsis halleri', 'A. halleri', 'Arabidopsis halleri_81970',
        'Arabidopsis halleri 81970',
        'Arabidopsis halleri 81970',
        'Arabidopsis_halleri_81970@ABB29495.1',
        q{'Arabidopsis halleri_81970@ABB29495.1'} ],

    [ ('Listeria monocytogenes_GCA_000438585.1@AGR25087.1') x 2, 0, 0, 0, 0, undef, undef,
        'Listeria', 'monocytogenes', undef, 'AGR25087.1', undef,
        'GCA_000438585.1', 'GCA_000438585.1', 'GCA_000438585', '1', 'GCA', '000438585',
        undef, undef, undef, undef,
        'Listeria monocytogenes', 'L. monocytogenes', 'Listeria monocytogenes_GCA_000438585.1',
        'Listeria monocytogenes GCA_000438585.1',
        'Listeria monocytogenes GCA_000438585.1',
        'Listeria_monocytogenes_GCA_000438585.1@AGR25087.1',
        q{'Listeria monocytogenes_GCA_000438585.1@AGR25087.1'} ],

    [ ('Listeria monocytogenes_GCF_000438585.1@AGR25087.1') x 2, 0, 0, 0, 0, undef, undef,
        'Listeria', 'monocytogenes', undef, 'AGR25087.1', undef,
        'GCF_000438585.1', 'GCF_000438585.1', 'GCF_000438585', '1', 'GCF', '000438585',
        undef, undef, undef, undef,
        'Listeria monocytogenes', 'L. monocytogenes', 'Listeria monocytogenes_GCF_000438585.1',
        'Listeria monocytogenes GCF_000438585.1',
        'Listeria monocytogenes GCF_000438585.1',
        'Listeria_monocytogenes_GCF_000438585.1@AGR25087.1',
        q{'Listeria monocytogenes_GCF_000438585.1@AGR25087.1'} ],

    [ ('81970|ABB29495.1') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, 'ABB29495.1', undef,
        '81970', undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        '81970|ABB29495.1',
        q{'81970|ABB29495.1'} ],

    [ ('45351|NEMVEDRAFT_v1g121533-PA') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, 'NEMVEDRAFT_v1g121533-PA', undef,
        '45351', undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        '45351|NEMVEDRAFT_v1g121533-PA',
        q{'45351|NEMVEDRAFT_v1g121533-PA'} ],

    [ ('GCF_000438585.1|AGR25087.1') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, 'AGR25087.1', undef,
        'GCF_000438585.1', 'GCF_000438585.1', 'GCF_000438585', '1', 'GCF', '000438585',
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'GCF_000438585.1|AGR25087.1',
        q{'GCF_000438585.1|AGR25087.1'} ],

    [ ('gi|404160475') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        '404160475', undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'gi|404160475',
        q{'gi|404160475'} ],

    [ ('gi|404160475|gb|AFR53081.1|') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, 'AFR53081.1', undef,
        undef, undef, undef, undef, undef, undef,
        '404160475', undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'gi|404160475|gb|AFR53081.1|',
        q{'gi|404160475|gb|AFR53081.1|'} ],

    [ ('gi|404160475|gb|AFR53081.1| AOX [Anthurium andraeanum]') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, 'AFR53081.1', undef,
        undef, undef, undef, undef, undef, undef,
        '404160475', undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'gi|404160475|gb|AFR53081.1| AOX [Anthurium andraeanum]',
        q{'gi|404160475|gb|AFR53081.1| AOX [Anthurium andraeanum]'} ],

    [ ('gi|11245480|gb|AAG33633.1|AF314254_1') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, 'AAG33633.1', undef,
        undef, undef, undef, undef, undef, undef,
        '11245480', undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'gi|11245480|gb|AAG33633.1|AF314254_1',
        q{'gi|11245480|gb|AAG33633.1|AF314254_1'} ],

    [ ('gi|11245480|gb|AAG33633.1|AF314254_1 alternative oxidase 1 [Chlamydomonas reinhardtii]') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, 'AAG33633.1', undef,
        undef, undef, undef, undef, undef, undef,
        '11245480', undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'gi|11245480|gb|AAG33633.1|AF314254_1 alternative oxidase 1 [Chlamydomonas reinhardtii]',
        q{'gi|11245480|gb|AAG33633.1|AF314254_1 alternative oxidase 1 [Chlamydomonas reinhardtii]'} ],

    [ ('gnl|EF-Ts_27|PF3D7_0305000') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, 'EF-Ts_27', 'PF3D7_0305000', undef,
        undef, undef, undef,
        undef,
        undef,
        'gnl|EF-Ts_27|PF3D7_0305000',
        q{'gnl|EF-Ts_27|PF3D7_0305000'},
        'gnl', 'EF-Ts_27', 'PF3D7_0305000' ],

    [ ('gnl|met-10+|PF3D7_0914300') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, 'met-10+', 'PF3D7_0914300', undef,
        undef, undef, undef,
        undef,
        undef,
        'gnl|met-10+|PF3D7_0914300',
        q{'gnl|met-10+|PF3D7_0914300'},
        'gnl', 'met-10+', 'PF3D7_0914300' ],

    [ ('gnl|TPx(Gl)_120|PF3D7_1212000') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, 'TPx(Gl)_120', 'PF3D7_1212000', undef,
        undef, undef, undef,
        undef,
        undef,
        'gnl|TPx(Gl)_120|PF3D7_1212000',
        q{'gnl|TPx(Gl)_120|PF3D7_1212000'},
        'gnl', 'TPx(Gl)_120', 'PF3D7_1212000' ],

    [ ('gnl|OTUlcp2|PF3D7_1031400.2|more-stuff preserved description') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, 'OTUlcp2', 'PF3D7_1031400.2', undef,
        undef, undef, undef,
        undef,
        undef,
        'gnl|OTUlcp2|PF3D7_1031400.2|more-stuff preserved description',
        q{'gnl|OTUlcp2|PF3D7_1031400.2|more-stuff preserved description'},
        'gnl', 'OTUlcp2', 'PF3D7_1031400.2', 'more-stuff' ],

    [ ('seq1') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'seq1',
        q{'seq1'} ],

    [ (q{Arthrospira platensis UTEX 'LB 2340' [88792662]}) x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        q{Arthrospira platensis UTEX 'LB 2340' [88792662]},
        q{'Arthrospira platensis UTEX LB 2340 [88792662]'} ],

    [ ('candidatus_methylomirabilis_oxyfera~GCA_000091165.1@FP565575~[[462948..463340]]=Bacteria-Candidate_division_nc10-unknown_class-unknown_order-unknown_family-Candidatus_methylomirabilis-Candidatus_methylomirabilis_oxyfera') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'candidatus_methylomirabilis_oxyfera~GCA_000091165.1@FP565575~[[462948..463340]]=Bacteria-Candidate_division_nc10-unknown_class-unknown_order-unknown_family-Candidatus_methylomirabilis-Candidatus_methylomirabilis_oxyfera',
        q{'candidatus_methylomirabilis_oxyfera~GCA_000091165.1@FP565575~[[462948..463340]]=Bacteria-Candidate_division_nc10-unknown_class-unknown_order-unknown_family-Candidatus_methylomirabilis-Candidatus_methylomirabilis_oxyfera'} ],

    [ ('candidatus_kinetoplastibacterium_crithidii|TCC036E~GCA_000340825.1@CP003804~[[809869..810243]]C=Bacteria-Proteobacteria-Betaproteobacteria-unknown_order-unknown_family-Kinetoplastibacterium-Candidatus_kinetoplastibacterium_crithidii') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'candidatus_kinetoplastibacterium_crithidii|TCC036E~GCA_000340825.1@CP003804~[[809869..810243]]C=Bacteria-Proteobacteria-Betaproteobacteria-unknown_order-unknown_family-Kinetoplastibacterium-Candidatus_kinetoplastibacterium_crithidii',
        q{'candidatus_kinetoplastibacterium_crithidii|TCC036E~GCA_000340825.1@CP003804~[[809869..810243]]C=Bacteria-Proteobacteria-Betaproteobacteria-unknown_order-unknown_family-Kinetoplastibacterium-Candidatus_kinetoplastibacterium_crithidii'} ],

    [ ('Escherichia_coli|ER2796~GCA_000800215.1@CP009644~[[4152126..4152491]]=Bacteria-Proteobacteria-Gammaproteobacteria-Enterobacteriales-Enterobacteriaceae-Escherichia-Escherichia_coli') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'Escherichia_coli|ER2796~GCA_000800215.1@CP009644~[[4152126..4152491]]=Bacteria-Proteobacteria-Gammaproteobacteria-Enterobacteriales-Enterobacteriaceae-Escherichia-Escherichia_coli',
        q{'Escherichia_coli|ER2796~GCA_000800215.1@CP009644~[[4152126..4152491]]=Bacteria-Proteobacteria-Gammaproteobacteria-Enterobacteriales-Enterobacteriaceae-Escherichia-Escherichia_coli'} ],

    [ ('Salmonella_enterica_subsp._enterica|SEROVARENTERITIDISEC20110358~GCA_000623335.1@CP007260~[[4225927..4226292]]=Bacteria-Proteobacteria-Gammaproteobacteria-Enterobacteriales-Enterobacteriaceae-Salmonella-Salmonella_enterica-Salmonella_enterica_subsp._enterica') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'Salmonella_enterica_subsp._enterica|SEROVARENTERITIDISEC20110358~GCA_000623335.1@CP007260~[[4225927..4226292]]=Bacteria-Proteobacteria-Gammaproteobacteria-Enterobacteriales-Enterobacteriaceae-Salmonella-Salmonella_enterica-Salmonella_enterica_subsp._enterica',
        q{'Salmonella_enterica_subsp._enterica|SEROVARENTERITIDISEC20110358~GCA_000623335.1@CP007260~[[4225927..4226292]]=Bacteria-Proteobacteria-Gammaproteobacteria-Enterobacteriales-Enterobacteriaceae-Salmonella-Salmonella_enterica-Salmonella_enterica_subsp._enterica'} ],

    [ ('Mycobacterium_tuberculosis|BEIJING/NITR203~GCA_000364825.1@CP005082~[[748789..749181]]=Bacteria-Actinobacteria-Actinobacteria-Corynebacteriales-Mycobacteriaceae-Mycobacterium-Mycobacterium_tuberculosis') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'Mycobacterium_tuberculosis|BEIJING/NITR203~GCA_000364825.1@CP005082~[[748789..749181]]=Bacteria-Actinobacteria-Actinobacteria-Corynebacteriales-Mycobacteriaceae-Mycobacterium-Mycobacterium_tuberculosis',
        q{'Mycobacterium_tuberculosis|BEIJING/NITR203~GCA_000364825.1@CP005082~[[748789..749181]]=Bacteria-Actinobacteria-Actinobacteria-Corynebacteriales-Mycobacteriaceae-Mycobacterium-Mycobacterium_tuberculosis'} ],

    [ ('Pycnococcus provasolii_41880@PROTID001') x 2, 0, 0, 0, 0, undef, undef,
        'Pycnococcus', 'provasolii', undef, 'PROTID001', undef,
        '41880', undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Pycnococcus provasolii', 'P. provasolii', 'Pycnococcus provasolii_41880',
        'Pycnococcus provasolii 41880',
        'Pycnococcus provasolii 41880',
        'Pycnococcus_provasolii_41880@PROTID001',
        q{'Pycnococcus provasolii_41880@PROTID001'} ],

    [ ('Pycnococcus provasolii_RCC251_MMETSP1472_41880@PROTID001') x 2, 0, 0, 0, 0, undef, undef,
        'Pycnococcus', 'provasolii', 'RCC251_MMETSP1472', 'PROTID001', undef,
        '41880', undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Pycnococcus provasolii', 'P. provasolii', 'Pycnococcus provasolii_RCC251_MMETSP1472_41880',
        'Pycnococcus provasolii RCC251_MMETSP1472 41880',
        'Pycnococcus provasolii RCC251_MMETSP1472 41880',
        'Pycnococcus_provasolii_RCC251_MMETSP1472_41880@PROTID001',
        q{'Pycnococcus provasolii_RCC251_MMETSP1472_41880@PROTID001'} ],

    [ ('Moorea producens_GCF_001854205.1@PROTID001') x 2, 0, 0, 0, 0, undef, undef,
        'Moorea', 'producens', undef, 'PROTID001', undef,
        'GCF_001854205.1', 'GCF_001854205.1', 'GCF_001854205', '1', 'GCF', '001854205',
        undef, undef, undef, undef,
        'Moorea producens', 'M. producens', 'Moorea producens_GCF_001854205.1',
        'Moorea producens GCF_001854205.1',
        'Moorea producens GCF_001854205.1',
        'Moorea_producens_GCF_001854205.1@PROTID001',
        q{'Moorea producens_GCF_001854205.1@PROTID001'} ],

    [ ('Moorea producens_JHB_GCF_001854205.1@PROTID001') x 2, 0, 0, 0, 0, undef, undef,
        'Moorea', 'producens', 'JHB', 'PROTID001', undef,
        'GCF_001854205.1', 'GCF_001854205.1', 'GCF_001854205', '1', 'GCF', '001854205',
        undef, undef, undef, undef,
        'Moorea producens', 'M. producens', 'Moorea producens_JHB_GCF_001854205.1',
        'Moorea producens JHB GCF_001854205.1',
        'Moorea producens JHB GCF_001854205.1',
        'Moorea_producens_JHB_GCF_001854205.1@PROTID001',
        q{'Moorea producens_JHB_GCF_001854205.1@PROTID001'} ],

    [ ('u#Emiliania huxleyi_PLYM219@CAMNT_0030889445') x 2, 0, 0, 0, '1', undef, 'u',
        'Emiliania', 'huxleyi', 'PLYM219', 'CAMNT_0030889445', undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        'Emiliania huxleyi', 'E. huxleyi', 'Emiliania huxleyi_PLYM219',
        'Emiliania huxleyi PLYM219',
        'Emiliania huxleyi PLYM219',
        'u#Emiliania_huxleyi_PLYM219@CAMNT_0030889445',
        q{'u#Emiliania huxleyi_PLYM219@CAMNT_0030889445'} ],

    # space-trailing ids (unparsable)
    [ ('Arabidopsis halleri_81970@78182999 ') x 2, '1', undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        undef, undef, undef, undef,
        undef, undef, undef,
        undef,
        undef,
        'Arabidopsis halleri_81970@78182999 ',
        q{'Arabidopsis halleri_81970@78182999 '} ],

    # quoted ids (from trees)
    [ q{'Nematostella_vectensis_45351@NEMVEDRAFT_v1g166011-PA'}, 'Nematostella vectensis_45351@NEMVEDRAFT_v1g166011-PA', 0, 0, 0, 0, undef, undef,
        'Nematostella', 'vectensis', undef, 'NEMVEDRAFT_v1g166011-PA', undef, '45351',
        undef, undef, undef, undef, undef, undef, undef, undef, undef,
        'Nematostella vectensis', 'N. vectensis', 'Nematostella vectensis_45351',
        'Nematostella vectensis 45351', 'Nematostella vectensis 45351',
        'Nematostella_vectensis_45351@NEMVEDRAFT_v1g166011-PA',
        q{'Nematostella vectensis_45351@NEMVEDRAFT_v1g166011-PA'} ],
);

for my $exp_row (@valid_ids) {
    my $seq_id = $class->new( full_id => $exp_row->[0] );
    explain $seq_id->full_id;
    my $got_row = [
        $seq_id->full_id,                           # 0
        $seq_id->is_foreign,                        # 1
        $seq_id->is_new,                            # 2
        $seq_id->is_genus_only,                     # 3
        $seq_id->is_doubtful,                       # 4
        $seq_id->family,                            # 5
        $seq_id->tag,                               # 6
        $seq_id->genus,                             # 7
        $seq_id->species,                           # 8
        $seq_id->strain,                            # 9
        $seq_id->accession,                         # 10
        $seq_id->tail,                              # 11
        $seq_id->taxon_id,                          # 12
        $seq_id->gca,                               # 13
        $seq_id->gca_novers,                        # 14
        $seq_id->gca_vers,                          # 15
        $seq_id->gca_prefix,                        # 16
        $seq_id->gca_number,                        # 17
        $seq_id->gi,                                # 18
        $seq_id->database,                          # 19
        $seq_id->identifier,                        # 20
        $seq_id->contam_org,                        # 21
        $seq_id->org,                               # 22
        $seq_id->abbr_org,                          # 23
        $seq_id->full_org,                          # 24
        $seq_id->full_org( q{ } ),                  # 25
        $seq_id->family_then_full_org( q{ } ),      # 26
        $seq_id->foreign_id,                        # 27
        $seq_id->nexus_id,                          # 28
        $seq_id->all_parts,                         # 29 must be the last element because when undef
                                                    #    it returns an empty list that flatens to no
                                                    #    element and shortens the list by one and thus
                                                    #    modifies array index
    ];
    # explain $got_row;
    is_deeply $got_row, [ @{$exp_row}[1..$#{$exp_row}] ],
        "Built and queried SeqId: $exp_row->[0]";
}

my @ids2build = (
    [ 'Arabidopsis halleri', '81970', '78182999',
        'Arabidopsis halleri_81970@78182999' ],
    [ 'Micromonas sp. RCC299', '296587', '255079694',
        'Micromonas sp._296587@255079694' ],
    [ 'Capsella bursa-pastoris', '3719', '158513961',
        'Capsella bursa-pastoris_3719@158513961' ],
    [ 'Pseudo-nitzschia multiseries', '37319', '194836',
        'Pseudo-nitzschia multiseries_37319@194836' ],
    [ 'Capsella bursa-pastoris', '3719', q{},
        'Capsella bursa-pastoris_3719' ],
    [ 'Ostreococcus \'lucimarinus\'', '242159', q{},
        'Ostreococcus lucimarinus_242159' ],
    [ 'Micromonas sp. RCC299', '296587', q{},
        'Micromonas sp._296587' ],
    [ 'Candidatus Phytoplasma mali', '37692', q{},
        'Phytoplasma mali_37692' ],
    [ 'Candidatus Arthromitus sp. SFB-rat-Yit', '1041504', q{},
        'Arthromitus sp._1041504' ],
    [ 'Candidatus Cloacamonas acidaminovorans str. Evry', '459349', q{},
        'Cloacamonas acidaminovorans_459349' ],
    [ 'Clostridium sticklandii', '1511', q{},
        'Clostridium sticklandii_1511' ],
    [ 'Clostridium sticklandii', q{}, q{},
        'Clostridium sticklandii' ],

    # TODO: add more ids! (test no species at all genus-like, viruses etc)
);

my @strains2build = (
    [ 'Arabidopsis halleri', '81970', '78182999', 1,
        'Arabidopsis halleri_81970@78182999' ],
    [ 'Micromonas sp. RCC299', '296587', '255079694', 1,
        'Micromonas sp._RCC299_296587@255079694' ],
    [ 'Capsella bursa-pastoris', '3719', '158513961', 1,
        'Capsella bursa-pastoris_3719@158513961' ],
    [ 'Pseudo-nitzschia multiseries', '37319', '194836', 1,
        'Pseudo-nitzschia multiseries_37319@194836' ],
    [ 'Capsella bursa-pastoris', '3719', q{}, 1,
        'Capsella bursa-pastoris_3719' ],
    [ 'Ostreococcus \'lucimarinus\'', '242159', q{}, 1,
        'Ostreococcus lucimarinus_242159' ],
    [ 'Micromonas sp. RCC299', '296587', q{}, 1,
        'Micromonas sp._RCC299_296587' ],
    [ 'Candidatus Phytoplasma mali', '37692', q{}, 1,
        'Phytoplasma mali_37692' ],
    [ 'Candidatus Arthromitus sp. SFB-rat-Yit', '1041504', q{}, 1,
        'Arthromitus sp._SFBratYit_1041504' ],
    [ 'Candidatus Cloacamonas acidaminovorans str. Evry', '459349', q{}, 1,
        'Cloacamonas acidaminovorans_Evry_459349' ],
    [ 'Clostridium sticklandii', '1511', q{}, 1,
        'Clostridium sticklandii_1511' ],
    [ 'Clostridium sticklandii', q{}, q{}, 1,
        'Clostridium sticklandii' ],

    # TODO: add more ids! (test no species at all genus-like, viruses etc)
);

for my $exp_row (@ids2build) {
    my $seq_id = $class->new_with(
        org       => $exp_row->[0],
        taxon_id  => $exp_row->[1],
        accession => $exp_row->[2]
    );
    cmp_ok $seq_id->full_id, 'eq', $exp_row->[3],
        "got expected SeqId: $exp_row->[3]";
}

for my $exp_row (@strains2build) {
    my $seq_id = $class->new_with(
        org         => $exp_row->[0],
        taxon_id    => $exp_row->[1],
        accession   => $exp_row->[2],
        keep_strain => $exp_row->[3]
    );
    cmp_ok $seq_id->full_id, 'eq', $exp_row->[4],
        "got expected SeqId: $exp_row->[4]";
}

my @ids2clean = (
    [ 'Candidatus Phytoplasma mali', 'Phytoplasma mali' ],
    [ 'Candidatus Arthromitus sp. SFB-rat-Yit', 'Arthromitus sp. SFB-rat-Yit' ],
# TODO: check these
#     [ 'uncultured cyanobacterium', 'cyanobacterium' ],
#     [ 'uncultured actinobacterium WB039', 'actinobacterium WB039' ],
    [ 'uncultured Candidatus Hamiltonella sp.', 'Hamiltonella sp.' ],
    [ 'cf. Stagonospora sp. S619', 'Stagonospora sp. S619' ],
    [ 'cf. Pavona sp. 2 DGL-2013', 'Pavona sp. 2 DGL-2013' ],
);
explain \@ids2clean;

for my $exp_row (@ids2clean) {
    my $org = $class->clean_ncbi_name( $exp_row->[0] );

    cmp_ok $org, 'eq', $exp_row->[1],
        "got expected SeqId: $exp_row->[1]";
}

done_testing;
