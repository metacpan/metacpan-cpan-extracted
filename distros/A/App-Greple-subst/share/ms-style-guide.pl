#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;

use utf8;
use open IO => ':utf8', ':std';

do 'common.pl' or die;

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
	ignore    => { map {$_ => 1} qw() },
    },
    "debug!",
    "minimum=i",
    "reorder!",
    "category!",
    "monomania!",
    "skipfixed!",
    "ignore=s%",
    ) || usage({status => 1});

use Text::VisualPrintf qw(vprintf vsprintf);
use Text::VisualWidth::PP qw(vwidth);
use List::Util qw(max);

use Data::Section::Simple qw(get_data_section);
my $header = get_data_section "HEAD";
$_ = get_data_section "HTML";

my @data;
my %maxlen = ( en => 0, pattern => 0, kana => 0 );
while (m{<p>■(\w+?)</p>\n<p>(.*?)</p>}gx) {
    my $title = $1;
    my $words = $2;
    while ($words =~ m{(?<kana>\p{InKatakana}+)（(?<en>\w+)）}gx) {
	pushdict(en      => $+{en},
		 pattern => &mkpat($+{en}, $+{kana}),
		 kana    => $+{kana}
	    );
    }
}

sub pushdict {
    push @data, my $data = { @_ };
    for my $key (qw(en pattern)) {
	if ((my $w = vwidth $data->{$key}) > $maxlen{$key}) {
	    $maxlen{$key} = $w;
	}
    }
    $data->{regex} = qr/$data->{pattern}/;
    $data->{ignore}++ if get_length($data->{kana}) < $opt->{minimum};
    $data->{fixed}++ if $data->{pattern} eq $data->{kana};
}

sub mkpat {
    (my $en, local $_) = @_;
    for my $op (
	[ qr/wer$/
	  => sub {
	      s/(?:[アワ])ー?/[アワ]ー?/;
	  } ],
	[ qr/^/
	  => sub {
	      s/[アヤ]ー?$/[アヤ]ー?/;
	      s/(?<=[アァカガサザタダナハバパマヤャラワ])$/ー?/;
#	      s/[ウゥクグスズツッヅヌフブプムユュル]\Kー(?!$)/ー?/g;
	      s/[エェケゲセゼテデネヘベペメレヱ]\K[イー]/[イー]/g;
	      s/ー$/ー?/;
	  } ],
	[ qr/w/
	  => sub {
	      s/ウ[イィ]/ウ[イィ]/;
	      s/ウ[エェ]/ウ[エェ]/;
	      s/ウ[オォ]/ウ[オォ]/;
	  } ],
	[ qr/q/
	  => sub {
	      s/ク[アァ]/ク[アァ]/;
	      s/ク[イィ]/ク[イィ]/;
	      s/ク[エェ]/ク[エェ]/;
	      s/ク[オォ]/ク[オォ]/;
	  } ],
	[ qr/v[ae]/
	  => sub {
	      s/バ/(?:バ|ヴァ)/g;
	      s/ベ/(?:ベ|ヴェ)/g;
	  } ],
	[ qr/v[i]/
	  => sub {
	      s/ビ(?![ユュ])/(?:ビ|ヴィ)/g;
	      s/ビュ/(?:ビ[ユュ]|ヴュ)/g;
	  } ],
	[ qr/v/
	  => sub {
	      s/ブ/(?:ブ|ヴ)/g;
	  }] ,
	[ qr/vo/
	  => sub {
	      s/ボ/(?:ボ|ヴォ)/g;
	  } ],
	[ qr/t[eiy]/
	  => sub {
	      s/(?:チ(?![ャュェョ])|ティ)/(?:チ|ティ)/g;
	  } ],
	[ qr/^di/
	  => sub {
	      s/^ディ?/ディ?/g;
	  } ],
	[ qr/(?!^)di/
	  => sub {
	      s/(?!^)(?:ディ|ジ(?![ャィュェョ]))/(?:ディ|ジ)/g;
	  } ],
	)
    {
	my($re, $sub) = @$op;
	$en =~ $re and $sub->()
    }
    $_;
}

if ($opt->{reorder}) {
    use List::Util qw(first);
    for my $i (1 .. $#data) {
	my $match =
	    (first { $data[$i]->{kana} =~ $data[$_]->{regex} } 0 .. $i - 1)
	    // next;
	splice @data, $match, 0 => splice @data, $i, 1;
    }
}

print $header if $header;

for my $data (@data) {
    if ($opt->{skipfixed} and $data->{fixed}) {
	print "##";
    }
    elsif ($data->{ignore}) {
	print "# ";
    } else {
	print "  ";
    }
    vprintf "%-*s ", $maxlen{en}, $data->{en};
    vprintf "%-*s %s\n",
	$maxlen{pattern}, $data->{pattern},
	$data->{kana},
	;
}

__DATA__

@@ HEAD
##
## Generated from https://www.atmarkit.co.jp/news/200807/25/microsoft.html
##
@@ HTML
<p>　同社では従来から「2音の用語は長音符号を付け、3音以上の用語の場合は省くことを原則とする」としたJIS規格（JISZ 8301）に準じてきた。私企業として「何らかの外部のガイドラインに従う必要があった」（マイクロソフト 最高技術責任者 加治佐俊一氏）と、これまでJIS規格を参照してきた。ただ、この規格はJISの規格書作成時のガイドラインとして定められたもので、科学技術・工学系のドキュメントなど一部で用いられてきたルールに過ぎない。</p>
<p>　新聞や雑誌などでは「長音あり」としたルールを採用するケースが多い。これは1991年に国語審議会の答申を受けて出された内閣告示に基づく外来語の表記ルールに準じるもので、原則として語尾が“-er”、“-or”、“-ar”で終わる語彙は長音を付けるというものだ。IT業界でもメーカーによっては「プリンター」「ドライバー」などの表記を採用している。</p>
<p>　マイクロソフトはコンピュータが日常必需品となり一般化してくるにつれて、長音なしの表記に対してユーザーが違和感を感じるようになっているとし、「一般的な表記に合わせる時期」（加治佐氏）と判断。2003年ごろから具体的な検討を始めた。これまで画面表示領域やメモリ容量の制限などから、コンピュータ業界では長音記号を省略するケースが多かったが「ハードウェアやソフトウェアの制約がなくなってきた」（加治佐氏）こともルール変更の理由の1つという。</p>
<p>　長音記号の有無による表記の揺れは、語末だけでなく文中にもあるが、今回の変更は語末に限るという。例えば今回の変更で「バッファ」を「バッファー」と書くようになったが「バッファリング」の場合には従来通りとする。また、「インターフェイス」「インターフェース」、「セキュリティ／セキュリティー」や「プロパティ／プロパティー」のよう“y”で終わる語彙の表記の揺れについては「まだ取り組んでいかなければならない問題は多い」（加治佐氏）とし、今回のルール変更では扱わない。</p>
<p>　過去に出荷した製品については、従来通りとして今後リリースする製品やドキュメントを新ルール適用の対象とする。最初の対象製品となるのは8月中に予定されているInternet Explorer 8 Beta2で「エクスプローラ」は「エクスプローラー」となる。</p>
<p>　同社は7月25日から<A HREF="http://www.microsoft.com/language/ja/jp/default.mspx">Webサイト</A>を通じて変更対象となる語彙リストを含んだスタイルガイドの提供を開始した。「アウトドア」「コンパイラ」「プログラマ」「プロセッサ」など慣例により長音なしとする43語のリストや、「ソルバー」「セーバー」「カレンダー」などもともと例外的に長音が付いていた約400語のリストも含む。</p>
<p>　マイクロソフト製品でも、Xboxなど一般向けに出荷している製品では、例えば「コントローラー」と表記していたため、これまでどおり変更はない。</p>
<p>■長音記号付きに変更となるもの</p>
<p>アクセサー（accessor）、アクター（actor）、アクティベーター（activator）、アグリゲーター（aggregator）、アセンブラー（assembler）、アダプター（adapter）、アップデーター（updater）、アップローダー（uploader）、アドバイザー（advisor）、アドミニストレーター（administrator）、アナライザー（analyzer）、アニメーター（animator）、アロケーター（allocator）、アンインストーラー（uninstaller）、アンカー（anchor）、アンギュラー（angular）、アンパッカー（unpacker）、イコライザー（equalizer）、イニシエーター（initiator）、イニシャライザー（initializer）、イネーブラー（enabler）、イメージセッター（imagesetter）、インサーター（inserter）、インジェクター（injector）、インジケーター（indicator）、インストーラー（installer）、インスペクター（inspector）、インターセプター（interceptor）、インタープリター（interpreter）、インデクサー（indexer）、インテグレーター（integrator）、インバーター（inverter）、インバリデーター（invalidator）、インポーター（importer）、ウォーカー（walker）、ウォーター（water）、ウォリアー（warrior）、エキスパンダー（expander）、エクスチェンジャー（exchanger）、エクステンダー（extender）、エクスプローラー（explorer）、エクスポーター（exporter）、エスカレーター（escalator）、エゼクター（ejector）、エディター（editor）、エバリュエーター（evaluator）、エミュレーター（emulator）、エレベーター（elevator）、エンコーダー（encoder）、オーガナイザー（organizer）、オートダイヤラー（autodialer）、オートフィルター（autofilter）、オシレーター（oscillator）、オフィサー（officer）、オブザーバー（observer）、オプティマイザー（optimizer）、オペレーター（operator）、オルタネーター（alternator）、カウンター（counter）、カスタマー（customer）、カスタマイザー（customizer）、カテゴライザー（categorizer）、ガバナー（governor）、カプラー（coupler）、カムコーダー（camcorder）、キャラクター（character）、キュイラシェー（cuirassier）、クラスター（cluster）、クリーナー（cleaner）、クリエーター（creator）、クローラー（crawler）、コーディネーター（coordinator）、コレクター（collector）、コンシューマー（consumer）、コンストラクター（constructor）、コンセントレーター（concentrator）、コンダクター（conductor）、コンテナー（container）、コンデンサー（condenser）、コントリビューター（contributor）、コントローラー（controller）、コンバーター（converter）、コンピューター（computer）、コンフィギュレーター（configurator）、コンプレッサー（compressor）、コンベクター（convector）、コンペンセーター（compensator）、コンポーザー（composer）、コンポジター（compositor）、サブウーファー（subwoofer）、サブコンテナー（subcontainer）、サブスクライバー（subscriber）、サブフィルター（subfilter）、サブフォルダー（subfolder）、サブマスター（submaster）、サプライヤー（supplier）、サブレイヤー（sublayer）、サプレッサー（suppressor）、サマライザー（summarizer）、シアター（theater）、シーケンサー（sequencer）、シェーダー（shader）、ジェネレーター（generator）、シフター（shifter）、シャッター（shutter）、ジャンパー（jumper）、シリアライザー（serializer）、シリンダー（cylinder）、シンクロナイザー（synchronizer）、シンセサイザー（synthesizer）、スイッチャー（switcher）、スーパーバイザー（supervisor）、スーパーバイザー（supervisor）、スーペリアー（superior）、スカベンジャー（scavenger）、スカラー（scalar）、スキャッター（scatter）、スキャナー（scanner）、スクリーナー（screener）、スクリーンセーバー（screensaver）、スクリプター（scriptor）、スクレーパー（scraper）、スタッカー（stacker）、ステージャー（stager）、ステマー（stemmer）、ストーカー（stoker）、スニファー（sniffer）、スパイダー（spider）、スピアー（spear）、スピーカー（speaker）、スプーラー（spooler）、スプリッター（splitter）、スペーサー（spacer）、スライサー（slicer）、スライダー（slider）、セクター（sector）、セパレーター（separator）、セレクター（selector）、センサー（sensor）、センター（center）、センダー（sender）、タイプライター（typewriter）、タイマー（timer）、ダイヤラー（dialer）、ダウンローダー（downloader）、チェンジャー（changer）、チャプター（chapter）、チャレンジャー（challenger）、チューナー（tuner）、ディザー（dither）、ディストリビューター（distributor）、ディスパッチャー（dispatcher）、ディスペンサー（dispenser）、ディバイダー（divider）、ディフューザー（diffuser）、ディレクター（director）、テクスチャライザー（texturizer）、デコーダー（decoder）、デザイナー（designer）、デジタイザー（digitizer）、デシリアライザー（deserializer）、テスター（tester）、デストラクター（destructor）、デスプーラー（despooler）、デバイザー（divisor）、デバッガー（debugger）、デベロッパー（developer）、デマルチプレクサー（demultiplexer）、デリミター（delimiter）、ドライバー（driver）、ドライヤー（dryer）、トラクター（tractor）、トラッカー（tracker）、トランシーバー（transceiver）、トランスデューサー（transducer）、トランスファー（transfer）、トランスフォーマー（transformer）、トランスポンダー（transponder）、トランスレーター（translator）、トリガー（trigger）、トリマー（trimmer）、トレーサー（tracer）、トレーラー（trailer）、ドロアー（drawer）、ナビゲーター（navigator）、ナレーター（narrator）、ノーマライザー（normalizer）、パートナー（partner）、バーバライザー（verbalizer）、バインダー（binder）、パケッタイザー（packetizer）、パスファインダー（pathfinder）、バスマスター（busmaster）、パッケージャー（packager）、バッファー（buffer）、パブリッシャー（publisher）、パラメーター（parameter）、バランサー（balancer）、バリオメーター（variometer）、バリデーター（validator）、パルベライザー（pulverizer）、ハンドラー（handler）、ハンマー（hammer）、ビジュアライザー（visualizer）、ピッカー（picker）、ビヘイビアー（behavior）、ピュアライザー（purelyzer）、ビューアー（viewer）、ビルダー（builder）、ファイナライザー（finalizer）、ファイバー（fiber）、ファインダー（finder）、ファクター（factor）、フィーダー（feeder）、フィニッシャー（finisher）、フィルター（filter）、フィンガー（finger）、ブースター（booster）、ブートローダー（bootloader）、フェイダー（fader）、フォルダー（folder）、フォワーダー（forwarder）、フッター（footer）、ブラウザー（browser）、プランジャー（plunger）、プランナー（planner）、プリマスター（premaster）、プリンター（printer）、プルーナー（pruner）、ブレーカー（breaker）、プレースホルダー（placeholder）、フレーバー（flavor）、プレゼンター（presenter）、プレビューアー（previewer）、プレフィルター（prefilter）、ブレンダー（blender）、ブローカー（broker）、ブロードキャスター（broadcaster）、プロジェクター（projector）、ブロッカー（blocker）、プロッター（plotter）、プロテクター（protector）、プロデューサー（producer）、プロバイダー（provider）、プロファイラー（profiler）、ベアラー（bearer）、ページャー（pager）、ベクター（vector）、ヘッダー（header）、ヘリコプター（helicopter）、ヘルパー（helper）、ベンダー（vendor）、ボイジャー（voyager）、ポインター（pointer）、ポストマスター（postmaster）、ポリマー（polymer）、ホルダー（holder）、マーシャラー（marshaller）、マイナー（minor）、マインスイーパー（minesweeper）、マスター（master）、マッパー（mapper）、マニピュレーター（manipulator）、マネージャー（manager）、マルチフィーダー（multifeeder）、マルチプライヤー（multiplier）、マルチプレクサー（multiplexer）、マルチマスター（multimaster）、マルチモニター（multimonitor）、マルチレイヤー（multilayer）、ミキサー（mixer）、ミニドライバー（minidriver）、ミニフィルター（minifilter）、ミューテーター（mutator）、メッセンジャー（messenger）、メディエイター（mediator）、メンバー（member）、メンバーシップ（membership）、モジュラー（modular）、モディファイヤー（modifier）、モデレーター（moderator）、モニカー（moniker）、モニター（monitor）、ライザー（riser）、ライセンサー（licensor）、ライター（writer）、ラスター（raster）、ラスタライザー（rasterizer）、リアクター（reactor）、リクエスター（requestor）、リスナー（listener）、リゾルバー（resolver）、リダイレクター（redirector）、リパッケージャー（repackager）、リパブリッシャー（republisher）、リファクター（refactor）、リフレッシャー（refresher）、リマインダー（reminder）、リンカー（linker）、レイヤー（layer）、レコーダー（recorder）、レコグナイザー（recognizer）、レシーバー（receiver）、レジストラー（registrar）、レスポンダー（responder）、レビューアー（reviewer）、レプリケーター（replicator）、レベラー（leveler）、レポーター（reporter）、レンダー（render）、レンダラー（renderer）、ローカライザー（localizer）、ロケーター（locator）</p>
<p>■慣例に基づき変更しないもの</p>
<p>アウトドア（outdoor）、アクセラレータ（accelerator）、インテリア（interior）、インドア（indoor）、エクステリア（exterior）、エンジニア（engineer）、ギア（gear）、キャリア（carrier）、クリア（clear）、コネクタ（connector）、コンパイラ（compiler）、コンベヤ（conveyor）、シニア（senior）、ジュニア（junior）、スケジューラ（scheduler）、ステラ（stellar）、スリッパ（slipper）、センチメートル（centimeter）、ターミネータ（terminator）、タール（tar）、ドア（door）、トランジスタ（transistor）、ドル（dollar）、バザール（bazaar）、バリア（barrier）、ビール（beer）、フォーマッタ（formatter）、プレミア（premier）、フロア（floor）、プログラマ（programmer）、プロセッサ（processor）、プロペラ（propeller）、フロンティア（frontier）、ベア（bear）、ボランティア（volunteer）、ポリエステル（polyester）、ミリメートル（millimeter）、メートル（meter）、ユーモア（humor）、ラジエータ（radiator）、リア（rear）、リニア（linear）、レジスタ（register）</p>
<p>■もともと長音が付いていて変更のないもの</p>
<p>アーチャー（archer）、アウター（outer）、アウトロー（outlaw）、アカデミー（academy）、アスキー（ASCII）、アッパー（upper）、アドベンチャー（adventure）、アニュバー（anubar）、アバター（avatar）、アバランチャー（avalancher）、アフター（after）、アベンジャー（avenger）、アレルギー（allergy）、アングラー（angler）、アンサー（answer）、アンダー（under）、アンダーバー（underbar）、イージー（easy）、イースター（easter）、イェーガー（jaeger）、イグナイター（igniter）、インストラクター（instructor）、インタビュー（interview）、インナー（inner）、インベンター（inventor）、ウィスキー（whiskey）、ウィスパー（whisper）、ウィッカー（wicker）、ウォーマー（warmer）、ウォッチャー（watcher）、エコー（echo）、エコノミー（economy）、エナジー（energy）、エネルギー（energy）、エラー（error）、エルダー（elder）、エンター（enter）、エンタープライズ（enterprise）、エンチャンター（enchanter）、エンフォーサー（enforcer）、オーサー（author）、オーダー（order）、オーナー（owner）、オーバー（over）、オファー（offer）、オリバー（oliver）、ガードナー（gardener）、カウンセラー（counselor）、カッター（cutter）、カヌー（canoe）、カバー（cover）、カラー（color）、カレー（curry）、カレンダー（calendar）、カロリー（calorie）、カンガルー（kangaroo）、ガンナー（gunner）、カンパニー（company）、キー（key）、ギター（guitar）、キッカー（kicker）、キャスター（caster）、キャッチャー（catcher）、キャノニアー（cannoneer）、キャブレター（carburetor）、ギャラリー（gallery）、キャンカー（canker）、キュー（cue）、キュー（queue）、キラー（killer）、クーラー（cooler）、グライダー（glider）、クラッカー（cracker）、クラッシャー（crusher）、クランベリー（cranberry）、クリーバー（cleaver）、クルー（crew）、クルーザー（cruiser）、クルセイダー（crusader）、グレー（gray）、クレーター（crater）、グレーター（greater）、グロー（glow）、クローバー（clover）、クロスバー（crossbar）、クロバー（clobber）、ゲートキーパー（gatekeeper）、ゲーマー（gamer）、コーナー（corner）、コーヒー（coffee）、コーラー（caller）、ゴールキーパー（goalkeeper）、コピー（copy）、コマンダー（commander）、コミューター（commuter）、コンピテンシー（competency）、サーバー（server）、サイドバー（sidebar）、サイバー（cyber）、サッカー（soccer）、ザッパー（zapper）、サブキー（subkey）、サブツリー（subtree）、サマリー（summary）、サラマンダー（salamander）、シーソー（seesaw）、シーナリー（scenery）、シグナラー（signaler）、シチュー（stew）、ジッター（jitter）、シナジー（synergy）、シミター（scimitar）、ジャガー（jaguar）、シャワー（shower）、シャンプー（shampoo）、ジュエリー（jewelry）、シュガー（sugar）、ショー（show）、ジョーカー（joker）、ショッカー（shocker）、シルバー（silver）、スーパー（super）、スカーミッシャー（skirmisher）、スキー（ski）、スキッター（skitter）、スキナー（skinner）、スクーナー（schooner）、スクリュー（screw）、スクロールバー（scrollbar）、スコーチャー（scorcher）、スター（star）、スターター（starter）、スターフラワー（starflower）、スティンガー（stinger）、ステッカー（sticker）、ストーリー（story）、ストッパー（stopper）、ストライダー（strider）、ストロベリー（strawberry）、スナイパー（sniper）、スニーカー（sneaker）、スノー（snow）、スパイカー（spiker）、スパッター（spatter）、スピッター（spitter）、スプリンクラー（sprinkler）、スプレー（spray）、スポイラー（spoiler）、スポンサー（sponsor）、スラッシャー（slasher）、スリーパー（sleeper）、スリンガー（slinger）、スルー（through）、スロー（slow）、スローター（slaughter）、セーター（sweater）、セーバー（saver）、セッター（setter）、セプター（scepter）、セミナー（seminar）、セルラー（cellular）、セレモニー（ceremony）、ソーター（sorter）、ソーラー（solar）、ソルジャー（soldier）、ソルバー（solver）、タイガー（tiger）、ダイバー（diver）、タイムリー（timely）、ダガー（dagger）、タクシー（taxi）、ダミー（dummy）、タワー（tower）、タンカー（tanker）、ダンサー（dancer）、ダンパー（damper）、チーター（cheetah）、チェッカー（checker）、チェリー（cherry）、チャーター（charter）、チャウダー（chowder）、チャネラー（channeler）、チョッパー（chopper）、チンパンジー（chimpanzee）、ツアー（tour）、ツリー（tree）、ティー（tea）、ディーラー（dealer）、ディスカバー（discover）、ディナー（dinner）、ディフェンダー（defender）、デイリー（daily）、ティンバー（timber）、デスクバー（deskbar）、デストロイヤー（destroyer）、デスポイラー（despoiler）、テレポーター（teleporter）、テンキー（tenkey）、ドゥエラー（dweller）、ドクター（doctor）、トッパー（topper）、ドップラー（doppler）、ドッペルゲンガー（doppelganger）、トナー（toner）、トラベラー（traveler）、ドラマー（drummer）、ドリルスルー（drillthrough）、ドルビー（dolby）、トレーダー（trader）、トレーナー（trainer）、トレジャー（treasure）、ドレッサー（dresser）、トロフィー（trophy）、トロリー（trolley）、ナンバー（number）、ニードラー（needler）、ニュー（new）、ニュースリーダー（newsreader）、ニュースレター（newsletter）、ネイチャー（nature）、ネービー（navy）、バー（bar）、パーサー（parser）、バーサーカー（berserker）、バースデー（birthday）、バーテンダー（bartender）、バーナー（burner）、ハーバー（harbor）、バーベキュー（barbecue）、ハーモニー（harmony）、ハイカー（hiker）、ハイカラー（high-color）、バイザー（visor）、ハイパー（hyper）、パイパー（piper）、バイヤー（buyer）、パウダー（powder）、ハウツー（how-to）、ハウラー（howler）、バザー（bazaar）、パスキー（passkey）、パススルー（passthrough）、バスター（buster）、バター（butter）、ハッカー（hacker）、バックラー（buckler）、バッシャー（basher）、ハッピー（happy）、パトローラー（patroller）、バナー（banner）、パブリシティー（publicity）、バリュー（value）、バルコニー（balcony）、パワー（power）、ハンガー（hanger）、バンカー（bunker）、パンサー（panther）、パンジー（pansy）、ハンター（hunter）、パンチャー（puncher）、バンパー（bumper）、ハンバーガー（hamburger）、ピアサー（piercer）、ヒーター（heater）、ビーバー（beaver）、ヒーロー（hero）、ビギナー（beginner）、ビクトリー（victory）、ビジー（busy）、ビジター（visitor）、ピトー（pitot）、ビフォー（before）、ビュー（view）、ヒューザー（fuser）、ピューリファイアー（purifier）、ファイター（fighter）、ファンシー（fancy）、ファンタジー（fantasy）、フィッシャー（fisher）、フェールオーバー（failover）、フェザー（feather）、フェリー（ferry）、フォッカー（fokker）、フォトグラフィー（photography）、フォロー（follow）、ブザー（buzzer）、ブッチャー（butcher）、フライヤー（flyer）、ブラスター（blaster）、フラワー（flower）、フリー（free）、フリークエンシー（frequency）、フリッカー（flicker）、フリッパー（flipper）、ブルー（blue）、ブルーベリー（blueberry）、ブルドーザー（bulldozer）、プレイナー（planar）、プレーヤー（player）、プレーリー（prairie）、プレオーダー（preorder）、プレデター（predator）、プレビュー（preview）、フロー（flow）、フロッピー（floppy）、プロンプター（prompter）、ペイズリー（paisley）、ペーパー（paper）、ベストセラー（bestseller）、ペッカリー（peccary）、ペッパー（pepper）、ヘビー（heavy）、ベビー（baby）、ベビーシッター（babysitter）、ベリー（berry）、ヘルシー（healthy）、ベンチャー（venture）、ボイラー（boiler）、ボー（baud）、ボーダー（border）、ポーター（porter）、ポスター（poster）、ホッケー（hockey）、ホットキー（hotkey）、ホッパー（hopper）、ポニー（pony）、ホバー（hover）、ホビー（hobby）、ポピュラー（popular）、ホラー（horror）、ポリシー（policy）、マーカー（marker）、マーキー（marquee）、マッシャー（masher）、マッチャー（matcher）、マナー（manner）、マネー（money）、マホガニー（mahogany）、ミステリー（mystery）、ミラー（mirror）、ムーバー（mover）、ムービー（movie）、メーカー（maker）、メーター（meter）、メーラー（mailer）、メジャー（major）、メニュー（menu）、モーター（motor）、モットー（motto）、モンスター（monster）、ユーザー（user）、ライダー（raider）、ラグジュアリー（luxury）、ラズベリー（raspberry）、ラダー（ladder）、ラッキー（lucky）、ラッシャー（rusher）、ラッパー（wrapper）、ラプター（raptor）、ラベンダー（lavender）、ランガー（lunger）、ランチャー（launcher）、ランデブー（rendezvous）、ランナー（runner）、リーダー（leader）、リセラー（reseller）、リビーラー（revealer）、リフラクター（refractor）、リベレーター（liberator）、リレー（relay）、ルーター（router）、ルーラー（ruler）、ルビー（ruby）、レーザー（laser）、レーダー（radar）、レギュラー（regular）、レクサー（lexer）、レザー（leather）、レジャー（leisure）、レスキュー（rescue）、レター（letter）、レッカー（wrecker）、レッサー（lesser）、レトリバー（retriever）、レバー（lever）、レビュー（review）、レンジャー（ranger）、ローター（rotor）、ローダー（loader）、ロータリー（rotary）、ローラー（roller）、ロガー（logger）、ロッカー（locker）、ロビー（lobby）、ワーカー（worker）、ワークフロー（workflow）、ワインセラー（winecellar）、ワッカー（whacker）</p>
