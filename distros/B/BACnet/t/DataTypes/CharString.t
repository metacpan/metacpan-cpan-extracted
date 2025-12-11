#!/usr/bin/perl


use strict;
use warnings;

use Test2::V0;
use Data::Dumper;

use utf8;

use lib './t';

use Utils;

use BACnet::DataTypes::CharString;

subtest "Context" => sub {
    Utils::construct_self_parse_test_char_string(
        class          => 'BACnet::DataTypes::CharString',
        coding_type    => 'UTF-32',
        char_string    => 'root',
        modified_tag   => 20,
        debug_prints   => 0,
        expected_value => 'root',
    );
};

subtest "Cz lang" => sub {
    Utils::construct_self_parse_test_char_string(
        class          => 'BACnet::DataTypes::CharString',
        coding_type    => 'UTF-32',
        char_string    => "Břehy řeky čeřil běsný svyšť.",
        expected_value => 'Břehy řeky čeřil běsný svyšť.',
    );
};

my @english_texts = (
"When I woke up this morning, the rain was falling softly against the window, and I felt like staying in bed a little longer.",
"After finishing my work, I went for a long walk along the river to clear my head and enjoy the cool evening air.",
"Learning a new programming language can be challenging at first, but it becomes easier once you start building real projects.",
"I met an old friend at the cafe yesterday, and we talked for hours about our lives and how much things have changed.",
"Although it was already late, she decided to continue studying because the exam was very important to her.",
"When I travel to another country, I always try to learn a few local phrases to communicate politely with people.",
"The city lights reflected beautifully on the water, creating a scene that looked almost like a painting.",
"He promised that no matter how difficult things became, he would never give up on his dream.",
"On weekends, I like to cook something new and listen to music while enjoying a quiet evening at home.",
"Even though we live far apart now, we still stay in touch through messages and occasional video calls. Even though we live far apart now, we still stay in touch through messages and occasional video calls. Even though we live far apart now, we still stay in touch through messages and occasional video calls. Even though we live far apart now, we still stay in touch through messages and occasional video calls."
);

my @japanese_texts = (
    "今朝目が覚めたとき、窓の外では静かに雨が降っていて、もう少しベッドにいたい気分でした。",
    "仕事を終えた後、頭をすっきりさせるために川沿いを長い散歩に出かけ、涼しい夕方の空気を楽しみました。",
    "新しいプログラミング言語を学ぶのは最初は難しいかもしれませんが、実際にプロジェクトを作り始めるとどんどん簡単になります。",
    "昨日カフェで昔の友人に会い、私たちは人生のことや変わってしまったことについて何時間も話しました。",
    "もう遅い時間でしたが、彼女は試験がとても大事だったので勉強を続けることにしました。",
    "外国へ旅行するときは、いつも現地の人と丁寧に話すためにいくつかの現地語のフレーズを覚えるようにしています。",
    "街の明かりが水面に美しく反射して、まるで絵画のような光景を作り出していました。",
    "どんなに困難な状況になっても、彼は自分の夢をあきらめないと約束しました。",
    "週末には新しい料理を作り、音楽を聴きながら家で静かな夜を楽しむのが好きです。",
"今では遠くに住んでいますが、私たちはメッセージや時々のビデオ通話で連絡を取り合っています。今では遠くに住んでいますが、私たちはメッセージや時々のビデオ通話で連絡を取り合っています。今では遠くに住んでいますが、私たちはメッセージや時々のビデオ通話で連絡を取り合っています。今では遠くに住んでいますが、私たちはメッセージや時々のビデオ通話で連絡を取り合っています。"
);

subtest 'All coding types except jis0208-raw' => sub {
    for my $code_type ( sort keys %{$BACnet::DataTypes::CharString::codes} ) {

        if ( $code_type eq 'jis0208-raw' ) {
            next;
        }

        for my $text (@english_texts) {
            subtest $code_type => sub {
                Utils::construct_self_parse_test_char_string(
                    class          => 'BACnet::DataTypes::CharString',
                    coding_type    => $code_type,
                    char_string    => $text,
                    expected_value => $text,
                );
            };
        }
    }
};

for my $text (@japanese_texts) {
    subtest "jis0208-raw" => sub {
        Utils::construct_self_parse_test_char_string(
            class          => 'BACnet::DataTypes::CharString',
            coding_type    => "jis0208-raw",
            char_string    => $text,
            expected_value => $text,
        );
    };
}

done_testing;
