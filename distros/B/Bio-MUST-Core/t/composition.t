#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(cmp_store);

my $class = 'Bio::MUST::Core::PostPred';

my %zscore_for = (
    Amphiprora => 1.58267937419711,
    Asterionel => 0.94549363988315,
    Asterion00 => -0.416268840218749,
    Aureococcu => -1.64239544020555,
    Aureoumbra => -0.844735408022128,
    Calliarthr => -1.02447895032135,
    Chattonell => -0.202831522668453,
    Chondrus_c => -1.76237036530368,
    Chroomonas => 88.9342117819499,
    Chrysochro => -1.18529485310968,
    Chrysophyc => -1.56721035547146,
    Compsopogo => -0.94241571236797,
    Coscinodis => -0.876741620656906,
    Cryptomona => 3.4844514244897,
    Cryptomo00 => 10.7720978628331,
    Cryptophyc => 119.549148090287,
    Cylindroth => -1.02907886611174,
    Desmaresti => -0.753812188710554,
    Dictyocha_ => -1.71201581993819,
    Dictyopter => -0.219134050348571,
    Didymosphe => 1.03901092160336,
    Durinskia_ => -1.14496341356319,
    Ectocarpus => -1.07232649466561,
    Emiliania_ => -1.1617011003295,
    Eunotia_sp => 0.56497295420961,
    Eustigmato => 66.2422264001362,
    Extubocell => 0.330160440473242,
    Fistulifer => 1.62055081531252,
    Fucus_vesi => -0.938629087732261,
    Geminigera => 0.799149152720513,
    Gracilaria => -1.64659386361315,
    Gracilar00 => -1.21426656927271,
    Grateloupi => 0.422236379075582,
    Guillardia => -0.945709253138492,
    Hemiselmis => -1.11732046776916,
    Heterosigm => -0.619869617095801,
    Ishige_oka => 3.14100218580257,
    Isochrysis => -1.29199084413055,
    Isochrys00 => -1.01270633010325,
    Karlodiniu => 65.0236165857814,
    Kryptoperi => -0.422091797257626,
    Leptocylin => -1.11423361687402,
    Lithodesmi => 0.125854987599378,
    Mallomonas => -1.4082765607768,
    Nannochlor => 1.88615767977141,
    Nannochl00 => 2.43014740106582,
    Ochromonas => -0.648622020864112,
    Odontella_ => -0.0369948725431423,
    Pavlova_lu => 0.423947562802014,
    Pavlova_00 => -0.723721357709189,
    Pavlovales => 1.10680015891664,
    Pedinellal => 4.78732481655296,
    Pelagophyc => -0.421552364057644,
    Phaeocysti => -1.214816474616,
    Phaeocys00 => -1.62186203476268,
    Phaeodacty => -0.920624636583998,
    Phaeomonas => 108.216723635804,
    Pleurochry => -0.77134309642405,
    Porphyra_p => -0.694110654678088,
    Porphyra00 => -0.449004440297331,
    Porphyridi => -0.590216204518807,
    Proteomona => 0.32848669862324,
    Prymnesium => -1.2183270857944,
    Pyropia_ha => -0.174869950414863,
    Pyropia_00 => -0.149076954596854,
    Rhizochrom => 21.6936402922861,
    Rhodella_m => -0.234245441441268,
    Rhodomonas => 0.106335143060398,
    Saccharina => -0.796548935453963,
    Sargassum_ => -0.601648874465658,
    Stylonema_ => 2.6503392416905,
    Synchroma_ => 1.76034428977781,
    Synedra_ac => -0.0458376747430704,
    Synura_spe => 0.762499683851161,
    Thalassios => -0.527779229427491,
    Thalassi00 => -0.578777788922867,
    Uncultured => -0.88832130243939,
    Uncultur00 => 1.09101601910895,
    Vaucheria_ => 0.00101485082317439,
    GLOBALMAX  => 90.9861522619417,
    GLOBALMEAN => 35.8579403665661,
);

{
    my @infiles = map { file('test', "ppred-$_.phy") } 1..50;
    my @alis = map { Bio::MUST::Core::Ali->load_phylip($_) } @infiles;
    my $alifile = file('test', 'for-ppred-comp.phy');
    my $ali = Bio::MUST::Core::Ali->load_phylip($alifile);

    my $test = $class->comp_test( [ $ali, @alis ] );

    # ensure that floating point values are comparable
    my $dp = 12;
    my %got_zscores = map {
        $_ => sprintf "%.${dp}g", $test->zscore_for($_)
    } $test->all_ids;
    my %exp_zscores = map {
        $_ => sprintf "%.${dp}g", $zscore_for{$_}
    } keys %zscore_for;

    is_deeply \%got_zscores, \%exp_zscores, 'got expected zscores';
}

done_testing;
