use strict;
use warnings;

use Acme::MilkyHolmes;
use Test::More;
use utf8;

subtest 'members - milkyholmes', sub {
    subtest 'en', sub {
        my @milkyholmes = Acme::MilkyHolmes->members( locale => 'en' );
        is( scalar(@milkyholmes), 4);
        is( $milkyholmes[0]->name, 'Sherlock Shellingford' );
        is( $milkyholmes[1]->name, 'Nero Yuzurizaki' );
        is( $milkyholmes[2]->name, 'Hercule Barton' );
        is( $milkyholmes[3]->name, 'Cordelia Glauca' );
    };
    subtest 'default - ja', sub {
        my @milkyholmes = Acme::MilkyHolmes->members();
        is( scalar(@milkyholmes), 4);
        is( $milkyholmes[0]->name, 'シャーロック・シェリンフォード' );
        is( $milkyholmes[1]->name, '譲崎 ネロ' );
        is( $milkyholmes[2]->name, 'エルキュール・バートン' );
        is( $milkyholmes[3]->name, 'コーデリア・グラウカ' );
    };
};

subtest 'members_of - milkyholmes', sub {
    subtest 'en', sub {
        my @milkyholmes = Acme::MilkyHolmes->members_of($Acme::MilkyHolmes::MilkyHolmes, locale => 'en' );
        is( scalar(@milkyholmes), 4);
        is( $milkyholmes[0]->name, 'Sherlock Shellingford' );
        is( $milkyholmes[1]->name, 'Nero Yuzurizaki' );
        is( $milkyholmes[2]->name, 'Hercule Barton' );
        is( $milkyholmes[3]->name, 'Cordelia Glauca' );
    };
    subtest 'default - ja', sub {
        my @milkyholmes = Acme::MilkyHolmes->members_of($Acme::MilkyHolmes::MilkyHolmes);
        is( scalar(@milkyholmes), 4);
        is( $milkyholmes[0]->name, 'シャーロック・シェリンフォード' );
        is( $milkyholmes[1]->name, '譲崎 ネロ' );
        is( $milkyholmes[2]->name, 'エルキュール・バートン' );
        is( $milkyholmes[3]->name, 'コーデリア・グラウカ' );
    };
};

subtest 'members_of - feathers', sub {
    subtest 'en', sub {
        my @members = Acme::MilkyHolmes->members_of($Acme::MilkyHolmes::MilkyHolmesFeathers, locale => 'en' );
        is( scalar(@members), 2);
        is( $members[0]->name, 'Kazumi Tokiwa' );
        is( $members[1]->name, 'Alice Myojingawa' );
    };
    subtest 'default - ja', sub {
        my @members = Acme::MilkyHolmes->members_of($Acme::MilkyHolmes::MilkyHolmesFeathers);
        is( scalar(@members), 2);
        is( $members[0]->name, '常盤 カズミ' );
        is( $members[1]->name, '明神川 アリス' );
    };
};

subtest 'members_of - milkyholmes sisters', sub {
    subtest 'en', sub {
        my @members = Acme::MilkyHolmes->members_of($Acme::MilkyHolmes::MilkyHolmesSisters, locale => 'en' );
        is( scalar(@members), 6);
        is( $members[0]->name, 'Sherlock Shellingford' );
        is( $members[1]->name, 'Nero Yuzurizaki' );
        is( $members[2]->name, 'Hercule Barton' );
        is( $members[3]->name, 'Cordelia Glauca' );
        is( $members[4]->name, 'Kazumi Tokiwa' );
        is( $members[5]->name, 'Alice Myojingawa' );
    };
    subtest 'default - ja', sub {
        my @members = Acme::MilkyHolmes->members_of($Acme::MilkyHolmes::MilkyHolmesSisters);
        is( scalar(@members), 6);
        is( $members[0]->name, 'シャーロック・シェリンフォード' );
        is( $members[1]->name, '譲崎 ネロ' );
        is( $members[2]->name, 'エルキュール・バートン' );
        is( $members[3]->name, 'コーデリア・グラウカ' );
        is( $members[4]->name, '常盤 カズミ' );
        is( $members[5]->name, '明神川 アリス' );
    };
};



subtest 'Sherlock', sub {
    subtest 'en', sub {
        my $sherlock = Acme::MilkyHolmes::Character::SherlockShellingford->new();
        $sherlock->locale('en');
        is( $sherlock->name,               'Sherlock Shellingford' );
        is( $sherlock->firstname,          'Sherlock' );
        is( $sherlock->familyname,         'Shellingford' );
        is( $sherlock->nickname,           'Sheryl' );
        is( $sherlock->birthday,           'March 31' );
        is( $sherlock->voiced_by,          'Suzuko Mimori' );
        is( $sherlock->nickname_voiced_by, 'mimorin' );
        is( $sherlock->toys,               'Psychokinesis' );
        is( $sherlock->color,              'pink' );
        ok( $sherlock->color_enable );
    };

    subtest 'ja', sub {
        my $sherlock = Acme::MilkyHolmes::Character::SherlockShellingford->new();
        is( $sherlock->locale,             'ja' );
        is( $sherlock->name,               'シャーロック・シェリンフォード' );
        is( $sherlock->firstname,          'シャーロック' );
        is( $sherlock->familyname,         'シェリンフォード' );
        is( $sherlock->nickname,           'シャロ' );
        is( $sherlock->birthday,           '3/31' );
        is( $sherlock->voiced_by,          '三森 すずこ' );
        is( $sherlock->nickname_voiced_by, 'みもりん' );
        is( $sherlock->toys,               'サイコキネシス' );
        is( $sherlock->color,              'pink' );
        ok( $sherlock->color_enable );
    };
};



subtest 'Nero', sub {
    subtest 'en', sub {
        my $nero = Acme::MilkyHolmes::Character::NeroYuzurizaki->new();
        $nero->locale('en');
        is( $nero->name,               'Nero Yuzurizaki' );
        is( $nero->firstname,          'Nero' );
        is( $nero->familyname,         'Yuzurizaki' );
        is( $nero->nickname,           'Nero' );
        is( $nero->birthday,           'August 28' );
        is( $nero->voiced_by,          'Sora Tokui' );
        is( $nero->nickname_voiced_by, 'soramaru' );
        is( $nero->toys,               'Direct Hack' );
        is( $nero->color,              'yellow' );
        ok( $nero->color_enable );
    };

    subtest 'ja', sub {
        my $nero = Acme::MilkyHolmes::Character::NeroYuzurizaki->new();
        is( $nero->locale,             'ja' );
        is( $nero->name,               '譲崎 ネロ' );
        is( $nero->firstname,          'ネロ' );
        is( $nero->familyname,         '譲崎' );
        is( $nero->nickname,           'ネロ' );
        is( $nero->birthday,           '8/28' );
        is( $nero->voiced_by,          '徳井 青空' );
        is( $nero->nickname_voiced_by, 'そらまる' );
        is( $nero->toys,               'ダイレクトハック' );
        is( $nero->color,              'yellow' );
        ok( $nero->color_enable );
    };
};


subtest 'Elly', sub {
    subtest 'en', sub {
        my $elly = Acme::MilkyHolmes::Character::HerculeBarton->new();
        $elly->locale('en');
        is( $elly->name,               'Hercule Barton' );
        is( $elly->firstname,          'Hercule' );
        is( $elly->familyname,         'Barton' );
        is( $elly->nickname,           'Elly' );
        is( $elly->birthday,           'October 21' );
        is( $elly->voiced_by,          'Mikoi Sasaki' );
        is( $elly->nickname_voiced_by, 'mikoron' );
        is( $elly->toys,               'Tri-Ascend' );
        is( $elly->color,              'green' );
        ok( $elly->color_enable );
    };

    subtest 'ja', sub {
        my $elly = Acme::MilkyHolmes::Character::HerculeBarton->new();
        is( $elly->locale,             'ja' );
        is( $elly->name,               'エルキュール・バートン' );
        is( $elly->firstname,          'エルキュール' );
        is( $elly->familyname,         'バートン' );
        is( $elly->nickname,           'エリー' );
        is( $elly->birthday,           '10/21' );
        is( $elly->voiced_by,          '佐々木 未来' );
        is( $elly->nickname_voiced_by, 'みころん' );
        is( $elly->toys,               'トライアセンド' );
        is( $elly->color,              'green' );
        ok( $elly->color_enable );
    };
};

subtest 'Cordelia', sub {
    subtest 'en', sub {
        my $cordelia = Acme::MilkyHolmes::Character::CordeliaGlauca->new();
        $cordelia->locale('en');
        is( $cordelia->name,               'Cordelia Glauca' );
        is( $cordelia->firstname,          'Cordelia' );
        is( $cordelia->familyname,         'Glauca' );
        is( $cordelia->nickname,           'Cordelia' );
        is( $cordelia->birthday,           'December 19' );
        is( $cordelia->voiced_by,          'Izumi Kitta' );
        is( $cordelia->nickname_voiced_by, 'izusama' );
        is( $cordelia->toys,               'Hyper Sensitive' );
        is( $cordelia->color,              'blue' );
        ok( $cordelia->color_enable );
    };

    subtest 'ja', sub {
        my $cordelia = Acme::MilkyHolmes::Character::CordeliaGlauca->new();
        is( $cordelia->locale,             'ja' );
        is( $cordelia->name,               'コーデリア・グラウカ' );
        is( $cordelia->firstname,          'コーデリア' );
        is( $cordelia->familyname,         'グラウカ' );
        is( $cordelia->nickname,           'コーデリア' );
        is( $cordelia->birthday,           '12/19' );
        is( $cordelia->voiced_by,          '橘田 いずみ' );
        is( $cordelia->nickname_voiced_by, 'いず様' );
        is( $cordelia->toys,               'ハイパーセンシティブ' );
        is( $cordelia->color,              'blue' );
        ok( $cordelia->color_enable );
    };
};

subtest 'Kazumi', sub {
    subtest 'en', sub {
        my $kazumi = Acme::MilkyHolmes::Character::KazumiTokiwa->new();
        $kazumi->locale('en');
        is( $kazumi->name,               'Kazumi Tokiwa' );
        is( $kazumi->firstname,          'Kazumi' );
        is( $kazumi->familyname,         'Tokiwa' );
        is( $kazumi->nickname,           'Kazumi' );
        is( $kazumi->birthday,           'November 20' );
        is( $kazumi->voiced_by,          'Aimi' );
        is( $kazumi->nickname_voiced_by, 'aimin' );
        is( $kazumi->toys,               'Arrow' );
        is( $kazumi->color,              'black' );
        ok( !$kazumi->color_enable ); # default disable
    };

    subtest 'ja', sub {
        my $kazumi = Acme::MilkyHolmes::Character::KazumiTokiwa->new();
        is( $kazumi->locale,             'ja' );
        is( $kazumi->name,               '常盤 カズミ' );
        is( $kazumi->firstname,          'カズミ' );
        is( $kazumi->familyname,         '常盤' );
        is( $kazumi->nickname,           'カズミ' );
        is( $kazumi->birthday,           '11/20' );
        is( $kazumi->voiced_by,          '愛美' );
        is( $kazumi->nickname_voiced_by, 'あいみん' );
        is( $kazumi->toys,               'アロー' );
        is( $kazumi->color,              'black' );
        ok( !$kazumi->color_enable ); # default disable
    };
};

subtest 'Alice', sub {
    subtest 'en', sub {
        my $alice = Acme::MilkyHolmes::Character::AliceMyojingawa->new();
        $alice->locale('en');
        is( $alice->name,               'Alice Myojingawa' );
        is( $alice->firstname,          'Alice' );
        is( $alice->familyname,         'Myojingawa' );
        is( $alice->nickname,           'Alice' );
        is( $alice->birthday,           'June 3' );
        is( $alice->voiced_by,          'Ayasa Itoh' );
        is( $alice->nickname_voiced_by, 'ayasa' );
        is( $alice->toys,               'Bound' );
        is( $alice->color,              'white' );
        ok( !$alice->color_enable ); # default disable
    };

    subtest 'ja', sub {
        my $alice = Acme::MilkyHolmes::Character::AliceMyojingawa->new();
        is( $alice->locale,             'ja' );
        is( $alice->name,               '明神川 アリス' );
        is( $alice->firstname,          'アリス' );
        is( $alice->familyname,         '明神川' );
        is( $alice->nickname,           'アリス' );
        is( $alice->birthday,           '6/3' );
        is( $alice->voiced_by,          '伊藤 彩沙' );
        is( $alice->nickname_voiced_by, '彩沙' );
        is( $alice->toys,               'バウンド' );
        is( $alice->color,              'white' );
        ok( !$alice->color_enable ); # default disable
    };
};


done_testing;
