# NAME

App::Greple::xlate - grepleのための翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt4 --xlate pattern target-file

# VERSION

Version 0.9910

# DESCRIPTION

**Greple** **xlate** モジュールは、目的のテキストブロックを見つけて翻訳されたテキストに置き換えます。現在、DeepL（`deepl.pm`）およびChatGPT 4.1（`gpt4.pm`）モジュールがバックエンドエンジンとして実装されています。

Perlのpodスタイルで書かれたドキュメント内の通常のテキストブロックを翻訳したい場合は、**greple**コマンドを`xlate::deepl`および`perl`モジュールとともに次のように使用します。

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

このコマンドでは、パターン文字列`^([\w\pP].*\n)+`は英数字および句読点で始まる連続した行を意味します。このコマンドは、翻訳対象の領域をハイライト表示します。オプション**--all**は、全体のテキストを出力するために使用されます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に、`--xlate`オプションを追加して選択した領域を翻訳します。すると、目的のセクションを見つけて**deepl**コマンドの出力で置き換えます。

デフォルトでは、元のテキストと翻訳テキストは[git(1)](http://man.he.net/man1/git)と互換性のある「コンフリクトマーカー」形式で出力されます。`ifdef`形式を使用すると、[unifdef(1)](http://man.he.net/man1/unifdef)コマンドで目的の部分を簡単に取得できます。出力形式は**--xlate-format**オプションで指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

テキスト全体を翻訳したい場合は、**--match-all**オプションを使用してください。これは、テキスト全体にマッチするパターン`(?s).+`を指定するショートカットです。

コンフリクトマーカー形式のデータは、`sdif`コマンドと`-V`オプションでサイドバイサイド表示できます。文字列単位で比較しても意味がないため、`--no-cdif`オプションの使用を推奨します。テキストの色付けが不要な場合は、`--no-textcolor`（または`--no-tc`）を指定してください。

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

処理は指定した単位で行われますが、複数行の非空テキストが連続している場合は、まとめて1行に変換されます。この操作は次のように行われます。

- 各行の先頭と末尾の空白を削除します。
- 行末が全角句読点の場合、次の行と連結します。
- 行末が全角文字で、次の行の先頭も全角文字の場合、行を連結します。
- 行末または行頭のいずれかが全角文字でない場合、スペース文字を挿入して連結します。

キャッシュデータは正規化されたテキストに基づいて管理されるため、正規化結果に影響しない修正が行われても、キャッシュされた翻訳データは有効なままです。

この正規化処理は、最初（0番目）および偶数番目のパターンに対してのみ実行されます。したがって、次のように2つのパターンを指定した場合、最初のパターンにマッチしたテキストは正規化後に処理され、2番目のパターンにマッチしたテキストには正規化処理は行われません。

    greple -Mxlate -E normalized -E not-normalized

したがって、複数行を1行にまとめて処理したいテキストには最初のパターンを、整形済みテキストには2番目のパターンを使用してください。最初のパターンにマッチするテキストがない場合は、`(?!)`のように何にもマッチしないパターンを使用してください。

# MASKING

時々、翻訳したくないテキストの部分があります。例えば、Markdownファイル内のタグなどです。DeepLは、そのような場合、翻訳から除外したい部分をXMLタグに変換し、翻訳後に元に戻すことを提案しています。これをサポートするために、翻訳からマスクする部分を指定することが可能です。

    --xlate-setopt maskfile=MASKPATTERN

ファイル \`MASKPATTERN\` の各行を正規表現として解釈し、それに一致する文字列を翻訳し、処理後に元に戻します。`#` で始まる行は無視されます。

複雑なパターンは、バックスラッシュで改行をエスケープして複数行に記述できます。

マスキングによってテキストがどのように変換されるかは、**--xlate-mask** オプションで確認できます。

このインターフェースは実験的なものであり、将来的に変更される可能性があります。

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    一致した領域ごとに翻訳処理を実行します。

    このオプションがない場合、**greple** は通常の検索コマンドとして動作します。したがって、実際の作業を実行する前に、ファイルのどの部分が翻訳対象になるかを確認できます。

    コマンドの結果は標準出力に出力されるため、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) モジュールの使用を検討してください。

    オプション **--xlate** は、**--xlate-color** オプションを **--color=never** オプションとともに呼び出します。

    **--xlate-fold** オプションを指定すると、変換されたテキストが指定した幅で折り返されます。デフォルトの幅は70で、**--xlate-fold-width** オプションで設定できます。ランイン操作用に4列が予約されているため、各行は最大74文字まで保持できます。

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定します。`-Mxlate::deepl` のようにエンジンモジュールを直接指定した場合、このオプションを使用する必要はありません。

    現時点で利用可能なエンジンは以下の通りです

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** のインターフェースは不安定で、現時点では正しく動作する保証はありません。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、あなた自身が作業することが期待されています。翻訳するテキストを準備した後、それらがクリップボードにコピーされます。フォームに貼り付け、結果をクリップボードにコピーし、リターンキーを押してください。

- **--xlate-to** (Default: `EN-US`)

    ターゲット言語を指定します。**DeepL** エンジンを使用する場合、`deepl languages` コマンドで利用可能な言語を取得できます。

- **--xlate-format**=_format_ (Default: `conflict`)

    元のテキストと翻訳テキストの出力フォーマットを指定します。

    `xtxt` 以外の以下のフォーマットは、翻訳対象部分が行の集合であることを前提としています。実際には行の一部だけを翻訳することも可能ですが、`xtxt` 以外のフォーマットを指定しても意味のある結果は得られません。

    - **conflict**, **cm**

        元のテキストと変換後のテキストは、[git(1)](http://man.he.net/man1/git) のコンフリクトマーカーフォーマットで出力されます。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の [sed(1)](http://man.he.net/man1/sed) コマンドで元のファイルを復元できます。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        元のテキストと翻訳テキストは、Markdownのカスタムコンテナスタイルで出力されます。

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        上記のテキストは、HTMLで以下のように翻訳されます。

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        コロンの数はデフォルトで7です。`:::::` のようにコロンの並びを指定した場合は、7コロンの代わりにそれが使用されます。

    - **ifdef**

        元のテキストと変換後のテキストは、[cpp(1)](http://man.he.net/man1/cpp) `#ifdef` フォーマットで出力されます。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** コマンドで日本語テキストのみを取得できます。

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        元のテキストと変換後のテキストは、1行の空白で区切って印刷されます。`space+`の場合、変換後のテキストの後にも改行が出力されます。

    - **xtxt**

        `xtxt`（翻訳されたテキスト）や不明な場合は、翻訳されたテキストのみが印刷されます。

- **--xlate-maxlen**=_chars_ (Default: 0)

    一度にAPIに送信するテキストの最大長を指定します。デフォルト値は無料DeepLアカウントサービス用に設定されています：API用は128K（**--xlate**）、クリップボードインターフェース用は5000（**--xlate-labor**）。Proサービスを利用している場合は、これらの値を変更できる場合があります。

- **--xlate-maxline**=_n_ (Default: 0)

    一度にAPIに送信するテキストの最大行数を指定します。

    1行ずつ翻訳したい場合は、この値を1に設定してください。このオプションは`--xlate-maxlen`オプションより優先されます。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR出力で翻訳結果をリアルタイムで確認できます。

- **--xlate-stripe**

    [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)モジュールを使用して、ゼブラストライプ方式で一致部分を表示します。これは一致部分が連続している場合に便利です。

    カラーパレットはターミナルの背景色に応じて切り替わります。明示的に指定したい場合は、**--xlate-stripe-light**または**--xlate-stripe-dark**を使用できます。

- **--xlate-mask**

    マスキング機能を実行し、変換後のテキストを復元せずそのまま表示します。

- **--match-all**

    ファイル全体のテキストを対象領域として設定します。

- **--lineify-cm**
- **--lineify-colon**

    `cm`や`colon`形式の場合、出力は行ごとに分割されてフォーマットされます。そのため、行の一部だけを翻訳すると、期待される結果が得られません。これらのフィルターは、行の一部だけが翻訳されて壊れてしまった出力を、通常の行ごとの出力に修正します。

    現在の実装では、1行の複数の部分が翻訳された場合、それぞれが独立した行として出力されます。

# CACHE OPTIONS

**xlate**モジュールは、各ファイルの翻訳キャッシュテキストを保存し、実行前に読み込むことでサーバーへの問い合わせのオーバーヘッドを排除できます。デフォルトのキャッシュ戦略`auto`では、対象ファイルにキャッシュファイルが存在する場合のみキャッシュデータを保持します。

**--xlate-cache=clear**を使用してキャッシュ管理を開始したり、既存のキャッシュデータをすべてクリーンアップしたりできます。このオプションで実行すると、キャッシュファイルが存在しない場合は新規作成され、その後自動的に管理されます。

- --xlate-cache=_strategy_
    - `auto` (Default)

        キャッシュファイルが存在する場合は維持します。

    - `create`

        空のキャッシュファイルを作成して終了します。

    - `always`, `yes`, `1`

        対象が通常のファイルである限り、常にキャッシュを維持します。

    - `clear`

        まずキャッシュデータをクリアします。

    - `never`, `no`, `0`

        キャッシュファイルが存在しても決して使用しません。

    - `accumulate`

        デフォルトの動作では、未使用のデータはキャッシュファイルから削除されます。削除せずファイルに保持したい場合は`accumulate`を使用してください。
- **--xlate-update**

    このオプションは、必要がなくてもキャッシュファイルを強制的に更新します。

# COMMAND LINE INTERFACE

配布に含まれる`xlate`コマンドを使うことで、このモジュールをコマンドラインから簡単に利用できます。使い方は`xlate`のmanページを参照してください。

`xlate`コマンドはDocker環境と連携して動作するため、手元に何もインストールされていなくてもDockerが利用できれば使用可能です。`-D`または`-C`オプションを使用してください。

また、さまざまなドキュメントスタイル用のMakefileが用意されているため、特別な指定なしで他言語への翻訳も可能です。`-M`オプションを使用してください。

Dockerと`make`オプションを組み合わせて、Docker環境で`make`を実行することもできます。

`xlate -C`のように実行すると、現在の作業中のgitリポジトリをマウントしたシェルが起動します。

詳細は["SEE ALSO"](#see-also)セクションの日本語記事をお読みください。

# EMACS

リポジトリに含まれている`xlate.el`ファイルを読み込むことで、Emacsエディタから`xlate`コマンドを使用できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    `xlate-region`関数は指定した範囲を翻訳します。デフォルトの言語は`EN-US`で、プレフィックス引数を指定することで言語を変更できます。

- OPENAI\_API\_KEY

    DeepLサービス用の認証キーを設定してください。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

OpenAI認証キー。

DeepLとChatGPTのコマンドラインツールをインストールする必要があります。

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

# SEE ALSO

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    [App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    Dockerコンテナイメージ。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    DeepL PythonライブラリおよびCLIコマンド。

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI Pythonライブラリ

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    OpenAIコマンドラインインターフェース

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    対象テキストパターンの詳細については**greple**マニュアルを参照してください。マッチ範囲を制限するには**--inside**、**--outside**、**--include**、**--exclude**オプションを使用します。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    `-Mupdate`モジュールを使って**greple**コマンドの結果でファイルを修正できます。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    **sdif**を使用して、**-V**オプションとともにコンフリクトマーカーのフォーマットを並べて表示します。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple **stripe**モジュールは**--xlate-stripe**オプションで使用します。

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL APIで必要な部分だけ翻訳・置換するGrepleモジュール（日本語）

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL APIモジュールで15言語のドキュメントを生成（日本語）

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
