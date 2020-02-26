#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;

use utf8;
use open IO => 'utf8', ':std';

use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}

use Pod::Usage;
use Getopt::Long;
Getopt::Long::Configure("bundling");
GetOptions(
    my $opt = {
	minimum   => 3,
	reorder   => 1,
	category  => 1,
	monomania => 0,
	skipfixed => 0,
	ignore    => { map {$_ => 1} qw(ウエア デスク リコーダー リポート) },
    },
    "debug!",
    "minimum=i",
    "reorder!",
    "category!",
    "monomania!",
    "skipfixed!",
    "ignore=s%",
    ) || usage({status => 1});

my %functable = (

    '1-1'  => sub {
	s/[エケゲセゼテデネヘベペメレヱ]\Kー$/[イィー]/;
	s/ー$/ー?/;
	$_;
    },
    '1-1x' => sub {
	# 何をしたいのか不明
	$_;
    },
    '1-2'  => sub {
	s/[エェケゲセゼテデネヘベペメレヱ]\K[イィー]/[イィー]/g;
	s/[オォコゴソゾトドノホボポモロヲ]\Kー/[ウゥー]/g if $opt->{monomania};
	$_;
    },
    '1-2x' => sub {
	s/[エェケゲセゼテデネヘベペメレヱ]\Kイ/[イィー]/g;
	s/[オォコゴソゾトドノホボポモロヲ]\Kウ/[ウゥー]/g;
	$_;
    },
    '1-3'  => sub {
	s/ー$/ー?/ or s/(?<=[アァカガサザタダナハバパマヤャラワ])$/ー?/;
	$_;
    },
    '1-3x' => sub {
	s/ワイヤ\K(?!ー)/ー?/ or
	s/ー$/ー?/ or
	s/$/ー?/;
	$_;
    },
    '1-4'  => sub {
	s/[アァカガサザタダナハバパマヤャラワ]\Kー(?!\?)/[アー]/g if $opt->{monomania};
	$_;
    },
    '2-1'  => sub {
	s/ウ[イィ]/ウ[イィ]/;
	s/ウ[エェ]/ウ[エェ]/;
	s/ウ[オォ]/ウ[オォ]/;
	$_;
    },
    '2-1x' => '2-1',
    '2-2'  => sub {
	s/ク[アァ]/ク[アァ]/;
	s/ク[イィ]/ク[イィ]/;
	s/ク[エェ]/ク[エェ]/;
	s/ク[オォ]/ク[オォ]/;
	$_;
    },
    '2-2x' => '2-2',
    '2-3'  => sub {
	s/フ[アァ]/フ[アァ]/ if $opt->{monomania};
	s/フ[イィ]/フ[イィ]/ if $opt->{monomania};
	s/フ[エェ]/フ[エェ]/ if $opt->{monomania};
	$_;
    },
    '2-3x' => '2-3',
    '2-4'  => sub {
	s/フォ/(?:フォ|ホ)/ if $opt->{monomania};
	$_;
    },
    '2-4x' => sub {
	s/ホ/(?:フォ|ホ)/;
	$_;
    },
    '3' => sub {
	s/バ/(?:バ|ヴァ)/g;
	s/ビ(?![ユュ])/(?:ビ|ヴィ)/g;
	s/ビュ/(?:ビ[ユュ]|ヴュ)/g;
	s/ブ/(?:ブ|ヴ)/g;
	s/ベ/(?:ベ|ヴェ)/g;
	s/ボ/(?:ボ|ヴォ)/g;
	$_;
    },
    '4-1' => sub {
	s/チ/(?:チ|ティ)/g;
	$_;
    },
    '4-1x' => sub {
	s/ティ/(?:チ|ティ)/g;
	$_;
    },
    '4-2' => sub {
	s/ディ/(?:ディ|ヂ)/g if $opt->{monomania};
	$_;
    },
    '4-2x' => sub {
	s/デ(?!ィ)/ディ?/g;
	s/ジ(?![ャュェョ])/(?:[ジヂ]|ディ)/g;
	s/ダイ/(?:ダ[イィ]|ディ)/g if $opt->{monomania};
	$_;
    },
    '4-3' => sub {
	s/デ(?!ィ)/ディ?/g;
	$_;
    },
    '5' => sub {
	s/[イィキギシジチヂニヒビピミリ]\K[アヤ]/[アヤ]/g;
	$_;
    },
    '5x' => '5',
    '6'  => sub {
	s/^プ?\K[リレ]/[リレ]/g;
	$_;
    },
    '6x' => '6',
    );

while (my($k, $v) = each %functable) {
    if (ref($v) ne 'CODE') {
	$functable{$k} = $functable{$v} or die;
    }
}

use Text::VisualPrintf qw(vprintf vsprintf);
use Text::VisualWidth::PP qw(vwidth);
use List::Util qw(max);

my @data;
my %maxlen = map { $_ => 0 } qw(pattern kana category);
while (<DATA>) {

    if (/^\s*#/) {
	print;
	next;
    }

    chomp;
    tr[－０-９、][-0-9,];
    s/例外/x/g;

    m{
	^
	  (?<kana>\w+) (?<exp>[\[（]\S*?[\]）])?
	\s+
	  (?<orig>\S+(\s+\S+)*)
	\s+
	  (?<category>\S+)
	  \s*
	$
    }x or do {
	warn "ignore: \"$_\"\n";
	next;
    };
    local %_ = ( '_' => $_, %+ );
    next if length($_{kana} =~ s/ー$//r) < $opt->{minimum};

    $_{categories} = [ split /,/, $_{category} ];
    $_{pattern} = $_{kana};
    for my $cat (@{$_{categories}}) {
	my $func = $functable{$cat} or next;
	$func->() for $_{pattern};
    }

    $_{fixed} = $_{kana} eq $_{pattern};
    $_{ignore} = 1 if $opt->{ignore}->{$_{kana}};
    $_{regex} = qr/$_{pattern}/;

    for (qw(category pattern kana)) {
	$maxlen{$_} = max($maxlen{$_}, vwidth $_{$_});
    }

    # sanity check
    if ($_{kana} !~ /^$_{regex}$/) {
	warn sprintf "\"%s\" !~ /^%s\$/\n", $_{kana}, $_{pattern};
    }

#   push @data, \%_; # just in case.
    push @data, { %_ };
}

if ($opt->{reorder}) {
    use List::Util qw(first);
    for my $i (1 .. $#data) {
	my $match =
	    first { $data[$i]->{kana} =~ $data[$_]->{regex} } 0 .. $i - 1
	    or next;
	splice @data, $match, 0 => splice @data, $i, 1;
    }
}

for my $data (@data) {
    if ($opt->{skipfixed} and $data->{fixed}) {
	print "##";
    }
    elsif ($data->{ignore}) {
	print "# ";
    } else {
	print "  ";
    }

    if ($opt->{category}) {
	vprintf "%-*s ", $maxlen{category}, $data->{category};
    }
    vprintf "%-*s %s\n",
	$maxlen{pattern}, $data->{pattern},
	$data->{kana},
	;
}

__DATA__
#
# greple -Msubst モジュール用辞書ファイル
# https://github.com/kaz-utashiro/greple-subst
#
# 外来語（カタカナ）表記ガイドライン 第3版
# 制定：2015年8月
# 発行：2015年9月
# 一般財団法人テクニカルコミュニケーター協会 
# https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf
#
アイデア idea ４－３
アイデンティティー identity １－１、４－１例外、４－３
アクション action ４－１
アクセサリー accessory １－１
アクセシビリティー accessibility １－１
アコーディオン accordion １－４、４－２
アジャスター adjuster １－１
アセンブラー assembler １－１
アダプター adapter １－１
アップグレード upgrade １－２、４－３例外
アップデーター updater １－２
アップロード upload １－２
アドバイザー adviser １－１、３
アドバイス advice ３
アドベンチャー adventure １－３、３
アニメーション animation １－２、４－１
アフター after １－１
アブソーバー absorber １－１、１－４
アプリケーション application １－２、４－１
アベレージ average １－２、３
アライアンス alliance ５
アラビア Arabia ５
アラート alert １－４
アラーム alarm １－４
アルジェリア Algeria ５
アルゼンチン Argentina ４－１
アルファ alpha ２－３
アルファベット alphabet ２－３
アンカー anchor １－１
アンサー answer １－１
アンダーバー under bar（和製英語） １－１、４－３例外
アンチ anti ４－１
アンティーク antique ４－１例外
アンペア ampere １－２例外、１－３
アンモニア ammonia ５
アーキテクチャー architecture １－３、１－４
アーキテクト architect １－４
アーケード arcade １－４、４－３例外
アート art １－４
イエロー yellow １－２
イデオロギー ideology /ideologie [ドイツ語] ４－３
イニシアチブ initiative ３、４－１、５
イベント event ３
イミテーション imitation １－２、４－１
イメージ image １－４例外 
イヤホン earphone ２－４例外
イラスト illustration １－２、４－１
イラストレーション illustration １－２、４－１
イラストレーター illustrator １－１、１－２
イレーサー eraser １－１
インジケーター indicator １－１、１－２、１－３、４－２例外
インストラクター instructor １－１
インストーラー installer １－１、１－４
インストール install １－４
インタビュー interview ３
インタラクション interaction ４－１
インタラクティブ interactive ３、４－１例外
インターネット internet １－４
インターフェイス interface １－２例外、１－４、２－３
インターホン interphone １－４、２－４例外
インデックス index ４－３
インデント indent ４－３
インフォメーション information １－２、１－３、２－４、４－１
インフラストラクチャー infrastructure １－３
ウィザード wizard １－４、２－１例外
ウイスキー whiskey １－１、２－１
ウイット wit ２－１
ウインドウ window １－２、２－１
ウェア ware １－３、２－１
ウェイト weight １－２例外、２－１例外
ウェブ web ２－１例外
ウェールズ Wales １－２、１－４、２－１例外
ウエア wear １－１例外、２－１
ウエアラブル wearable ２－１
ウエディング wedding ２－１、４－２例外
ウオッチ watch ２－１
ウオーター water １－１、２－１
ウオーターフォール waterfall ２－１例外
ウオーム warm ２－１例外
エイリアス alias ５
エクスクラメーション exclamation １－２、４－１
エクスプローラー explorer １－１
エスカレーター escalator １－１、１－２
エチケット etiquette ４－１
エディター editor １－１、４－２
エディット edit ４－２
エネルギー energy １－１
エフェクト effect ２－３
エラー error １－１
エレベーター elevator １－１、１－２、３
エンコーディング encoding １－２、４－２
エンコード encode １－２、４－３例外
エンジニア engineer １－１例外
エントリー entry １－１ 
オフィス office ２－３
オプション option ４－１
オペレーション operation １－２、４－１
オペレーター operator １－１、１－２
オペレーティング operating １－２、４－１例外
オリエンテーション orientation １－２、４－１
オーディオ audio １－２、４－２
オーディション audition ４－１、４－２
オートマチック automatic ４－１
オーナー owner １－１、１－２
オーナーズ owner's １－２
オーバー over １－１、１－２、３
オーバーコート overcoat １－２、３
オーバーセット overset １－２、３
オーバープリント overprint １－２、３
オープン open １－２
カウンター counter １－１
カスタマー customer １－１
カテゴリー category １－１
カバー cover １－１、３
カフェテリア cafeteria ２－３、５
カプラー coupler １－１
カラー color １－１
カルチャー culture １－３
カレンダー calendar １－１
カンデラ candela ４－３
カーソル cursor １－１例外、１－４
カーテン curtain １－４
カーディガン cardigan １－４、４－２
カード card １－４
カーニング kerning １－４
カーブ curve １－４、３
ガイド guide ４－３例外
ガイドブック guidebook ４－３例外
ガイドライン guideline ４－３例外
キャッチフレーズ catchphrase １－２
キャプション caption ４－１
キャプチャー capture １－３
キャラクター character １－１
キャラバン caravan ３
キャリブレーション calibration １－２、４－１
キー key １－１
キーフレーム keyframe １－４
キーボード keyboard １－４
キーワード keyword １－４
ギア gear １－１例外
クァルテット quartet ２－２例外
クアトロ cuatro（スペイン語） ２－２
クアハウス kurhaus（ドイツ語） ２－２ 
クィンテット quintet ２－２例外
クィーン queen １－４、２－２例外
クイック quick ２－２
クエスチョン question ２－２、４－１例外
クォーク quark ２－２例外
クオリティー quality １－１、２－２
クオータリー quarterly １－１、２－２例外
クオーツ quarts １－４、２－２
クリエイター creator １－１、１－２
クリエーティブ creative １－２、３、４－１例外
クリーナー cleaner １－１、１－４
クリーニング cleaning １－４
クーラー cooler １－１、１－４
グラタン gratin ４－１
グラデーション gradation ４－１
グラビア gravure １－３、３
グラフィカル graphical ２－３
グラフィック graphic ２－３
グラフィックス graphics ２－３
グルーピング grouping １－４
グループ group １－４
グループウェア groupware １－３、１－４、２－１
グレー gray １－１
グレースケール grayscale １－２
グローバリゼーション globalization １－２、４－１
グローバル global １－２
ケア care １－３
ケルビン kelvin ３
ケーキ cake １－２
ケース case １－２
ケーブル cable １－２
ゲージ gauge １－２
ゲートウェイ gateway １－１例外、１－２、２－１例外
コア core １－３
コネクター connector １－１
コピー copy １－１
コピーライティング copywriting １－４、４－１例外
コピーライト copyright １－４
コミュニケーション communication １－２、４－１
コミュニティー community １－１
コモディティー commodity １－１、４－２
コロンビア Columbia ５
コンサバティブ conservative ３、４－１例外
コンシューマー consumer １－１、１－４
コンソーシアム consortium １－４、４－１
コンダクター conductor １－１
コンディショナル conditional ４－１、４－２
コンディション condition ４－１、４－２
コンデンサー condenser １－１、４－３ 
コントローラー controller １－１、１－２
コントロール control １－２
コンバーター converter １－１、１－４、３
コンバート convert １－４、３
コンパイラー compiler １－１
コンピューター computer １－１、１－４
コンピューティング computing １－４、４－１例外
コンプライアンス compliance ５
コンポーネント component １－２
コーディネーター coordinator １－１、１－２、１－４、４－２
コーディネート coordinate １－４、４－２
コーディング coding １－２、４－２
コーディングレス coding less １－２、４－２
コード code １－２、４－３例外
コーナー corner １－１、１－４
コーポレーション corporation １－４、４－１
コーポレート corporate １－１、１－４
ゴー go １－４
ゴール goal １－４
ゴールデン golden １－４、４－３
サイド side ４－３例外
サディスト sadist ４－２
サファイア sapphire １－３、２－３
サブカラー sub‐color １－１
サブフォルダー subfolder １－１、２－４、４－３例外
サブルーチン subroutine １－４、４－１
サプライ supply １－１例外
サポート support １－４
サマリー summary １－１
サムネール thumbnail １－２
サーチ search １－４
サーディン sardine １－４、４－２
サード third １－４
サーバー server １－１、１－４、３
サービス service １－４、３
サーベイ survey １－１例外、１－４、３
シェア share １－３
シェアウェア shareware １－２例外、１－３、２－１
シェイプ shape １－２
シェーカー shaker １－１、１－２
シェード shade １－２、４－３例外
シグネチャー signature １－３
シチュエーション situation １－２、４－１
シナリオ scenario １－２例外
シビア severe １－３、３
シミュレーション simulation １－２、４－１
シミュレーター simulator １－１、１－２
シャッター shutter １－１
シャドウ shadow １－２例外 
シャープネス sharpness １－４
シリアル serial ５
シリンダー cylinder １－１、４－３例外
シリーズ series １－４
シルバー silver １－１、３
シングル single １－１
シンナー thinner １－１
シンメトリー symmetry １－１
シークレット secret １－４
シート sheet １－４
シール seal １－４
シーン scene １－４
ジェスチャー gesture １－３
ジェネレーター generator １－１、１－２
ジフテリア diphtheria ４－２例外、５
ジャギー jaggy １－１
ジャンル genre １－３
ジャーナル journal １－４
ジュース juice １－４
ジョッキー jockey １－１
ジレンマ dilemma ４－２例外
スキャナー scanner １－１
スキーマ schema １－４
スクエア square １－３、２－２
スクロール scroll １－４
スクール school １－４
スケジューリング scheduling １－４
スケジュール schedule １－４
スケール scale １－２
スコア score １－２例外、１－３
スタジオ studio ４－２例外
スタッカー stacker １－１
スチール steel １－４
スティック[棒状の物] stick ４－１例外
ステッキ[つえ] stick ４－１
ステークホルダー stakeholder １－２、４－３例外
ステージ stage １－２
ステータス status １－２
ステート state １－２
ストア store １－３
ストラクチャー structure １－３
ストーブ stove １－２、３
ストーリー story １－１、１－４
スパイウェア spyware １－３、２－１
スピーディー speedy １－１、１－４
スピード speed １－４
スペア spare １－３
スペイン Spain １－２
スペース space １－２ 
スポーツ sport １－４
スマートフォン smartphone ２－４
スムーズ smooth １－４
スライダー slider １－１、４－３例外
スライド slide ４－３例外
スリッパ slipper １－１例外
スーパー super １－１、１－４
スーパーバイザー supervisor １－１、１－４、３
セキュリティー security １－１、１－２例外
セクター sector １－１
セッター setter １－１
セパレーター separator １－１、１－２
セピア sepia ５
セミナー seminar １－１
セレクター selector １－１
センサー sensor １－１
センター center １－１
セーバー saver １－１、１－２、３
セーフティー safety １－１、１－２
セール sale １－２
セールス sales １－２
ゼラチン gelatin ４－１
ソイ soy １－２
ソフトウェア software １－３、２－１
ソリューション solutions １－４、４－１
ソース source １－４
ソーター sorter １－１、１－４
ソート sort １－４
ゾーン zone １－２
タイトル title ４－１
タイプフェース typefaces １－２、２－３
タイプライター typewriter １－１
タイポグラフィー typography １－１、２－３
タイマー timer １－１、４－１
タイミング timing ４－１
タイム time ４－１
タイムライン timeline ４－１
タイヤ tire １－３、４－１
ターゲット target １－４
ダイアリー diary １－１、４－２例外、５
ダイアログ dialog ４－２例外、５
ダイオード diode １－４、４－２例外、４－３例外
ダイカスト die casting の日本語形 ４－２例外
ダイジェスト digest ４－２例外
ダイニング dining ４－２例外
ダイビング diving ３、４－２例外
ダイメトリック dimetric ４－２例外
ダイヤグラム diagram ４－２例外、５例外
ダイヤモンド diamond ４－２例外、５例外 
ダイヤラー dialer １－１、４－２例外、５例外
ダイヤル dial ４－２例外、５例外
ダイレクト direct ４－２例外
ダウンロード download １－２
ダッシュ dash １－２
ダミー dummy １－１
ダーク dark １－４
チアミン thiamin ５
チェッカー checker １－１
チェック check １－４
チェーン chain １－２
チケット ticket ４－１
チップ tip ４－１
チャージャー charger １－１、１－４
チャート chart １－４
チュートリアル tutorial １－４、５
チューナー tuner １－１、１－４
チューニング tuning １－４
チューバ tuba １－４
ツイッター twitter １－１
ツール tool １－４
ツールバー toolbar １－１、１－４
テイスト taste １－２例外
テクスチャー texture １－３
テクノロジー technology １－１
テレビ television １－１、３
テレフォン telephone １－２例外、２－４
テンプレート template １－２
テーブル table １－２
テーマ theme １－１、１－４
ディクショナリー dictionary ４－１、４－２
ディザリング dithering ４－２
ディスカウント discount ４－２
ディスカッション discussion ４－２
ディスカバリー discovery １－１、３、４－２
ディスク disc ４－２
ディスク disk ４－２
ディスクロージャー disclosure １－３、４－２
ディスコ disco/discotheque ４－２
ディスタンス distance ４－２
ディスプレー display １－１、４－２
ディスポーザー disposer １－１、１－２、４－２
ディテール detail １－２、４－３例外
ディナー dinner １－１、４－２
ディバイド divide ３、４－２、４－３例外
ディファレンシャル differential ２－３、４－１、４－２
ディフェンス defense ２－３、４－３例外
ディレイ delay １－１例外、４－３例外
ディレクション direction ４－１、４－２ 
ディレクター director １－１、４－２
ディレクトリー directory １－１、４－２
ディレッタント dilettante ４－２
ディーラー dealer １－１、１－４、４－３例外
ディーゼル diesel １－４、４－２
デコーダー decoder １－１、１－２、４－３
デザイナー designer １－１、４－３
デザイン design ４－３
デジタル digital ４－２例外
デジャビュ dejavu/dejavu ３、４－３
デジュール de jure（ラテン語） １－４、４－３
デスク desk ４－３
デスクトップ desktop ４－３
デバイス device ３、４－３
デバッグ debug ４－３
デファクト de facto ２－３、４－３
デフォルト default ４－３
デフォルメ deformation/deformer[フランス語] ２－４、４－１、４－３
デベロッパー developer １－１、３、４－３
デポジット deposit ４－３
デマンド demand ４－３
デメリット demerit ４－３
デラウェア Delaware １－３例外、２－１例外、４－３
デリバリー delivery １－１、３、４－３
デンマーク Denmark １－４、４－３
データ data １－２
データベース database １－２
トイレット toilet １－２
トゥイーン tween １－４
トナー toner １－１、１－２
トライアル trial ５
トラッカー tracker １－１
トラブルシューティング troubleshooting １－４、４－１例外
トランシーバー transceiver １－１、３
トランジション transition ４－１
トランスミッター transmitter １－１
トランスレーション translation １－２、４－１
トランスレーター translator １－１、１－２
トレーサビリティー traceability １－１、１－２
トレース trace １－２
トレード trade １－２、４－３例外
トレーナー trainer １－１、１－２
トレーニング training １－２、１－４
トースト toast １－２
トーナメント tournament １－４
トーン tone １－２
ドア door １－１例外
ドキュメンテーション documentation １－２、４－１ 
ドメイン domain １－２例外
ドライバー driver １－１、３
ドライブ drive ３
ドリア doria ５
ドーム dome １－２
ナビゲーション navigation １－２、３、４－１
ナレーション narration １－２、４－１
ナンバー number １－１
ニュース news １－４
ニュートン newton １－４
ニーズ needs １－４
ヌーディスト nudist ４－２
ネイチャー nature １－２例外、１－３
ネイティブ native １－２例外、３、４－１例外
ネガティブ negative ３、４－１例外
ネクタイ necktie ４－１
ネーム name １－２
ノルウェー Norway １－１、２－１例外
ノート note １－２
ノード node １－２、４－３例外
ハイデルベルグ Heidelberg ４－３
ハイパー hyper １－１
ハイパーリンク hyperlink １－４
ハンガリー Hungary １－１
ハンチング hunting ４－１
ハンディキャップ handicap ４－２
ハンディー handy １－１
ハンドラー handler １－１
ハード hard １－１
ハードウェア hardware １－３、２－１
ハーフトーン halftone １－２、１－４
バイアス bias ５
バイオリン violin ３
バイナリー binary １－１
バインダリー bindery １－１、４－３例外
バインダー binder １－１、４－３例外
バウンディング bounding ４－２
バクテリア bacteria ５
バッテリー battery １－１
バッファー buffer １－１、２－３
バナー banner １－１
バニラ vanilla ３
バラエティー variety １－１、１－２、３
バリア barrier １－１例外
バリエーション variation １－２、３、４－１
バリデーター validator １－１、１－２、３
バリデート validate １－２、３
バルブ valve ３
バー bar １－１ 
バージョン version １－４、３
バージン virgin ３
バーティカル vertical １－１、１－４、３、４－１例外
パスワード password １－４
パピルス papyrus １－２例外
パフォーマンス performance １－４、２－４
パラメーター parameter １－１、１－４
パース perth １－４
パースペクティブ perspective １－４、３、４－１例外
パーセント percent １－４
パーソナル personal １－１、１－４
パーツ parts １－４
パーティー party １－１、１－４
パート part １－４
ヒューリスティック heuristic ４－１例外
ビジネスパーソン businessperson １－４
ビジュアル visual ３
ビジョン vision ３
ビジー busy １－１
ビデオ video ３、４－３
ビニール vinyl ３
ビビッド vivid ３
ビューアー viewer １－１、１－４、３
ビリヤード billiard １－４、５例外
ビルディング building ４－２
ビーナス venus １－４、３
ピア peer １－１例外
ピアノ piano ５
ピクチャー picture １－３
ピボット pivot ３
ピュア pure １－３
ファイアウォール firewall ２－１例外、２－３
ファイル file ２－３
ファインダー finder １－１、２－３、４－３例外
ファクス fax ２－３
ファニチャー furniture １－３、２－３
ファミリー family １－１、２－３
ファン fan ２－３
ファンタスティック fantastic ２－３、４－１例外
ファースト first ２－３
ファームウェア firmware １－３、２－１、２－３
フィギュア figure １－３、２－３
フィニッシャー finisher １－１、２－３
フィリピン Philippine ２－３
フィルター filter １－１、２－３
フィルム film ２－３
フィルムストリップ filmstrip ２－３
フィーダー feeder １－１、１－４、２－３、４－３例外
フィーチャー feature １－３、１－４、２－３ 
フィート feet １－４、２－３
フィードバック feedback １－４、２－３
フィールド field １－４、２－３
フェンシング fencing ２－３
フェード fade １－２、１－４、２－３、４－３例外
フォト photo １－１、２－４
フォルダー folder １－１、１－２、２－４、４－３例外
フォロー follow ２－４
フォワード forward １－４、２－４
フォント font ２－４
フォーカス focus ２－４
フォーク folk １－２、２－４
フォーマッター formatter １－１、１－４、２－４
フォーマッティング formatting １－４、２－４、４－１例外
フォーマット format １－４、２－４
フォーム form １－４、２－４
フォーラム forum １－４、２－４
フッター footer １－１
フューザー fuser １－１、１－４
フュージョン fusion １－４
フライ fly １－１例外
フリッカー flicker １－１
フリーウェア freeware １－３、１－４、２－１
フリーハンド freehand １－４
フリーランサー freelancer １－１、１－４
フル full １－１
フレーム frame １－２
フロッピー floppy １－１
ブラウザー browser １－１
プライバシー privacy １－１、３
プライベート private ３
プライマリー primary １－１
プラス plus １－１
プラスチック plastic ４－１
プラットフォーム（アプリケーションの動作環境） platform ２－４
プラットホーム（駅） platform ２－４例外
プリインストール preinstall １－４
プリンター printer １－１
プレゼンテーション presentation ４－１
プレッシャー pressure １－３
プレビュー preview ３
プレースホルダー placeholder １－１、１－２、４－３例外
プレーヤー player １－１、１－２
プレーン plane/plain １－２
プログラマー programmer １－１
プロジェクター projector １－１
プロセッサー processor １－１ 
プロッター plotter １－１
プロデューサー producer １－１、１－４
プロデュース produce １－４
プロバイダー provider １－１、３、４－３例外
プロパティ property １－１例外
プロファイル profile ２－３
プロフェッショナル professional ２－３
プロポーショナル proportional １－４、４－１
プロモーション promotion １－４、４－１
プローブ probe １－２
ヘッダー header １－１、４－３例外
ヘッドホン headphone ２－４例外
ヘルスケア healthcare １－３
ベクター vector １－１、３
ベジェ bezier １－１例外
ベテラン veteran ３
ベンダー vendor １－１、３
ベンチャー venture １－３、１－４、３
ベール bale １－２
ベール veil １－２、３
ペア pair １－１例外
ペナルティー penalty １－１
ページ page １－２
ページネーション pagination １－２、４－１
ペース pace １－２
ペースト paste １－２
ペーパー paper １－１、１－２
ペーパーレス paperless １－２
ホルマリン formalin ２－４例外
ホーム home １－４
ボウル bowl １－２例外
ボディー body １－１
ボランティア volunteer １－１例外、３
ボリューム volume ３
ボーカル vocal １－２、３
ボード board １－４
ポインター pointer １－１
ポジ positive ３
ポスター poster １－１
ポリシー policy １－１
ポーランド Poland １－２
マジック magic １－１
マスター master １－１
マニュファクチャー manufacture １－３、２－３
マネージャー manager １－１
マルチ multi ４－１
マルチステート multi‐state １－２、４－１
マルチページ multi‐page １－２、４－１
マルチメディア multimedia ４－１、４－２、５ 
マルチユース multi‐use ４－１
マルチランゲージ multi‐language １－１、４－１
マーカー marker １－１、１－４
マーキング marking １－４
マーク mark １－４
マークアップ mark‐up １－４
マーケット market １－４
マーケティング marketing １－４、４－１例外
マージ merge １－４
マージン margin １－４
ミディ midi ４－２
ミネラル mineral １－１
ミラー miller １－１
ミラー mirror １－１
ミリメートル millimeter １－１例外
ミルクセーキ milk shake １－２
ムービー movie １－４、３
メイン main １－２例外
メガホン megaphone ２－４例外
メソポタミア Mesopotamia ５
メタデータ metadata １－２
メッセージ message １－２
メディア media ４－２、５
メモリー memory １－１
メロディー melody １－１
メンテナンス maintenance １－２例外
メンバー member １－１
メーカー maker １－１、１－２
メーター（計器） meter １－１、１－４
メートル（長さの単位） meter １－１例外、１－４
メール mail １－２
モジュラー modular １－１
モチーフ motif １－４、４－１
モデル model ４－３
モニター monitor １－１
モーション motion １－２、４－１
モーター motor １－１、１－２
モード mode １－２、４－３例外
モールド mold １－２
ユニバーサル universal １－４、３
ユニフォーム uniform １－４、２－３、２－４
ユーザビリティー usability １－１
ユーザー user １－１、１－４
ユーティリティー utility １－１、１－４、４－１例外
ユーモア humor １－１例外
ヨーロッパ Europe １－４
ライター writer １－１
ライティング lighting ４－１例外
ライティング writing ４－１例外 
ライブ live ３
ライブラリー library １－１
ラウンド round １－２
ラジアル radial ４－２例外、５
ラジオ radio ４－２例外
ラスタライザー rasterizer １－１
ラスター raster １－１
ラテン Latin ４－１
ランゲージ language １－１
ランタイム run‐time １－１、４－１
リア rear １－１例外、６
リアル real ６
リコーダー（縦笛） recorder １－１、１－４、４－３例外、６
リコール recall １－４、６
リサイクル recycle ６
リジューム resume ６
リズム rhythm ６
リセット reset ６
リソース resources １－４、６
リタイア retire １－３、４－１、６
リダイヤル redial ４－２例外、５例外、６
リテラシー literacy １－１
リデュース reduce １－４、６
リハーサル rehearsal ６
リバイバル revival １－２、３、６
リバーサル reversal １－４、３、６
リピート repeat １－４、６
リファレンス reference ２－３、６
リフォーム reform １－４、２－４、６
リフレッシュ refresh ６
リフロー reflow １－２、６
リボルビング revolving ３、６
リポジトリー repository １－１、６
リポート（報告） report １－４、６
リモコン remote control ６
リユース reuse ６
リライト rewrite ６
リラクセーション relaxation １－２、４－１、６
リラックス relax ６
リリース release １－４、６
リーダー leader １－１、１－４、４－３例外
リーダー reader １－１、４－３例外、６
リード lead １－４
ルート root １－１
ルーマニア Romania １－２、５
ルーラー ruler １－１、１－４
ルール rule １－４
ルール rules １－４
レイヤー layer １－１ 
レインコート raincoat １－２
レクチャー lecture １－３
レクリエーション recreation １－２、４－１、６例外
レコーダー（録音機） recorder １－１、１－４、４－３例外、６例外
レコード record ６例外
レシピ recipe ６例外
レシーバー receiver １－１、１－４、３、６例外
レジスター register １－１、６例外
レジストリー registry １－１、６例外
レジストレーション registration １－２、４－１、６例外
レジャー leisure １－３
レスポンス response ６例外
レタッチ retouch ２－４、６例外
レター letter １－１
レッド red ６例外
レトルト retort ６例外
レバー lever １－１、３
レパートリー repertory １－１、１－４、６例外
レビュー review ３、６例外
レビュー revue ３、６例外
レベル level ３
レポート（‐用紙） report １－４、６例外
レーザー laser １－１、１－２
レーダー radar １－１、１－２
ロマンチック romantic ４－１例外
ローカライズ localize １－２
ローカライゼーション localization １－２、４－１
ローカル local １－２
ロープ rope １－２
ローマ Rome １－２
ローマン Roman １－２
ローラー roller １－１、１－２
ロール roll １－２
ワイド wide ４－３例外
ワイヤ wire １－３
ワイヤレス wireless １－３例外
ワーキング working １－４
ワークフロー workflow １－２、１－４
ワード word １－４
ワードパッド wordpad １－４
ワープロ word processor １－４
