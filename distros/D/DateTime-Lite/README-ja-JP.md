# NAME

DateTime::Lite - DateTimeの軽量かつ依存関係の少ないドロップイン代替モジュール

# SYNOPSIS

    use DateTime::Lite;

    my $dt = DateTime::Lite->new(
        year       => 2026,
        month      => 4,
        day        => 10,
        hour       => 6,
        minute     => 10,
        second     => 30,
        nanosecond => 0,
        time_zone  => 'Asia/Tokyo',
        locale     => 'ja-JP',
    ) || die( DateTime::Lite->error );

    my $now   = DateTime::Lite->now( time_zone => 'UTC' );
    my $today = DateTime::Lite->today( time_zone => 'Asia/Tokyo' );

    # GPS 座標からタイムゾーンを取得
    # （ハーサイン距離に基づく最も近い IANA タイムゾーン）
    use DateTime::Lite::TimeZone;
    my $tz = DateTime::Lite::TimeZone->new(
        latitude  => 35.658581,
        longitude => 139.745433,   # 東京タワー
    );
    my $dt_local = DateTime::Lite->now( time_zone => $tz );
    say $dt_local->time_zone_long_name;  # Asia/Tokyo

    # BCP47 の -u-tz- ロケール拡張:
    # ロケールタグからタイムゾーンを推定
    my $dt_bcp47 = DateTime::Lite->now( locale => 'he-IL-u-ca-hebrew-tz-jeruslm' );
    say $dt_bcp47->time_zone_long_name;  # Asia/Jerusalem

    my $from_epoch = DateTime::Lite->from_epoch( epoch => time() );
    my $from_doy   = DateTime::Lite->from_day_of_year(
        year        => 2026,
        day_of_year => 100,
        time_zone   => 'UTC',
    );
    my $eom = DateTime::Lite->last_day_of_month( year => 2026, month => 2 );

    # 複製（XS を使用）
    my $copy = $dt->clone;

    # アクセサ
    $dt->year;          # 2026
    $dt->month;         # 4（1-12）
    # エイリアス
    $dt->mon;
    $dt->day;           # 10（1-31）
    # エイリアス
    $dt->day_of_month
    $dt->hour;          # 6（0-23）
    $dt->minute;        # 10（0-59）
    $dt->second;        # 30（うるう秒の日のみ 0-61）
    $dt->nanosecond;    # 0（0-999_999_999）

    $dt->day_of_week;   # 5（1=月曜 .. 7=日曜）
    $dt->day_of_year;   # 99（1-366）
    $dt->day_abbr;      # "金"（ロケールが 'en-US' なら "Fri"）
    $dt->day_name;      # "金曜日"（ロケールが 'en-US' なら "Friday"）
    $dt->month_0;       # 3（0-11）
    # エイリアス
    $dt->mon_0;
    $dt->month_abbr;    # "4月"（ロケールが 'en-US' なら "Apr"）
    $dt->month_name;    # "4月"（ロケールが 'en-US' なら "April"）
    $dt->quarter;       # 2（1-4）
    $dt->week;          # ( 2026, 15 )（$week_year, $week_number）
    $dt->week_number;   # 15（1-53）
    $dt->week_year;     # 2026（ISO 週年）

    $dt->epoch;         # 1775769030（Unix タイムスタンプ。整数）
    $dt->hires_epoch;   # 1775769030（浮動小数点 epoch。IEEE 754 double、約マイクロ秒精度）
    # hires_epochはIEEE 754 doubleにより、約マイクロ秒精度に制限される
    # 完全なナノ秒精度が必要な場合は、epoch() と nanosecond() を手動で組み合わせる:
    say sprintf "%d.%09d", $dt->epoch, $dt->nanosecond;  # 1775769030.000000005
    # または
    # use Math::BigFloat;
    # say Math::BigFloat->new( $dt->epoch ) + Math::BigFloat->new( $dt->nanosecond ) / 1_000_000_000
    # -> 1775769030.0000001
    $dt->jd;            # 2461140.38229167（ユリウス日）
    $dt->mjd;           # 61139.8822916667（修正ユリウス日）

    $dt->offset;                # 32400（UTC オフセット秒）
    $dt->time_zone;             # "Asia/Tokyo"（DateTime::Lite::TimeZone オブジェクト）
    $dt->time_zone_long_name;   # "Asia/Tokyo"
    $dt->time_zone_short_name;  # "JST"
    $dt->locale;                # ja-JP（DateTime::Locale::FromCLDR オブジェクト）
    $dt->is_dst;                # 1または0
    $dt->is_leap_year;          # 1または0
    $dt->is_finite;             # 通常のオブジェクトでは 1
    $dt->is_infinite;           # 通常のオブジェクトでは 0

    # 内部 Rata Die 表現
    my( $days, $secs, $ns ) = $dt->utc_rd_values;         # 739715, 76230, 0
    my $rd_secs             = $dt->utc_rd_as_seconds;     # 63911452230
    my( $ld, $ls, $lns )    = $dt->local_rd_values;       # 739716, 22230, 0
    my $local_secs          = $dt->local_rd_as_seconds;   # 63911484630
    my $utc_y               = $dt->utc_year;              # 2027

    # フォーマット
    $dt->iso8601;                        # "2026-04-10T06:10:30"
    # エイリアス
    $dt->datetime;
    $dt->ymd;                            # "2026-04-10"
    $dt->ymd('/');                       # "2026/04/10"
    $dt->hms;                            # "06:10:30"
    $dt->dmy('.');                       # "10.04.2026"
    $dt->mdy('-');                       # "10-04-2026"
    $dt->rfc3339;                        # "2026-04-10T06:10:30+09:00"
    $dt->strftime('%Y-%m-%d %H:%M:%S');  # "2026-04-10 06:10:30"
    $dt->format_cldr('yyyy/MM/dd');      # "2026/04/10"（Unicode CLDRパターン）
    "$dt";                               # iso8601（またはformatter）による文字列化

    # 日時演算
    $dt->add( years => 1, months  => 2, days    => 3,
              hours => 4, minutes => 5, seconds => 6 );
    $dt->subtract( weeks => 2 );

    my $dur = DateTime::Lite::Duration->new( months => 6 );
    $dt->add_duration( $dur );
    $dt->subtract_duration( $dur );

    my $diff     = $dt->subtract_datetime( $other );           # Duration
    my $abs_diff = $dt->subtract_datetime_absolute( $other );  # 時刻のみの Duration
    my $dd       = $dt->delta_days( $other );
    my $dmd      = $dt->delta_md( $other );
    my $dms      = $dt->delta_ms( $other );

    # ミューテータ
    $dt->set( year => 2027, month => 1, day => 1 );
    $dt->set_year(2027);
    $dt->set_month(1);
    $dt->set_day(1);
    $dt->set_hour(0);
    $dt->set_minute(0);
    $dt->set_second(0);
    $dt->set_nanosecond(0);
    $dt->set_time_zone('America/New_York');
    $dt->set_locale('en-US');  # 新しい DateTime::Locale::FromCLDR オブジェクトを設定
    $dt->set_formatter( $formatter );
    $dt->truncate( to => 'day' );   # 'year','month','week','day','hour','minute','second'

    # second, minute, hour, day, week, local_week, month, quarter,
    # year, decade, century に対応
    $dt->end_of( 'month' );
    say $dt;  # 2026-04-30T23:59:59.999999999
    $dt->start_of( 'month' );
    say $dt;  # 2026-04-01T00:00:00

    # 比較
    my @sorted = sort { $a <=> $b } @datetimes;  # オーバーロードされた <=>
    DateTime::Lite->compare( $dt1, $dt2 );       # -1, 0, 1
    DateTime::Lite->compare_ignore_floating( $dt1, $dt2 );
    $dt->is_between( $lower, $upper );

    # クラスレベルの設定
    DateTime::Lite->DefaultLocale('fr-FR');
    my $class = $dt->duration_class;  # 'DateTime::Lite::Duration'

    # 定数
    DateTime::Lite::INFINITY();        # +Inf
    DateTime::Lite::NEG_INFINITY();    # -Inf
    DateTime::Lite::NAN();             # NaN
    DateTime::Lite::MAX_NANOSECONDS(); # 1_000_000_000
    DateTime::Lite::SECONDS_PER_DAY(); # 86400

    # エラー処理
    my $dt2 = DateTime::Lite->new( %bad_args ) ||
        die( DateTime::Lite->error );
    # チェーン呼び出し:
    # 不正な呼び出しは NullObject を返すため、チェーンを安全に継続できる。
    # チェーンの最後の呼び出しの戻り値を確認すること。
    my $result = $dt->some_method->another_method ||
        die( $dt->error );

# VERSION

    v0.6.8

# DESCRIPTION

`DateTime::Lite`は、[DateTime](https://metacpan.org/pod/DateTime)の軽量かつメモリ効率の高いドロップイン代替モジュールです。主な設計目標は次のとおりです。

- 依存関係を少なくすること

    実行時の依存関係は、[DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone)（SQLiteに格納されたタイムゾーンデータを同梱し、[DBD::SQLite](https://metacpan.org/pod/DBD%3A%3ASQLite)が利用できない場合は[DateTime::TimeZone](https://metacpan.org/pod/DateTime%3A%3ATimeZone)へ自動的にフォールバック）、[DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR)（[Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData)のSQLiteバックエンド経由のロケールデータ）、[Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode)、およびコアモジュールに限定されています。

    重い[Specio](https://metacpan.org/pod/Specio)、[Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler)、[Try::Tiny](https://metacpan.org/pod/Try%3A%3ATiny)、`namespace::autoclean`は完全に排除されています。

- メモリ使用量を抑えること

    `DateTime`は多数のモジュールを連鎖的に読み込むため、`%INC`が大きく膨らみます。`DateTime::Lite`は、必要なものだけを遅延読み込みすることで、これを避けています。

- TZifバイナリから正確なタイムゾーンデータを得ること

    `DateTime::TimeZone`は、IANA Olsonの_source_ファイル（`africa`、`northamerica`など）を独自のテキストパーサ（`DateTime::TimeZone::OlsonDB`）で解析し、配布物のビルド時にタイムゾーンごとに`.pm`ファイルを事前生成します。これは、公式のIANAツールチェーンには含まれない追加の解析ステップを導入することになります。

    一方、`DateTime::Lite::TimeZone`はIANAのソースファイルを公式のIANAコンパイラである`zic(1)`でコンパイルし、その結果得られるTZifバイナリファイルを直接読み込みます。これは[RFC 9636](https://www.rfc-editor.org/rfc/rfc9636)（TZifバージョン1から4）に従います。タイムスタンプは符号付き64ビット整数として保存されるため、範囲はおよそ`+/-`2920億年になります。

    重要なのは、`EST5EDT,M3.2.0,M11.1.0`のように、すべてのTZif v2+ファイルに埋め込まれているPOSIXフッターのTZ文字列を抽出し、SQLiteデータベースに保存している点です。

    この文字列は、最後の明示的な遷移以降のすべての日付に対する、繰り返しの夏時間規則を表します。実行時には、`DateTime::Lite::TimeZone`がIANA`tzcode`の参照アルゴリズムをXSで実装したものを使って、このフッター規則を評価します（`dtl_posix.h`を参照。これは`tzcode2026a/localtime.c`に由来し、パブリックドメインです）。これにより、完全な遷移テーブルを将来にわたって展開しなくても、任意の将来日付について正しいタイムゾーン計算を行えます。

- XSによるホットパスの高速化

    XSレイヤーは、CPU負荷の高いすべてのカレンダー演算（`_rd2ymd`、`_ymd2rd`、`_seconds_as_components`、すべてのうるう秒関連ヘルパー）を担当します。さらに、元の実装にはなかった`_rd_to_epoch`、`_epoch_to_rd`、`_normalize_nanoseconds`、`_compare_rd`も追加されています。

- 互換性のあるAPI

    公開APIは可能な限り[DateTime](https://metacpan.org/pod/DateTime)に近づけているため、`DateTime`を使っている既存のコードは、`DateTime::Lite`をドロップイン代替として利用できるはずです。

- Unicode CLDR / BCP 47ロケールへの完全対応

    `DateTime`は、ロケールごとに事前生成された`DateTime::Locale::*`モジュールの集合に制限されています。`DateTime::Lite`は、有効なUnicode CLDR / BCP 47ロケールタグであれば、Unicode拡張（`-u-`）、変換拡張（`-t-`）、およびスクリプトサブタグを含む複雑な形式も受け付けます。

        my $dt = DateTime::Lite->now( locale => 'en' );    # 単純な形式
        my $dt = DateTime::Lite->now( locale => 'en-GB' ); # 単純な形式
        # より複雑な形式にも対応
        my $dt = DateTime::Lite->now( locale => 'he-IL-u-ca-hebrew-tz-jeruslm' );
        my $dt = DateTime::Lite->now( locale => 'ja-Kana-t-it' );
        my $dt = DateTime::Lite->now( locale => 'ar-SA-u-nu-latn' );

    ロケールデータは、[DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR)が[Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData)を通じて動的に解決します。そのため、`he-IL-u-ca-hebrew-tz-jeruslm`や`ja-Kana-t-it`のようなタグも、追加モジュールをインストールすることなく透過的に動作します。

    さらに、ロケールタグに[Unicode timezone extension](https://metacpan.org/pod/Locale%3A%3AUnicode#Unicode-extensions)（`-u-tz-`）が含まれており、かつコンストラクタに明示的な`time_zone`引数が渡されていない場合、`DateTime::Lite`はそこから対応するIANAの正規タイムゾーン名を自動的に解決します。

        # -u-tz-jeruslm 拡張から、time_zone はC<Asia/Jerusalem> と推定される
        my $dt = DateTime::Lite->now( locale => 'he-IL-u-ca-hebrew-tz-jeruslm' );
        say $dt->time_zone;            # Asia/Jerusalem
        say $dt->time_zone_long_name;  # Asia/Jerusalem

    明示的な`time_zone`引数は、常にロケール拡張より優先されます。

- 通常の処理ではdie()しないこと

    [Module::Generic](https://metacpan.org/pod/Module%3A%3AGeneric) / [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode)のエラー処理方針に従い、`DateTime::Lite`は通常のエラーパスで`die()`を呼び出しません。

    代わりに[DateTime::Lite::Exception](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)オブジェクトを設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。

    ただし、エラー時にこのモジュールを本当に`die`させたい場合は、オブジェクト生成時に真の値を持つ`fatal`オプションを渡すことができます。

# DateTimeとの既知の相違点

- バリデーション

    `DateTime`はコンストラクタのバリデーションに[Specio](https://metacpan.org/pod/Specio) / [Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler)を使用します。`DateTime::Lite`は同等のチェックを手動で行います。エラーメッセージは似ていますが、完全には同一ではありません。

- warnings::register の濫用なし

    `DateTime::Lite`は`warnings::enabled`を一貫して使用し、ユーザー向けの出力に`warnings::register`の仕組みへ依存しません。

# 未実装のメソッド

現時点ではありません。[DateTime](https://metacpan.org/pod/DateTime)APIに存在するメソッドで、このモジュールに不足しているものを見つけた場合は、報告してください。

# CONSTRUCTORS

## new

受け付けるパラメータは次のとおりです。

- `year`（必須）
- `month`
- `day`
- `hour`
- `minute`
- `second`
- `nanosecond`
- `time_zone`

    日時に使用するタイムゾーンです。次の形式を受け付けます。

    - `Asia/Tokyo`のようなゾーン名文字列、`+09:00`のような固定オフセット文字列、`UTC`、`floating`、または`local`。
    - [DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone)オブジェクト。
    - キーがそのまま["new" in DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone#new)に渡されるハッシュリファレンス。これにより、文字列形式では指定できないオプションを渡せます。たとえば、`JST`や`CET`のようなタイムゾーン略称を解決するための`extended => 1`、または座標に基づく解決のための`latitude` / `longitude`などです。

            time_zone => { name => 'JST', extended => 1 }
            time_zone => { latitude => 35.658558, longitude => 139.745504 }

    省略された場合で、`locale`引数に`he-IL-u-ca-hebrew-tz-jeruslm`のようなBCP47 `-u-tz-`拡張が含まれているときは、対応するIANAの正規タイムゾーンが自動的に解決されます。どちらも指定されていない場合は、デフォルトのfloatingタイムゾーンが使用されます（または`$ENV{PERL_DATETIME_DEFAULT_TZ}`が設定されていれば、その値が使用されます）。

- `locale`

    Unicode CLDR（Common Locale Data Repository）およびBCP47で定義される、有効な任意のロケールです。[Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode)を参照してください。

- `formatter`
- `fatal`

成功時には新しいオブジェクトを返します。失敗時には[error](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。チェーン呼び出し（オブジェクトコンテキスト）では、典型的な`Can't call method '%s' on an undefined value`を避けるため、ダミーオブジェクト（`DateTime::Lite::Null`）を返します。

## from\_day\_of\_year

    my $dt2 = DateTime::Lite->from_day_of_year(
        year        => 2026,
        day_of_year => 100,
        time_zone   => 'UTC',
        locale      => 'fr-FR',
    );

年と年内通算日（1-366）からオブジェクトを構築します。

成功時には新しいオブジェクトを返します。失敗時には[error](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。チェーン呼び出し（オブジェクトコンテキスト）では、典型的な`Can't call method '%s' on an undefined value`を避けるため、ダミーオブジェクト（`DateTime::Lite::Null`）を返します。

## from\_epoch

    my $dt = DateTime::Lite->from_epoch(
        epoch     => 1775769030,
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP',
        formatter => $formatter,
    );

ユニックスエポック値（整数または浮動小数点数）からオブジェクトを構築します。整数でない値は、最も近いマイクロ秒に丸められます。

`time_zone`、`locale`、`formatter`パラメータを受け付けます。

返されるオブジェクトは`UTC`タイムゾーンになります。

`time_zone`引数を指定した場合、それはオブジェクトの生成_後_に適用されます。したがって、渡されたエポック値は常にUTCタイムゾーンの値として設定されます。

例：

    my $dt = DateTime::Lite->from_epoch(
        epoch     => 0,
        time_zone => 'Asia/Tokyo'
    );
    say $dt; # Asia/TokyoはUTCから+09:00のため、1970-01-01T09:00:00を出力します。
    $dt->set_time_zone('UTC');
    say $dt; # 1970-01-01T00:00:00を出力します。

成功時には新しいオブジェクトを返します。失敗時には[error](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。チェーン呼び出し（オブジェクトコンテキスト）では、典型的な`Can't call method '%s' on an undefined value`を避けるため、ダミーオブジェクト（`DateTime::Lite::Null`）を返します。

## from\_object

    my $dt1 = DateTime->new;
    my $dt = DateTime::Lite->from_object(
        object    => $dt1,
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP'
    );

`utc_rd_values()`を実装している任意のオブジェクトを、`DateTime::Lite`インスタンスへ変換します。

成功時には新しいオブジェクトを返します。失敗時には[error](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。チェーン呼び出し（オブジェクトコンテキスト）では、典型的な`Can't call method '%s' on an undefined value`を避けるため、ダミーオブジェクト（`DateTime::Lite::Null`）を返します。

## last\_day\_of\_month

    my $dt = DateTime::Lite->last_day_of_month(
        year  => 2026,
        month => 4,
    );
    say $dt;  # 2026-04-30T00:00:00

    my $dt = DateTime::Lite->last_day_of_month(
        year      => 2026,
        month     => 4,
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP',
        hour      => 6,
        minute    => 10,
        second    => 30
    );
    say $dt;  # 2026-04-30T06:10:30

指定された月の最終日でオブジェクトを構築します。

成功時には新しいオブジェクトを返します。失敗時には[error](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。チェーン呼び出し（オブジェクトコンテキスト）では、典型的な`Can't call method '%s' on an undefined value`を避けるため、ダミーオブジェクト（`DateTime::Lite::Null`）を返します。

## now

    my $now = DateTime::Lite->now(
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP'
    );

    # -u-tz- BCP47 拡張から time_zone を推定します:
    my $now2 = DateTime::Lite->now( locale => 'he-IL-u-ca-hebrew-tz-jeruslm' );
    say $now2->time_zone;            # Asia/Jerusalem
    say $now2->time_zone_long_name;  # Asia/Jerusalem

現在の日時を返します（`from_epoch( epoch =` time )> を呼び出します）。

`time_zone`が省略され、`locale`に上記の例のようなBCP47 `-u-tz-`拡張が含まれている場合、タイムゾーンは自動的に推定されます。優先順位の詳細については["new"](#new)を参照してください。

成功時には新しいオブジェクトを返します。失敗時には[error](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。チェーン呼び出し（オブジェクトコンテキスト）では、典型的な`Can't call method '%s' on an undefined value`を避けるため、ダミーオブジェクト（`DateTime::Lite::Null`）を返します。

## today

    my $dt = DateTime::Lite->today(
        time_zone => 'Asia/Tokyo',
        locale    => 'ja-JP'
    );

現在の日付を、午前0時に切り詰めた状態で返します。

これは次と同等です。

    DateTime::Lite->now( @_ )->truncate( to => 'day' );

成功時には新しいオブジェクトを返します。失敗時には[error](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。チェーン呼び出し（オブジェクトコンテキスト）では、典型的な`Can't call method '%s' on an undefined value`を避けるため、ダミーオブジェクト（`DateTime::Lite::Null`）を返します。

## clone

    my $copy = $dt->clone;
    $copy->set_time_zone( 'Asia/Tokyo' );  # $dt には影響しません

呼び出し元オブジェクトの独立したディープコピーである、新しい`DateTime::Lite`オブジェクトを返します。すべてのスカラフィールドは複製され、ネストされたオブジェクト（`tz`および`locale`）も独立してコピーされるため、クローンを変更しても元のオブジェクトには影響しません。

# ACCESSORS

## year

    my $year = $dt->year;  # 例：2026

日時の年コンポーネントを返します。

## month

    my $m = $dt->month;  # 1..12

月を1（1月）から12（12月）までの数値として返します。

## mon

["month"](#month)のエイリアスです。

## day

    my $d = $dt->day;

月内の日（1-31）を返します。

## day\_of\_month

["day"](#day)のエイリアスです。

## hour

    my $h = $dt->hour;

時（0-23）を返します。

## minute

    my $min = $dt->minute;

分（0-59）を返します。

## second

    my $s = $dt->second;

日時の秒コンポーネントを返します。範囲は通常0-59ですが、例外的な場合には60または61になることがあります。

- `60`

    正の**うるう秒**です。IERS（International Earth Rotation and Reference Systems Service）は、原子時を地球の自転と同期させるため、UTC日の終わりに追加の1秒を挿入することがあります。その場合、時計は午前0時へ進む前に`23:59:60`を示します。1972年以降、すべてのうるう秒は正のうるう秒です（秒は追加されており、削除されたことはありません）。

- `61`

    POSIX標準により、仮想的な二重うるう秒のために予約されています。実際に発生したことはなく、極めて起こりにくいと考えられていますが、標準への完全な準拠のため、上限61は維持されています。

実際には、ほとんどすべての日時オブジェクトは常に`0..59`の値を返します。コンストラクタは61までの値を受け付け、それより大きい値に対してはエラーを返します。

## nanosecond

    my $ns = $dt->nanosecond;

秒未満のコンポーネントをナノ秒単位（0-999\_999\_999）で返します。

## day\_of\_week

    my $dow = $dt->day_of_week;  # 1=月曜 .. 7=日曜

ISO 8601の慣習に従い、曜日を1（月曜）から7（日曜）までの数値として返します。

## day\_of\_year

    my $doy = $dt->day_of_year;

年内通算日（1-366）を返します。

## day\_abbr

    my $abbr = $dt->day_abbr;  # 例: "Mon"

現在のロケールにおける曜日の省略名を返します。

## day\_name

    my $name = $dt->day_name;  # 例："Monday"

現在のロケールにおける曜日の完全名を返します。

## month\_0

    my $m0 = $dt->month_0;  # 0=1月 .. 11=12月

月を0起点の数値（0-11）として返します。

## mon\_0

["month\_0"](#month_0)のエイリアスです。

## month\_abbr

    my $abbr = $dt->month_abbr;  # 例: "Jan"

現在のロケールにおける月の省略名を返します。

## month\_name

    my $name = $dt->month_name;  # 例: "January"

現在のロケールにおける月の完全名を返します。

## week

    my( $wy, $wn ) = $dt->week;

ISO 8601の週番号に従い、2要素のリスト`( $week_year, $week_number )`を返します。

## week\_number

    my $wn = $dt->week_number;

ISO 8601の週番号（1-53）を返します。

## week\_year

    my $wy = $dt->week_year;

そのISO 8601週が属する年を返します。暦年の始まりまたは終わり付近の日付では、["year"](#year)と異なる場合があります。

## quarter

    my $q = $dt->quarter;

年の四半期（1-4）を返します。

## epoch

    my $ts = $dt->epoch;

Unixタイムスタンプ（1970-01-01T00:00:00UTCからの秒数）を整数として返します。

## hires\_epoch

    my $ts = $dt->hires_epoch;

秒未満の精度を含むUnixタイムスタンプを、浮動小数点数（IEEE 754 double）として返します。

**精度に関する注意:**64ビットdoubleは約15-16桁の有効10進数字しか持ちません。2026年頃のUnixタイムスタンプは整数部だけで既に10桁を消費するため、小数部には約6桁しか残りません。つまり、実効精度はマイクロ秒程度（約1µs）に制限され、数百ナノ秒未満の値は浮動小数点の丸めで失われます。

完全なナノ秒精度が必要な場合は、["epoch"](#epoch)と["nanosecond"](#nanosecond)を直接組み合わせてください。

    printf "%d.%09d\n", $dt->epoch, $dt->nanosecond;

## jd

    my $jd = $dt->jd;

ユリウス日を浮動小数点数として返します。

## mjd

    my $mjd = $dt->mjd;

修正ユリウス日（ユリウス日から2,400,000.5を引いた値）を返します。

## offset

    my $off = $dt->offset;

現在の日時におけるUTCオフセットを秒単位で返します。たとえば`+09:00`の場合は`32400`です。

## time\_zone

    my $tz = $dt->time_zone;

この日時に関連付けられた[DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone)オブジェクトを返します。

## time\_zone\_long\_name

    my $name = $dt->time_zone_long_name;

`America/New_York`のようなタイムゾーンの長い名前を返します。

## time\_zone\_short\_name

    my $abbr = $dt->time_zone_short_name;

この日時で有効なタイムゾーンの短い略称（例：`EST`または`EDT`）を返します。

## locale

    my $loc = $dt->locale;

この日時に関連付けられた[DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR)オブジェクトを返します。

## is\_leap\_year

    if( $dt->is_leap_year ) { ... }

この日時の年がうるう年であれば真を返します。

## is\_dst

    if( $dt->is_dst ) { ... }

この日時で夏時間が有効であれば真を返します。

## is\_finite

真を返します（無限ではないオブジェクトでは常に真）。無限の場合については[DateTime::Lite::Infinite](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AInfinite)を参照してください。

## is\_infinite

偽を返します（無限ではないオブジェクトでは常に偽）。

## stringify

    my $str = $dt->stringify;
    print "$dt";   # 同じこと

この日時の文字列表現を返します。["set\_formatter"](#set_formatter)によりformatterが設定されている場合は、`$formatter->format_datetime( $self )`に委譲します。それ以外の場合は["iso8601"](#iso8601)文字列を返します。

このメソッドは`""`オーバーロード演算子からも呼び出されます。

## utc\_rd\_values

    my( $days, $secs, $ns ) = $dt->utc_rd_values;

内部UTC Rata Die表現である3要素のリスト`( $utc_rd_days, $utc_rd_secs, $rd_nanosecs )`を返します。

## utc\_rd\_as\_seconds

    my $rd_secs = $dt->utc_rd_as_seconds;

内部UTC表現を単一の整数`utc_rd_days * 86400 + utc_rd_secs`として返します。

## utc\_year

    my $uy = $dt->utc_year;

UTCオフセットを計算する際に発生する循環依存を断ち切るため、`year + 1`で初期化された内部的な近似値を返します（タイムゾーンオフセットを調べるにはおおよその年が必要ですが、正確なUTC年を知るにはオフセットが必要です）。保存されている値は意図的に実際のUTC 年以上になるため、アプリケーションコードで直接使用するには**適していません**。実際のUTC年を取得するには、次のようにしてください。

    $dt->clone->set_time_zone('UTC')->year;

## local\_rd\_values

    my( $days, $secs, $ns ) = $dt->local_rd_values;

内部ローカル時刻Rata Die表現である3要素のリスト`( $local_rd_days, $local_rd_secs, $rd_nanosecs )`を返します。

## local\_rd\_as\_seconds

    my $rd_secs = $dt->local_rd_as_seconds;

内部ローカル時刻表現を単一の整数`local_rd_days * 86400 + local_rd_secs`として返します。

## duration\_class

    my $class = $dt->duration_class;

期間オブジェクトの構築に使用されるクラス名`DateTime::Lite::Duration`を返します。

## DefaultLocale

    # 現在のデフォルトを読み取る
    my $loc = DateTime::Lite->DefaultLocale;

    # デフォルトをフランス語に変更する
    DateTime::Lite->DefaultLocale( 'fr-FR' );

クラスメソッドです。明示的なロケールを指定せずに新しい`DateTime::Lite`オブジェクトを構築する際に使用されるデフォルトロケールを取得または設定します。

引数は、`en-US`、`ja-JP`、`fr-FR`、さらには`ja-Kana-t-it`や`he-IL-u-ca-hebrew-tz-jeruslm`のような、有効な[CLDRロケールタグ](https://metacpan.org/pod/Locale%3A%3AUnicode)でなければなりません。
初期デフォルトは`en-US`です。

# CONSTANTS

次の定数は、引数を取らないサブルーチンとしてエクスポートされます。内部で使用されますが、完全性のため公開されています。

## INFINITY

    use DateTime::Lite qw();
    my $inf = DateTime::Lite::INFINITY();

正の無限大（`100**100**100**100`）を返します。

## NEG\_INFINITY

    my $neg = DateTime::Lite::NEG_INFINITY();

負の無限大（`-INFINITY`）を返します。

## NAN

    my $nan = DateTime::Lite::NAN();

非数（Not-a-Number、`INFINITY - INFINITY`）を返します。

## MAX\_NANOSECONDS

    my $max_ns = DateTime::Lite::MAX_NANOSECONDS();

1秒に含まれるナノ秒数である`1_000_000_000`（10^9）を返します。

## SECONDS\_PER\_DAY

    my $spd = DateTime::Lite::SECONDS_PER_DAY();

1日に含まれる秒数である`86400`を返します（うるう秒は除きます）。

# フォーマット

## strftime( @patterns )

POSIX形式のフォーマットです。指定されたパターンに従って日時を文字列として返します。標準的なすべての`%x`指定子に加えて、任意の`DateTime::Lite`メソッド呼び出しに対応する`%{method_name}`、および秒未満の精度を指定する`%NNN`をサポートします。

以下のすべての例では、英国夏時間（UTC+1）の水曜日にあたる、次の参照日時を使用します。

    my $dt = DateTime::Lite->new(
        year       => 2026,
        month      => 7,
        day        => 15,
        hour       => 14,
        minute     => 30,
        second     => 45,
        nanosecond => 123456789,
        time_zone  => 'Europe/London',
        locale     => 'en-GB',
    );
    # 2026年7月15日 水曜日 14:30:45.123456789 BST (UTC+01:00)
    # 次で再現できます: $dt->strftime('%A %d %B %Y, %T.%N %Z (UTC%:z)');

次の`%x` トークンがサポートされています。

- `%a`

    曜日の省略名です。

        $dt->strftime('%a')  # "Wed"

- `%A`

    曜日の完全名です。

        $dt->strftime('%A')  # "Wednesday"

- `%b`

    月の省略名です。

        $dt->strftime('%b')  # "Jul"

- `%B`

    月の完全名です。

        $dt->strftime('%B')  # "July"

- `%c`

    オブジェクトのロケールにおけるデフォルトの日時形式です（`%a %b %e %H:%M:%S %Y`）。

        $dt->strftime('%c')  # "Wed Jul 15 14:30:45 2026"

- `%C`

    世紀番号（year/100）を2桁の整数として表します。

        $dt->strftime('%C')  # "20"

- `%d`

    月内の日を10進数で表します（範囲01から31）。

        $dt->strftime('%d')  # "15"

- `%D`

    `%m/%d/%y` と同等です。

        $dt->strftime('%D')  # "07/15/26"

- `%e`

    `%d` と同様ですが、先頭のゼロは空白に置き換えられます。

        $dt->strftime('%e')  # "15"

- `%E`

    曜日の省略名です（`%a` のエイリアス）。

        $dt->strftime('%E')  # "Wed"

- `%F`

    `%Y-%m-%d` と同等です（ISO 8601の日付形式）。

        $dt->strftime('%F')  # "2026-07-15"

- `%G`

    世紀を含む ISO 8601年を10進数として表します。

        $dt->strftime('%G')  # "2026"

- `%g`

    `%G` と同様ですが、世紀を含まない2桁の年です。

        $dt->strftime('%g')  # "26"

- `%h`

    `%b` と同等です（月の省略名）。

        $dt->strftime('%h')  # "Jul"

- `%H`

    24時間制の時を10進数で表します（範囲00から23）。

        $dt->strftime('%H')  # "14"

- `%I`

    12時間制の時を10進数で表します（範囲01から12）。

        $dt->strftime('%I')  # "02"

- `%j`

    年内通算日を10進数で表します（範囲001から366）。

        $dt->strftime('%j')  # "196"

- `%k`

    24時間制の時を10進数で表します（範囲0から23）。1桁の場合は前に空白が付きます。

        $dt->strftime('%k')  # "14"

- `%l`

    12時間制の時を10進数で表します（範囲1から12）。1桁の場合は前に空白が付きます。

        $dt->strftime('%l')  # " 2"

- `%m`

    月を10進数で表します（範囲01から12）。

        $dt->strftime('%m')  # "07"

- `%M`

    分を10進数で表します（範囲00から59）。

        $dt->strftime('%M')  # "30"

- `%n`

    改行文字です。

        $dt->strftime('date%ntime')  # "date\ntime"

- `%N`

    秒未満の桁です。デフォルトは9桁（ナノ秒）です。

        %3N   ミリ秒（3桁）
        %6N   マイクロ秒（6桁）
        %9N   ナノ秒（9桁）

- `%O`

    `Asia/Tokyo`や`Europe/London`のようなIANAタイムゾーン名です。

        $dt->strftime('%O')  # "Europe/London"

- `%p`

    指定された時刻値に応じた `AM`または`PM`です。

        $dt->strftime('%p')  # "PM"

- `%P`

    `%p` と同様ですが、小文字の`am`または`pm`です。

        $dt->strftime('%P')  # "pm"

- `%r`

    午前・午後表記の時刻です（`%I:%M:%S %p`）。

        $dt->strftime('%r')  # "02:30:45 PM"

- `%R`

    24時間表記の時刻です（`%H:%M`）。

        $dt->strftime('%R')  # "14:30"

- `%s`

    epoch からの秒数です。

        $dt->strftime('%s')  # "1784122245"

- `%S`

    秒を10進数で表します（範囲00から61）。

        $dt->strftime('%S')  # "45"

- `%t`

    タブ文字です。

        $dt->strftime('date%ttime')  # "date\ttime"

- `%T`

    24時間表記の時刻です（`%H:%M:%S`）。

        $dt->strftime('%T')  # "14:30:45"

- `%u`

    曜日を10進数で表します。範囲は1から7で、月曜日が1です。

        $dt->strftime('%u')  # "3"  （水曜日）

- `%U`

    現在の年の週番号です。最初の日曜日を週01の最初の日として数えます。

        $dt->strftime('%U')  # "28"

- `%V`

    現在の年のISO 8601:1988週番号です。

        $dt->strftime('%V')  # "29"

- `%w`

    曜日を10進数で表します。範囲は0から6で、日曜日が0です。

        $dt->strftime('%w')  # "3"  （水曜日）

- `%W`

    現在の年の週番号です。最初の月曜日を週01の最初の日として数えます。

        $dt->strftime('%W')  # "28"

- `%x`

    オブジェクトのロケールにおけるデフォルトの日付形式です。

        $dt->strftime('%x')  # "07/15/26"

- `%X`

    オブジェクトのロケールにおけるデフォルトの時刻形式です。

        $dt->strftime('%X')  # "14:30:45"

- `%y`

    世紀を含まない年を10進数で表します（範囲00から99）。

        $dt->strftime('%y')  # "26"

- `%Y`

    世紀を含む年を10進数で表します。

        $dt->strftime('%Y')  # "2026"

- `%z`

    UTCからの時差を時分形式で表したタイムゾーンです（例：`+0900`）。

        $dt->strftime('%z')  # "+0100"  （BST = UTC+1）

- `%Z`

    タイムゾーンの短い名前です（例：`JST`または`EST`）。

        $dt->strftime('%Z')  # "BST"

- `%%`

    リテラルの`%`文字です。

        $dt->strftime('100%%')  # "100%"

- `%{method}`

    `%{method}`形式を使って、任意のメソッド名を指定できます。ここで_method_は有効な`DateTime::Lite`オブジェクトメソッドです。

        $dt->strftime('%{quarter}')      # "3"
        $dt->strftime('%{day_of_year}')  # "196"

## format\_cldr( @patterns )

CLDR / Unicode の日付フォーマットパターンです（[DateTime](https://metacpan.org/pod/DateTime) で使われるものと同様）。標準的なすべてのCLDR記号をサポートします。

## iso8601

    my $str = $dt->iso8601;

`2026-04-09T12:34:56`のようなISO 8601文字列として日時を返します。

## datetime

["iso8601"](#iso8601)のエイリアスです。

## ymd( \[$sepr\] )

    my $date = $dt->ymd;          # "2026-04-09"
    my $date = $dt->ymd( '/' );   # "2026/04/09"

日付部分を`YYYY-MM-DD`として返します（デフォルトの区切り文字は`"-"`）。

## hms( \[$sep\] )

    my $time = $dt->hms;          # "12:34:56"
    my $time = $dt->hms( '.' );   # "12.34.56"

時刻部分を`HH:MM:SS`として返します（デフォルトの区切り文字は`":"`）。

## dmy( \[$sep\] )

    my $dmy = $dt->dmy;           # "09-04-2026"

日付を`DD-MM-YYYY`として返します。

## mdy( \[$sep\] )

    my $mdy = $dt->mdy;           # "04-09-2026"

日付を`MM-DD-YYYY`として返します。

## rfc3339

    my $str = $dt->rfc3339;       # "2026-04-09T12:34:56+09:00" 

RFC 3339文字列を返します。UTCの日時では、`Z`サフィックス付きの["iso8601"](#iso8601)と同じです。それ以外のタイムゾーンでは、数値オフセットを付加します。

# 算術演算

## add( %args )

    $dt->add( years => 1, months => 3 );
    $dt->add( hours => 2, minutes => 30 );

日時に期間をその場で加算します（`$self`を変更します）。["new" in DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration#new)と同じキーを受け付けます：`years`、`months`、`weeks`、`days`、`hours`、`minutes`、`seconds`、`nanoseconds`。

チェーン呼び出しを可能にするため、`$self`を返します。

## subtract( %args )

    $dt->subtract( days => 7 );

日時から期間をその場で減算します（`$self`を変更します）。すべての値を負にした`$dt->add`と同等です。

## add\_duration( $dur )

    my $dur = DateTime::Lite::Duration->new( months => 2 );
    $dt->add_duration( $dur );

[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)オブジェクトを日時にその場で加算します（`$self`を変更します）。

チェーン呼び出しを可能にするため、`$self`を返します。

## subtract\_duration( $dur )

    $dt->subtract_duration( $dur );

[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)オブジェクトを日時からその場で減算します（`$self`を変更します）。`$dt->add_duration( $dur->inverse )`と同等です。

## subtract\_datetime( $dt )

2つの`DateTime::Lite`オブジェクト間の差分を表す[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)を返します（カレンダーを考慮します）。

## subtract\_datetime\_absolute( $dt )

UTC上の絶対的な秒数 / ナノ秒数の差分を表す[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)を返します。

## delta\_days( $dt )

    my $dur = $dt1->delta_days( $dt2 );
    printf "%d days apart\n", $dur->days;

`$self`と`$dt`の間の完全な日数を表す`days`コンポーネントのみを含む[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)を返します。

## delta\_md( $dt )

    my $dur = $dt1->delta_md( $dt2 );

`months`と`days`コンポーネントを持つ[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)を返します（カレンダーを考慮した差分）。

## delta\_ms( $dt )

    my $dur = $dt1->delta_ms( $dt2 );

`minutes`と`seconds`コンポーネントを持つ[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)を返します（絶対的な時計上の差分）。

# セッター

## set

    $dt->set( hour => 0, minute => 0, second => 0 );

1つ以上の日時コンポーネントをその場で設定します。受け付けるキーは`year`、`month`、`day`、`hour`、`minute`、`second`、`nanosecond`のいずれかです。`$self`を返します。

## set\_year

    $dt->set_year(2030);

年コンポーネントを設定します。`$self`を返します。

## set\_month

    $dt->set_month(12);

月（1-12）を設定します。`$self`を返します。

## set\_day

    $dt->set_day(31);

月内の日を設定します。`$self`を返します。

## set\_hour

    $dt->set_hour(14);

時（0-23）を設定します。`$self`を返します。

## set\_minute

    $dt->set_minute(40);

分（0-59）を設定します。`$self`を返します。

## set\_second

    $dt->set_second(30);

秒を設定します（通常は0-59、うるう秒との互換性のため最大61まで）。`$self`を返します。

## set\_nanosecond

    $dt->set_nanosecond(1000);

ナノ秒コンポーネント（0-999\_999\_999）を設定します。`$self`を返します。

## set\_locale

    $dt->set_locale( 'zh-TW' );

ロケールを設定します。`fr-FR`のようなCLDRロケール文字列、または[DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR)オブジェクトを受け付けます。`$self`を返します。

## set\_formatter

    $dt->set_formatter( $my_formatter );

["stringify"](#stringify)で使用されるformatterオブジェクトを設定します。このオブジェクトは`format_datetime`に応答しなければなりません。デフォルトのISO 8601表現に戻すには`undef`を渡します。

## set\_time\_zone

    $dt->set_time_zone( 'Asia/Tokyo' );
    $dt->set_time_zone( $tz_object );  # DateTime::Lite::TimeZone オブジェクト
    $dt->set_time_zone( { name => 'JST', extended => 1 } );
    $dt->set_time_zone( { latitude => 35.658558, longitude => 139.745504 } );

日時のタイムゾーンをその場で変更します。`America/New_York`のようなタイムゾーン名文字列、[DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone)オブジェクト、またはキーがそのまま["new" in DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone#new)に渡されるハッシュリファレンスを受け付けます（`extended => 1`や座標に基づく解決などのオプションを指定できます）。`$self`を返します。

## end\_of

    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 15,
        hour      => 14,
        minute    => 32,
        second    => 47,
        time_zone => 'UTC',
    );
    $dt->end_of( 'month' );
    say $dt;  # 2026-04-30T23:59:59.999999999

指定された単位の最後の瞬間を表すように、オブジェクトをその場で変更します。
対応している単位は`second`、`minute`、`hour`、`day`、`week`、`local_week`、`month`、`quarter`、`year`、`decade`、`century`です。

結果は次の単位の開始直前の最後のナノ秒になります。そのため、タイムゾーンや月・年のような可変長単位も、境界値をハードコードすることなく正しく処理されます。

成功時には変更後のオブジェクトを返します。失敗時には[エラーオブジェクト](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。チェーン呼び出し（オブジェクトコンテキスト）では、典型的な`Can't call method '%s' on an undefined value`を避けるため、ダミーオブジェクト（`DateTime::Lite::Null`）を返します。

["start\_of"](#start_of) および ["truncate"](#truncate) も参照してください。

## start\_of

    my $dt = DateTime::Lite->new(
        year      => 2026,
        month     => 4,
        day       => 15,
        hour      => 14,
        minute    => 32,
        second    => 47,
        time_zone => 'UTC',
    );
    $dt->start_of( 'month' );
    say $dt;  # 2026-04-01T00:00:00

指定された単位の最初の瞬間を表すように、オブジェクトをその場で変更します。
対応している単位は`second`、`minute`、`hour`、`day`、`week`、`local_week`、`month`、`quarter`、`year`、`decade`、`century`です。

ほとんどの単位では["truncate"](#truncate)に委譲します。`decade`と`century`は独立して処理されます。2026年に対する`start_of('decade')`は2020-01-01を返し、`start_of('century')`は2001-01-01を返します。

成功時には変更後のオブジェクトを返します。失敗時には[エラーオブジェクト](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。チェーン呼び出し（オブジェクトコンテキスト）では、典型的な`Can't call method '%s' on an undefined value`を避けるため、ダミーオブジェクト（`DateTime::Lite::Null`）を返します。

["end\_of"](#end_of)および["truncate"](#truncate)も参照してください。

## truncate

    $dt->truncate( to => 'day' );   # h/m/s/ns をゼロに設定します

日時を指定された精度レベルまで切り詰めます。`to`に指定できる値は`year`、`month`、`week`、`local_week`、`day`、`hour`、`minute`、`second`です。

# 比較

## compare( $dt1, $dt2 )

クラスメソッドまたはインスタンスメソッドです。2つの`DateTime::Lite`オブジェクトを比較します。`$dt1`が早ければ-1、等しければ0、遅ければ1を返します。

XSレイヤーが読み込まれている場合は、高速パスであるXS`_compare_rd()`を使用します。

    my $cmp = DateTime::Lite->compare( $dt1, $dt2 );

オーバーロードされた`<=>`および`cmp`演算子経由でも使用できます。

    my @sorted = sort { $a <=> $b } @datetimes;

## compare\_ignore\_floating( $dt1, $dt2 )

["compare"](#compare)と同様ですが、floatingタイムゾーンの日時を、もう一方のオペランドと同じUTCオフセットを持つものとして扱います。タイムゾーンに関係なくローカルの壁時計時刻を比較したい場合に便利です。

## is\_between( $lower, $upper )

`$self`が2つの境界の厳密な間にある場合に真を返します。

## error

    my $dt = DateTime::Lite->new( %bad_args );
    if( !defined( $dt ) )
    {
        my $err = DateTime::Lite->error;
        warn "Error: $err";
    }

インスタンスメソッドおよびクラスメソッドです。メッセージ付きで呼び出された場合、[DateTime::Lite::Exception](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)オブジェクトを構築し、内部に保存します。そして`fatal`モードがオフなら警告し、オンなら`die`します。スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。

引数なしで呼び出された場合は、直近のエラーオブジェクトを返します（エラーが発生していない場合は `undef`）。

## pass\_error

    sub my_method
    {
        my $self = shift( @_ );
        my $tz = DateTime::Lite::TimeZone->new( name => 'Invalid' ) ||
            return( $self->pass_error );
        ...
    }

別のオブジェクト（またはクラスレベル）のエラーを、新しい例外を構築せずに、現在のオブジェクトのエラースロットへ伝播します。下位レベルの呼び出しが失敗し、呼び出し元が同じエラーを自分自身の呼び出し元へ表面化させたい場合に、内部で使用されます。

# 低レベル XS ユーティリティ

## posix\_tz\_lookup

    my $r = DateTime::Lite->posix_tz_lookup( 1775769030, 'EST5EDT,M3.2.0,M11.1.0' );
    my $r = $dt->posix_tz_lookup( 1775769030, 'EST5EDT,M3.2.0,M11.1.0' );
    if( defined( $r ) )
    {
        say $r->{offset};     # -14400  (UTC の東側を正とする秒数)
        say $r->{is_dst};     # 1
        say $r->{short_name}; # "EDT"
    }

Unixタイムスタンプ（1970-01-01T00:00:00 UTCからの秒数を表す符号付き64ビット整数）とPOSIX TZフッター文字列を受け取り、そのフッター文字列を解析して、指定されたUnixタイムスタンプに対するUTCオフセット、DSTフラグ、タイムゾーン略称を解決します。

これは、TZifデータベースに保存されている最後の明示的な遷移を超える日付を扱うために、[DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone)が内部で使用する低レベル関数です。

最初の引数はクラス名またはインスタンスのいずれでも構いません。どちらの形式も受け付けます。

POSIX TZフッター文字列はTZif v2+ファイルに由来し、`EST5EDT,M3.2.0,M11.1.0`、`JST-9`、`<+0545>-5:45` のような形式です。

実装は`dtl_posix.h`にあるCコードで、IANA`tzcode`の参照実装（パブリックドメイン）に由来します。すべてのPOSIX TZ文字列規則形式（`Jn`ユリウス日、`n`0起点ユリウス日、`Mm.w.d`月/週/曜日）に加えて、TZif v3+向けの[RFC 9636](https://www.rfc-editor.org/rfc/rfc9636.html)拡張にも対応します。

- `Jn`

    ユリウス日（1-365、うるう日は含めません）

- `n`

    0起点のユリウス日（0-365、うるう日を数えます）

- `Mm.w.d`

    月/週/曜日規則（例：`M3.2.0` = 3月の第2日曜日）

また、`<+0545>`のような山括弧で引用された略称、小数オフセット、負の遷移時刻および24時間を超える遷移時刻（TZif v3+向けの[RFC 9636 section 3.3.2](https://www.rfc-editor.org/rfc/rfc9636.html#name-tz-string-extension)拡張）、およびDST期間が年境界をまたぐ南半球のDST（start > end）にも対応します。

成功時には3つのキーを持つハッシュリファレンスを返します。

- `offset`

    UTCの東側を正とするUTCオフセット秒数です（ESTの`-18000`のように、UTCの西側のゾーンでは負になります）。

- `is_dst`

    タイムスタンプがDST期間内にある場合は`1`、そうでない場合は`0`です。

- `short_name`

    `EDT`、`JST`、`+0545` のようなタイムゾーン略称です。

`$tz_string` を解析できない場合は`undef`を返します。

このメソッドは主に、`DateTime::Lite::TimeZone`の上に独自のタイムゾーンライブラリを構築するような高度なユースケースを想定しています。ほとんどのユーザーが直接呼び出す必要はありません。

# シリアライズ

`STORABLE_freeze`と`STORABLE_thaw`が実装されており、[Storable](https://metacpan.org/pod/Storable)と互換性があります。

`FREEZE`と`THAW`も実装されており、[Sereal](https://metacpan.org/pod/Sereal)または[CBOR](https://metacpan.org/pod/CBOR)と互換性があります。

# エラー処理

エラー時、このクラスのメソッドは[例外オブジェクト](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)を設定し、スカラコンテキストでは`undef`、リストコンテキストでは空リストを返します。例外オブジェクトには次のようにアクセスできます。

    my $err = DateTime::Lite->error;   # クラスメソッド
    my $err = $dt->error;              # インスタンスメソッド

例外オブジェクトは、ファイル名と行番号を含む、人間が読めるメッセージへ文字列化されます。

`error`は、コンテキストがチェーン呼び出し、またはオブジェクトコンテキストであることを検出します。その場合、`undef`を返す代わりに`DateTime::Lite::Null`のダミーインスタンスを返し、典型的なPerlエラー`Can't call method '%s' on an undefined value`を避けます。

たとえば次のような場合です。

    $dt->now( %bad_arguments )->subtract( %params );

`now`でエラーが発生していた場合でも、チェーンは実行されます。しかし、この例では最後の`subtract`が`undef`を返すため、戻り値を確認できますし、確認すべきです。

    $dt->now( %bad_arguments )->subtract( %params ) ||
        die( $dt->error );

# パフォーマンス

このセクションでは、`DateTime::Lite`と参照実装である[DateTime](https://metacpan.org/pod/DateTime)1.66を、モジュールのフットプリント、読み込み時間、メモリ、CPUスループットの4つの観点から比較します。以下の数値は、Perl 5.36.1を実行する`aarch64`マシン上で記録されたものです。自分の環境で再現するには、この配布物に含まれる`scripts/benchmark.pl`を実行してください。

この比較の目的は、成熟しており、機能が充実し、実戦で十分に鍛えられたライブラリである[DateTime](https://metacpan.org/pod/DateTime)を貶めることではありません。むしろ、利用する状況に応じて適切なツールを選べるよう、トレードオフを明確にすることです。

## モジュールフットプリント

`use DateTime`または`use DateTime::Lite`が評価されたときに、依存関係を通じて直接・間接に`%INC`へ読み込まれるファイル数です。

                          DateTime 1.66   DateTime::Lite
    -------               -------------   --------------
    use Module                      137               67
    TimeZone class alone            105               47
    Runtime prereqs (META)           23               11

`DateTime`は[Specio](https://metacpan.org/pod/Specio)、[Params::ValidationCompiler](https://metacpan.org/pod/Params%3A%3AValidationCompiler)、[namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)、および複数の補助モジュールに依存しており、これらが追加のオーバーヘッドの主な要因になっています。`DateTime::Lite`は、このバリデーション層を軽量な手書きチェックに置き換え、より重い[DateTime::Locale](https://metacpan.org/pod/DateTime%3A%3ALocale)スタックの代わりに[DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR)を使用します。

`DateTime::TimeZone`が105個のモジュールを読み込むのは、`DateTime::TimeZone::America::New_York`のようにIANAゾーンごとに1つの`.pm`ファイルを同梱しており、それらが最初の`new()`呼び出し時に読み込まれるためです。`DateTime::Lite::TimeZone`は、直接・間接を含めて47個のモジュールを読み込み、すべてのゾーンデータを単一のSQLiteファイルに格納します。

## 読み込み時間

まだ`%INC`に読み込まれていない状態で、`require`の前後を`time()`で測定したものです。

                               DateTime 1.66   DateTime::Lite
    -------                    -------------   --------------
    require Module                     48 ms            32 ms
    require TimeZone standalone       180 ms           100 ms

起動時間は、cronジョブ、CLIツール、CGIのような短命なスクリプトでは重要です。プロセス初期化が総実行時間の大きな割合を占めるためです。一方、長時間稼働するApache2/mod\_perl2、Plack、Mojoliciousサービスでは、このコストは一度だけ支払われ、その後は数百万リクエストにわたって償却されます。

## メモリ（読み込み後の RSS）

クリーンなPerlプロセスで`use Module`直後に測定した値です。

                          DateTime 1.66   DateTime::Lite
    -------               -------------   --------------
    use Module (~28 MB)        ~28 MB           ~37 MB
    TimeZone class only        ~19 MB           ~16 MB

`use Module`の行だけを見ると、やや誤解を招きます。`DateTime::Lite`は`DBD::SQLite`を読み込みますが、これは作成するタイムゾーンオブジェクトの数に関係なく、完全にコンパイル済みのSQLiteエンジン（ネイティブコード約14MB）を含んでいるためです。日付演算を実際に扱うコンポーネントである`TimeZone`クラス単体で測定すると、`DateTime::Lite::TimeZone`の方が軽量です（約16MB 対 約19MB）。これは、すべてのOlsonゾーンデータをRAMに事前読み込みしないためです。

`DateTime::TimeZone`は、最初の`new()`呼び出し時にすべてのIANAOlson定義をメモリへ事前読み込みします（モジュール自体のオーバーヘッドに加えて、コンパイル済みPerl構造体としておよそ3-4MB）。`DateTime::Lite::TimeZone`は、コンパクトなSQLiteデータベースを必要に応じて問い合わせ、それらの構造をディスク上に保持します。

## CPUスループット（10,000回反復、1呼び出しあたりµs）

                                        DateTime 1.66   DateTime::Lite
    -------                             -------------   --------------
    new( UTC )                                 ~13 µs          ~10 µs
    new( named zone, string )                  ~25 µs          ~64 µs  (*)
    new( named zone, all caches enabled )      ~25 µs          ~14 µs
    now( UTC )                                 ~11 µs          ~10 µs
    year + month + day + epoch                ~0.5 µs         ~0.4 µs
    clone + add( days + hours )                ~35 µs          ~25 µs
    strftime                                  ~3.5 µs         ~3.6 µs
    TimeZone->new (warm, no mem cache)          ~2 µs          ~19 µs  (*)
    TimeZone->new (mem cache enabled)           ~2 µs         ~0.4 µs

`(*)`が付いた行は、メモリキャッシュを使わないデフォルト動作を反映しています。
`DateTime::Lite::TimeZone->enable_mem_cache`を有効にすると、`TimeZone-`new>は約0.4µsまで下がり、`new(named zone)`は約14µsまで下がります。これは`DateTime`（約25µs）より高速です。詳細な説明は["TimeZone キャッシュモデル"](#timezone-キャッシュモデル)を参照してください。

UTCでの構築、`now()`、アクセサ、算術演算、フォーマットについては、`DateTime::Lite`は同等または高速です。算術演算での向上は、XSで高速化されたcloneと、より軽量なバリデーション層によるものです。

## TimeZone キャッシュモデル

これは理解すべき最も重要なトレードオフです。

**DateTime::TimeZone**は、名前付きゾーンが初めて構築された時点で、IANAタイムゾーン規則一式をRAMに読み込みます（起動約180ms、メモリ上のハッシュ構造約4MB）。その後の`DateTime::TimeZone->new( name => $name )`呼び出しは、すべてそのハッシュから約4µsで処理されます。長時間稼働するプロセスで、1秒あたり何千もの`DateTime`オブジェクトを構築する場合、このモデルは初期ウォームアップ後には非常に高速です。

**DateTime::Lite::TimeZone**は、同じIANAデータをコンパクトなSQLiteデータベース（配布物に含まれる`tz.sqlite3`）に格納します。あるゾーン名に対する最初の呼び出しではクエリが実行され（約22ms）、インスタンスごとのキャッシュが作成されます。同じゾーンに対する以後の呼び出しでは、キャッシュ済みの`DBD::SQLite` prepared statementが使われ、約130µsで返ります。デフォルトではプロセス全体のsingletonは存在しないため、同じ名前で2回呼び出すと、それぞれ130µsのコストが発生します。

**任意のメモリキャッシュ:**`DateTime::Lite::TimeZone`は、プロセスレベルのメモリキャッシュもopt-inで提供します。これにより、呼び出しごとの速度は`DateTime::TimeZone`と同等、またはそれ以上になります。

    # アプリケーション起動時に一度だけ有効化します:
    DateTime::Lite::TimeZone->enable_mem_cache;

    # または呼び出しごとに指定します:
    my $tz = DateTime::Lite::TimeZone->new(
        name          => 'America/New_York',
        use_cache_mem => 1,
    );

メモリキャッシュが有効な場合、同じゾーンに対する繰り返しの`new()`呼び出しは、単純なハッシュ参照からキャッシュ済みオブジェクトを返し、約0.8µsで完了します。

                              DateTime::TimeZone   DateTime::Lite::TimeZone
    ------                    -----------------   ------------------------
    Cold first call                    ~225 ms                      ~22 ms
    Warm (no mem cache)                  ~2 µs                      ~19 µs
    Warm (mem cache only)                ~2 µs                      ~0.4 µs
    Warm (mem+span+footer cache)         ~2 µs                      ~0.4 µs
    new(named zone, all caches)         ~25 µs                      ~14 µs

実用上の指針:

- 名前付きゾーンを持つdatetimeオブジェクトを構築する長時間稼働サービスでは、起動時に一度`DateTime::Lite::TimeZone->enable_mem_cache`を呼び出してください。
これにより、3層のキャッシュが有効になります。

    - 1. オブジェクトキャッシュ（SQLite構築を回避します）。
    - 2. spanキャッシュ（UTCオフセットクエリを回避します）。
    - 3. footerキャッシュ（POSIX DST規則計算を回避します）。

    すべての層が準備完了してから、`new(named zone)`のコストは約14µsで、`DateTime`（約25µs）より高速です。

- 明示的な制御を好む場合は、個々の`new()`呼び出しごとに`use_cache_mem => 1`を渡すか、1つの`TimeZone`オブジェクトを構築して再利用してください。

        my $tz = DateTime::Lite::TimeZone->new( name => 'America/New_York' );
        my $dt = DateTime::Lite->new( ..., time_zone => $tz );

- バッチ処理（ログ解析、ETL、レポート生成）では、タイムゾーン構築は総I/O時間のごく一部であることが多いため、どの選択肢を選んでも差は体感できません。
- 短命なスクリプトやコマンドラインツールでは、`DateTime::Lite`は起動時間（約120ms 対 約320ms）とメモリ（約19MB 対 約28MB）の両方で有利です。

## ベンチマークの実行

自己完結したベンチマークスクリプトが配布物に含まれています。

    cd DateTime-Lite-vX.X.X
    perl Makefile.PL && make  # XS コードがコンパイルされていることを確認します
    perl -Iblib/lib -Iblib/arch scripts/benchmark.pl

    # より安定した数値を得るために反復回数を増やす:
    perl -Iblib/lib -Iblib/arch scripts/benchmark.pl --iterations 50000

    # 機械可読な CSV 出力:
    perl -Iblib/lib -Iblib/arch scripts/benchmark.pl --csv > results.csv

# 使用方法

## 0起点の数値と1起点の数値

`DateTime::Lite`は、0起点と1起点の数値について単純な規則に従います。

月、月内の日、曜日、年内通算日は**1起点**です。すべての1起点メソッドには`_0`版もあります。たとえば、`day_of_week`は1（月曜日）から7（日曜日）までを返しますが、`day_of_week_0`は0から6までを返します。

すべての_時刻_関連の値（時、分、秒）は**0起点**です。

年はどちらでもありません。正の値にも負の値にもなり得ます。年0も存在します。

`quarter_0`メソッドはありません。

## Floating DateTimes（タイムゾーン非固定の日時）

新しい`DateTime::Lite`オブジェクトのデフォルトタイムゾーンは、特に明記されていない限り、`floating`タイムゾーンです。この概念はiCal標準に由来します。floating datetimeは特定のタイムゾーンに固定されておらず、うるう秒も含みません。うるう秒を適用するには実際のタイムゾーンが必要だからです。

floating datetimeと実際のタイムゾーンを持つdatetimeの間で日付計算や比較を行うと、結果の妥当性は限定的になります。一方はうるう秒を含み、もう一方は含まないためです。

実際のタイムゾーンを持つオブジェクトを使用する予定がある場合は、floating datetimeと混在させないことを**強く推奨します**。

## ローカルタイムゾーンの判定は遅い場合があります

`$ENV{TZ}`が設定されていない場合、ローカルタイムゾーンの検索には`/etc`以下の複数のファイルを読む必要があることがあります。プログラムの実行中にローカルタイムゾーンが変わらないことが分かっており、そのゾーンのオブジェクトを多数必要とする場合は、一度だけキャッシュしてください。

    my $local_tz = DateTime::Lite::TimeZone->new( name => 'local' );

    my $dt = DateTime::Lite->new( ..., time_zone => $local_tz );

`DateTime::Lite::TimeZone`は、このコストを完全に取り除くプロセスレベルのキャッシュも提供しています。

    DateTime::Lite::TimeZone->enable_mem_cache;
    my $dt = DateTime::Lite->new( ..., time_zone => 'local' );

## 遠い将来の DST

現在から数千年後のような非常に遠い将来の日付では、名前付きタイムゾーンを使う`DateTime`は大量のメモリを消費することがあります。これは`DateTime::TimeZone`が、現在からその日付までのすべてのDST遷移を事前計算するためです。

`DateTime::Lite`はこの問題の影響を受けません。`DateTime::Lite::TimeZone`は、コンパクトなSQLiteデータベースとPOSIX footer TZ文字列を使用して、完全な遷移テーブルを展開することなく、任意の将来の日付に対する正しいオフセットを導出します。

## デフォルトタイムゾーンをグローバルに設定する

**警告: これは非常に危険です。自己責任で使用してください。**

次のように設定することで、`DateTime::Lite`に特定のデフォルトタイムゾーンを強制できます。

    $ENV{PERL_DATETIME_DEFAULT_TZ} = 'America/New_York';

これは、使用しているCPANモジュールを含め、`DateTime::Lite`オブジェクトを作成するすべてのコードに影響します。本番環境で使用する前に、依存関係を監査してください。

## 上限と下限

内部的には、日付は`0001-01-01`の前後の日数として保存され、Perl整数に保持されます。利用可能な範囲は、プラットフォームの整数サイズ（`$Config{ivsize}`）に依存します。

- **32ビットPerl:**およそ`+/-1,469,903`年
- **64ビットPerl:**およそ`+/-12,626,367,463,883,278`年

## オーバーロード

`DateTime::Lite`は次の演算子をオーバーロードします。

- **`+`** - [DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)をdatetimeに加算し、新しいdatetimeを返します。
- **`-`** - durationをdatetimeから減算して新しいdatetimeを返すか、2つのdatetimeを減算して[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)を返します。
- **`<=>`および**`cmp`**** - `sort`や比較演算子で使用するための数値比較および文字列比較です。
- **`""`**（文字列化）- [stringify](#stringify)を呼び出します。formatterが設定されていればそれに委譲し、そうでなければ[iso8601](#iso8601)文字列を返します。
- **`bool`** - 有限オブジェクトでは常に真です。

`fallback`パラメータが設定されているため、派生演算子（`+=`、`-=`など）は期待通りに動作します。`++`や`--`が有用であるとは期待しないでください。

    my $dt2 = $dt + $duration;  # 新しい datetime
    my $dt3 = $dt - $duration;  # 新しい datetime
    my $dur = $dt - $other_dt;  # Duration

    for my $dt ( sort @datetimes ) { ... }  # <=> を使用します

## Formatterと文字列化

datetimeの文字列化方法を制御するために、`formatter`オブジェクトを指定できます。
どのコンストラクタでも`formatter`引数を受け付けます。

    my $fmt = DateTime::Format::Unicode->new( locale => 'fr-FR' );
    my $dt  = DateTime::Lite->new( year => 2026, formatter => $fmt );

または、後から設定することもできます。

    $dt->set_formatter( $fmt );
    my $current_fmt = $dt->formatter;

一度設定すると、`$dt`は[iso8601](#iso8601)の代わりに`$fmt->format_datetime($dt)`を呼び出します。デフォルトに戻すには`undef`を渡してください。

formatterは`format_datetime($dt)`メソッドを実装していなければなりません。[DateTime::Format::Unicode](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AUnicode) モジュール（CPANで別途利用可能）は、日付/時刻期間や、[format\_cldr](#format_cldr)では扱わない追加のパターントークンに対応した、フル機能のCLDRformatterを提供します。

# CLDR パターン

CLDR（Unicode Common Locale Data Repository）のパターン言語は、strftimeよりも強力で、より複雑です。strftimeと異なり、パターンは接頭辞なしの通常の文字で表されるため、リテラルテキストは引用符で囲む必要があります。

## クォートとエスケープ

リテラルのASCII文字はシングルクォート（`'`）で囲みます。リテラルのシングルクォートを含めるには、連続する2つのシングルクォート（`''`）を書きます。空白および文字ではない記号は、常にそのまま通されます。

    my $p1 = q{'Today is ' EEEE};           # "Today is Thursday"
    my $p2 = q{'It is now' h 'o''clock' a}; # "It is now 9 o'clock AM"

## パターン長とパディング

ほとんどのパターンでは、指定子が1文字より長い場合、先頭ゼロでパディングされます。たとえば、`h`は`9`を返しますが、`hh`は`09`を返します。例外として、同じ文字が**5個**並ぶ場合は、多くの場合narrow形式を意味します。たとえば`EEEEE`は木曜日に対して`T`を返し、5文字幅の値を返すわけではありません。

## format 形式と stand-alone 形式

多くのトークンには_format_形式（より大きな文字列の中で使われる形式）と_stand-alone_形式（カレンダーのヘッダーなど、単独で使われる形式）があります。これらは大文字小文字で区別されます。月では`M`がformat、`L`がstand-aloneです。曜日では`E` / `e`がformat、`c`がstand-aloneです。

## トークンリファレンス

    Era
      G{1,3}   eraの省略形（BC, AD）
      GGGG     eraのwide形式（Before Christ, Anno Domini）
      GGGGG    eraのnarrow形式

    Year
      y        年。必要に応じてゼロ埋めされます
      yy       2桁の年（特別扱い）
      Y{1,}    週年カレンダーの年（week_year由来）
      u{1,}    yと同じですが、yyは特別扱いされません

    Quarter
      Q{1,2}   四半期を数値で表します（1-4）
      QQQ      format四半期の省略形
      QQQQ     format四半期のwide形式
      q{1,2}   四半期を数値で表します（stand-alone）
      qqq      stand-alone四半期の省略形
      qqqq     stand-alone四半期のwide形式

    Month
      M{1,2}   数値の月（format）
      MMM      format月名の省略形
      MMMM     format月名のwide形式
      MMMMM    format月名のnarrow形式
      L{1,2}   数値の月（stand-alone）
      LLL      stand-alone月名の省略形
      LLLL     stand-alone月名のwide形式
      LLLLL    stand-alone月名のnarrow形式

    Week
      w{1,2}   年内の週（week_number由来）
      W        月内の週（week_of_month由来）

    Day
      d{1,2}   月内の日
      D{1,3}   年内通算日
      F        月内の第何曜日か（weekday_of_month由来）
      g{1,}    修正ユリウス日（mjd由来）

    Weekday
      E{1,3}   format曜日の省略形
      EEEE     format曜日のwide形式
      EEEEE    format 曜日のnarrow形式
      e{1,2}   ロケール基準の数値曜日（1 = そのロケールにおける週の最初の日）
      eee      format曜日の省略形（E{1,3}と同じ）
      eeee     format曜日のwide形式
      eeeee    format曜日のnarrow形式
      c        数値曜日。月曜日 = 1（stand-alone）
      ccc      stand-alone 曜日の省略形
      cccc     stand-alone 曜日のwide形式
      ccccc    stand-alone 曜日のnarrow形式

    Period
      a        AMまたはPM（ローカライズ済み）

    Hour
      h{1,2}   1-12 時制の時
      H{1,2}   0-23 時制の時
      K{1,2}   0-11 時制の時
      k{1,2}   1-24 時制の時
      j{1,2}   ロケールで推奨される時制（12時間制または24時間制）

    Minute / Second
      m{1,2}   分
      s{1,2}   秒
      S{1,}    秒未満の桁（小数点なし）
      A{1,}    1日内のミリ秒

    Time zone
      z{1,3}   短いタイムゾーン名
      zzzz     長いタイムゾーン名
      Z{1,3}   タイムゾーンオフセット（例: -0500）
      ZZZZ     短い名前 + オフセット（例: CDT-0500）
      ZZZZZ    sexagesimal オフセット（例: -05:00）
      v{1,3}   短いタイムゾーン名
      vvvv     長いタイムゾーン名
      V{1,3}   短いタイムゾーン名
      VVVV     長いタイムゾーン名

次のトークンは`format_cldr()`では**サポートされていません**が、[DateTime::Format::Unicode](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AUnicode)ではサポートされています。

- `b` / `B` - day periodおよびflexible day period（`noon`、`at night` など）
- `O` / `OOOO` - ローカライズされたGMT形式（`GMT-8`、`GMT-08:00`）
- `r` - 関連するグレゴリオ暦年
- `x` / `X` - 任意の`Z`を伴うISO 8601タイムゾーンオフセット

## CLDR available formats

CLDRデータには、ロケール固有の事前定義フォーマットskeletonが含まれています。skeletonは、ロケールに適した描画パターンへ対応付けられるパターンキーです。たとえば、skeleton`MMMd`は`en-US`では`MMM d`に対応し（`Apr 9`になります）、`fr-FR`では`d MMM`に対応します（`9 avr.`になります）。

ロケール固有のパターンをlocaleオブジェクトから取得し、それを`format_cldr`に渡してください。

    say $dt->format_cldr( $dt->locale->available_format('MMMd') );
    say $dt->format_cldr( $dt->locale->available_format('yQQQ') );
    say $dt->format_cldr( $dt->locale->available_format('hm') );

任意のロケールで利用可能なskeletonの完全な一覧については、["available\_formats" in DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR#available_formats)を参照してください。

## DateTime::Format::Unicode

`format_cldr()`では扱わない機能を含む、より高度なフォーマットには、[DateTime::Format::Unicode](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AUnicode)（CPANで別途利用可能）を使用してください。これは次を提供します。

- 上記の追加トークン（`b`、`B`、`O`、`r`、`x`、`X`）のサポート
- `"Apr 9 - 12, 2026"`のようなdatetime**interval**のフォーマット
- CLDR 数字体系の完全サポート（アラビア・インド数字など）
- `es-419-u-ca-gregory`のような複雑なタグを含む任意のCLDRロケール

    use DateTime::Format::Unicode;

    my $fmt = DateTime::Format::Unicode->new(
        locale  => 'ja-JP',
        pattern => 'GGGGy年M月d日（EEEE）',
    ) || die( DateTime::Format::Unicode->error );

    say $fmt->format_datetime( $dt );

    # Interval formatting:
    my $fmt2 = DateTime::Format::Unicode->new(
        locale  => 'en',
        pattern => 'GyMMMd',
    );
    say $fmt2->format_interval( $dt1, $dt2 );  # 例: "Apr 9 - 12, 2026"

# DateTimeの計算の仕組み

`DateTime::Lite`における日付計算は、[DateTime](https://metacpan.org/pod/DateTime)と同じモデルに従います。重要な違いは、_カレンダー単位_（月、日）と_時計単位_（分、秒、ナノ秒）の区別です。この区別を理解することは、正しい結果を得るために不可欠です。

## duration のバケット

[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)は、そのコンポーネントを5つの独立した_バケット_に保存します：months、days、minutes、seconds、nanosecondsです。各バケットは符号付き整数として保持されます。バケット同士は互いに**正規化されません**。たとえば`{ months => 1, days => 31 }`という期間は、`{ months => 2, days => 0 }`とは別物です。月の日数は一定ではないためです。

## カレンダー単位と時計単位

_カレンダー単位_（月、日）は相対的です。実際の長さは、それが適用されるdatetimeに依存します。_時計単位_（分、秒、ナノ秒）は絶対的です。

[add](#add)が期間を適用する際には、まずカレンダー単位が適用され、その後に時計単位が適用されます。

    $dt->add( months => 1, hours => 2 );
    # Step 1: 1か月進める（カレンダー）
    # Step 2: 2時間進める（時計）

## 月末処理

対象月の末日を超える日付に対して月を加算する場合、方針を決める必要があります。[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)は3つの`end_of_month`モードをサポートします。

- `wrap`（デフォルト）-　次の月へ繰り越します。1月31日 + 1か月 = 3月3日（うるう年では3月2日）です。
- `limit` - 対象月の最終日に丸めます。1月31日 + 1か月 = 2月28日（うるう年では2月29日）です。
- `preserve` - `limit` と同様ですが、元の日付が月末だったことを記憶するため、さらに1か月加算した場合も月末になります。

## 減算

`$dt1->subtract_datetime( $dt2 )`は、差分を表す期間を返します。カレンダー部分はローカル日付からmonthsとdaysとして計算され、時計部分はUTC表現からsecondsとnanosecondsとして計算されます。これは最も一般的に有用な結果です。

`$dt1->subtract_datetime_absolute( $dt2 )`は、UTCエポック差分に基づき、純粋な時計単位（secondsとnanoseconds）のdurationを返します。DSTの変化に依存しない正確な経過時間が必要な場合に有用です。

## うるう秒

`DateTime::Lite`は、タイムゾーンがfloatingでない場合、うるう秒を扱います。
時計単位の期間をうるう秒境界をまたいで加算すると、追加の1秒が正しく考慮されます。

# SEE ALSO

[DateTime](https://metacpan.org/pod/DateTime)、[DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration)、[DateTime::Lite::Exception](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AException)、[DateTime::Lite::Infinite](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3AInfinite)、[DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR)、[Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData)、[DateTime::Format::Unicode](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AUnicode)

# CREDITS

[DateTime](https://metacpan.org/pod/DateTime)の元の作者であるDave Rolsky氏、およびすべての貢献者の素晴らしい仕事に謝意を表します。本モジュール[DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite)は、その成果を基に派生しています。

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
