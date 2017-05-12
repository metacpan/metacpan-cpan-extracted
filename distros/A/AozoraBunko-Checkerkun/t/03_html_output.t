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
    'zentilde'         => 0, # 全角チルダをチェックする
    '78hosetsu_tekiyo' => 0, # 78互換包摂の対象となる不要な外字注記をチェックする
    'hosetsu_tekiyo'   => 0, # 包摂の対象となる不要な外字注記をチェックする
    '78'               => 0, # 78互換包摂29字をチェックする
    'jyogai'           => 0, # 新JIS漢字で包摂規準の適用除外となる104字をチェックする
    'gonin1'           => 0, # 誤認しやすい文字をチェックする(1)
    'gonin2'           => 0, # 誤認しやすい文字をチェックする(2)
    'gonin3'           => 0, # 誤認しやすい文字をチェックする(3)
    'simplesp'         => 0, # 半角スペースは「_」で、全角スペースは「□」で出力する
    'kouetsukun'       => 0, # 旧字体置換可能チェッカー「校閲君」を有効にする
    'output_format'    => 'html', # 'plaintext' または 'html'
);

subtest 'no options' => sub {
    my $text = "\x{0000}\r\nｴ AB　Ｃ" x 2;
    my $checker1 = AozoraBunko::Checkerkun->new(\%option);
    is($checker1->check($text), qq|<span data-checkerkun-tag="ctrl" data-checkerkun-message="U+0000">\x{0000}</span>\r\n<span data-checkerkun-tag="hankata" data-checkerkun-message="半角カタカナ">ｴ</span> AB　Ｃ| x 2);
};

subtest 'gaiji' => sub {
    my %opts = %option;

    my $text = '森鷗外' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'gaiji'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '森<span data-checkerkun-tag="gaiji" data-checkerkun-message="JIS外字">鷗</span>外' x 2);
};

subtest 'hansp' => sub {
    my %opts = %option;

    my $text = '太宰 治' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'hansp'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太宰<span data-checkerkun-tag="hansp" data-checkerkun-message="半角スペース"> </span>治' x 2);
};

subtest 'hanpar' => sub {
    my %opts = %option;

    my $text = '太)宰治(' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'hanpar'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太<span data-checkerkun-tag="hanpar" data-checkerkun-message="半角括弧">)</span>宰治<span data-checkerkun-tag="hanpar" data-checkerkun-message="半角括弧">(</span>' x 2);
};

subtest 'zensp' => sub {
    my %opts = %option;

    my $text = '太宰　治' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'zensp'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太宰<span data-checkerkun-tag="zensp" data-checkerkun-message="全角スペース">　</span>治' x 2);
};

subtest 'zentilde' => sub {
    my %opts = %option;

    my $text = '二次元～三次元' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'zentilde'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '二次元<span data-checkerkun-tag="zentilde" data-checkerkun-message="全角チルダ">～</span>三次元' x 2);
};

subtest '78hosetsu_tekiyo' => sub {
    my %opts = %option;

    my $text = '※［＃「區＋鳥」、第3水準1-94-69］外' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'78hosetsu_tekiyo'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '<span data-checkerkun-tag="78hosetsuTekiyo" data-checkerkun-message="鴎">※［＃「區＋鳥」、第3水準1-94-69］</span>外' x 2);
};

subtest 'hosetsu_tekiyo' => sub {
    my %opts = %option;

    my $text = '※［＃「漑－さんずい」、第3水準1-85-11］' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'hosetsu_tekiyo'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '<span data-checkerkun-tag="hosetsuTekiyo" data-checkerkun-message="既">※［＃「漑－さんずい」、第3水準1-85-11］</span>' x 2);
};

subtest 'j78' => sub {
    my %opts = %option;

    my $text = '唖然' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'78'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '<span data-checkerkun-tag="78" data-checkerkun-message="第三水準1-15-8に">唖</span>然' x 2);
};

subtest 'jyogai' => sub {
    my %opts = %option;

    my $text = '戻戾' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'jyogai'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '<span data-checkerkun-tag="jyogai" data-checkerkun-message="新JIS漢字で包摂規準の適用除外となる">戻</span>戾' x 2);
};

subtest 'gonin1' => sub {
    my %opts = %option;

    my $text = '目白' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'gonin1'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '<span data-checkerkun-tag="gonin1" data-checkerkun-message="中にあるのは横棒二本">目</span><span data-checkerkun-tag="gonin1" data-checkerkun-message="中にあるのは横棒一本">白</span>' x 2);
};

subtest 'gonin2' => sub {
    my %opts = %option;

    my $text = '沖縄の冲方丁' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'gonin2'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '<span data-checkerkun-tag="gonin2" data-checkerkun-message="さんずい">沖</span>縄の<span data-checkerkun-tag="gonin2" data-checkerkun-message="にすい">冲</span>方丁' x 2);
};

subtest 'gonin3' => sub {
    my %opts = %option;

    my $text = '桂さんが柱壊した' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'gonin3'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '<span data-checkerkun-tag="gonin3" data-checkerkun-message="かつら">桂</span>さんが<span data-checkerkun-tag="gonin3" data-checkerkun-message="はしら">柱</span>壊した' x 2);
};

subtest 'simplesp' => sub {
    my %opts = %option;

    my $text = '太宰 治　の小説' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'simplesp'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太宰<span data-checkerkun-tag="simplesp">_</span>治<span data-checkerkun-tag="simplesp">□</span>の小説' x 2);
};

subtest 'simplesp, hansp & zensp' => sub {
    my %opts = %option;

    my $text = '太宰 治　の小説' x 2;

    $opts{'simplesp'} = 1;
    $opts{'hansp'}    = 1;
    $opts{'zensp'}    = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太宰<span data-checkerkun-tag="simplesp">_</span>治<span data-checkerkun-tag="simplesp">□</span>の小説' x 2);
};

subtest 'gaiji, 78hosetsu_tekiyo & hosetsu_tekiyo' => sub {
    my %opts = %option;

    my $text = '鷗※［＃「區＋鳥」、第3水準1-94-69］既※［＃「漑－さんずい」、第3水準1-85-11］' x 1000;

    $opts{'gaiji'}            = 1;
    $opts{'78hosetsu_tekiyo'} = 1;
    $opts{'hosetsu_tekiyo'}   = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '<span data-checkerkun-tag="gaiji" data-checkerkun-message="JIS外字">鷗</span><span data-checkerkun-tag="78hosetsuTekiyo" data-checkerkun-message="鴎">※［＃「區＋鳥」、第3水準1-94-69］</span><span data-checkerkun-tag="gaiji" data-checkerkun-message="JIS外字">既</span><span data-checkerkun-tag="hosetsuTekiyo" data-checkerkun-message="既">※［＃「漑－さんずい」、第3水準1-85-11］</span>' x 1000);
};

done_testing;
