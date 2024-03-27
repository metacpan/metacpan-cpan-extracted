# NAME

App::Greple::xlate - greple 用の翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.3101

# DESCRIPTION

**Greple** **xlate**モジュールは目的のテキストブロックを見つけ、翻訳されたテキストに置き換えます。現在、DeepL (`deepl.pm`) と ChatGPT (`gpt3.pm`) モジュールがバックエンドエンジンとして実装されています。gpt-4 も実験的にサポートされています。

Perlのポッドスタイルで書かれた文書中の通常のテキストブロックを翻訳したい場合は、**greple**コマンドを`xlate::deepl`と`perl`モジュールと一緒に次のように使います：

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

このコマンドでは、パターン文字列`^( \w.*n)+` は英数字で始まる連続行を意味します。このコマンドでは、翻訳される領域が強調表示されます。オプション**--all**はテキスト全体を表示します。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に、`--xlate`オプションを追加して、選択した領域を翻訳します。そして、必要な部分を見つけ、**deepl**コマンドの出力で置き換えます。

デフォルトでは、原文と翻訳文は [git(1)](http://man.he.net/man1/git) と互換性のある "conflict marker" フォーマットで出力されます。`ifdef`形式を使えば、[unifdef(1)](http://man.he.net/man1/unifdef)コマンドで簡単に目的の部分を取得できます。出力形式は**--xlate-format**オプションで指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

テキスト全体を翻訳したい場合は、**--match-all**オプションを使います。これはテキスト全体にマッチするパターン`(?s).+`を指定するショートカットです。

コンフリクトマーカー形式のデータは、`sdif`コマンドに`-V`オプションを付けることで、並べて表示することができます。文字列単位で比較するのは意味がないので、`--no-cdif`オプションを推奨します。テキストに色を付ける必要がない場合は、`--no-color` または `--cm 'TEXT*='` を指定してください。

    sdif -V --cm '*TEXT=' --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

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

    使用する翻訳エンジンを指定します。`-Mxlate::deepl`のようにエンジンモジュールを直接指定する場合は、このオプションを使用する必要はありません。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、翻訳エンジンのために働くことが期待されています。翻訳するテキストを準備すると、クリップボードにコピーされます。それをフォームに貼り付け、結果をクリップボードにコピーし、リターンキーを押す。

- **--xlate-to** (Default: `EN-US`)

    対象言語を指定します。**DeepL**エンジンを使っている場合は、`deepl languages`コマンドで利用可能な言語を得ることができます。

- **--xlate-format**=_format_ (Default: `conflict`)

    原文と訳文の出力形式を指定します。

    - **conflict**, **cm**

        オリジナルと変換後のテキストは、[git(1)](http://man.he.net/man1/git) conflict marker フォーマットで表示されます。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の[sed(1)](http://man.he.net/man1/sed)コマンドで元のファイルを復元することができます。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        オリジナルと変換後のテキストは、[cpp(1)](http://man.he.net/man1/cpp) `#ifdef` フォーマットで表示されます。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef**コマンドで日本語テキストのみを取り出すことができます。

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        元のテキストと変換後のテキストは、1行の空白行で区切られて表示されます。

    - **xtxt**

        フォーマットが`xtxt`（翻訳文）またはunknownの場合、翻訳文のみが印刷されます。

- **--xlate-maxlen**=_chars_ (Default: 0)

    APIに一度に送信するテキストの最大長を指定します。既定値は、無料の DeepL アカウント・サービスと同じように、API (**--xlate**) では 128K、クリップボード・インタフェース (**--xlate-labor**) では 5000 に設定されています。Pro サービスを使用している場合は、これらの値を変更できます。

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

配布物に含まれている`xlate`コマンドを使えば、コマンドラインからこのモジュールを簡単に使うことができます。使い方については`xlate`のヘルプ情報を参照してください。

`xlate`コマンドはDocker環境と協調して動作するため、手元に何もインストールされていなくても、Dockerが利用可能であれば使用することができます。`-D`または`-C`オプションを使用してください。

また、様々なドキュメントスタイルに対応したmakefileが提供されているため、特別な指定なしに他言語への翻訳が可能です。`-M`オプションを使用してください。

Dockerオプションとmakeオプションを組み合わせて、Docker環境でmakeを実行することもできます。

`xlate -GC`のように実行すると、現在作業中のgitリポジトリがマウントされたシェルが起動します。

詳しくは["SEE ALSO"](#see-also)セクションの日本語記事をお読みください。

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -s   silent mode
        -e # translation engine (default "deepl")
        -p # pattern to determine translation area
        -w # wrap line by # width
        -o # output format (default "xtxt", or "cm", "ifdef")
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   terminate option parsing
    Make options
        -M   run make
        -n   dry-run
    Docker options
        -G   mount git top-level directory
        -B   run in non-interactive (batch) mode
        -R   mount read-only
        -E * specify environment variable to be inherited
        -I * specify altanative docker image (default: tecolicom/xlate:version)
        -D * run xlate on the container with the rest parameters
        -C * run following command on the container, or run shell

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef)
        *.ENGINE  translation engine (deepl or gpt3)

# EMACS

Emacsエディタから`xlate`コマンドを使うには、リポジトリに含まれている`xlate.el`ファイルを読み込んでください。`xlate-region`関数は、指定された地域を翻訳します。デフォルトの言語は`EN-US`で、prefix引数で言語を指定することができます。

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービス用の認証キーを設定します。

- OPENAI\_API\_KEY

    OpenAI認証キー。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepLおよびChatGPT用のコマンドラインツールをインストールする必要があります。

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)を使用します。

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)をインストールします。

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3) をインストールしてください。

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL の Python ライブラリと CLI コマンド。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python ライブラリ

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAIコマンドラインインターフェイス

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    対象テキストパターンの詳細については、**greple**のマニュアルを参照してください。**--inside**, **--outside**, **--include**, **--exclude**オプションでマッチング範囲を限定することができます。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate`モジュールを用いると、**greple**コマンドの結果をもとにファイルを修正することができます。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**を使用すると、**-V**オプションでコンフリクトマーカー形式を並べて表示することができます。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL APIで必要な部分だけを翻訳して置き換えるGrepleモジュール

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL APIモジュールによる15言語のドキュメント生成

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL APIによる自動翻訳Docker環境

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
