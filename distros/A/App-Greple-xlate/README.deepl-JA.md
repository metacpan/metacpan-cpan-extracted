# NAME

App::Greple::xlate - greple 用の翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.3202

# DESCRIPTION

**Greple** **xlate**モジュールは目的のテキストブロックを見つけ、翻訳されたテキストに置き換えます。現在、DeepL (`deepl.pm`) と ChatGPT (`gpt3.pm`) モジュールがバックエンドエンジンとして実装されています。gpt-4 も実験的にサポートされています。

PerlのPodスタイルで書かれた文書中の通常のテキストブロックを翻訳したい場合は、`xlate::deepl`と`perl`モジュールを使って、次のように**greple**コマンドを使います：

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

このコマンドでは、パターン文字列 `^( \w.*n)+` は、英数字で始まる連続行を意味します。このコマンドは翻訳される領域をハイライト表示します。オプション**--all**はテキスト全体を生成するために使われます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に`--xlate`オプションを加えて、選択された範囲を翻訳します。そして、必要な部分を見つけて、**deepl**コマンドの出力で置き換えます。

デフォルトでは、原文と訳文は [git(1)](http://man.he.net/man1/git) と互換性のある "conflict marker" フォーマットで出力されます。`ifdef`形式を使えば、[unifdef(1)](http://man.he.net/man1/unifdef)コマンドで簡単に目的の部分を得ることができます。出力形式は**--xlate-format**オプションで指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

テキスト全体を翻訳したい場合は、**--match-all**オプションを使います。これはテキスト全体にマッチするパターン`(?s).+`を指定するショートカットです。

`sdif`コマンドに`-V`オプションを指定すると、コンフリクトマーカー形式のデータを並べて表示することができます。文字列単位で比較するのは意味がないので、`--no-cdif`オプションを推奨します。テキストに色をつける必要がない場合は、`--no-textcolor`（または`--no-tc`）を指定します。

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

処理は指定された単位で行われるが、空でないテキストが複数行連続している場合は、それらをまとめて1行に変換します。この処理は次のように行われる：

- 各行の先頭と末尾の空白を取り除く。
- ある行が全角文字で終わり、次の行が全角文字で始まる場合、その行を連結します。
- 行末または行頭が全角文字でない場合は、スペース文字を挿入して連結します。

キャッシュデータは正規化されたテキストに基づいて管理されるため、正規化結果に影響を与えない範囲で修正を加えても、キャッシュされた翻訳データは有効です。

この正規化処理は、最初の（0 番目の）偶数パターンに対してのみ行われます。したがって、以下のように2つのパターンを指定した場合、1つ目のパターンにマッチするテキストは正規化処理後に処理され、2つ目のパターンにマッチするテキストには正規化処理は行われないです。

    greple -Mxlate -E normalized -E not-normalized

したがって、複数行を1行にまとめて処理するテキストには最初のパターンを使い、整形済みテキストには2番目のパターンを使う。最初のパターンにマッチするテキストがない場合は、何もマッチしないパターン、例えば `(?!)`.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    マッチした各領域に対して翻訳処理を起動します。

    このオプションをつけないと、**greple**は通常の検索コマンドとして動作します。したがって、実際の作業を開始する前に、ファイルのどの部分が翻訳の対象となるかをチェックすることができます。

    コマンドの結果は標準出力されますので、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)モジュールの使用を検討してください。

    **--xlate** オプションは **--xlate-color** オプションを **--color=never** オプションで呼び出します。

    **--xlate-fold** オプションを指定すると、変換されたテキストは指定した幅で折り返されます。デフォルトの幅は70で、**--xlate-fold-width**オプションで設定できます。ランイン操作のために4つのカラムが予約されているので、各行は最大74文字を保持できます。

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定します。`-Mxlate::deepl`のようにエンジンモジュールを直接指定する場合は、このオプションを使う必要はありません。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、以下の作業を行うことになります。翻訳するテキストを準備すると、クリップボードにコピーされます。フォームに貼り付け、結果をクリップボードにコピーし、returnを押してください。

- **--xlate-to** (Default: `EN-US`)

    ターゲット言語を指定します。**DeepL**エンジンを使用している場合は、`deepl languages`コマンドで利用可能な言語を取得できます。

- **--xlate-format**=_format_ (Default: `conflict`)

    原文と訳文の出力形式を指定します。

    - **conflict**, **cm**

        原文と訳文は[git(1)](http://man.he.net/man1/git) conflict marker形式で出力されます。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の[sed(1)](http://man.he.net/man1/sed)コマンドで元のファイルを復元できます。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        原文と訳文は[cpp(1)](http://man.he.net/man1/cpp) `#ifdef`形式で出力されます。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef**コマンドで日本語のテキストだけを取り出すことができます：

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        変換前のテキストと変換後のテキストは空白行で区切られて表示されます。

    - **xtxt**

        形式が`xtxt`（翻訳済みテキスト）または未知の場合は、翻訳済みテキストのみが印刷されます。

- **--xlate-maxlen**=_chars_ (Default: 0)

    APIに一度に送信するテキストの最大長を指定します。既定値は、無料のDeepLアカウント・サービスと同様に、API (**--xlate**) では128K、クリップボード・インタフェース (**--xlate-labor**) では5000に設定されています。Pro サービスを使用している場合は、これらの値を変更できます。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR出力でリアルタイムにトランザクション結果を見ます。

- **--match-all**

    ファイルの全文を対象領域に設定します。

# CACHE OPTIONS

**xlate**モジュールは、各ファイルの翻訳テキストをキャッシュしておき、実行前に読み込むことで、サーバーに問い合わせるオーバーヘッドをなくすことができます。デフォルトのキャッシュ戦略`auto`では、対象ファイルに対してキャッシュファイルが存在する場合にのみキャッシュデータを保持します。

- --cache-clear

    **--cache-clear**オプションを使用すると、キャッシュ管理を開始したり、既存のキャッシュデータをすべてリフレッシュしたりすることができます。このオプションを一度実行すると、キャッシュ・ファイルが存在しない場合は新しいキャッシュ・ファイルが作成され、その後は自動的に維持されます。

- --xlate-cache=_strategy_
    - `auto` (Default)

        キャッシュ・ファイルが存在すれば、それを維持します。

    - `create`

        空のキャッシュ・ファイルを作成して終了します。

    - `always`, `yes`, `1`

        対象が通常ファイルである限り、とにかくキャッシュを維持します。

    - `clear`

        最初にキャッシュデータをクリアします。

    - `never`, `no`, `0`

        キャッシュファイルが存在しても使用しないです。

    - `accumulate`

        デフォルトの動作では、未使用のデータはキャッシュ・ファイルから削除されます。削除せず、ファイルに残しておきたい場合は、`accumulate`を使ってください。

# COMMAND LINE INTERFACE

配布物に含まれる `xlate` コマンドを使用することで、コマンドラインからこのモジュールを簡単に使用できます。使い方については `xlate` のヘルプ情報を参照してください。

`xlate`コマンドはDocker環境と協調して動作するため、手元に何もインストールされていなくても、Dockerが利用可能であれば使用することができます。`-D`または`-C`オプションを使用してください。

また、様々なドキュメントスタイルに対応したmakefileが提供されているので、特別な指定なしに他言語への翻訳が可能です。`-M`オプションを使用してください。

Dockerオプションとmakeオプションを組み合わせて、Docker環境でmakeを実行することもできます。

`xlate -GC`のように実行すると、現在作業中のgitリポジトリがマウントされたシェルが起動します。

詳しくは["SEE ALSO"](#see-also)セクションの日本語記事を読んでください。

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

Emacsエディタから`xlate`コマンドを使うには、リポジトリに含まれる`xlate.el`ファイルを読み込みます。`xlate-region`関数は指定された領域を翻訳します。デフォルトの言語は`EN-US`で、prefix引数で言語を指定できます。

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービスの認証キーを設定します。

- OPENAI\_API\_KEY

    OpenAIの認証キーです。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepLおよびChatGPT用のコマンドラインツールをインストールする必要があります。

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate) とします。

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) (英語)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3) です。

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python ライブラリと CLI コマンド。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python ライブラリ

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI コマンドラインインタフェース

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    ターゲット・テキスト・パターンの詳細については、**greple** のマニュアルを参照してください。**--inside**、**--outside**、**--include**、**--exclude**オプションを使用して、マッチング範囲を制限します。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate` モジュールを使って、**greple** コマンドの結果によってファイルを変更することができます。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**を使うと、**-V**オプションでコンフリクトマーカの書式を並べて表示することができます。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL APIで必要な部分だけを翻訳・置換するGrepleモジュール

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
