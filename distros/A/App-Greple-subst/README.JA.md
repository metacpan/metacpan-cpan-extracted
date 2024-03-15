# NAME

subst - テキスト検索と置換のための Greple モジュール

# VERSION

Version 2.3305

# SYNOPSIS

greple -Msubst --dict _dictionary_ \[ オプション \]。

    Dictionary:
      --dict      dictionary file
      --dictdata  dictionary data

    Check:
      --check=[ng,ok,any,outstand,all,none]
      --select=N
      --linefold
      --stat
      --with-stat
      --stat-style=[default,dict]
      --stat-item={match,expect,number,ok,ng,dict}=[0,1]
      --subst
      --[no-]warn-overlap
      --[no-]warn-include

    File Update:
      --diff
      --diffcmd command
      --create
      --replace
      --overwrite

# DESCRIPTION

この **greple** モジュールは、辞書データに基づくテキストファイルのチェックと置換をサポートする。

辞書ファイルは**--dict**オプションで与えられ、各行にはマッチするパターンと期待される文字列のペアが含まれる。

    greple -Msubst --dict DICT

辞書ファイルが以下のようなデータを含んでいる場合

    colou?r      color
    cent(er|re)  center

上記のコマンドは、2番目の文字列にマッチしない最初のパターン、つまり、この場合、"color "と "center "を見つける。

辞書データのフィールド`//`は無視されるので、このファイルはこのように書くことができる。

    colou?r      //  color
    cent(er|re)  //  center

**greple**の**-f**オプションで同じファイルを使うこともでき、その場合は`//`の後ろの文字列はコメントとして無視される。

    greple -f DICT ...

**--dictdata**オプションは、コマンドラインで辞書データを提供するために使用することができる。

    greple --dictdata $'colou?r color\ncent(er|re) center\n'

シャープ記号(`#`)で始まる辞書項目はコメントとなり、無視される。

## Overlapped pattern

マッチした文字列が、以前に別のパターンでマッチした文字列と同じか短い場合は、単に無視される (デフォルトでは **--no-warn-include**)。したがって、矛盾するパターンを宣言する必要がある場合は、長い方のパターンを先に配置する。

マッチした文字列が前にマッチした文字列と重なる場合、警告を出し (デフォルトでは **--warn-overlap)、無視される。**

## Terminal color

このバージョンでは、[Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor) モジュールを使用する。これは、コマンドを実行した端末、または環境変数**TERM\_BGCOLOR**に応じて、**--light-screen**または**--dark-screen**オプションを設定する。

一部の端末 (例: "Apple\_Terminal" や "iTerm") は自動的に検出され、何もする必要はない。それ以外の場合は、**TERM\_BGCOLOR**環境変数に#000000（黒）〜#FFFFFF（白）の数字を設定し、端末の背景色に依存する。

# OPTIONS

- **--dict**=_file_

    辞書ファイルを指定する。

- **--dictdata**=_data_

    辞書データをテキストで指定する。

- **--check**=`outstand`|`ng`|`ok`|`any`|`all`|`none`

    オプション**--check**は、`ng`, `ok`, `any`, `outstand`, `all`, `none`から引数を取る。

    デフォルトの`outstand`では、同じファイルに予想外の単語があった場合のみ、予想外の単語と予想外の単語の両方についての情報を表示する。

    `ng`を指定すると、予期しない単語についての情報を表示する。値`ok`を指定すると、予想される単語についての情報を表示する。値`any`の場合は両方である。

    `all`と`none`は**--stat**オプションと一緒に使われたときだけ意味があり、マッチしなかったパターンに関する情報を表示する。

- **--select**=_N_

    _N_番目のエントリを辞書から選択する。引数は[Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers)モジュールによって解釈される。範囲は**--select**=`1:3,7:9`のように定義することができる。**--stat**オプションで数値を取得することができる。

- **--linefold**

    **--linefold**オプションは、対象データがテキストの途中で折り返されている場合に使用する。行をまたぐ文字列にマッチする正規表現パターンが作成される。ただし、置換される文字列には改行が含まれない。正規表現の動作を多少混乱させるので、なるべく使わないでください。

- **--stat**
- **--with-stat**

    統計情報を表示する。**--check**オプションと併用する。

    **--with-stat**オプションは通常の出力の後に統計情報を出力し、**--stat**は統計情報のみを出力する。

- **--stat-style**=`default`|`dict`

    **--stat**と**--check=any**に**--stat-style=dict**オプションを併用すると、作業文書に対して辞書風の出力を行うことができる。

- **--stat-item** _item_=\[0,1\]

    統計情報に表示される項目を指定する。デフォルト値は

        match=1
        expect=1
        number=1
        ng=1
        ok=1
        dict=0

    patternフィールドを表示する必要がない場合は、このように使用する。

        --stat-item match=0

    複数のパラメータを一度に設定することができる。

        --stat-item match=number=0,ng=1,ok=1

- **--subst**

    マッチしたパターンを期待される文字列に置き換える。マッチした文字列の改行文字は無視される。置換文字列のないパターンは変更されない。

- **--\[no-\]warn-overlap**

    オーバーラップしたパターンを警告する。デフォルトはonである。

- **--\[no-\]warn-include**

    含まれるパターンを警告する。デフォルトはオフ。

## FILE UPDATE OPTIONS

- **--diff**
- **--diffcmd**=_command_

    **--diff**オプションは、変換前のテキストと変換後のテキストの差分を出力する。

    **--diff**オプションで使用するdiffコマンド名を指定する。デフォルトは "diff -u "である。

- **--create**

    新規ファイルを作成し、結果を書き込む。元のファイル名の末尾に".new "が付加される。

- **--replace**

    対象ファイルを変換後の結果で置き換える。元ファイルはバックアップ名に".bak "を付けてリネームされる。

- **--overwrite**

    バックアップを取らずに、変換後のファイルを上書きする。

# DICTIONARY

本モジュールには、サンプル辞書が含まれている。これらは共有ディレクトリにインストールされ、**--exdict**オプションでアクセスすることができる。

    greple -Msubst --exdict jtca-katakana-guide-3.dict

- **--exdict** _dictionary_

    辞書ファイルとしては、配布されている_dictionary_ flieを使用する。

- **--exdictdir**

    辞書ディレクトリを表示する。

- **--exdict** jtca-katakana-guide-3.dict
- **--jtca-katakana-guide**

    以下のガイドラインに基づいて作成されている。

        外来語（カタカナ）表記ガイドライン 第3版
        制定：2015年8月
        発行：2015年9月
        一般財団法人テクニカルコミュニケーター協会 
        Japan Technical Communicators Association
        https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf

- **--jtca**

    **--jtca-katakana-guide**をカスタマイズしたもの。オリジナルの辞書は公開されたデータから自動生成されたものである。この辞書は、実用のためにカスタマイズされている。

- **--exdict** jtf-style-guide-3.dict
- **--jtf-style-guide**

    以下のガイドラインに基づいて作成されている。

        JTF日本語標準スタイルガイド（翻訳用）
        第3.0版
        2019年8月20日
        一般社団法人 日本翻訳連盟（JTF）
        翻訳品質委員会
        https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf

- **--jtf**

    カスタマイズ**--jtf-style-guide**。オリジナル辞書は公開データから自動生成される。この辞書は、実用に耐えるようにカスタマイズされている。

- **--exdict** sccc2.dict
- **--sccc2**

    2014年に出版された「C/C++ セキュアコーディング 第2版」で使用された辞書。

        https://www.jpcert.or.jp/securecoding_book_2nd.html

- **--exdict** ms-style-guide.dict
- **--ms-style-guide**

    Microsoftのローカライズスタイルガイドから生成された辞書。

        https://www.microsoft.com/ja-jp/language/styleguides

    本記事から生成されたデータである。

        https://www.atmarkit.co.jp/news/200807/25/microsoft.html

- **--microsoft**

    カスタマイズされた**--ms-style-guide**。オリジナルの辞書は、公開されたデータから自動生成されたものである。本辞書は、実用化に向けてカスタマイズしたものである。

    修正辞書は、[こちら](https://github.com/kaz-utashiro/greple-subst/blob/master/share/ms-amend.dict)で見ることができる。更新の要望があれば、issueを送るか、pull-requestを送信してください。

# JAPANESE

このモジュールは、日本語のテキスト編集をサポートするためにオリジナルで作成された。

## KATAKANA

日本語のカタカナ語は、同じ言葉を表すのにいくつものバリエーションがあるので、統一することが重要だが、かなり面倒な作業である。次の例では

    イ[エー]ハトー?([ヴブボ]ォ?)  //  イーハトーヴォ

左のパターンは、次の単語全てにマッチする。

    イエハトブ
    イーハトヴ
    イーハトーヴ
    イーハトーヴォ
    イーハトーボ
    イーハトーブ

このモジュールは、これらの単語を検出し、修正するのに役立つ。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::subst

# SEE ALSO

[https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/kaz-utashiro/greple-subst](https://github.com/kaz-utashiro/greple-subst)

[https://github.com/kaz-utashiro/greple-update](https://github.com/kaz-utashiro/greple-update)

[https://www.jtca.org/standardization/katakana\_guide\_3\_20171222.pdf](https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf)

[https://www.jtf.jp/jp/style\_guide/styleguide\_top.html](https://www.jtf.jp/jp/style_guide/styleguide_top.html), [https://www.jtf.jp/jp/style\_guide/pdf/jtf\_style\_guide.pdf](https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf)

[https://www.microsoft.com/ja-jp/language/styleguides](https://www.microsoft.com/ja-jp/language/styleguides)，[https://www.atmarkit.co.jp/news/200807/25/microsoft.html](https://www.atmarkit.co.jp/news/200807/25/microsoft.html)。

L＜文化庁 国語施策・日本語教育 国語施策情報 内閣告示・内閣訓 外来語の表記|https://www.bunka.go.jp/kokugo\_nihongo/sisaku/joho/joho/kijun/naikaku/gairai/index.html>

[https://qiita.com/kaz-utashiro/items/85add653a71a7e01c415](https://qiita.com/kaz-utashiro/items/85add653a71a7e01c415)

[イーハトーブ](https://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%BC%E3%83%8F%E3%83%88%E3%83%BC%E3%83%96)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2017-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 72:

    Unterminated B<...> sequence
