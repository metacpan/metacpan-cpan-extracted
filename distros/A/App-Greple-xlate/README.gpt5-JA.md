# NAME

App::Greple::xlate - greple のための翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9915

# DESCRIPTION

**Greple** **xlate** モジュールは、目的のテキストブロックを見つけて翻訳されたテキストに置き換えます。現在、DeepL（`deepl.pm`）、ChatGPT 4.1（`gpt4.pm`）、および GPT-5（`gpt5.pm`）モジュールがバックエンドエンジンとして実装されています。

Perl の POD 形式で書かれた文書内の通常のテキストブロックを翻訳したい場合は、**greple** コマンドに `xlate::deepl` と `perl` モジュールを組み合わせて次のように使用します:

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

このコマンドにおいて、パターン文字列 `^([\w\pP].*\n)+` は英数字および句読記号で始まる連続行を意味します。このコマンドは翻訳対象の領域をハイライト表示します。オプション **--all** は全文を出力するために使用します。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

続いて選択領域を翻訳するために `--xlate` オプションを追加します。すると、所望のセクションを見つけて **deepl** コマンドの出力で置き換えます。

デフォルトでは、原文と訳文は [git(1)](http://man.he.net/man1/git) と互換性のある「コンフリクトマーカー」形式で出力されます。`ifdef` 形式を使うと、[unifdef(1)](http://man.he.net/man1/unifdef) コマンドで必要な部分だけを簡単に取得できます。出力形式は **--xlate-format** オプションで指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

全文を翻訳したい場合は、**--match-all** オプションを使用します。これは、全文にマッチするパターン `(?s).+` を指定するショートカットです。

コンフリクトマーカー形式のデータは、[sdif](https://metacpan.org/pod/App%3A%3Asdif) コマンドに `-V` オプションを付けてサイドバイサイド表示することができます。文字列単位で比較しても意味がないため、`--no-cdif` オプションを推奨します。文字の色付けが不要な場合は、`--no-textcolor`（または `--no-tc`）を指定してください。

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

処理は指定した単位で行われますが、空でない複数行の連続したテキストの場合は、まとめて 1 行に変換されます。この操作は次のように行われます:

- 各行の先頭と末尾の空白を削除します。
- 行が全角の句読点で終わる場合は、次の行と連結します。
- 行が全角文字で終わり、次の行が全角文字で始まる場合は、行を連結します。
- 行末または行頭のいずれかが全角文字でない場合は、スペース文字を挿入して連結します。

キャッシュデータは正規化後のテキストに基づいて管理されるため、正規化結果に影響しない変更が行われても、キャッシュされた翻訳データは引き続き有効です。

この正規化処理は最初（0 番目）および偶数番目のパターンに対してのみ行われます。したがって、次のように 2 つのパターンが指定された場合、最初のパターンに一致するテキストは正規化後に処理され、2 番目のパターンに一致するテキストには正規化処理は行われません。

    greple -Mxlate -E normalized -E not-normalized

したがって、複数行を 1 行にまとめて処理するテキストには最初のパターンを使用し、整形済みテキストには 2 番目のパターンを使用してください。最初のパターンに一致するテキストがない場合は、`(?!)` のような何にも一致しないパターンを使用します。

# MASKING

ときどき、翻訳したくないテキストの一部があります。たとえば、Markdown ファイル内のタグなどです。DeepL は、そのような場合には除外したいテキスト部分を XML タグに変換してから翻訳し、翻訳完了後に元に戻すことを推奨しています。これをサポートするため、翻訳からマスクする部分を指定できます。

    --xlate-setopt maskfile=MASKPATTERN

ファイル \`MASKPATTERN\` の各行を正規表現として解釈し、それに一致する文字列を変換してから処理後に復元します。先頭が `#` の行は無視されます。

複雑なパターンは、バックスラッシュで改行をエスケープして複数行に記述できます。

マスキングによってテキストがどのように変換されるかは、**--xlate-mask** オプションで確認できます。

このインターフェイスは実験的で、将来変更される可能性があります。

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    一致した各領域ごとに翻訳処理を呼び出します。

    このオプションがない場合、**greple** は通常の検索コマンドとして動作します。したがって、実際の作業を行う前に、ファイルのどの部分が翻訳対象になるかを確認できます。

    コマンド結果は標準出力に出るため、必要に応じてファイルにリダイレクトするか、[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) モジュールの使用を検討してください。

    オプション **--xlate** は **--color=never** オプション付きで **--xlate-color** オプションを呼び出します。

    **--xlate-fold** オプションを指定すると、変換後のテキストは指定した幅で折り返されます。デフォルト幅は 70 で、**--xlate-fold-width** オプションで設定できます。先頭に 4 桁分が突き出し用に予約されるため、1 行あたり最大 74 文字まで保持できます。

- **--xlate-engine**=_engine_

    使用する翻訳エンジンを指定します。`-Mxlate::deepl` のようにエンジンモジュールを直接指定する場合は、このオプションを使う必要はありません。

    現時点では、以下のエンジンが利用可能です。

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** のインターフェイスは不安定で、現時点では正しく動作することを保証できません。

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、ユーザが手動で作業することを想定しています。翻訳対象のテキストを準備したら、クリップボードにコピーします。フォームに貼り付け、得られた結果をクリップボードにコピーし、リターンキーを押してください。

- **--xlate-to** (Default: `EN-US`)

    ターゲット言語を指定します。**DeepL** エンジン使用時は、`deepl languages` コマンドで利用可能な言語を取得できます。

- **--xlate-format**=_format_ (Default: `conflict`)

    原文と翻訳文の出力形式を指定します。

    `xtxt` 以外の以下の形式は、翻訳対象部分が行の集合であることを前提としています。実際には行の一部だけを翻訳することも可能ですが、`xtxt` 以外の形式を指定しても意味のある結果にはなりません。

    - **conflict**, **cm**

        原文と変換後のテキストを [git(1)](http://man.he.net/man1/git) のコンフリクトマーカー形式で出力します。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の [sed(1)](http://man.he.net/man1/sed) コマンドで元のファイルを復元できます。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        原文と翻訳文を Markdown のカスタムコンテナ形式で出力します。

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        上記のテキストは HTML では次のように変換されます。

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        コロンの数はデフォルトで 7 です。`:::::` のようにコロンの並びを指定した場合は、7 個の代わりにそれが使用されます。

    - **ifdef**

        原文と変換後のテキストを [cpp(1)](http://man.he.net/man1/cpp) の `#ifdef` 形式で出力します。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        日本語テキストのみを取り出すには、**unifdef** コマンドを使用します:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        元のテキストと変換後のテキストは、1行の空行で区切って出力されます。`space+` の場合は、変換後のテキストの後に改行も出力します。

    - **xtxt**

        形式が `xtxt`（翻訳済みテキスト）または不明な場合は、翻訳済みテキストのみが出力されます。

- **--xlate-maxlen**=_chars_ (Default: 0)

    一度にAPIへ送信するテキストの最大長を指定します。デフォルト値は無料のDeepLアカウント向けに設定されています: API 用は 128K（**--xlate**）、クリップボードインターフェイス用は 5000（**--xlate-labor**）。Pro サービスを使用している場合は、この値を変更できる場合があります。

- **--xlate-maxline**=_n_ (Default: 0)

    一度にAPIへ送信するテキストの最大行数を指定します。

    1行ずつ翻訳したい場合は、この値を 1 に設定します。このオプションは `--xlate-maxlen` オプションより優先されます。

- **--xlate-prompt**=_text_

    翻訳エンジンに送信するカスタムプロンプトを指定します。このオプションは ChatGPT エンジン（gpt3、gpt4、gpt4o）使用時のみ有効です。AIモデルに具体的な指示を与えることで翻訳動作をカスタマイズできます。プロンプトに `%s` が含まれる場合は、対象言語名に置き換えられます。

- **--xlate-context**=_text_

    翻訳エンジンに送信する追加のコンテキスト情報を指定します。このオプションは複数回使用して、複数のコンテキスト文字列を提供できます。コンテキスト情報は翻訳エンジンが背景を理解し、より正確な翻訳を行うのに役立ちます。

- **--xlate-glossary**=_glossary_

    翻訳に使用する用語集IDを指定します。このオプションは DeepL エンジン使用時のみ有効です。用語集IDは DeepL アカウントから取得し、特定用語の一貫した翻訳を保証します。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR 出力で翻訳結果をリアルタイムに確認します。

- **--xlate-stripe**

    [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) モジュールを使用して、マッチした部分をゼブラストライプ風に表示します。マッチ部分が背中合わせに連結している場合に有用です。

    端末の背景色に応じてカラーパレットが切り替わります。明示的に指定したい場合は、**--xlate-stripe-light** または **--xlate-stripe-dark** を使用できます。

- **--xlate-mask**

    マスキング機能を実行し、復元せずに変換後のテキストをそのまま表示します。

- **--match-all**

    ファイル全体のテキストを対象領域として設定します。

- **--lineify-cm**
- **--lineify-colon**

    `cm` および `colon` 形式の場合、出力は行ごとに分割して整形されます。したがって、行の一部のみを翻訳すると、期待どおりの結果が得られません。これらのフィルタは、行の一部のみを翻訳したことで破損した出力を、通常の行単位の出力に修正します。

    現在の実装では、1行の複数箇所が翻訳された場合、それらは独立した行として出力されます。

# CACHE OPTIONS

**xlate** モジュールは、ファイルごとに翻訳のキャッシュテキストを保存し、実行前に読み込んでサーバーへの問い合わせのオーバーヘッドを排除できます。デフォルトのキャッシュ戦略 `auto` では、対象ファイルにキャッシュファイルが存在する場合にのみキャッシュデータを保持します。

**--xlate-cache=clear** を使用してキャッシュ管理を開始するか、既存のすべてのキャッシュデータをクリーンアップします。このオプションで実行すると、キャッシュファイルが存在しない場合は新規作成され、その後は自動的に維持されます。

- --xlate-cache=_strategy_
    - `auto` (Default)

        キャッシュファイルが存在する場合に維持します。

    - `create`

        空のキャッシュファイルを作成して終了します。

    - `always`, `yes`, `1`

        対象が通常のファイルである限り、キャッシュを常に維持します。

    - `clear`

        まずキャッシュデータを消去します。

    - `never`, `no`, `0`

        存在していてもキャッシュファイルを決して使用しません。

    - `accumulate`

        デフォルトの動作では、未使用のデータはキャッシュファイルから削除されます。削除せずにファイルに保持したい場合は`accumulate`を使用します。
- **--xlate-update**

    このオプションは、必要がなくてもキャッシュファイルの更新を強制します。

# COMMAND LINE INTERFACE

配布物に含まれる`xlate`コマンドを使えば、コマンドラインからこのモジュールを簡単に利用できます。使用方法は`xlate`のmanページを参照してください。

`xlate`コマンドはDocker環境と連携して動作するため、手元に何もインストールしていなくてもDockerが使える環境であれば利用できます。`-D`または`-C`オプションを使用してください。

また、各種ドキュメントスタイル向けのmakefileが提供されているため、特別な指定なしに他言語への翻訳が可能です。`-M`オプションを使用してください。

Dockerと`make`オプションを組み合わせて、Docker環境で`make`を実行することもできます。

`xlate -C`のように実行すると、現在の作業中のgitリポジトリをマウントしたシェルが起動します。

詳細は["SEE ALSO"](#see-also)セクションの日本語記事を参照してください。

# EMACS

リポジトリに含まれる`xlate.el`ファイルを読み込むと、Emacsエディタから`xlate`コマンドを使用できます。`xlate-region`関数は指定したリージョンを翻訳します。デフォルト言語は`EN-US`で、プレフィックス引数を付けて起動すると言語を指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービスの認証キーを設定します。

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

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockerコンテナイメージ。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepLのPythonライブラリおよびCLIコマンド。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythonライブラリ

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAIコマンドラインインターフェイス

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    **greple**マニュアルで対象テキストのパターンについての詳細を参照してください。**--inside**、**--outside**、**--include**、**--exclude**オプションを使用してマッチ範囲を制限します。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate`モジュールを使って、**greple**コマンドの結果でファイルを修正できます。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**を使用すると、**-V**オプションと並べてコンフリクトマーカー形式を表示できます。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe**モジュールは**--xlate-stripe**オプションで使用します。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    DeepL APIで必要な部分だけを翻訳して置換するGrepleモジュール（日本語）

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    DeepL APIモジュールで15言語のドキュメントを生成（日本語）

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    DeepL APIによる自動翻訳Docker環境（日本語）

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
