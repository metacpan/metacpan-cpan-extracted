# NAME

App::Greple::xlate - grepleの翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9909

# DESCRIPTION

**Greple** **xlate**モジュールは、望ましいテキストブロックを見つけて翻訳されたテキストに置き換える機能を提供します。現在、DeepL（`deepl.pm`）とChatGPT（`gpt3.pm`）モジュールがバックエンドエンジンとして実装されています。gpt-4とgpt-4oの実験的なサポートも含まれています。

Perlのpodスタイルで書かれたドキュメント内の通常のテキストブロックを翻訳したい場合は、次のように`xlate::deepl`と`perl`モジュールを使用した**greple**コマンドを使用してください。

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

このコマンドでは、パターン文字列`^([\w\pP].*\n)+`は、アルファベット、数字、句読点で始まる連続した行を意味します。このコマンドは、翻訳する領域をハイライト表示します。オプション**--all**は、全文を表示するために使用されます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に、選択したエリアを翻訳するために`--xlate`オプションを追加します。そうすると、必要なセクションを見つけて、それらを**deepl**コマンドの出力で置き換えます。

デフォルトでは、元のテキストと翻訳されたテキストは[git(1)](http://man.he.net/man1/git)と互換性のある「競合マーカー」形式で出力されます。`ifdef`形式を使用すると、[unifdef(1)](http://man.he.net/man1/unifdef)コマンドで必要な部分を簡単に取得できます。出力形式は**--xlate-format**オプションで指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

テキスト全体を翻訳したい場合は、**--match-all**オプションを使用してください。これは、テキスト全体にマッチするパターン`(?s).+`を指定するためのショートカットです。

コンフリクトマーカーフォーマットデータは、`sdif`コマンドを`-V`オプションとともに使用することで、サイドバイサイドスタイルで表示できます。文字列単位で比較する意味がないため、`--no-cdif`オプションが推奨されています。テキストに色を付ける必要がない場合は、`--no-textcolor`（または`--no-tc`）を指定してください。

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

処理は指定された単位で行われますが、複数行の非空のテキストのシーケンスの場合、それらは一緒に1行に変換されます。この操作は次のように行われます：

- 各行の先頭と末尾の空白を削除します。
- もし行が全角の句読点で終わる場合は、次の行と結合してください。
- 行が全角文字で終わり、次の行が全角文字で始まる場合、行を連結します。
- 行の終わりまたは始まりが全角文字でない場合、スペース文字を挿入してそれらを連結します。

キャッシュデータは正規化されたテキストに基づいて管理されるため、正規化結果に影響を与えない変更が行われても、キャッシュされた翻訳データは引き続き有効です。

この正規化プロセスは、最初の（0番目）および偶数番目のパターンに対してのみ実行されます。したがって、2つのパターンが次のように指定された場合、最初のパターンに一致するテキストは正規化後に処理され、2番目のパターンに一致するテキストには正規化プロセスが実行されません。

    greple -Mxlate -E normalized -E not-normalized

したがって、複数の行を1行に結合して処理するテキストには最初のパターンを使用し、整形済みのテキストには2番目のパターンを使用します。最初のパターンに一致するテキストがない場合は、`(?!)`のように何も一致しないパターンを使用してください。

# MASKING

時々、翻訳したくないテキストの部分があります。たとえば、markdownファイル内のタグなどです。DeepLは、そのような場合、翻訳を除外するテキスト部分をXMLタグに変換し、翻訳が完了した後に元に戻すことを提案しています。これをサポートするために、翻訳からマスクする部分を指定することができます。

    --xlate-setopt maskfile=MASKPATTERN

これにより、ファイル\`MASKPATTERN\`の各行を正規表現として解釈し、それに一致する文字列を翻訳し、処理後に元に戻します。行頭が`#`で始まる行は無視されます。

複雑なパターンは、バックスラッシュで改行をエスケープして複数行に書くことができます。

テキストがマスキングによって変換される方法は、**--xlate-mask**オプションで確認できます。

このインターフェースは実験的であり、将来変更される可能性があります。

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    一致したエリアごとに翻訳プロセスを呼び出します。

    このオプションを指定しない場合、**greple**は通常の検索コマンドとして動作します。したがって、実際の作業を呼び出す前に、ファイルのどの部分が翻訳の対象になるかを確認できます。

    コマンドの結果は標準出力に表示されるため、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)モジュールを使用することを検討してください。

    オプション**--xlate**は、**--xlate-color**オプションを**--color=never**オプションとともに呼び出します。

    **--xlate-fold**オプションを使用すると、変換されたテキストが指定された幅で折り返されます。デフォルトの幅は70で、**--xlate-fold-width**オプションで設定できます。4つの列はランイン操作に予約されているため、各行には最大で74文字が含まれることができます。

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定します。`-Mxlate::deepl`のようにエンジンモジュールを直接指定する場合は、このオプションを使用する必要はありません。

    現時点では、以下のエンジンが利用可能です。

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o**のインターフェースは不安定であり、現時点では正常に動作することが保証されていません。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、あなたが作業することが期待されています。翻訳するためのテキストを準備した後、それらはクリップボードにコピーされます。フォームに貼り付けて結果をクリップボードにコピーし、リターンキーを押すことが期待されています。

- **--xlate-to** (Default: `EN-US`)

    対象言語を指定します。**DeepL**エンジンを使用する場合は、`deepl languages`コマンドで使用可能な言語を取得できます。

- **--xlate-format**=_format_ (Default: `conflict`)

    元のテキストと翻訳されたテキストの出力形式を指定します。

    `xtxt`以外の以下のフォーマットは、翻訳する部分が複数行のコレクションであると想定しています。実際には、1行の一部のみを翻訳することも可能であり、`xtxt`以外のフォーマットを指定しても意味のある結果は得られません。

    - **conflict**, **cm**

        オリジナルと変換されたテキストは、[git(1)](http://man.he.net/man1/git)の競合マーカーフォーマットで印刷されます。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の[sed(1)](http://man.he.net/man1/sed)コマンドで元のファイルを復元できます。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`html

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        &lt;div class="translation">

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        Number of colon is 7 by default. If you specify colon sequence like \`:::::::\`, it is used instead of 7 colons.

    - **ifdef**

        オリジナルと変換されたテキストは、[cpp(1)](http://man.he.net/man1/cpp)の`#ifdef`フォーマットで印刷されます。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef**コマンドで日本語のテキストのみを取得できます：

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Hello, how can I help you today?

    - **xtxt**

        形式が`xtxt`（翻訳されたテキスト）または不明な場合、翻訳されたテキストのみが表示されます。

- **--xlate-maxlen**=_chars_ (Default: 0)

    以下のテキストを日本語に翻訳してください。一度にAPIに送信するテキストの最大長を指定してください。デフォルト値は、無料のDeepLアカウントサービスに設定されています：API（**--xlate**）には128K、クリップボードインターフェース（**--xlate-labor**）には5000です。Proサービスを使用している場合は、これらの値を変更できるかもしれません。

- **--xlate-maxline**=_n_ (Default: 0)

    一度にAPIに送信するテキストの最大行数を指定します。

    1行ずつ翻訳したい場合は、この値を1に設定してください。このオプションは`--xlate-maxlen`オプションよりも優先されます。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR出力でリアルタイムに翻訳結果を確認します。

- **--xlate-stripe**

    マッチした部分をゼブラストライプのように表示するために、[App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)モジュールを使用します。マッチした部分が連続している場合に便利です。

    カラーパレットは、端末の背景色に応じて切り替わります。明示的に指定したい場合は、**--xlate-stripe-light**または**--xlate-stripe-dark**を使用できます。

- **--xlate-mask**

    マスキング機能を実行し、変換されたテキストを復元せずに表示します。

- **--match-all**

    ファイルの全体のテキストを対象エリアとして設定します。

# CACHE OPTIONS

**xlate**モジュールは、各ファイルの翻訳のキャッシュテキストを保存し、実行前にそれを読み込んでサーバーへの問い合わせのオーバーヘッドを排除することができます。デフォルトのキャッシュ戦略`auto`では、対象ファイルのキャッシュファイルが存在する場合にのみキャッシュデータを保持します。

**--xlate-cache=clear**を使用してキャッシュ管理を開始するか、既存のすべてのキャッシュデータをクリアします。このオプションを使用して実行すると、新しいキャッシュファイルが存在しない場合は作成され、その後自動的に維持されます。

- --xlate-cache=_strategy_
    - `auto` (Default)

        キャッシュファイルが存在する場合はメンテナンスします。

    - `create`

        空のキャッシュファイルを作成して終了します。

    - `always`, `yes`, `1`

        対象が通常のファイルである限り、常にキャッシュをメンテナンスします。

    - `clear`

        まずキャッシュデータをクリアします。

    - `never`, `no`, `0`

        キャッシュファイルを使用しないでください。

    - `accumulate`

        デフォルトの動作では、キャッシュファイルから未使用のデータが削除されます。それらを削除せずにファイルに保持したい場合は、`accumulate`を使用してください。
- **--xlate-update**

    このオプションは、必要ない場合でもキャッシュファイルを更新するように強制します。

# COMMAND LINE INTERFACE

このモジュールは、配布物に含まれる `xlate` コマンドを使用することで、簡単にコマンドラインから利用できます。使用方法については、`xlate` マニュアルページを参照してください。

`xlate`コマンドはDocker環境と連携して動作するため、手元に何もインストールされていなくても、Dockerが利用可能であれば使用することができます。`-D`または`-C`オプションを使用してください。

また、さまざまなドキュメントスタイルのためのメイクファイルが提供されているため、特別な指定なしに他の言語への翻訳も可能です。`-M`オプションを使用してください。

Dockerと`make`オプションを組み合わせることもできます。これにより、Docker環境で`make`を実行できます。

`xlate -C`のように実行すると、現在の作業gitリポジトリがマウントされたシェルが起動します。

詳細については、["関連記事"](#関連記事)セクションの日本語の記事を読んでください。

# EMACS

Emacsエディタから`xlate`コマンドを使用するには、リポジトリに含まれる`xlate.el`ファイルをロードしてください。`xlate-region`関数は指定された領域を翻訳します。デフォルトの言語は`EN-US`であり、プレフィックス引数を使用して言語を指定することができます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービスの認証キーを設定してください。

- OPENAI\_API\_KEY

    OpenAIの認証キーです。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

DeepLとChatGPTのコマンドラインツールをインストールする必要があります。

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockerコンテナイメージ。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL PythonライブラリとCLIコマンドです。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythonライブラリ

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAIコマンドラインインターフェース

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    対象のテキストパターンに関する詳細については、**greple**マニュアルを参照してください。一致する範囲を制限するために、**--inside**、**--outside**、**--include**、**--exclude**オプションを使用できます。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    **greple**コマンドの結果を使用してファイルを変更するために、`-Mupdate`モジュールを使用することができます。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **-V**オプションとともに、衝突マーカーフォーマットを並べて表示するために**sdif**を使用してください。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe**モジュールは、**--xlate-stripe**オプションを使用しています。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL APIを使用して必要な部分のみを翻訳および置換するためのGrepleモジュール（日本語）

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL APIモジュールを使用して15言語でドキュメントを生成する（日本語）

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL APIを使用した自動翻訳Docker環境（日本語）

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
