use strict;
use warnings;
use utf8;
use AozoraBunko::Checkerkun;
use Test::More;
binmode Test::More->builder->$_ => ':utf8' for qw/output failure_output todo_output/;

my %option = (
    'gaiji'            => 0, # JIS外字をチェックする
    'hansp'            => 0, # 半角スペースをチェックする
    'hanpar'           => 0, # 半角カッコをチェックする
    'zensp'            => 0, # 全角スペースをチェックする
    '78hosetsu_tekiyo' => 0, # 78互換包摂の対象となる不要な外字注記をチェックする
    'hosetsu_tekiyo'   => 0, # 包摂の対象となる不要な外字注記をチェックする
    '78'               => 0, # 78互換包摂29字をチェックする
    'jyogai'           => 0, # 新JIS漢字で包摂規準の適用除外となる104字をチェックする
    'gonin1'           => 0, # 誤認しやすい文字をチェックする(1)
    'gonin2'           => 0, # 誤認しやすい文字をチェックする(2)
    'gonin3'           => 0, # 誤認しやすい文字をチェックする(3)
    'simplesp'         => 0, # 半角スペースは「_」で、全角スペースは「□」で出力する
    'kouetsukun'       => 1, # 旧字体置換可能チェッカー「校閲君」を有効にする
    'output_format'    => 'plaintext', # 'plaintext' または 'html'
);

subtest 'plaintext output' => sub {
    my $text = "\x{0000}\r\nｴ A繊瑶薮B　Ｃ" x 2;
    my $checker1 = AozoraBunko::Checkerkun->new(\%option);
    is($checker1->check($text), "\x{0000}[ctrl]（U+0000）\r\nｴ[hankata] A▼繊纖纎▲▼瑶瑤▲▼薮藪籔▲B　Ｃ" x 2);
};

subtest 'html output' => sub {
    my %opts = %option;
    $opts{'output_format'} = 'html';

    my $text = "\x{0000}\r\nｴ A繊瑶薮B　Ｃ" x 2;
    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), qq|<span data-checkerkun-tag="ctrl" data-checkerkun-message="U+0000">\x{0000}</span>\r\n<span data-checkerkun-tag="hankata" data-checkerkun-message="半角カタカナ">ｴ</span> A<span data-checkerkun-tag="kyuji" data-checkerkun-message="纖纎">繊</span><span data-checkerkun-tag="kyuji" data-checkerkun-message="瑤">瑶</span><span data-checkerkun-tag="itaiji" data-checkerkun-message="藪籔">薮</span>B　Ｃ| x 2);
};

done_testing;
