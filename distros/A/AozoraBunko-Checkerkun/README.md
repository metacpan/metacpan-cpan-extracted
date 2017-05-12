# NAME

AozoraBunko::Checkerkun - 青空文庫の工作員のための文字チェッカー（作：結城浩）をライブラリ化したもの

# SYNOPSIS

    use AozoraBunko::Checkerkun;
    use utf8;

    my $checker1 = AozoraBunko::Checkerkun->new;
    $checker1->check('森※［＃「區＋鳥」、第3水準1-94-69］外💓'); # => '森※［＃「區＋鳥」、第3水準1-94-69］→[78hosetsu_tekiyo]【鴎】外💓[gaiji]'
    $checker1->check('森鷗外'); # => '森鷗[gaiji]外'
    $checker1->check('森鴎外'); # => '森鴎外'

    my $checker2 = AozoraBunko::Checkerkun->new({ output_format => 'html', gonin1 => 1, gonin2 => 1, gonin3 => 1 });
    $checker2->check('桂さんが柱を壊した。'); # => '<span data-checkerkun-tag="gonin3" data-checkerkun-message="かつら">桂</span>さんが<span data-checkerkun-tag="gonin3" data-checkerkun-message="はしら">柱</span>を壊した。'

    my $checker3 = AozoraBunko::Checkerkun->new({ kouetsukun => 1 });
    $checker3->check('薮さん'); # => '▼薮藪籔▲さん'

# DESCRIPTION

AozoraBunko::Checkerkun は、青空文庫工作員のための文字チェッカーで、結城浩氏が作成したスクリプトを私がライブラリ化したものです。

大野裕・結城浩・ゼファー生の各氏による旧字体置換可能チェッカー「校閲君」もこのライブラリに組み込まれています。

# METHODS

## $checker = AozoraBunko::Checkerkun->new(\\%option)

新しい AozoraBunko::Checkerkun インスタンスを生成します。

    my $checker = AozoraBunko::Checkerkun->new(
        'gaiji'            => 1, # JIS外字をチェックする
        'hansp'            => 1, # 半角スペースをチェックする
        'hanpar'           => 1, # 半角カッコをチェックする
        'zensp'            => 0, # 全角スペースをチェックする
        'zentilde'         => 1, # 全角チルダをチェックする
        '78hosetsu_tekiyo' => 1, # 78互換包摂の対象となる不要な外字注記をチェックする
        'hosetsu_tekiyo'   => 1, # 包摂の対象となる不要な外字注記をチェックする
        '78'               => 0, # 78互換包摂29字をチェックする
        'jyogai'           => 0, # 新JIS漢字で包摂規準の適用除外となる104字をチェックする
        'gonin1'           => 0, # 誤認しやすい文字をチェックする(1)
        'gonin2'           => 0, # 誤認しやすい文字をチェックする(2)
        'gonin3'           => 0, # 誤認しやすい文字をチェックする(3)
        'simplesp'         => 0, # 半角スペースは「_」で、全角スペースは「□」で出力する
        'kouetsukun'       => 0, # 旧字体置換可能チェッカー「校閲君」を有効にする（html出力時は kyuji か itaiji のチェッカー君タグ情報が付きます。）
        'output_format'    => 'plaintext', # 出力フォーマット（plaintext または html）
    );

上記のコードで設定されている値がデフォルト値です。

## $checked\_text = $checker->check($text)

new で指定したオプションでテキストをチェックします。戻り値はチェック後のテキストです。

# 秘伝のタレ（文字チェック用ハッシュリファレンス）へのアクセス

このモジュールを use すると以下の文字チェック用ハッシュリファレンスへアクセス可能になります。

    # 78互換包摂の対象となる不要な外字注記をチェックする
    $AozoraBunko::Checkerkun::KUTENMEN_78HOSETSU_TEKIYO;

    # 包摂の対象となる不要な外字注記をチェックする
    $AozoraBunko::Checkerkun::KUTENMEN_HOSETSU_TEKIYO;

    # 新JIS漢字で包摂基準の適用除外となる104字
    $AozoraBunko::Checkerkun::JYOGAI;

    # 78互換文字
    $AozoraBunko::Checkerkun::J78;

    # 誤認1
    # 間違えやすい文字
    # かとうかおりさんの「誤認識されやすい文字リスト」から
    # http://plaza.users.to/katokao/digipr/digipr_charlist.html
    $AozoraBunko::Checkerkun::GONIN1;

    # 誤認2
    $AozoraBunko::Checkerkun::GONIN2;

    # 誤認3
    # （砂場清隆さんの入力による）
    $AozoraBunko::Checkerkun::GONIN3;

    # 新字体・旧字体対応リスト
    $AozoraBunko::Checkerkun::KYUJI;

    # 異体字
    $AozoraBunko::Checkerkun::ITAIJI;

# 秘伝のタレを増量させたい

電子メールや github で要望を受け付けております。

# SEE ALSO

[Net::AozoraBunko](https://metacpan.org/pod/Net::AozoraBunko)

[本ライブラリを用いた新しいチェッカー君](http://chobitool.com/checkerkun/)

[青空文庫作業マニュアル【入力編】](http://www.aozora.gr.jp/aozora-manual/index-input.html)

[チェッカー君](http://www.aozora.jp/tools/checker.cgi)

[外字](http://www.aozora.gr.jp/annotation/external_character.html)

[波ダッシュ - Wikipedia](https://ja.wikipedia.org/wiki/%E6%B3%A2%E3%83%80%E3%83%83%E3%82%B7%E3%83%A5#Unicode.E3.81.AB.E9.96.A2.E9.80.A3.E3.81.99.E3.82.8B.E5.95.8F.E9.A1.8C)

[包摂 (文字コード) - Wikipedia](https://ja.wikipedia.org/wiki/%E5%8C%85%E6%91%82_\(%E6%96%87%E5%AD%97%E3%82%B3%E3%83%BC%E3%83%89\))

[JIS漢字で包摂の扱いが変わる文字（\[78\] \[jyogai\] など）](http://www.aozora.gr.jp/newJIS-Kanji/gokan_henkou_list.html)

[校閲君を使ってみよう](http://www.aozora.gr.jp/tools/kouetsukun/online_kouetsukun.html)

[Embedding custom non-visible data with the data-\* attributes](http://www.w3.org/TR/html5/dom.html#embedding-custom-non-visible-data-with-the-data-*-attributes)

# LICENSE

Copyright (C) pawa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

pawa <pawa@pawafuru.com>
