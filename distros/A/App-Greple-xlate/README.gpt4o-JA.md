# NAME

App::Greple::xlate - grepleの翻訳サポートモジュール  

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9904

# DESCRIPTION

**Greple** **xlate**モジュールは、希望するテキストブロックを見つけ、それを翻訳されたテキストに置き換えます。現在、DeepL (`deepl.pm`) と ChatGPT (`gpt3.pm`) モジュールがバックエンドエンジンとして実装されています。gpt-4およびgpt-4oの実験的サポートも含まれています。  

Perlのpodスタイルで書かれたドキュメント内の通常のテキストブロックを翻訳したい場合は、次のように**greple**コマンドを`xlate::deepl`および`perl`モジュールと共に使用します：  

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

このコマンドでは、パターン文字列 `^([\w\pP].*\n)+` は、英数字および句読点文字で始まる連続した行を意味します。このコマンドは、翻訳されるべき領域をハイライト表示します。オプション **--all** は、全体のテキストを生成するために使用されます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に、選択した領域を翻訳するために`--xlate`オプションを追加します。そうすると、希望するセクションを見つけて、それを**deepl**コマンドの出力で置き換えます。  

デフォルトでは、元のテキストと翻訳されたテキストは、[git(1)](http://man.he.net/man1/git)と互換性のある「コンフリクトマーカー」形式で印刷されます。`ifdef`形式を使用すると、[unifdef(1)](http://man.he.net/man1/unifdef)コマンドで簡単に希望する部分を取得できます。出力形式は**--xlate-format**オプションで指定できます。  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

全体のテキストを翻訳したい場合は、**--match-all**オプションを使用します。これは、全体のテキストに一致する`(?s).+`パターンを指定するためのショートカットです。  

コンフリクトマーカー形式のデータは、`sdif`コマンドと`-V`オプションを使用して、サイドバイサイドスタイルで表示できます。文字列ごとに比較する意味がないため、`--no-cdif`オプションが推奨されます。テキストに色を付ける必要がない場合は、`--no-textcolor`（または`--no-tc`）を指定します。  

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

処理は指定された単位で行われますが、空でないテキストの複数行のシーケンスの場合、それらは一つの行にまとめて変換されます。この操作は次のように行われます：  

- 各行の先頭と末尾の空白を削除します。  
- 行が全角の句読点で終わる場合、次の行と連結します。  
- 行が全角文字で終わり、次の行が全角文字で始まる場合、行を連結します。  
- 行の終わりまたは始まりが全角文字でない場合、スペース文字を挿入して連結します。  

キャッシュデータは正規化されたテキストに基づいて管理されるため、正規化結果に影響を与えない修正が行われても、キャッシュされた翻訳データは依然として有効です。  

この正規化プロセスは、最初（0番目）および偶数番号のパターンに対してのみ実行されます。したがって、次のように2つのパターンが指定されている場合、最初のパターンに一致するテキストは正規化後に処理され、2番目のパターンに一致するテキストには正規化プロセスは実行されません。  

    greple -Mxlate -E normalized -E not-normalized

したがって、複数の行を1行に結合して処理するテキストには最初のパターンを使用し、整形済みテキストには2番目のパターンを使用します。最初のパターンに一致するテキストがない場合は、`(?!)`のように何にも一致しないパターンを使用してください。

# MASKING

時折、翻訳したくないテキストの部分があります。例えば、マークダウンファイルのタグなどです。DeepLは、そのような場合、除外するテキスト部分をXMLタグに変換し、翻訳後に元に戻すことを提案しています。これをサポートするために、翻訳からマスクする部分を指定することが可能です。  

    --xlate-setopt maskfile=MASKPATTERN

この機能は、ファイル \`MASKPATTERN\` の各行を正規表現として解釈し、それに一致する文字列を翻訳し、処理後に元に戻します。`#` で始まる行は無視されます。  

複雑なパターンは、バックスラッシュでエスケープされた改行を使って複数行に書くことができます。

テキストがマスキングによってどのように変換されるかは、**--xlate-mask** オプションで確認できます。

このインターフェースは実験的であり、将来的に変更される可能性があります。  

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    一致した領域ごとに翻訳プロセスを呼び出します。  

    このオプションがない場合、**greple** は通常の検索コマンドとして動作します。したがって、実際の作業を開始する前に、ファイルのどの部分が翻訳の対象になるかを確認できます。  

    コマンドの結果は標準出力に出力されるため、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) モジュールの使用を検討してください。  

    オプション **--xlate** は、**--color=never** オプションを伴って **--xlate-color** オプションを呼び出します。  

    **--xlate-fold** オプションを使用すると、変換されたテキストが指定された幅で折りたたまれます。デフォルトの幅は70で、**--xlate-fold-width** オプションで設定できます。ランイン操作のために4列が予約されているため、各行は最大74文字を保持できます。  

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定します。`-Mxlate::deepl` のようにエンジンモジュールを直接指定する場合、このオプションを使用する必要はありません。  

    現時点で利用可能なエンジンは以下の通りです。  

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** のインターフェースは不安定であり、現時点では正しく動作することが保証されていません。  

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

        \`\`\`markdown
        &lt;custom-container>
        The original and translated text are output in a markdown's custom container style.
        元のテキストと翻訳されたテキストは、マークダウンのカスタムコンテナスタイルで出力されます。
        &lt;/custom-container>
        \`\`\`

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

        コロンの数はデフォルトで7です。  
        `:::::`のようにコロンのシーケンスを指定すると、7つのコロンの代わりに使用されます。

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

        元のテキストと変換されたテキストは、1つの空白行で区切られて印刷されます。
        `space+`の場合、変換されたテキストの後に改行も出力されます。

    - **xtxt**

        形式が `xtxt`（翻訳されたテキスト）または不明な場合、翻訳されたテキストのみが印刷されます。  

- **--xlate-maxlen**=_chars_ (Default: 0)

    一度にAPIに送信するテキストの最大長を指定します。デフォルト値は、無料のDeepLアカウントサービスに設定されています：API（**--xlate**）用に128K、クリップボードインターフェース（**--xlate-labor**）用に5000です。Proサービスを使用している場合、これらの値を変更できるかもしれません。  

- **--xlate-maxline**=_n_ (Default: 0)

    一度にAPIに送信するテキストの最大行数を指定します。

    この値を1に設定すると、一度に1行を翻訳することができます。このオプションは`--xlate-maxlen`オプションよりも優先されます。  

- **--**\[**no-**\]**xlate-progress** (Default: True)

    リアルタイムでSTDERR出力に翻訳結果を表示します。  

- **--xlate-stripe**

    [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) モジュールを使用して、ゼブラストライプのスタイルで一致した部分を表示します。これは、一致した部分が連続している場合に便利です。

    ターミナルの背景色に応じてカラーパレットが切り替わります。明示的に指定したい場合は、**--xlate-stripe-light** または **--xlate-stripe-dark** を使用できます。

- **--xlate-mask**

    マスキング機能を実行し、復元せずに変換されたテキストをそのまま表示します。

- **--match-all**

    ファイル全体のテキストをターゲットエリアとして設定します。  

# CACHE OPTIONS

**xlate**モジュールは、各ファイルの翻訳のキャッシュテキストを保存し、実行前にそれを読み込むことでサーバーへの問い合わせのオーバーヘッドを排除できます。デフォルトのキャッシュ戦略`auto`では、ターゲットファイルのキャッシュファイルが存在する場合のみキャッシュデータを維持します。  

**--xlate-cache=clear**を使用して、キャッシュ管理を開始するか、既存のキャッシュデータをすべてクリーンアップします。このオプションで実行されると、存在しない場合は新しいキャッシュファイルが作成され、その後自動的に維持されます。

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

        デフォルトの動作では、未使用のデータはキャッシュファイルから削除されます。削除せずにファイルに保持したい場合は、`accumulate`を使用します。  
- **--xlate-update**

    このオプションは、必要でなくてもキャッシュファイルを更新することを強制します。

# COMMAND LINE INTERFACE

このモジュールは、配布に含まれている`xlate`コマンドを使用することで、コマンドラインから簡単に使用できます。使用法については、`xlate`マニュアルページを参照してください。

`xlate`コマンドはDocker環境と連携して動作するため、手元に何もインストールされていなくても、Dockerが利用可能であれば使用できます。`-D`または`-C`オプションを使用してください。  

さまざまな文書スタイルのためのMakefileが提供されているため、特別な指定なしに他の言語への翻訳が可能です。`-M`オプションを使用してください。  

DockerとMakeオプションを組み合わせて、Docker環境でMakeを実行することもできます。  

`xlate -GC`のように実行すると、現在の作業中のgitリポジトリがマウントされたシェルが起動します。  

詳細については["SEE ALSO"](#see-also)セクションの日本語の記事をお読みください。  

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -u   force update cache
        -s   silent mode
        -e # translation engine (*deepl, gpt3, gpt4, gpt4o)
        -p # pattern to determine translation area
        -x # file containing mask patterns
        -w # wrap line by # width
        -o # output format (*xtxt, cm, ifdef, space, space+, colon)
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   end of option
        N.B. default is marked as *

    Make options
        -M   run make
        -n   dry-run

    Docker options
        -D * run xlate on the container with the same parameters
        -C * execute following command on the container, or run shell
        -S * start the live container
        -A * attach to the live container
        N.B. -D/-C/-A terminates option handling

        -G   mount git top-level directory
        -H   mount home directory
        -V # specify mount directory
        -U   do not mount
        -R   mount read-only
        -L   do not remove and keep live container
        -K   kill and remove live container
        -E # specify environment variable to be inherited
        -I # docker image or version (default: tecolicom/xlate:version)

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef, colon, space)
        *.ENGINE  translation engine (deepl, gpt3, gpt4, gpt4o)

# EMACS

リポジトリに含まれる`xlate.el`ファイルを読み込んで、Emacsエディタから`xlate`コマンドを使用します。`xlate-region`関数は指定された領域を翻訳します。デフォルトの言語は`EN-US`で、プレフィックス引数を使用して言語を指定できます。  

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

    **-V**オプションを使用して、**sdif**で競合マーカー形式を横に表示します。  

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** モジュールは **--xlate-stripe** オプションによって使用されます。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL APIを使用して必要な部分のみを翻訳および置換するためのGrepleモジュール（日本語）  

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL APIモジュールを使用して15言語で文書を生成する（日本語）  

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    自動翻訳Docker環境とDeepL API（日本語）

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
