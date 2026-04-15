# NAME

subst - テキスト検索と置換のための Greple モジュール

# VERSION

Version 2.3702

# SYNOPSIS

greple -Msubst --dict _dictionary_ \[ オプション \]。

    Dictionary:
      --dict      dictionary file
      --dictdata  dictionary data
      --dictpair  dictionary entry pair

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

この **greple** モジュールは、辞書データに基づくテキストファイルのチェックと置換をサポートします。

辞書ファイルは**--dict**オプションで与えられ、各行にはマッチするパターンと期待される文字列のペアが含まれます。

    greple -Msubst --dict DICT

辞書ファイルが以下のようなデータを含んでいる場合

    colou?r      color
    cent(er|re)  center

上記のコマンドは、2番目の文字列にマッチしない最初のパターン、つまり、この場合、"color "と "center "を見つけます。

実際には、スペースで区切られた文字列の最後の2つの要素は、それぞれパターンと置換文字列として扱われます。

辞書データは、次のように`//`で区切って書くこともできます：

    colou?r      //  color
    cent(er|re)  //  center

`//`の前後には空白を入れなければなりません。この形式では、その前後の文字列は、最後の2つの要素ではなく、パターン文字列と置換文字列として扱われます。先頭の空白と`//`の前後の空白は無視されますが、その他の空白はすべて有効です。

**greple**の**-f**オプションで同じファイルを使うこともでき、その場合は`//`の後ろの文字列はコメントとして無視されます。

    greple -f DICT ...

オプション**--dictdata**は、コマンド行で辞書データを提供するために使用できます。

    greple -Msubst \
           --dictdata $'colou?r color\ncent(er|re) center\n'

オプション **--dictpair** を使用すると、コマンドラインから生の辞書エントリを指定できます。この場合、空白、コメント、または DEFINE の展開に関する処理は一切行われません。

    greple -Msubst \
           --dictpair 'colou?r' color \
           --dictpair 'cent(er|re)' center

シャープ記号(`#`)で始まる辞書項目はコメントとなり、無視されます。

## DEFINE

PerlのDEFINE構文を使用して、辞書ファイル内で名前付き正規表現パターンを定義できます：

    (?(DEFINE)(?<name>pattern))

定義されたパターンは、`(?&name)` 構文を使用して辞書エントリ内で参照できます。

    (?(DEFINE)(?<digit>\d+))
    (?&digit)/(?&digit)/(?&digit)  //  YYYY/MM/DD

複数のパターンを定義し、それらを組み合わせて使用することができます。パターン定義は、その参照よりも前に記述する必要があります。

## Overlapped pattern

マッチした文字列が、以前に別のパターンでマッチした文字列と同じか短い場合は、単に無視される (デフォルトでは **--no-warn-include**)。したがって、矛盾するパターンを宣言する必要がある場合は、長い方のパターンを先に配置します。

マッチした文字列が前にマッチした文字列と重なる場合、警告 (**--warn-overlap** がデフォルト) が出され、無視されます。

## Terminal color

このバージョンでは、[Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor) モジュールを使用します。これは、コマンドを実行した端末、または環境変数**TERM\_BGCOLOR**に応じて、**--light-screen**または**--dark-screen**オプションを設定します。

一部の端末 (例: "Apple\_Terminal" や "iTerm") は自動的に検出され、何もする必要はありません。それ以外の場合は、**TERM\_BGCOLOR**環境変数に#000000（黒）〜#FFFFFF（白）の数字を設定し、端末の背景色に依存します。

# OPTIONS

- **--dict**=_file_

    辞書ファイルを指定します。

- **--dictdata**=_data_

    辞書データをテキストで指定します。

- **--dictpair** _pattern_ _replacement_

    辞書項目ペアを指定します。このオプションは2つのパラメータをとます。1つ目はパターンで、2つ目は置換文字列です。

- **--check**=`outstand`|`ng`|`ok`|`any`|`all`|`none`

    オプション**--check**は、`ng`, `ok`, `any`, `outstand`, `all`, `none`から引数を取ります。

    デフォルトの`outstand`では、同じファイルに予想外の単語があった場合のみ、予想外の単語と予想外の単語の両方についての情報を表示します。

    `ng`を指定すると、予期しない単語についての情報を表示します。値`ok`を指定すると、予想される単語についての情報を表示します。値`any`の場合は両方です。

    `all`と`none`は**--stat**オプションと一緒に使われたときだけ意味があり、マッチしなかったパターンに関する情報を表示します。

- **--select**=_N_

    _N_番目のエントリを辞書から選択します。引数は[Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers)モジュールによって解釈されます。範囲は**--select**=`1:3,7:9`のように定義することができます。**--stat**オプションで数値を取得することができます。

- **--linefold**

    **--linefold**オプションは、対象データがテキストの途中で折り返されている場合に使用します。行をまたぐ文字列にマッチする正規表現パターンが作成されます。ただし、置換される文字列には改行が含まれません。正規表現の動作を多少混乱させるので、なるべく使わないでください。

- **--stat**
- **--with-stat**

    統計情報を表示します。**--check**オプションと併用します。

    **--with-stat**オプションは通常の出力の後に統計情報を出力し、**--stat**は統計情報のみを出力します。

- **--stat-style**=`default`|`dict`

    **--stat**と**--check=any**に**--stat-style=dict**オプションを併用すると、作業文書に対して辞書風の出力を行うことができます。

- **--stat-item** _item_=\[0,1\]

    統計情報に表示される項目を指定します。デフォルト値は

        match=1
        expect=1
        number=1
        ng=1
        ok=1
        dict=0

    patternフィールドを表示する必要がない場合は、このように使用します。

        --stat-item match=0

    複数のパラメータを一度に設定することができます。

        --stat-item match=number=0,ng=1,ok=1

- **--subst**

    マッチしたパターンを期待される文字列に置き換えます。マッチした文字列の改行文字は無視されます。置換文字列のないパターンは変更されません。

- **--\[no-\]warn-overlap**

    オーバーラップしたパターンを警告します。デフォルトはonです。

- **--\[no-\]warn-include**

    含まれるパターンを警告します。デフォルトはオフ。

## FILE UPDATE OPTIONS

- **--diff**
- **--diffcmd**=_command_

    **--diff**オプションは、変換前のテキストと変換後のテキストの差分を出力します。

    **--diff**オプションで使用するdiffコマンド名を指定します。デフォルトは "diff -u" です。

- **--create**

    新規ファイルを作成し、結果を書き込む。元のファイル名の末尾に".new "が付加されます。

- **--replace**

    対象ファイルを変換後の結果で置き換えます。元ファイルはバックアップ名に".bak "を付けてリネームされます。

- **--overwrite**

    バックアップを取らずに、変換後のファイルを上書きします。

# DICTIONARY

本モジュールには、サンプル辞書が含まれています。これらは共有ディレクトリにインストールされ、**--exdict**オプションでアクセスすることができます。

    greple -Msubst --exdict jtca-katakana-guide-3.dict

- **--exdict** _dictionary_

    辞書ファイルとしては、配布されている_dictionary_ flieを使用します。

- **--exdictdir**

    辞書ディレクトリを表示します。

- **--exdict** jtca-katakana-guide-3.dict
- **--jtca-katakana-guide**

    以下のガイドラインに基づいて作成されています。

        外来語（カタカナ）表記ガイドライン 第3版
        制定：2015年8月
        発行：2015年9月
        一般財団法人テクニカルコミュニケーター協会 
        Japan Technical Communicators Association
        https://jtca.org/tcwp/wp-content/uploads/2023/06/katakana_guide_3_20171222.pdf

- **--jtca**

    **--jtca-katakana-guide**をカスタマイズしたもの。オリジナルの辞書は公開されたデータから自動生成されたものです。この辞書は、実用のためにカスタマイズされています。

- **--exdict** jtf-style-guide-3.dict
- **--jtf-style-guide**

    以下のガイドラインに基づいて作成されています。

        JTF日本語標準スタイルガイド（翻訳用）
        第3.0版
        2019年8月20日
        一般社団法人 日本翻訳連盟（JTF）
        翻訳品質委員会
        https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf

- **--jtf**

    カスタマイズ**--jtf-style-guide**。オリジナル辞書は公開データから自動生成されます。この辞書は、実用に耐えるようにカスタマイズされています。

- **--exdict** sccc2.dict
- **--sccc2**

    2014年に出版された「C/C++ セキュアコーディング 第2版」で使用された辞書。

        https://www.jpcert.or.jp/securecoding_book_2nd.html

- **--exdict** ms-style-guide.dict
- **--ms-style-guide**

    Microsoftのローカライズスタイルガイドから生成された辞書。

        https://www.microsoft.com/ja-jp/language/styleguides

    本記事から生成されたデータです。

        https://www.atmarkit.co.jp/news/200807/25/microsoft.html

- **--microsoft**

    カスタマイズされた**--ms-style-guide**。オリジナルの辞書は、公開されたデータから自動生成されたものです。本辞書は、実用化に向けてカスタマイズしたものです。

    修正辞書は、[こちら](https://github.com/kaz-utashiro/greple-subst/blob/master/share/ms-amend.dict)で見ることができます。更新の要望があれば、issueを送るか、pull-requestを送信してください。

# JAPANESE

このモジュールは、日本語のテキスト編集をサポートするためにオリジナルで作成されました。

## KATAKANA

日本語のカタカナ語は、同じ言葉を表すのにいくつものバリエーションがあるので、統一することが重要ですが、かなり面倒な作業です。次の例では

    イ[エー]ハトー?([ヴブボ]ォ?)  //  イーハトーヴォ

左のパターンは、次の単語全てにマッチします。

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

[https://www.jtf.jp/jp/style\_guide/styleguide\_top.html](https://www.jtf.jp/jp/style_guide/styleguide_top.html),
[https://www.jtf.jp/jp/style\_guide/pdf/jtf\_style\_guide.pdf](https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf)

[https://www.microsoft.com/ja-jp/language/styleguides](https://www.microsoft.com/ja-jp/language/styleguides),
[https://www.atmarkit.co.jp/news/200807/25/microsoft.html](https://www.atmarkit.co.jp/news/200807/25/microsoft.html)

[文化庁 国語施策・日本語教育 国語施策情報 内閣告示・内閣訓令 外来語の表記](https://www.bunka.go.jp/kokugo_nihongo/sisaku/joho/joho/kijun/naikaku/gairai/index.html)

[https://qiita.com/kaz-utashiro/items/85add653a71a7e01c415](https://qiita.com/kaz-utashiro/items/85add653a71a7e01c415)

[イーハトーブ](https://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%BC%E3%83%8F%E3%83%88%E3%83%BC%E3%83%96)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2017-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
