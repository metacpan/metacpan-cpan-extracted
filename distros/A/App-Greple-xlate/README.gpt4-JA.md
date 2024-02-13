# NAME

App::Greple::xlate - grepleのための翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.30

# DESCRIPTION

**Greple** **xlate** モジュールは、目的のテキストブロックを見つけて、それを翻訳されたテキストで置き換えます。現在、DeepL (`deepl.pm`) と ChatGPT (`gpt3.pm`) モジュールがバックエンドエンジンとして実装されています。gpt-4の実験的なサポートも含まれています。

Perlのpodスタイルで書かれたドキュメント内の通常のテキストブロックを翻訳したい場合は、`xlate::deepl` と `perl` モジュールを使って **greple** コマンドをこのように使用します：

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

このコマンドでは、パターン文字列 `^(\w.*\n)+` は英数字で始まる連続する行を意味します。このコマンドは翻訳されるべきエリアをハイライトして表示します。オプション **--all** は全文を生成するために使用されます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

次に、選択されたエリアを翻訳するために `--xlate` オプションを追加します。すると、望ましいセクションを見つけて、それを **deepl** コマンドの出力で置き換えます。

デフォルトでは、オリジナルテキストと翻訳テキストは、[git(1)](http://man.he.net/man1/git)と互換性のある「コンフリクトマーカー」形式で出力されます。`ifdef`形式を使用すると、[unifdef(1)](http://man.he.net/man1/unifdef)コマンドを使って簡単に必要な部分を取得できます。出力形式は**--xlate-format**オプションで指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

全てのテキストを翻訳したい場合は、**--match-all**オプションを使用します。これは、テキスト全体にマッチするパターン`(?s).+`を指定するショートカットです。

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    各マッチしたエリアに対して翻訳プロセスを呼び出します。

    このオプションがない場合、**greple**は通常の検索コマンドとして動作します。そのため、実際の作業を行う前に、ファイルのどの部分が翻訳の対象になるかを確認できます。

    コマンドの結果は標準出力に出るので、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)モジュールの使用を検討してください。

    オプション**--xlate**は、**--color=never**オプションとともに**--xlate-color**オプションを呼び出します。

    **--xlate-fold** オプションを使用すると、指定された幅で変換されたテキストが折りたたまれます。デフォルトの幅は70で、**--xlate-fold-width** オプションで設定できます。ランイン操作用に4列が予約されているため、各行は最大で74文字を保持できます。

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定します。`-Mxlate::deepl` のようにエンジンモジュールを直接指定する場合、このオプションを使用する必要はありません。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、あなたが作業することが期待されています。翻訳するテキストを準備した後、それらはクリップボードにコピーされます。あなたはそれらをフォームに貼り付け、結果をクリップボードにコピーし、リターンキーを押すことが期待されています。

- **--xlate-to** (Default: `EN-US`)

    対象言語を指定します。**DeepL** エンジンを使用する場合、利用可能な言語は `deepl languages` コマンドで取得できます。

- **--xlate-format**=_format_ (Default: `conflict`)

    元のテキストと翻訳されたテキストの出力形式を指定します。

    - **conflict**, **cm**

        元のテキストと変換されたテキストは、[git(1)](http://man.he.net/man1/git) コンフリクトマーカー形式で印刷されます。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の [sed(1)](http://man.he.net/man1/sed) コマンドによって元のファイルを復元できます。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        原文と変換されたテキストは、[cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 形式で印刷されます。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        **unifdef** コマンドを使って、日本語のテキストのみを取得できます：

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        原文と変換されたテキストは、単一の空白行で区切られて印刷されます。

    - **xtxt**

        形式が `xtxt`（翻訳されたテキスト）または不明な場合、翻訳されたテキストのみが印刷されます。

- **--xlate-maxlen**=_chars_ (Default: 0)

    一度にAPIに送信するテキストの最大長を指定します。デフォルト値は無料のDeepLアカウントサービス用に設定されています：API用は128K（**--xlate**）、クリップボードインターフェース用は5000（**--xlate-labor**）。Proサービスを使用している場合は、これらの値を変更できるかもしれません。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    標準エラー出力（STDERR）でリアルタイムに翻訳結果を確認します。

- **--match-all**

    ファイルの全テキストを対象領域として設定します。

# CACHE OPTIONS

**xlate** モジュールは、各ファイルの翻訳されたテキストのキャッシュを保存し、実行前に読み込むことで、サーバーに問い合わせるオーバーヘッドを排除できます。デフォルトのキャッシュ戦略 `auto` では、対象ファイルのキャッシュファイルが存在する場合にのみキャッシュデータを維持します。

- --cache-clear

    **--cache-clear** オプションは、キャッシュ管理を開始するため、または既存のキャッシュデータをリフレッシュするために使用できます。このオプションで実行すると、キャッシュファイルが存在しない場合は新しいキャッシュファイルが作成され、その後自動的に維持されます。

- --xlate-cache=_strategy_
    - `auto` (Default)

        キャッシュファイルが存在する場合は、そのファイルを維持します。

    - `create`

        空のキャッシュファイルを作成して終了します。

    - `always`, `yes`, `1`

        対象が通常のファイルである限り、キャッシュを維持します。

    - `clear`

        まずキャッシュデータをクリアします。

    - `never`, `no`, `0`

        キャッシュファイルが存在しても、決してキャッシュファイルを使用しません。

    - `accumulate`

        デフォルトの動作では、使用されていないデータはキャッシュファイルから削除されます。それらを削除せずにファイルに保持したい場合は、`accumulate` を使用してください。

# COMMAND LINE INTERFACE

リポジトリに含まれる `xlate` コマンドを使用することで、このモジュールをコマンドラインから簡単に使用できます。使用方法については、`xlate` のヘルプ情報を参照してください。

# EMACS

リポジトリに含まれる `xlate.el` ファイルをロードして、Emacs エディターから `xlate` コマンドを使用します。`xlate-region` 関数は指定された範囲を翻訳します。デフォルト言語は `EN-US` で、プレフィックス引数を使って言語を指定することができます。

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービスの認証キーを設定してください。

- OPENAI\_API\_KEY

    OpenAIの認証キー。

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

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL PythonライブラリとCLIコマンド。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythonライブラリ

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAIコマンドラインインターフェース

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    対象テキストパターンの詳細については、**greple**マニュアルを参照してください。マッチングエリアを限定するには、**--inside**、**--outside**、**--include**、**--exclude**オプションを使用します。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate`モジュールを使用して、**greple**コマンドの結果によってファイルを変更できます。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**を使用して、**-V**オプションでコンフリクトマーカー形式を並べて表示します。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL APIを使用して必要な部分のみを翻訳・置換するGrepleモジュール（日本語）

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL APIモジュールで15言語の文書を生成（日本語）

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL APIを使用した自動翻訳Docker環境（日本語）

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
