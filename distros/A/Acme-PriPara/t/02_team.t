use strict;
use warnings;
use Acme::PriPara;
use Test::More;
use utf8;

subtest 'Team' => sub {
    subtest 'Main Members' => sub {
        my ($laara, $mirei, $sophy, $sion, $dorothy, $reona) = Acme::PriPara->main_members;

        is ref $laara,      'Acme::PriPara::MainMembers::ManakaLaara';
        is ref $mirei,      'Acme::PriPara::MainMembers::MinamiMirei';
        is ref $sophy,      'Acme::PriPara::MainMembers::HojoSophy';
        is ref $sion,       'Acme::PriPara::MainMembers::TodoSion';
        is ref $dorothy,    'Acme::PriPara::MainMembers::DorothyWest';
        is ref $reona,      'Acme::PriPara::MainMembers::ReonaWest';
    };
    subtest 'Laara and Mirei' => sub {
        my ($laara, $mirei) = Acme::PriPara->members_of($Acme::PriPara::Laara_and_Mirei);

        is ref $laara,      'Acme::PriPara::MainMembers::ManakaLaara';
        is ref $mirei,      'Acme::PriPara::MainMembers::MinamiMirei';
    };
    subtest 'SoLaMiSmile' => sub {
        my ($laara, $mirei, $sophy) = Acme::PriPara->members_of($Acme::PriPara::SoLaMi_Smile);

        is ref $laara,      'Acme::PriPara::MainMembers::ManakaLaara';
        is ref $mirei,      'Acme::PriPara::MainMembers::MinamiMirei';
        is ref $sophy,      'Acme::PriPara::MainMembers::HojoSophy';
    };
    subtest 'Dorothy_and_Reona' => sub {
        my ($dorothy, $reona) = Acme::PriPara->members_of($Acme::PriPara::Dorothy_and_Reona);

        is ref $dorothy,    'Acme::PriPara::MainMembers::DorothyWest';
        is ref $reona,      'Acme::PriPara::MainMembers::ReonaWest';
    };
    subtest 'Dressing_Pafé' => sub {
        my ($sion, $dorothy, $reona) = Acme::PriPara->members_of($Acme::PriPara::Dressing_Pafé);

        is ref $sion,       'Acme::PriPara::MainMembers::TodoSion';
        is ref $dorothy,    'Acme::PriPara::MainMembers::DorothyWest';
        is ref $reona,      'Acme::PriPara::MainMembers::ReonaWest';
    };
};

done_testing;
