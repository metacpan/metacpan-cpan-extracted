use strict;
use warnings;
use utf8;
use AozoraBunko::Checkerkun;
use Encode qw//;
use Test::More;
use Test::Fatal;
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
    'output_format'    => 'plaintext', # 'plaintext' または 'html'
);

subtest 'no options' => sub {
    my $text = "\x{0000}\r\nｴ AB　Ｃ" x 2;
    my $checker1 = AozoraBunko::Checkerkun->new(\%option);
    is($checker1->check($text), "\x{0000}[ctrl]（U+0000）\r\nｴ[hankata] AB　Ｃ" x 2);
};

subtest 'gaiji' => sub {
    my %opts = %option;

    my $text = '森鷗外' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'gaiji'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '森鷗[gaiji]外' x 2);
};

subtest 'hansp' => sub {
    my %opts = %option;

    my $text = '太宰 治' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'hansp'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太宰 [hansp]治' x 2);
};

subtest 'hanpar' => sub {
    my %opts = %option;

    my $text = '太)宰治(' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'hanpar'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太)[hanpar]宰治([hanpar]' x 2);
};

subtest 'zensp' => sub {
    my %opts = %option;

    my $text = '太宰　治' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'zensp'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太宰　[zensp]治' x 2);
};

subtest 'zentilde' => sub {
    my %opts = %option;

    my $text = '二次元～三次元' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'zentilde'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '二次元～[zentilde]三次元' x 2);
};

subtest '78hosetsu_tekiyo' => sub {
    my %opts = %option;

    my $text = '※［＃「區＋鳥」、第3水準1-94-69］外' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'78hosetsu_tekiyo'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '※［＃「區＋鳥」、第3水準1-94-69］→[78hosetsu_tekiyo]【鴎】外' x 2);
};

subtest 'hosetsu_tekiyo' => sub {
    my %opts = %option;

    my $text = '※［＃「漑－さんずい」、第3水準1-85-11］' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'hosetsu_tekiyo'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '※［＃「漑－さんずい」、第3水準1-85-11］→[hosetsu_tekiyo]【既】' x 2);
};

subtest 'j78' => sub {
    my %opts = %option;

    my $text = '唖然' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'78'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '唖[78]（第三水準1-15-8に）然' x 2);
};

subtest 'jyogai' => sub {
    my %opts = %option;

    my $text = '戻戾' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'jyogai'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '戻[jyogai]戾' x 2);
};

subtest 'gonin1' => sub {
    my %opts = %option;

    my $text = '目白' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'gonin1'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '目[gonin1]（中にあるのは横棒二本）白[gonin1]（中にあるのは横棒一本）' x 2);
};

subtest 'gonin2' => sub {
    my %opts = %option;

    my $text = '沖縄の冲方丁' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'gonin2'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '沖[gonin2]（さんずい）縄の冲[gonin2]（にすい）方丁' x 2);
};

subtest 'gonin3' => sub {
    my %opts = %option;

    my $text = '桂さんが柱壊した' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'gonin3'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '桂[gonin3]（かつら）さんが柱[gonin3]（はしら）壊した' x 2);
};

subtest 'simplesp' => sub {
    my %opts = %option;

    my $text = '太宰 治　の小説' x 2;

    my $checker1 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker1->check($text), $text);

    $opts{'simplesp'} = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太宰_治□の小説' x 2);
};

subtest 'simplesp, hansp & zensp' => sub {
    my %opts = %option;

    my $text = '太宰 治　の小説' x 2;

    $opts{'simplesp'} = 1;
    $opts{'hansp'}    = 1;
    $opts{'zensp'}    = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '太宰_治□の小説' x 2);
};

subtest 'gaiji, 78hosetsu_tekiyo & hosetsu_tekiyo' => sub {
    my %opts = %option;

    my $text = '鷗※［＃「區＋鳥」、第3水準1-94-69］既※［＃「漑－さんずい」、第3水準1-85-11］' x 1000;

    $opts{'gaiji'}            = 1;
    $opts{'78hosetsu_tekiyo'} = 1;
    $opts{'hosetsu_tekiyo'}   = 1;

    my $checker2 = AozoraBunko::Checkerkun->new(\%opts);
    is($checker2->check($text), '鷗[gaiji]※［＃「區＋鳥」、第3水準1-94-69］→[78hosetsu_tekiyo]【鴎】既[gaiji]※［＃「漑－さんずい」、第3水準1-85-11］→[hosetsu_tekiyo]【既】' x 1000);
};

subtest 'hash size' => sub {
    is(scalar keys %{$AozoraBunko::Checkerkun::KUTENMEN_78HOSETSU_TEKIYO}, 29);
    is(scalar keys %{$AozoraBunko::Checkerkun::KUTENMEN_HOSETSU_TEKIYO},   104);
    is(scalar keys %{$AozoraBunko::Checkerkun::JYOGAI},                    104);
    is(scalar keys %{$AozoraBunko::Checkerkun::J78},                       29);
};

subtest 'hiden_no_tare has no gaiji' => sub {
    my @key_list = (
        keys %{$AozoraBunko::Checkerkun::KUTENMEN_78HOSETSU_TEKIYO}
      , keys %{$AozoraBunko::Checkerkun::KUTENMEN_78HOSETSU_TEKIYO}
      , keys %{$AozoraBunko::Checkerkun::JYOGAI}
      , keys %{$AozoraBunko::Checkerkun::J78}
      , keys %{$AozoraBunko::Checkerkun::GONIN1}
      , keys %{$AozoraBunko::Checkerkun::GONIN2}
      , keys %{$AozoraBunko::Checkerkun::GONIN3}
      , keys %{$AozoraBunko::Checkerkun::KYUJI}
      , keys %{$AozoraBunko::Checkerkun::ITAIJI}
    );

    my @value_list = (
          values %{$AozoraBunko::Checkerkun::KUTENMEN_78HOSETSU_TEKIYO}
        , values %{$AozoraBunko::Checkerkun::KUTENMEN_78HOSETSU_TEKIYO}
        , values %{$AozoraBunko::Checkerkun::JYOGAI}
        , values %{$AozoraBunko::Checkerkun::J78}
        , values %{$AozoraBunko::Checkerkun::GONIN1}
        , values %{$AozoraBunko::Checkerkun::GONIN2}
        , values %{$AozoraBunko::Checkerkun::GONIN3}
        , values %{$AozoraBunko::Checkerkun::KYUJI}
        , values %{$AozoraBunko::Checkerkun::ITAIJI}
    );

    my $enc = Encode::find_encoding("Shift_JIS");

    my $exception;

    $exception = exception { $enc->encode(join('', @key_list), Encode::FB_CROAK) };
    is($exception, undef, 'keys have no gaiji');

    $exception = exception { $enc->encode(join('', @value_list), Encode::FB_CROAK) };
    is($exception, undef, 'values have no gaiji');
};

done_testing;
