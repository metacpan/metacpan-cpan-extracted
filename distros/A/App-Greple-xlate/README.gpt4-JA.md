# NAME

App::Greple::xlate - grepleの翻訳サポートモジュール  

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9908

# DESCRIPTION

**Greple** **xlate** モジュールは、目的のテキストブロックを見つけて、翻訳されたテキストに置き換えます。現在、DeepL (`deepl.pm`) と ChatGPT (`gpt3.pm`) モジュールがバックエンドエンジンとして実装されています。gpt-4 および gpt-4o の実験的サポートも含まれています。

Perlのpodスタイルで書かれたドキュメント内の通常のテキストブロックを翻訳したい場合は、次のように**greple**コマンドを`xlate::deepl`および`perl`モジュールと共に使用します：  

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

このコマンドでは、パターン文字列 `^([\w\pP].*\n)+` は、英数字および句読点で始まる連続する行を意味します。このコマンドは翻訳されるべき領域をハイライト表示します。オプション **--all** は全文を生成するために使用されます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に、選択した領域を翻訳するために`--xlate`オプションを追加します。そうすると、希望するセクションを見つけて**deepl**コマンドの出力で置き換えます。  

デフォルトでは、元のテキストと翻訳されたテキストは[git(1)](http://man.he.net/man1/git)と互換性のある「コンフリクトマーカー」形式で印刷されます。`ifdef`形式を使用すると、[unifdef(1)](http://man.he.net/man1/unifdef)コマンドで簡単に希望の部分を取得できます。出力形式は**--xlate-format**オプションで指定できます。  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

全体のテキストを翻訳したい場合は、**--match-all**オプションを使用します。これは、全体のテキストに一致する`(?s).+`パターンを指定するためのショートカットです。  

コンフリクトマーカーフォーマットのデータは、`sdif`コマンドと`-V`オプションを使用して、サイドバイサイドスタイルで表示できます。文字列ごとに比較することは意味がないため、`--no-cdif`オプションが推奨されます。テキストに色を付ける必要がない場合は、`--no-textcolor`（または`--no-tc`）を指定します。  

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

処理は指定された単位で行われますが、非空のテキストの複数行のシーケンスの場合、それらは一つの行にまとめて変換されます。この操作は次のように行われます：  

- 各行の先頭と末尾の空白を削除します。  
- もし行が全角句読点で終わる場合は、次の行と連結します。
- 行が全角文字で終わり、次の行が全角文字で始まる場合、行を連結します。  
- 行の末尾または先頭が全角文字でない場合、スペース文字を挿入して連結します。  

キャッシュデータは正規化されたテキストに基づいて管理されるため、正規化結果に影響を与えない修正が行われても、キャッシュされた翻訳データは引き続き有効です。  

この正規化プロセスは、最初（0番目）および偶数番号のパターンに対してのみ実行されます。したがって、次のように2つのパターンが指定されている場合、最初のパターンに一致するテキストは正規化後に処理され、2番目のパターンに一致するテキストには正規化プロセスは実行されません。  

    greple -Mxlate -E normalized -E not-normalized

したがって、複数の行を1行に結合して処理するテキストには最初のパターンを使用し、事前にフォーマットされたテキストには2番目のパターンを使用します。最初のパターンに一致するテキストがない場合は、`(?!)`のように何も一致しないパターンを使用してください。

# MASKING

時折、翻訳したくないテキストの部分があります。例えば、マークダウンファイルのタグなどです。DeepLは、そのような場合、翻訳から除外するテキスト部分をXMLタグに変換し、翻訳後に元に戻すことを提案しています。これをサポートするために、翻訳からマスクする部分を指定することが可能です。  

    --xlate-setopt maskfile=MASKPATTERN

これは、ファイル \`MASKPATTERN\` の各行を正規表現として解釈し、それに一致する文字列を翻訳し、処理後に元に戻します。`#` で始まる行は無視されます。  

複雑なパターンは、バックスラッシュでエスケープされた改行を使って、複数行にわたって記述することができます。

テキストがマスキングによってどのように変換されるかは、**--xlate-mask**オプションで確認できます。

このインターフェースは実験的であり、将来的に変更される可能性があります。  

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    一致した領域ごとに翻訳プロセスを呼び出します。  

    このオプションがない場合、**greple** は通常の検索コマンドとして動作します。したがって、実際の作業を開始する前に、ファイルのどの部分が翻訳の対象になるかを確認できます。  

    コマンドの結果は標準出力に出力されるため、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) モジュールの使用を検討してください。  

    オプション **--xlate** は、**--color=never** オプションを使用して **--xlate-color** オプションを呼び出します。  

    **--xlate-fold** オプションを使用すると、変換されたテキストは指定された幅で折りたたまれます。デフォルトの幅は70で、**--xlate-fold-width** オプションで設定できます。ランイン操作のために4列が予約されているため、各行は最大74文字を保持できます。  

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定します。エンジンモジュールを直接指定する場合（例：`-Mxlate::deepl`）、このオプションを使用する必要はありません。  

    現時点で、以下のエンジンが利用可能です

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o**のインターフェースは不安定で、現在正しく動作することは保証できません。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、あなたが作業することが期待されています。翻訳するテキストを準備した後、それらはクリップボードにコピーされます。あなたはそれらをフォームに貼り付け、結果をクリップボードにコピーし、リターンを押すことが期待されています。  

- **--xlate-to** (Default: `EN-US`)

    ターゲット言語を指定します。**DeepL** エンジンを使用している場合、`deepl languages` コマンドで利用可能な言語を取得できます。  

- **--xlate-format**=_format_ (Default: `conflict`)

    元のテキストと翻訳されたテキストの出力形式を指定します。  

    `xtxt` 以外の以下の形式は、翻訳される部分が行のコレクションであることを前提としています。実際には、行の一部だけを翻訳することも可能であり、`xtxt` 以外の形式を指定すると意味のある結果は得られません。  

    - **conflict**, **cm**

        元のテキストと変換されたテキストは、[git(1)](http://man.he.net/man1/git) の競合マーカー形式で印刷されます。  

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の [sed(1)](http://man.he.net/man1/sed) コマンドで元のファイルを復元できます。  

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        オリジナルと翻訳されたテキストは、マークダウンのカスタムコンテナスタイルで出力されます。

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        上記のテキストはHTMLで以下のように翻訳されます。

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        コロンの数はデフォルトで7つです。`:::::`のようにコロンの並びを指定した場合、それが7つのコロンの代わりに使用されます。

    - **ifdef**

        元のテキストと変換されたテキストは、[cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 形式で印刷されます。  

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** コマンドを使用して、日本語のテキストのみを取得できます：  

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        原文と変換されたテキストは、単一の空白行で区切られて印刷されます。`space+`の場合、変換されたテキストの後にも改行が出力されます。

    - **xtxt**

        形式が `xtxt`（翻訳されたテキスト）または不明な場合、翻訳されたテキストのみが印刷されます。  

- **--xlate-maxlen**=_chars_ (Default: 0)

    APIに一度に送信するテキストの最大長を指定します。デフォルト値は、無料のDeepLアカウントサービスに設定されています：API（**--xlate**）用に128K、クリップボードインターフェース（**--xlate-labor**）用に5000です。Proサービスを使用している場合、これらの値を変更できるかもしれません。  

- **--xlate-maxline**=_n_ (Default: 0)

    APIに一度に送信する最大行数を指定してください。

    この値を1に設定すると、一度に1行ずつ翻訳します。このオプションは`--xlate-maxlen`オプションよりも優先されます。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR出力で翻訳結果をリアルタイムで確認します。  

- **--xlate-stripe**

    [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) モジュールを使用して、マッチした部分をシマウマのストライプのファッションで表示します。これは、マッチした部分が背中合わせに接続されている場合に便利です。

    カラーパレットはターミナルの背景色に応じて切り替えられます。明示的に指定したい場合は、**--xlate-stripe-light** または **--xlate-stripe-dark** を使用できます。

- **--xlate-mask**

    マスキング機能を実行し、復元せずに変換されたテキストをそのまま表示します。

- **--match-all**

    ファイル全体のテキストを対象領域として設定します。

# CACHE OPTIONS

**xlate**モジュールは、各ファイルの翻訳のキャッシュテキストを保存し、実行前にそれを読み込むことで、サーバーへの問い合わせのオーバーヘッドを排除できます。デフォルトのキャッシュ戦略`auto`では、ターゲットファイルのキャッシュファイルが存在する場合のみキャッシュデータを維持します。  

**--xlate-cache=clear** を使用してキャッシュ管理を開始するか、すべての既存のキャッシュデータをクリーンアップします。このオプションを実行すると、キャッシュファイルが存在しない場合は新しいキャッシュファイルが作成され、その後は自動的に維持されます。

- --xlate-cache=_strategy_
    - `auto` (Default)

        キャッシュファイルが存在する場合はそれを維持します。  

    - `create`

        空のキャッシュファイルを作成して終了します。  

    - `always`, `yes`, `1`

        ターゲットが通常のファイルである限り、キャッシュを維持します。  

    - `clear`

        最初にキャッシュデータをクリアします。  

    - `never`, `no`, `0`

        キャッシュファイルが存在しても決して使用しません。  

    - `accumulate`

        デフォルトの動作では、未使用のデータはキャッシュファイルから削除されます。削除せずにファイルに保持したい場合は、`accumulate`を使用してください。  
- **--xlate-update**

    このオプションは、必要がない場合でもキャッシュファイルを更新するように強制します。

# COMMAND LINE INTERFACE

このモジュールは、配布されている`xlate`コマンドを使用してコマンドラインから簡単に使用できます。使用方法については、`xlate`マンページを参照してください。

`xlate`コマンドはDocker環境と連携して動作するため、手元に何もインストールされていなくても、Dockerが利用可能であれば使用できます。`-D`または`-C`オプションを使用してください。  

また、さまざまな文書スタイルのためのMakefileが提供されているため、特別な指定なしに他の言語への翻訳が可能です。`-M`オプションを使用してください。  

Dockerと`make`オプションを組み合わせて、Docker環境で`make`を実行できます。

`xlate -C`のように実行すると、現在の作業中のgitリポジトリがマウントされたシェルが起動します。

詳細については["SEE ALSO"](#see-also)セクションの日本語の記事をお読みください。  

# EMACS

リポジトリに含まれる`xlate.el`ファイルをロードして、Emacsエディタから`xlate`コマンドを使用します。`xlate-region`関数は指定された領域を翻訳します。デフォルトの言語は`EN-US`で、プレフィックス引数を使用して言語を指定できます。  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービスの認証キーを設定します。  

- OPENAI\_API\_KEY

    OpenAI認証キー。  

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

    DeepL PythonライブラリとCLIコマンド。  

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythonライブラリ  

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAIコマンドラインインターフェース  

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    ターゲットテキストパターンに関する詳細は**greple**マニュアルを参照してください。**--inside**、**--outside**、**--include**、**--exclude**オプションを使用してマッチングエリアを制限します。  

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate`モジュールを使用して、**greple**コマンドの結果によってファイルを修正できます。  

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**を使用して、**-V**オプションとともにコンフリクトマーカー形式を並べて表示します。  

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe**モジュールは、**--xlate-stripe**オプションによって使用されます。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL APIを使用して必要な部分のみを翻訳および置換するGrepleモジュール（日本語）  

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL APIモジュールを使用して15言語で文書を生成する（日本語）  

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL APIを使用した自動翻訳Docker環境（日本語）  

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
