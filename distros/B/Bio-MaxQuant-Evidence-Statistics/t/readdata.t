#!perl -T

use strict;
use warnings;
use Test::More::Behaviour;

BEGIN {
    use_ok('Bio::MaxQuant::Evidence::Statistics');
}

describe 'Bio::MaxQuant::Evidence::Statistics' => sub {
    
#            'MCF7.ET.r2' => -0.168901948588134, # SD=0.357498874489868; MAD=0.236642882466628; SD via MAD=0.350847132598894; n=12
#            'MCF7.ET.r3' => 0.273803945055041, # stdev=0.294588165594879 mad=0.19618609916723 sd-via-mad=0.290865838140269; n=10
            # ( MAD = 0.67449 SD;  SD = 1.4826016694 MAD )

    };
    context 'setup' => sub {
        it 'should be able to make a new object' => sub {
            my $o = Bio::MaxQuant::Evidence::Statistics->new();
        };
    };
    context 'parsing, saving and reloading essentials' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        my $p = Bio::MaxQuant::Evidence::Statistics->new();
        it 'should parse a file' => sub {
            $o->parseEssentials(filename=>'t/selectedEvidence.txt');
        };
        it 'should have parsed the right number of proteins' => sub {
            is($o->proteinCount(), 7, 'counting proteins');
        };
        it 'should have parsed the correct protein ids and names' => sub {
            is( join(';', sort $o->getLeadingProteins()), 
                'P03372;P11388;P41743;P49454;Q02880-2;Q05655;Q92547',
                'leading proteins');
            is( join(';', sort $o->getProteinGroupIds()),
                '1371;1485;1775;1846;2111;2131;2913',
                'protein group ids'
            );
        };
        it 'should have the right number of experiments and evidences' => sub {
            is( scalar($o->experiments), 27, 'experiments');
            is( scalar($o->ids), 2793, 'ids');
        };
        it 'should have the right number shared and unique' => sub {
            is( scalar($o->sharedIds), 400, 'shared');
            is( scalar($o->uniqueIds), 2393, 'unique');
        };
        it 'should be able to serialize the data' => sub {
            $o->saveEssentials(filename=>'t/serialized');
        };
        it 'should have serialized the data correctly' => sub {
            # diff serialized and serialized.expected??
        };
        it 'should be able to load serialized data' => sub {
            $p->loadEssentials(filename=>'t/serialized');
        };
        it 'should have correctly loaded serialized data' => sub {
            # deep comparison between $o and $p data??
            is_deeply($p, $o, 'loaded vs pre saved.');
            is($p->proteinCount(), 7, 'counting proteins');
            is( scalar($p->experiments), 27, 'experiments');
            is( scalar($p->ids), 2793, 'ids');
            is( scalar($p->sharedIds), 400, 'shared');
            is( scalar($p->uniqueIds), 2393, 'unique');
            is( join(';', sort $p->getLeadingProteins()), 
                'P03372;P11388;P41743;P49454;Q02880-2;Q05655;Q92547',
                'leading proteins');
            is( join(';', sort $p->getProteinGroupIds()),
                '1371;1485;1775;1846;2111;2131;2913',
                'protein group ids'
            );
        };
    };
    context 'independent subs' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        it 'should get correct medians' => sub {
            is($o->median(qw/0 2 3 4 5 6 10/), 4, 'middle sorted');
            is($o->median(qw/5 2 3 6 0 4 10/), 4, 'middle unsorted');
            is($o->median(qw/0 2 3 4 6 7 8 20/), 5, 'mean of middles sorted');
            is($o->median(qw/3 7 0 4 8 2 6 20/), 5, 'mean of middles unsorted');
        };
        it 'should give correct summary stats' => sub {
            my $d1 = $o->sd(qw/1 2 3 4 5/);
            my $d2 = $o->sd(qw/5 6 7 8 9/);
            is($d1->{sd}, 1.58113883008419, 'sd');
            is($d1->{usv}, 2.5, 'usv');
            
            my $tt = $o->welchs_ttest(
                usv1=>$d1->{usv},  usv2=>$d2->{usv},
                n1=>$d1->{n},  n2=>$d2->{n},
                mean1=>$d1->{mean},  mean2=>$d2->{mean},
            );
            is($tt->{df}, 8, 'df');
            print STDERR $tt->{t};
            use Statistics::Distributions;
            cmp_ok(
                sprintf("%.7f", Statistics::Distributions::tprob($tt->{df}, $tt->{t})), 
                '==', 
                sprintf("%.7f", 0.00197488640172266), 
                'welchs ttest'
            );
        };
    };
    context 'data prep' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        $o->{data}->{'MCF7.ET.r1'}->{'Q05655'}->{'Ratio H/L'}->[0] = 1;
        it 'should log all the ratios' => sub {
            is($o->logRatios(),1,'log ratios');
            is($o->{data}->{'MCF7.ET.r1'}->{'Q05655'}->{'Ratio H/L'}->[0], 0, 'log check');
        };
        it 'should not log the ratios twice' => sub {
            is($o->logRatios(),0,'2nd try should fail');
        };
    };
    context 'normalization' => sub {
        my @sets = qw/All select_Q05655 select_Q05655_P11388 exclude_Q05655 exclude_Q05655_P11388/;
        my %medians_data = (
            Expts => [qw/LCC1.nE.r1 LCC1.nE.r2 LCC1.nE.r3 LCC1.wE.r1 LCC1.wE.r2 LCC1.wE.r3 LCC1.ET.r1 LCC1.ET.r2 LCC1.ET.r3 LCC9.nE.r1 LCC9.nE.r2 LCC9.nE.r3 LCC9.wE.r1 LCC9.wE.r2 LCC9.wE.r3 LCC9.ET.r1 LCC9.ET.r2 LCC9.ET.r3 MCF7.nE.r1 MCF7.nE.r2 MCF7.nE.r3 MCF7.wE.r1 /],
            All => [qw/-1.63648125984708 -1.24002732928225 -1.17496248821031 -1.75742769084347 -1.48236893250806 -1.35363466330692 -1.16782156198554 -0.799040767571155 -1.40763147067625 -1.37627215538279 -1.49366210724807 -1.01148411915581 -1.03364967993477 -0.849128423079465 -0.67013012768234 -1.6490049675735 -1.7099059320793 -0.954991099698264 -0.163833476364181 -0.842335352988528 -0.648597816370036 -0.672636102487885 /],
            select_Q05655 => [qw/-0.63509986575466 -0.556789022536737 -0.98459034333131 -0.603708964185035 -0.585366678188408 -0.890733059997463 -0.735619706777835 -0.245762391293794 -0.899695094204314 0.457226545544628 0.757620688778619 -0.269787612886921 0.821334441348077 1.11648837917085 0.163852361197212 -0.288135106038059 0.0322419242393385 -0.278661026942532 1.09910969653997 0.688672738339143 1.45388831917853 0.450591031925189 /],
            select_Q05655_P11388 => [qw/-2.0785027329921 -1.75112517479158 -1.30639485495392 -1.439162508104 -1.85897700227383 -1.47196885525624 -1.31981921569953 -0.89598955383679 -1.63285262534206 -2.19945499829237 -2.04775590586458 -1.44772130900956 -1.51682165421132 -1.18737177007143 -0.949839644352705 -2.23487266034399 -2.145669159723 -1.1153139455028 0.664263458901235 -0.0244901060161585 0.585635601362301 0.532763798157621 /],
            exclude_Q05655 => [qw/-1.74714840094933 -1.30854647839915 -1.23917536507923 -1.82679579543345 -1.67865008344339 -1.47995497596018 -1.21641762605963 -0.858410260758666 -1.59459574635225 -1.55681773300778 -1.59864323359854 -1.05336518102205 -1.08389673806024 -0.904035083866926 -0.693084524258711 -1.84032035065785 -1.80783108999313 -1.07704988169697 -0.180331816503544 -0.8763162516483 -0.685639900752222 -0.77450294428223 /],
            exclude_Q05655_P11388 => [qw/-1.37875896320424 -1.06413296050399 -1.04996390692107 -1.89840374273412 -1.31939296977271 -1.32709497096238 -1.13718826848392 -0.774801721438059 -1.35840010661763 -1.0069930016948 -0.738746750581922 -0.851130956468999 -0.994835445458168 -0.754139298159647 -0.543239963955441 -1.22131097701049 -1.35781211214546 -0.827805541516328 -0.306948007438546 -0.946304750958459 -0.715289943441752 -0.860371702143931 /],
            Q05655_All => [qw/1.00138139409242 0.683238306745513 0.190372144879004 1.15371872665844 0.897002254319649 0.462901603309458 0.432201855207705 0.553278376277361 0.507936376471939 1.83349870092742 2.25128279602669 0.741696506268894 1.85498412128285 1.96561680225032 0.833982488879553 1.36086986153544 1.74214785631864 0.676330072755732 1.26294317290415 1.53100809132767 2.10248613554857 1.12322713441307 /],
            Q05655_select_Q05655 => [qw/0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 /],
            Q05655_select_Q05655_P11388 => [qw/1.44340286723744 1.19433615225485 0.321804511622611 0.835453543918969 1.27361032408543 0.581235795258778 0.584199508921699 0.650227162542996 0.733157531137741 2.656681543837 2.80537659464319 1.17793369612264 2.3381560955594 2.30386014924228 1.11369200554992 1.94673755430593 2.17791108396234 0.836652918560264 0.434846237638731 0.713162844355302 0.868252717816229 -0.0821727662324321 /],
            Q05655_exclude_Q05655 => [qw/1.11204853519467 0.751757455862414 0.254585021747916 1.22308683124842 1.09328340525498 0.589221915962719 0.480797919281794 0.612647869464872 0.694900652147933 2.01404427855241 2.35626392237715 0.783577568135126 1.90523117940832 2.02052346303778 0.856936885455923 1.55218524461979 1.84007301423247 0.798388854754437 1.27944151304351 1.56498898998744 2.13952821993075 1.22509397620742 /],
            Q05655_exclude_Q05655_P11388 => [qw/0.743659097449585 0.507343937967256 0.0653735635897594 1.29469477854908 0.734026291584304 0.436361910964912 0.401568561706083 0.529039330144265 0.458705012413319 1.46421954723943 1.49636743936054 0.581343343582078 1.81616988680625 1.8706276773305 0.707092325152653 0.933175870972427 1.3900540363848 0.549144514573796 1.40605770397851 1.6349774892976 2.16917826262028 1.31096273406912 /],

            sd => [qw/0.517709788365432 0.480667014635711 0.421314234268259 0.445544734662938 0.407955678850936 0.506814068346867 0.389366585408493 0.354874264244425 0.444719148105089 0.70257719665518 0.42491496711329 0.457991306286654 0.268002975609662 0.432266733312228 0.36607194000578 0.357160136618307 0.848107265916177 0.332179131645297 0.140554737538421 0.648092015060518 0.114628545585838 0.387865224681193 /],
            n => [qw/18 16 18 15 22 17 13 11 19 9 7 8 10 10 6 19 12 14 4 3 4 13 /],
            sd_from_mad => [qw/0.483581989796736 0.40787333475383 0.441259164810879 0.198638247906392 0.321944252150699 0.315660469894928 0.464832126712712 0.237542085194986 0.359104626036244 0.600791824556382 0.391975076838372 0.466859414840518 0.217154814931712 0.189890269085041 0.260785285805637 0.211717918241972 0.787101987439075 0.262047288433958 0.0946390642907358 0.651293035896203 0.107927319405304 0.18904541567798 /],
            mad => [qw/0.326171216300086 0.27510648555987 0.297624894075193 0.133979511831239 0.217148178634513 0.212909830340791 0.313524621148462 0.16021976104419 0.242212479216735 0.405228077747625 0.264383269578404 0.314892006717794 0.146468751124227 0.128079087595988 0.175897067424169 0.14280161867594 0.530892419511176 0.176748275576951 0.0638331024738665 0.439290639784439 0.0727958976661491 0.127509242421456 /],
            ttest => [qw/0.5 0.271919673640303 0.00766648743371879 0.136812819839709 0.212148797535008 0.0355343267407489 0.214911057469358 0.0265099735906373 0.071460291745273 0.00085095250022874 0.00000859587352900664 0.03376253263921 0.000000000477164004049282 0.0000000131663595111315 0.000461805862444748 0.0459979947041725 0.0490562684359915 0.110766448353591 0.000000000210727200822708 0.0439282009042248 0.00000000000162947915915658 0.000000202063127352644 /],
        );
        my %medians_rules = (
            All => {},
            select_Q05655 => {leadingProteins => '^Q05655$'},
            select_Q05655_P11388 => {leadingProteins => '^Q05655$|^P11388$'},
            exclude_Q05655 => {notLeadingProteins => '^Q05655$'},
            exclude_Q05655_P11388 => {notLeadingProteins => '^Q05655$|^P11388$'}
        );

        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        $o->logRatios(); # should be log 2!

        it 'should give median for a replicate' => sub {
            foreach my $set(@sets){
                my %medians = ();
                @medians{@{$medians_data{Expts}}} = @{$medians_data{$set}};
                my %rules = %{$medians_rules{$set}};
                foreach my $rep(sort keys %medians){
                    cmp_ok(
                        sprintf("%.10f", $o->replicateMedian(%rules, experiment=>$rep)),
                        '==',
                        sprintf("%.10f", $medians{$rep}),
                        "median of $set for $rep");
                }
            }
        };
        it 'should correctly subtract medians from the proteins' => sub {
            foreach my $set(@sets){
                # this is just like the above... but we call replicateMedianSubtractions first
                my $o = Bio::MaxQuant::Evidence::Statistics->new();
                $o->loadEssentials(filename=>'t/serialized');
                $o->logRatios(); # should be log 2!
                my %medians = ();
                @medians{@{$medians_data{Expts}}} = @{$medians_data{'Q05655_'.$set}};
                my %rules = %{$medians_rules{$set}};
                my %test_rules = %{$medians_rules{select_Q05655}};
                $o->replicateMedianSubtractions(%rules);
                foreach my $rep(sort keys %medians){
                    cmp_ok(
                        sprintf("%.10f", $o->replicateMedian(%test_rules,experiment=>$rep)),
                        '==',
                        sprintf("%.10f", $medians{$rep}),
                        "$rep Q05655 normalized on $set");
                }
        };
        # start afresh...
        $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        $o->logRatios(); # should be log 2!
        it 'should calculate MAD, SD, etc for each protein in each replicate' => sub {
            # each replicate
            my (%sds, %mads, %sds_via_mads, %ns);
            @sds{@{$medians_data{Expts}}} = @{$medians_data{'sd'}};
            @ns{@{$medians_data{Expts}}} = @{$medians_data{'n'}};
            @mads{@{$medians_data{Expts}}} = @{$medians_data{'mad'}};
            @sds_via_mads{@{$medians_data{Expts}}} = @{$medians_data{'sd_from_mad'}};
            my %test_rules = %{$medians_rules{select_Q05655}};
            foreach my $rep(@{$medians_data{Expts}}){
                my $d = $o->deviations(experiment=>$rep,%test_rules);
                is($d->{n}, $ns{$rep}, "deviation: n in $rep");
                cmp_ok( sprintf("%.10f", $d->{sd}), '==', sprintf("%.10f", $sds{$rep}), 'deviation: sd in $rep');
                cmp_ok( sprintf("%.10f", $d->{mad}), '==', sprintf("%.10f", $mads{$rep}), 'deviation: mad in $rep');
                cmp_ok( sprintf("%.10f", $d->{sd_via_mad}), '==', sprintf("%.10f", $sds_via_mads{$rep}), 'deviation: sd_via_mad in $rep');
            }
        };
    };
    context 'pairwise comparisons' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        $o->logRatios(); # should be log 2!
        it 'should give p-value for two items' => sub {
            my (%p);
            @p{@{$medians_data{Expts}}} = @{$medians_data{'ttest'}};
            foreach my $rep(@{$medians_data{Expts}}){
                my $ttest = $o->ttest(experiment1=>'LCC1.nE.r1', experiment2=>$rep, leadingProteins=>'^Q05655$');
                # allow 10% deviation because we're using a different method...
                my $ttp = $ttest->{ttest}->{p};
                my $p = $p{$rep};
                my $lttp = log($ttp)/log(2);
                my $lp = log($p)/log(2);
                my $pd = abs($lttp-$lp);
                ok($pd < 0.5 || $lp < 0.0000001 && $lttp < 0.0000001  , "ttest p-value for Q05655 LCC1.nE.r1 v $rep: $pd v 0.1 ($p $ttp/ $lp $lttp)");
            }
        };
        it 'should give maximum p-value among two sets of compared replicates' => sub {
            cmp_ok(sprintf("%.4f",
                    $o->experimentMaximumPvalue(experiment1=>'LCC1.ET',experiment2=>'LCC1.wE',filter=>'^Q05655$')->{p_max}
                ),
                '==',
                sprintf("%.4f",0.167794288667676)
            );

            cmp_ok(sprintf("%.4f",
                    $o->experimentMaximumPvalue(experiment1=>'LCC1.nE',experiment2=>'LCC1.wE',filter=>'^Q05655$')->{p_max}
                ),
                '==',
                sprintf("%.4f", 0.287775626830834)
            );
        };
    };
    context 'differential response detection' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        $o->logRatios(); # should be log 2!
        it 'should compare orthogonal items' => sub {
            my $expts = 'LCC1.ET.r1,LCC1.ET.r2,LCC1.ET.r3,LCC1.nE.r1,LCC1.nE.r2,LCC1.nE.r3,LCC1.wE.r1,LCC1.wE.r2,LCC1.wE.r3,LCC9.ET.r1,LCC9.ET.r2,LCC9.ET.r3,LCC9.nE.r1,LCC9.nE.r2,LCC9.nE.r3,LCC9.wE.r1,LCC9.wE.r2,LCC9.wE.r3,MCF7.ET.r1,MCF7.ET.r2,MCF7.ET.r3,MCF7.nE.r1,MCF7.nE.r2,MCF7.nE.r3,MCF7.wE.r1,MCF7.wE.r2,MCF7.wE.r3';
            my $replicated = 'LCC1.ET,LCC1.nE,LCC1.wE,LCC9.ET,LCC9.nE,LCC9.wE,MCF7.ET,MCF7.nE,MCF7.wE';
            my $exptpairs = 'LCC1.ET LCC1.nE,LCC1.ET LCC1.wE,LCC1.ET LCC9.ET,LCC1.ET LCC9.nE,LCC1.ET LCC9.wE,LCC1.ET MCF7.ET,LCC1.ET MCF7.nE,LCC1.ET MCF7.wE,LCC1.nE LCC1.wE,LCC1.nE LCC9.ET,LCC1.nE LCC9.nE,LCC1.nE LCC9.wE,LCC1.nE MCF7.ET,LCC1.nE MCF7.nE,LCC1.nE MCF7.wE,LCC1.wE LCC9.ET,LCC1.wE LCC9.nE,LCC1.wE LCC9.wE,LCC1.wE MCF7.ET,LCC1.wE MCF7.nE,LCC1.wE MCF7.wE,LCC9.ET LCC9.nE,LCC9.ET LCC9.wE,LCC9.ET MCF7.ET,LCC9.ET MCF7.nE,LCC9.ET MCF7.wE,LCC9.nE LCC9.wE,LCC9.nE MCF7.ET,LCC9.nE MCF7.nE,LCC9.nE MCF7.wE,LCC9.wE MCF7.ET,LCC9.wE MCF7.nE,LCC9.wE MCF7.wE,MCF7.ET MCF7.nE,MCF7.ET MCF7.wE,MCF7.nE MCF7.wE';
            my $orthogonals = 'LCC1.ET LCC1.nE LCC9.ET,LCC1.ET LCC1.nE MCF7.ET,LCC1.ET LCC1.wE LCC9.ET,LCC1.ET LCC1.wE MCF7.ET,LCC1.nE LCC1.ET LCC9.nE,LCC1.nE LCC1.ET MCF7.nE,LCC1.nE LCC1.wE LCC9.nE,LCC1.nE LCC1.wE MCF7.nE,LCC1.wE LCC1.ET LCC9.wE,LCC1.wE LCC1.ET MCF7.wE,LCC1.wE LCC1.nE LCC9.wE,LCC1.wE LCC1.nE MCF7.wE,LCC9.ET LCC9.nE LCC1.ET,LCC9.ET LCC9.nE MCF7.ET,LCC9.ET LCC9.wE LCC1.ET,LCC9.ET LCC9.wE MCF7.ET,LCC9.nE LCC9.ET LCC1.nE,LCC9.nE LCC9.ET MCF7.nE,LCC9.nE LCC9.wE LCC1.nE,LCC9.nE LCC9.wE MCF7.nE,LCC9.wE LCC9.ET LCC1.wE,LCC9.wE LCC9.ET MCF7.wE,LCC9.wE LCC9.nE LCC1.wE,LCC9.wE LCC9.nE MCF7.wE,MCF7.ET MCF7.nE LCC1.ET,MCF7.ET MCF7.nE LCC9.ET,MCF7.ET MCF7.wE LCC1.ET,MCF7.ET MCF7.wE LCC9.ET,MCF7.nE MCF7.ET LCC1.nE,MCF7.nE MCF7.ET LCC9.nE,MCF7.nE MCF7.wE LCC1.nE,MCF7.nE MCF7.wE LCC9.nE,MCF7.wE MCF7.ET LCC1.wE,MCF7.wE MCF7.ET LCC9.wE,MCF7.wE MCF7.nE LCC1.wE,MCF7.wE MCF7.nE LCC9.wE';
            is( join(',', sort $o->experiments()), $expts, 'experiments');
            is( join(',', sort $o->replicated()), $replicated, 'replicated');
            is( join(',', sort $o->pairs()), $exptpairs, 'pairs');
            is( join(',', sort $o->orthogonals()), $orthogonals, 'orthogonals');
        };
    };
    context 'summary stats and p-values' => sub {
        my $o = Bio::MaxQuant::Evidence::Statistics->new();
        $o->loadEssentials(filename=>'t/serialized');
        $o->logRatios(); # should be log 2!
        it 'should use pairs and orthogonals to generate p-values for each protein in each comparison' => sub {
            # orthongals should report the maximum of the two p-values returned
            # pairs should be indexed and that index used by orthogonals.
            # also... any replicate with no (or only one) observations for a protein should give a p-value of -1!
            # in addition, should give option to use proteotypic peptides or not. ( /$protein/ vs /^$protein$/ )
            ok($o->fullProteinComparison(filter=>'Q05655'), 'full protein comparison');
        };
        it 'should do comparisons across all proteins...' => sub {
            ok($o->fullComparison());
        };
    };
};
done_testing();
