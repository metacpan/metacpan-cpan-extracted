# NAME

App::Greple::xlate - greple 用の翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.23

# DESCRIPTION

**Greple** **xlate** モジュールは、テキストブロックを見つけ、翻訳されたテキストに置き換えます。現在、**xlate::deepl**モジュールが対応しているのはDeepLサービスのみです。

[pod](https://metacpan.org/pod/pod)形式の文書中の通常のテキストブロックを翻訳したい場合は、**greple**コマンドと`xlate::deepl`モジュール、`perl`モジュールを使って、以下のようにします。

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

パターン `^(\w.*n)+` は、英数字で始まる連続した行を意味します。このコマンドは、翻訳される領域を表示します。オプション**--all**は、テキスト全体を翻訳するために使用します。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に、`--xlate`オプションを追加して、選択された領域を翻訳します。これは、**deepl**コマンドの出力でそれらを見つけて置き換えます。

デフォルトでは、原文と訳文が [git(1)](http://man.he.net/man1/git) と互換性のある "conflict marker" フォーマットで出力されます。`ifdef` 形式を用いると、[unifdef(1)](http://man.he.net/man1/unifdef) コマンドで簡単に目的の部分を得ることができます。**--xlate-format**オプションでフォーマットを指定することができます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

テキスト全体を翻訳したい場合は、**--match-all**オプションを使用します。これは、テキスト全体にマッチするパターンを指定するためのショートカットです `(?s).+`.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    マッチした領域ごとに翻訳処理を起動します。

    このオプションがない場合、**greple**は通常の検索コマンドとして動作します。したがって、ファイルのどの部分が翻訳の対象となるかを、実際の作業を始める前に確認することができます。

    コマンドの結果は標準出力されますので、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)モジュールの使用を検討してください。

    **--xlate**オプションは、**--xlate-color**オプションを**--color=never**オプションで呼び出します。

    **--xlate-fold**オプションでは、変換されたテキストを指定した幅で折り返す。デフォルトの幅は70で、**--xlate-fold-width**オプションで設定することができます。ランイン動作のために4列が確保されているので、1行には最大で74文字が格納できます。

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定します。モジュール`xlate::deepl`で`--xlate-engine=deepl`と宣言されているので、このオプションを使う必要はないです。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、あなたが働くことが期待されています。翻訳するテキストを用意すると、それがクリップボードにコピーされます。それをフォームに貼り付け、結果をクリップボードにコピーし、リターンキーを押すことが期待されます。

- **--xlate-to** (Default: `EN-US`)

    対象言語を指定します。**DeepL**エンジンを使っている場合は、`deepl languages`コマンドで利用可能な言語を得ることができます。

- **--xlate-format**=_format_ (Default: `conflict`)

    原文と訳文の出力形式を指定します。

    - **conflict**, **cm**

        原文と訳文を[git(1)](http://man.he.net/man1/git)コンフリクトマーカ形式で出力します。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の[sed(1)](http://man.he.net/man1/sed)コマンドで元のファイルを復元することができます。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        原文と訳文を[cpp(1)](http://man.he.net/man1/cpp) `#ifdef`形式で出力します。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef**コマンドで日本語テキストのみを取り出すことができます。

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        原文と訳文を1行の空白で区切って表示します。

    - **xtxt**

        フォーマットが`xtxt`（翻訳文）またはunknownの場合、翻訳文のみが印刷されます。

- **--xlate-maxlen**=_chars_ (Default: 0)

    APIに一度に送信するテキストの最大長を指定します。初期値は、無料アカウントサービスの場合、API（**--xlate**）は128K、クリップボードインターフェース（**--xlate-labor**）は5000に設定されています。Proサービスをご利用の場合は、これらの値を変更することができます。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    翻訳結果はSTDERR出力にリアルタイムで表示されます。

- **--match-all**

    ファイルの全テキストを対象範囲に設定します。

# CACHE OPTIONS

**xlate**モジュールは、各ファイルの翻訳テキストをキャッシュしておき、実行前にそれを読むことで、サーバーへの問い合わせのオーバーヘッドをなくすことができます。デフォルトのキャッシュ戦略`auto`では、対象ファイルに対してキャッシュファイルが存在する場合のみ、キャッシュデータを保持します。

- --cache-clear

    **--cache-clear**オプションは、キャッシュ管理を開始するか、既存のキャッシュデータをすべてリフレッシュするために使用されます。このオプションを一度実行すると、キャッシュファイルが存在しない場合は新規に作成され、その後は自動的にメンテナンスされます。

- --xlate-cache=_strategy_
    - `auto` (Default)

        キャッシュファイルが存在する場合は、それを維持します。

    - `create`

        空のキャッシュファイルを作成し、終了します。

    - `always`, `yes`, `1`

        対象が通常ファイルである限り、とにかくキャッシュを維持します。

    - `clear`

        キャッシュデータを先にクリアします。

    - `never`, `no`, `0`

        キャッシュファイルが存在しても決して使用しないです。

    - `accumulate`

        デフォルトの動作では、未使用のデータはキャッシュファイルから削除されます。削除せずに残しておきたい場合は、`蓄積`を使用してください。

# COMMAND LINE INTERFACE

リポジトリに含まれる`xlate`コマンドを使用することで、コマンドラインから本モジュールを簡単に使用することができます。使い方については、`xlate`のヘルプ情報を参照してください。

# EMACS

Emacsエディタから`xlate`コマンドを使うには、リポジトリに含まれている`xlate.el`ファイルを読み込んでください。`xlate-region`関数は、指定された地域を翻訳します。デフォルトの言語は`EN-US`で、prefix引数で言語を指定することができます。

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービス用の認証キーを設定します。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)を使用します。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL の Python ライブラリと CLI コマンド。

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    対象テキストパターンの詳細については、**greple**のマニュアルを参照してください。**--inside**, **--outside**, **--include**, **--exclude**オプションでマッチング範囲を限定することができます。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate`モジュールを用いると、**greple**コマンドの結果をもとにファイルを修正することができます。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**を使用すると、**-V**オプションでコンフリクトマーカー形式を並べて表示することができます。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
