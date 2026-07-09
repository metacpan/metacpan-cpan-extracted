# NAME

App::Greple::xlate - greple のための翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.01

# DESCRIPTION

**Greple** **xlate** モジュールは目的のテキストブロックを見つけ、それらを翻訳されたテキストに置き換えます。主要なエンジンは GPT-5.5（`llm/gpt5.pm`）で、[llm](https://llm.datasette.io/) コマンドを呼び出します。DeepL（`deepl.pm`）および従来の **gpty** ベースのエンジンも含まれています。

翻訳はファイルごとにキャッシュされるため、変更されていないテキストについてはコマンドを再実行してもコストはかかりません。文書が編集された場合、変更された段落だけが再度 API に送信されます。コンテキスト対応エンジンには、周囲の翻訳、変更箇所の周辺の生のソーステキスト、および編集された段落の以前のバージョンも渡されるため、新しい翻訳は確立済みの言い回しを維持します（**--xlate-context-window** を参照）。機密文字列は送信前に隠蔽できます（["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates) を参照）。

Perlのpodスタイルで書かれた文書内の通常のテキストブロックを翻訳したい場合は、次のように **greple** コマンドを `--xlate-engine gpt5` および `perl` モジュールとともに使用してください。

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

このコマンドにおいて、パターン文字列 `^([\w\pP].*\n)+` は英数字および句読記号で始まる連続行を意味します。このコマンドは翻訳対象の領域をハイライト表示します。オプション **--all** は全文を出力するために使用します。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

続いて選択領域を翻訳するために `--xlate` オプションを追加します。すると、所望のセクションを見つけて翻訳エンジンの出力で置き換えます。

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

これは、ファイルの各行を`MASKPATTERN`として正規表現として解釈し、それにマッチする文字列を翻訳して処理後に元に戻します。`#`で始まる行は無視されます。

複雑なパターンは、バックスラッシュで改行をエスケープして複数行に記述できます。

マスキングによってテキストがどのように変換されるかは、**--xlate-mask** オプションで確認できます。

マスキングはマークアップが翻訳されないように保護します。翻訳サービス自体から機密文字列を隠蔽するには、["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)を参照してください。両方を併用できます。

このインターフェイスは実験的で、将来変更される可能性があります。

# ANONYMIZATION AND TEMPLATES

機密性の高い文字列は、翻訳 API に送信される前に隠蔽し、出力で復元できます。匿名化ルールのソースは 3 種類あります: 辞書ファイル（**--xlate-anonymize**）、文書自体のインラインマーク（**--xlate-anonymize-mark**）、および YAML フロントマターの値（**--xlate-frontmatter**）です。各文字列は、送信中に `<person id=1 />` のようなカテゴリタグに置き換えられます。隠蔽の対象は API 送信のみです。ローカルキャッシュファイルには復元されたプレーンテキストが保存されます。何が送信されるかを正確に確認するには、**--xlate-dryrun** を使用してください。

フォーム文書（四半期報告書など）では、アクターを最初に定義し、本文で参照します:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

言語ごとにテンプレートを一度、`--xlate-template`（値をファイル内に保持する場合は `--xlate-frontmatter` も）で翻訳し、その後 **pandoc-embedz** スタンドアロンモードで各ケースをレンダリングします。外部設定の `global:` 配下の値は、翻訳 API にはまったく送信されません:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

インラインマークについては、マクロ定義設定を指定すると、同じ翻訳済みテンプレートで実名または墨消し版のいずれもレンダリングできます:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

文書に embedz ブロックが含まれている場合は、それらを翻訳対象から除外します:

    --exclude '^```embedz\n(?s:.*?)^```\n'

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

    使用する翻訳エンジンを指定します。

    現時点では、以下のエンジンが利用可能です。

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    エンジンモジュールはまずバックエンド名前空間（`llm`、次に `gpty`）で検索され、その後 `App::Greple::xlate` の直下で検索されます。したがって `gpt5` は `llm` コマンドを呼び出す `App::Greple::xlate::llm::gpt5` をロードし、一方 `gpt4o` は `App::Greple::xlate::gpty::gpt4o` にフォールバックします。特定のバックエンドを強制するには `--xlate-setopt backend=gpty` を使用してください。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、ユーザが手動で作業することを想定しています。翻訳対象のテキストを準備したら、クリップボードにコピーします。フォームに貼り付け、得られた結果をクリップボードにコピーし、リターンキーを押してください。

- **--xlate-to** (Default: `EN-US`)

    ターゲット言語を指定します。LLM エンジンは、モデルが理解する任意の言語名またはコードを受け付けます。これは翻訳プロンプトに埋め込まれます。**DeepL** エンジン使用時は、`deepl languages` コマンドで利用可能な言語を取得できます。

- **--xlate-from** (Default: `ORIGINAL`)

    `conflict`、`colon`、`ifdef` 出力形式で原文に使用されるラベルです。**DeepL** エンジンでは、デフォルト以外の値もソース言語として渡されます。

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

    一度にAPIへ送信するテキストの最大長を指定します。デフォルト値 0 はエンジン自身の制限を意味します: 無料のDeepLアカウントサービスでは、API 用は 128K（**--xlate**）、クリップボードインターフェイス用は 5000（**--xlate-labor**）です。Pro サービスを使用している場合は、この値を変更できる場合があります。

- **--xlate-maxline**=_n_ (Default: 0)

    一度にAPIへ送信するテキストの最大行数を指定します。

    1行ずつ翻訳したい場合は、この値を 1 に設定します。このオプションは `--xlate-maxlen` オプションより優先されます。

- **--xlate-prompt**=_text_

    翻訳エンジンに送信するカスタムプロンプトを指定します。このオプションはLLMエンジン（`gpt3`、`gpt4o`、`gpt5`）で利用できますが、DeepLでは利用できません。AIモデルに具体的な指示を与えることで、翻訳の動作をカスタマイズできます。プロンプトに`%s`が含まれている場合、それは対象言語名に置き換えられます。

- **--xlate-context**=_text_

    翻訳エンジンに送信する追加のコンテキスト情報を指定します。このオプションは複数回使用して、複数のコンテキスト文字列を提供できます。コンテキスト情報は翻訳エンジンが背景を理解し、より正確な翻訳を行うのに役立ちます。

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    変更されたブロックを再翻訳する際に参照コンテキストとして渡される周辺の翻訳済みブロック数（デフォルトは2）です。このコンテキストには、変更領域の周囲にある生のソーステキスト（見出し、リスト構造、キャプション）も含まれ、利用可能な場合は、キャッシュから復元された変更テキストの以前のバージョンも含まれるため、変更されていない表現が保持されます。コンテキスト対応翻訳を完全に無効にするには0に設定します。各変更領域はそれぞれ独自のAPI呼び出しで翻訳され、コンテキストによりシステムプロンプトへ最大約8000文字が追加される可能性があるため、コンテキスト対応翻訳は一貫性と引き換えに多少の追加コストを伴うことに注意してください。

- **--xlate-cache-seed**=_file_

    新しい文書のキャッシュを別の文書のキャッシュファイルから初期化します。定期レポートに有用です。新しい号のキャッシュに前号のキャッシュをシードすることで、変更されていない段落は再翻訳されず、編集された段落は前号の表現を維持します。シードは対象キャッシュが空の場合にのみ使用され、それ以外の場合は警告とともに無視されます。デフォルトの `--xlate-cache=auto` では、シードを指定すると新しい文書のキャッシュファイルも作成されます。

- **--xlate-anonymize**=_file_

    機密文字列を翻訳APIに送信する前に匿名化し、出力で復元します。辞書ファイルは項目ごとに1つのエントリを与えます。JSON（標準的で、機械生成可能）

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    または単純な行形式（regexの場合は `category pattern`、`/.../`）で指定します。各項目は `<person id=1 />` のようなカテゴリタグに置き換えられます。同じ文字列には常に同じタグが割り当てられるため、モデルは誰が誰であるかを追跡できます。不明なJSONフィールドは無視されるため、生成器（たとえばエンティティを抽出するローカルLLM）は独自の注釈を追加できます。カテゴリ `lit` は予約されています。ローカルキャッシュファイルには復元済みの平文が引き続き保存されます。秘匿対象はAPI送信のみです。

    辞書は外部ツールで生成できます。たとえば、機密エンティティを抽出するローカルモデルです。

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    ファイル内のUTF-8 BOMは許容されます。フロントマターの行形式における値は、値の後ではなく、それだけの行に限って末尾コメントを持つことができます。

- **--xlate-anonymize-mark**\[=_regex_\]

    文書自体のインラインマークから匿名化エントリを収集します。最初の出現箇所を `{{ person("山田太郎") }}` のようにマークすると、その文字列の文書全体のすべての出現箇所が匿名化されます。マーク自体はソースおよび翻訳内に残るため、文書はJinja2スタイルのマクロプロセッサでも処理できます（名前を表示または墨消しするように `person` マクロを定義します）。カスタム _regex_ には、`(?<category>...)` と `(?<text>...)` という名前付きキャプチャを含める必要があります。

    このような任意値オプションでは、後続のファイル引数が値として扱われることに注意してください。デフォルト表記を使用する場合は、`--xlate-anonymize-mark=`（末尾に `=` を付けて）と書いてください。

    別の表記も設定できます。たとえば `@@person:NAME@@` スタイルのマークには `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'`、またはレンダリング済みMarkdownで不可視のままになるHTMLコメント形式などです。マーク規則は文書ごとに収集されます。ある入力ファイルでマークされた文字列は、同じ実行中の別ファイルでは秘匿されません（ファイル間で蓄積されるフロントマター値とは異なります）。

- **--xlate-template**\[=_regex_\]

    テンプレート式（デフォルト: Jinja2 `{{ ... }}`、`{% ... %}`、`{# ... #}`）を不透明なプレースホルダとして扱います。モデルにはそれらを変更せずにコピーするよう指示し、ブロックごとに、応答にまったく同じ式がそれぞれ同じ回数含まれていることを検証します。翻訳では対象言語の語順に合わせてそれらを並べ替えることが正当であるため、順序は変わる場合があります。式が壊れている場合は実行を中止します。キャッシュはチェックポイントされて凍結されるため、支払い済みのものが失われることはありません。

    このようなオプション値が任意のオプションでは、後続のファイル引数が値として扱われることに注意してください。デフォルトの表記を使用する場合は、`--xlate-template=`（末尾に `=` を付けて）と書きます。

- **--xlate-frontmatter**

    先頭の `---` ... `---` ブロックを YAML フロントマターとして扱います。翻訳およびフェーズ2のコンテキストスライスから除外し、そのフラットな `key: value` 値を安全策として匿名化ルール（カテゴリ `var`）に追加します。複数の入力ファイルがある場合、収集された値は蓄積されます（秘匿する側に倒します）。

    閉じる `---` の後には必ず空行を残してください。段落スタイルのマッチパターンでは、フロントマターが本文テキストに直接続いていると、除外で抑制できないまたがりブロックが1つ形成されます（その場合は警告が出力されます）。値は引き続き匿名化されますが、フロントマター自体は翻訳に送信されます。

- **--xlate-glossary**=_glossary_

    翻訳に使用する用語集IDを指定します。このオプションは DeepL エンジン使用時のみ有効です。用語集IDは DeepL アカウントから取得し、特定用語の一貫した翻訳を保証します。

- **--xlate-dryrun**

    翻訳 API を呼び出さず、代わりに進捗表示を通じて、各ペイロードを送信されるとおり（匿名化およびマスキング後）正確に表示します。マシンから何が出ていくかを確認し、実行コストを見積もるのに有用です。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR 出力で翻訳結果をリアルタイムに確認します。`From` ペイロードは、匿名化およびマスキング後に送信されるとおりに表示されます。

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

`xlate` コマンドは、`--to-lang`、`--from-lang`、`--engine`、`--file` などの GNU 形式のロングオプションをサポートします。`xlate -h` を使用して、利用可能なすべてのオプションを確認してください。

`xlate`コマンドはDocker環境と連携して動作するため、手元に何もインストールしていなくてもDockerが使える環境であれば利用できます。`-D`または`-C`オプションを使用してください。

Docker の操作は[App::dozo](https://metacpan.org/pod/App%3A%3Adozo)によって処理され、単独のコマンドとしても使用できます。`dozo`コマンドは、コンテナ設定を永続化するために`.dozorc`構成ファイルをサポートします。

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

    レガシー**gpty**エンジンで使用されるOpenAIの認証キー。`llm`ベースの**gpt5**エンジンもこの変数を読み取りますが、`llm keys set openai`で保存されたキーも使用できます。

- GREPLE\_XLATE\_CACHE

    デフォルトのキャッシュ戦略を設定します（["CACHE OPTIONS"](#cache-options)を参照）。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

使用するエンジン用のコマンドラインツールをインストールします。**gpt5**エンジンには`llm`、DeepLには`deepl`、レガシーGPTエンジンには`gpty`を使用します。

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - xlate がコンテナ操作に使用する汎用 Docker ランナー

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    **greple**マニュアルで対象テキストのパターンについての詳細を参照してください。**--inside**、**--outside**、**--include**、**--exclude**オプションを使用してマッチ範囲を制限します。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate`モジュールを使って、**greple**コマンドの結果でファイルを修正できます。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**を使用すると、**-V**オプションと並べてコンフリクトマーカー形式を表示できます。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe**モジュールは**--xlate-stripe**オプションで使用します。

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockerコンテナイメージ。

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh`ライブラリは、`xlate`スクリプトおよび[App::dozo](https://metacpan.org/pod/App%3A%3Adozo)でのオプション解析に使用されます。

- [https://llm.datasette.io/](https://llm.datasette.io/)

    **gpt5**エンジンがLLMモデルにアクセスするために使用する`llm`コマンド。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepLのPythonライブラリおよびCLIコマンド。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Pythonライブラリ

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAIコマンドラインインターフェイス

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

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
