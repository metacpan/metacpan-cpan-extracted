use strict;
use warnings;
use Acme::PriPara;
use Test::More;

subtest 'Charactors' => sub {
    subtest 'Lala' => sub {
        my $lala = Acme::PriPara::MainMembers::ManakaLala->new;
        is $lala->name,          'Manaka Lala';
        is $lala->firstname,     'Lala';
        is $lala->lastname,      'Manaka';
        is $lala->age,            10;
        is $lala->cv,            'Akaneya Himika';
        is $lala->say,           'Kashikoma!';
        is $lala->costume_brand,  undef;    # withiout PriPara Changing, you cannot get costume_brand.

        $lala->pripara_change;
        is $lala->costume_brand, 'Twinkle Ribbon';  
    };

    subtest 'Mirei' => sub {
        my $mirei = Acme::PriPara::MainMembers::MinamiMirei->new;
        is $mirei->name,       'Minami Mirei';
        is $mirei->firstname,  'Mirei';
        is $mirei->lastname,   'Minami';
        is $mirei->age,        '13';
        is $mirei->cv,         'Serizawa Yu';
        is $mirei->say,        '計算どおり';  # speak nomally
        
        my $word = '計算どおり';
        is $mirei->say($word),    $word . 'ぷり';  # speak with suffix ー 'ぷり'
        is $mirei->costume_brand, undef;

        $mirei->pripara_change;
        is $mirei->costume_brand, 'Candy à la Mode';
    };

    subtest 'Sophie' => sub {
        my $sophie = Acme::PriPara::MainMembers::HōjōSophie->new;
        is $sophie->name,          'Hōjō Sophie';
        is $sophie->firstname,     'Sophie';
        is $sophie->lastname,      'Hōjō';
        is $sophie->age,           '14?';
        is $sophie->cv,            'Kubota Miyu';
        is $sophie->costume_brand,  undef;
        is $sophie->say,           '';

        $sophie->pripara_change;
        is $sophie->costume_brand, undef;     # Sophie attempt to enter the PriPara World...

        $sophie->pripara_change('Red Flash'); # Sophie can get to the PriPara World after eating Red Flash
        is $sophie->costume_brand, 'Holic Trick';
        is $sophie->say,           'something';
    };

    subtest 'Shion' => sub {
        my $shion = Acme::PriPara::MainMembers::TodoShion->new;
        is $shion->name,          'Todo Shion';
        is $shion->cv,            'Yamakita Saki';
        is $shion->age,           '13';
        # ...

        $shion->pripara_change;
        is $shion->costume_brand, 'Baby Monster';
    };
    subtest 'Dorothy' => sub {
        my $dorothy = Acme::PriPara::MainMembers::DorothyWest->new;
        is $dorothy->name,        'Dorothy West';
        is $dorothy->cv,          'Shibuya Azuki';
        # ...

        $dorothy->pripara_change;
        is $dorothy->costume_brand, undef;

        my $leona = Acme::PriPara::MainMembers::LeonaWest->new;
        $dorothy->pripara_change($leona);  # Dorothy is always being with Leona ...
        is $dorothy->costume_brand, 'Fortune Party';
    };
    subtest 'Leona' => sub {
        my $leona = Acme::PriPara::MainMembers::LeonaWest->new;
        is $leona->name,         'Leona West';
        is $leona->cv,           'Wakai Yuki';
        # ...

        $leona->pripara_change;
        is $leona->costume_brand, undef;

        my $dorothy = Acme::PriPara::MainMembers::DorothyWest->new;
        $leona->pripara_change($dorothy);  # Leona is always being with Dorothy ...
        is $leona->costume_brand, 'Fortune Party';
    };
};

subtest 'Live' => sub {
    my ($lala, $mirei, $sophie, $shion, $dorothy, $leona) = Acme::PriPara->main_members;

    is (sing($lala, $mirei), 'Marble Make up a-ha-ha!');
    is (sing($sophie), 'Solar Flare Sherbet');
    is (sing($lala, $mirei, $sophie), 'Pretty Prism Paradise!!!');
    is (sing($lala, $sophie), 'Make it!');
    is (sing($shion, $dorothy, $leona), 'No D&D code');
};

subtest 'Costume' => sub {
    my ($lala, $mirei, $sophie, $shion, $dorothy, $leona) = Acme::PriPara->main_members;

    subtest 'lala' => sub {
        $lala->pripara_change;
        is $lala->costume(1), 'Twinkle Ribbon';     # take episode number to argument
        is $lala->costume(2), 'Wonderland Macaron Onepiece';
        # ...
    };
    subtest 'mirei' => sub {
        $mirei->pripara_change;
        is $mirei->costume(1), 'Candy à la Mode';
        is $mirei->costume(2), 'Wonderland Rabbit Onepiece';
        # ...
    };
    subtest 'sophie' => sub {
        $shophie->pripara_change('Red Flash');
        is $shophie->costume(1),  undef;
        is $shophie->costume(2), 'Holic Trick';
        # ...
    };
};

subtest 'Team' => sub {
    subtest 'Lara and Mirei' => sub {
        my ($lala, $mirei) = Acme::PriPara->lala_and_mirei;
    };
    subtest 'SoLaMi☆ SMILE' => sub {
        my ($lala, $mirei, $sophie) = Acme::PriPara->solami_smile;
    };
    subtest 'Dressing Pafé' => sub {
        my ($shion, $dorothy, $leona) = Acme::PriPara->dressing_pafé;
    };
};

done_testing;


