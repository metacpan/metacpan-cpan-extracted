# NAME

App::Greple::xlate - greple 用の翻訳サポートモジュール

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** モジュールが対象のテキストブロックを検索し、翻訳されたテキストに置き換えます。メインのエンジンは GPT-5.5 (`llm/gpt5.pm`) で、[llm](https://llm.datasette.io/) コマンドを呼び出します。 DeepL (`deepl.pm`) や、従来の **gpty** ベースのエンジンも含まれています。

翻訳結果はファイルごとにキャッシュされるため、変更のないテキストに対してコマンドを再実行してもコストはかかりません。 ドキュメントが編集された場合、変更された段落のみが再度APIに送信されます。また、コンテキスト認識型エンジンには、周囲の翻訳、変更箇所の前後の原文、および編集された段落の以前のバージョンも送信されるため、新しい翻訳でも従来の表現が維持されます（**--xlate-context-window**を参照）。 機密性の高い文字列は、送信前に非表示にすることができます（["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)を参照）。

Perlのpodスタイルで記述されたドキュメント内の通常のテキストブロックを翻訳したい場合は、**greple**コマンドを`--xlate-engine gpt5`および`perl`モジュールと組み合わせて、次のように使用します：

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

このコマンドのパターン文字列`^([ \wpP].*n)+` は、英数字と句読点で始まる連続した行を意味します。このコマンドは、翻訳される領域が強調表示されます。オプション**--all**はテキスト全体を翻訳するのに使われます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

その後、`--xlate` オプションを追加して、選択した領域を翻訳します。これにより、対象のセクションが検出され、翻訳エンジンの出力に置き換えられます。

デフォルトでは、原文と訳文は [git(1)](http://man.he.net/man1/git) と互換性のある "conflict marker" フォーマットで出力されます。`ifdef`形式を使えば、[unifdef(1)](http://man.he.net/man1/unifdef)コマンドで簡単に目的の部分を得ることができます。出力形式は**--xlate-format**オプションで指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

テキスト全体を翻訳したい場合は、**--match-all**オプションを使います。これはテキスト全体にマッチするパターン`(?s).+`を指定するショートカットです。

[sdif](https://metacpan.org/pod/App%3A%3Asdif)コマンドに`-V`オプションをつけると、競合マーカーフォーマットのデータを並べて表示することができます。文字列ごとに比較するのは意味がないので、`--no-cdif`オプションの使用をお勧めします。テキストに色をつける必要がない場合は`--no-textcolor`（または`--no-tc`）を指定してください。

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

処理は指定された単位で行われるが、空でないテキストが複数行連続している場合は、それらをまとめて1行に変換します。この処理は次のように行われる：

- 各行の先頭と末尾の空白を取り除く。
- 行末が全角句読点の場合は、次の行と連結します。
- ある行が全角文字で終わり、次の行が全角文字で始まる場合、その行を連結します。
- 行末または行頭が全角文字でない場合は、スペース文字を挿入して連結します。

キャッシュデータは正規化されたテキストに基づいて管理されるため、正規化結果に影響を与えない範囲で修正を加えても、キャッシュされた翻訳データは有効です。

この正規化処理は、最初の（0 番目の）偶数パターンに対してのみ行われます。したがって、以下のように2つのパターンを指定した場合、1つ目のパターンにマッチするテキストは正規化処理後に処理され、2つ目のパターンにマッチするテキストには正規化処理は行われないです。

    greple -Mxlate -E normalized -E not-normalized

したがって、複数行を1行にまとめて処理するテキストには最初のパターンを使い、整形済みテキストには2番目のパターンを使う。最初のパターンにマッチするテキストがない場合は、`(?!)`のように何もマッチしないパターンを使う。

# MASKING

時々、翻訳してほしくないテキストの部分があります。例えば、マークダウン・ファイルのタグなどです。DeepL では、このような場合、除外するテキストの部分を XML タグに変換して翻訳し、翻訳完了後に復元することを推奨しています。これをサポートするために、翻訳からマスクする部分を指定できます。

    --xlate-setopt maskfile=MASKPATTERN

ファイル`MASKPATTERN`の各行を正規表現として解釈し、一致する文字列を翻訳後、処理後に元に戻します。`#`で始まる行は無視されます。

複雑なパターンは、バックスラッシュでエスケープした改行を含めて複数行で記述できます。

マスキングによってテキストがどのように変換されるかは、**--xlate-mask**オプションで見ることができます。

マスキングにより、マークアップが翻訳されるのを防ぐことができます。翻訳サービス自体から機密性の高い文字列を隠すには、["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)を参照してください。両方を併用することも可能です。

このインターフェースは実験的なものであり、将来変更される可能性があります。

# ANONYMIZATION AND TEMPLATES

機密性の高い文字列は、翻訳APIに送信される前に隠蔽し、出力時に復元することができます。 匿名化ルールのソースとして、辞書ファイル（**--xlate-anonymize**）、ドキュメント内のインラインマーク（**--xlate-anonymize-mark**）、YAMLフロントマターの値（**--xlate-frontmatter**）の3つが利用可能です。 各文字列は、送信中に `<person id=1 />` のようなカテゴリタグに置き換えられます。非表示の対象は API への送信時のみです。ローカルのキャッシュファイルには、復元されたプレーンテキストが保存されます。実際に送信される内容を正確に確認するには、**--xlate-dryrun** を使用してください。

定型文書（四半期報告書など）の場合は、事前にアクターを定義し、本文内でそれらを参照します：

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

`--xlate-template` を使用して、テンプレートを言語ごとに一度翻訳し （値がファイル内に保持されている場合は `--xlate-frontmatter` を使用）、その後、**pandoc-embedz** を使用して各ケースをレンダリングします。スタンドアロンモードでは、外部設定ファイル内の `global:` 以下の値は翻訳 API に一切到達しません：

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

インラインマークの場合、マクロ定義設定を指定することで、同じ翻訳済みテンプレートから実名または伏せ字版のいずれかをレンダリングできます：

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

ドキュメントにembedzブロックが含まれている場合は、それらを翻訳対象から除外します：

    --exclude '^```embedz\n(?s:.*?)^```\n'

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

    使用する翻訳エンジンを指定します。

    現時点では、以下のエンジンが利用可能です。

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    エンジンモジュールは、まずバックエンドネームスペース（`llm`、次に `gpty`）で検索され、その後 `App::Greple::xlate` の直下で検索されます。 したがって、`gpt5`は`App::Greple::xlate::llm::gpt5`を読み込み、それが`llm`コマンドを呼び出しますが、`gpt4o`は`App::Greple::xlate::gpty::gpt4o`にフォールバックします。特定のバックエンドを強制するには、`--xlate-setopt backend=gpty`を使用してください。

- **--xlate-labor**
- **--xlabor**

    翻訳エンジンを呼び出す代わりに、以下の作業を行うことになります。翻訳するテキストを準備すると、クリップボードにコピーされます。フォームに貼り付け、結果をクリップボードにコピーし、returnを押してください。

- **--xlate-to** (Default: `EN-US`)

    対象言語を指定します。LLMエンジンは、モデルが理解できる任意の言語名またはコードを受け付け、それが翻訳プロンプトに挿入されます。**DeepL**エンジンを使用する場合、`deepl languages`コマンドで利用可能な言語を取得できます。

- **--xlate-from** (Default: `ORIGINAL`)

    `conflict`、`colon`、および`ifdef`出力形式における原文に付与されるラベルです。**DeepL**エンジンを使用する場合、デフォルト以外の値もソース言語として渡されます。

- **--xlate-format**=_format_ (Default: `conflict`)

    原文と訳文の出力形式を指定します。

    `xtxt`以外の以下の書式は、翻訳される部分が行の集まりであることを前提としています。実際、行の一部だけを翻訳することは可能ですが、 `xtxt`以外の書式を指定しても意味のある結果は得られません。

    - **conflict**, **cm**

        原文と訳文は[git(1)](http://man.he.net/man1/git) conflict marker形式で出力されます。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        次の[sed(1)](http://man.he.net/man1/sed)コマンドで元のファイルを復元できます。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        元のテキストと翻訳されたテキストは、マークダウンのカスタム・コンテナ・スタイルで出力されます。

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        上記のテキストはHTMLでは以下のように翻訳されます。

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        コロンの数はデフォルトでは7です。`::::`のようにコロン列を指定すると、7コロンの代わりにそれが使われます。

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
    - **space+**

        変換前のテキストと変換後のテキストは1行の空白行で区切られて出力されます。`space+`の場合は、変換後のテキストの後に改行も出力されます。

    - **xtxt**

        形式が`xtxt`（翻訳済みテキスト）または未知の場合は、翻訳済みテキストのみが印刷されます。

- **--xlate-maxlen**=_chars_ (Default: 0)

    API に一度に送信するテキストの最大長を指定します。 デフォルト値の 0 は、エンジン独自の制限を意味します。DeepLの無料アカウントサービスの場合、API (**--xlate**) では128K、クリップボードインターフェース (**--xlate-labor**) では5000です。 Proサービスをご利用の場合は、これらの値を変更できる場合があります。

- **--xlate-maxline**=_n_ (Default: 0)

    APIに一度に送信するテキストの最大行数を指定します。

    一度に1行ずつ翻訳したい場合は、この値を1に設定します。このオプションは`--xlate-maxlen`オプションより優先されます。

- **--xlate-prompt**=_text_

    翻訳エンジンに送信するカスタムプロンプトを指定します。このオプションはLLMエンジン（`gpt3`、`gpt4o`、`gpt5`）で利用可能ですが、DeepLでは利用できません。 AIモデルに具体的な指示を与えることで、翻訳の挙動をカスタマイズできます。プロンプトに `%s` が含まれている場合、それは対象言語名に置き換えられます。

- **--xlate-context**=_text_

    翻訳エンジンに送信する追加コンテキスト情報を指定します。このオプションは、複数のコンテキスト文字列を提供するために複数回使用することができます。コンテキスト情報は、翻訳エンジンが背景を理解し、より正確な翻訳を生成するのに役立ちます。

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    変更されたブロックを再翻訳する際に、参照コンテキストとして渡される周囲の翻訳済みブロックの数（デフォルトは 2）。このコンテキストには、変更された領域の周囲の生のソーステキスト（見出し、リスト構造、キャプション）や、利用可能な場合はキャッシュから復元された変更前のテキストも含まれるため、変更されていない表現が保持されます。 コンテキスト対応翻訳を完全に無効にするには、0 に設定します。変更された各領域は個別の API 呼び出しで翻訳され、コンテキストによってシステムプロンプトに最大約 8000 文字が追加される可能性があるため、コンテキスト対応翻訳は一貫性を確保するために多少の追加コストを伴います。

- **--xlate-cache-seed**=_file_

    別のドキュメントのキャッシュファイルから、新しいドキュメントのキャッシュを初期化します。定期的なレポートの作成に有用です。新しい号のキャッシュに前の号のキャッシュをシードすることで、変更されていない段落が再翻訳されるのを防ぎ、編集された段落は前の号の表現を維持します。 シードは、ターゲットキャッシュが空の場合にのみ使用されます。それ以外の場合は、警告が表示され無視されます。デフォルトの `--xlate-cache=auto` では、シードを指定すると、新しいドキュメントのキャッシュファイルも作成されることになります。

- **--xlate-anonymize**=_file_

    機密性の高い文字列を翻訳APIに送信する前に匿名化し、出力時に復元します。辞書ファイルには、項目ごとに1つのエントリが記載されます：JSON形式（標準的、機械生成可能）

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    または単純な行形式（`category pattern`、正規表現の場合は `/.../`）。 各項目は `<person id=1 />` のようなカテゴリタグに置き換えられます。同じ文字列には常に同じタグが割り当てられるため、モデルは各項目を識別できます。未知の JSON フィールドは無視されるため、ジェネレータ（例：エンティティを抽出するローカル LLM）は独自の注釈を追加できます。 カテゴリ `lit` は予約済みです。ローカルキャッシュファイルには、復元されたプレーンテキストが引き続き保存されます。隠蔽の対象はAPI経由の送信のみです。

    辞書は外部ツール（例えば、機密エンティティを抽出するローカルモデルなど）によって生成できます：

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    ファイル内の UTF-8 BOM は許容されます。フロントマター行形式の値には、値の直後ではなく、その行の末尾にのみコメントを付加できます。

- **--xlate-anonymize-mark**\[=_regex_\]

    文書自体に含まれるインラインマークから匿名化エントリを収集します。 最初の出現箇所を `{{ person("山田太郎") }}` のようにマークすると、文書全体におけるその文字列のすべての出現箇所が匿名化されます。マーク自体はソースおよび翻訳文に残るため、文書を Jinja2 スタイルのマクロプロセッサで処理することも可能です（名前を出力または伏字にするには、`person` マクロを定義します）。 カスタム _regex_ には、`(?<category>...)` および `(?<text>...)` という名前のキャプチャが含まれている必要があります。

    このようなオプション値を持つオプションの場合、後続のファイル引数が値として扱われることに注意してください。デフォルトの表記法を使用する場合は、`--xlate-anonymize-mark=`（末尾に `=` を付加）と記述します。

    代替表記を設定することも可能です。例えば、`@@person:NAME@@` 形式のマークには `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` を使用したり、レンダリングされた Markdown では表示されない HTML コメント形式を使用したりできます。 マークルールはドキュメントごとに収集されます。つまり、ある入力ファイルでマークされた文字列は、同じ実行内の別のファイルでは非表示にはなりません（ファイル間で蓄積されるフロントマターの値とは異なります）。

- **--xlate-template**\[=_regex_\]

    テンプレート式（デフォルト：Jinja2 `{{ ... }}`、`{% ... %}`、`{# ... #}`）を不透明なプレースホルダーとして扱います。モデルに対して、それらをそのままコピーし、ブロックごとに、応答にまったく同じ式が、それぞれ同じ回数含まれていることを確認するよう指示します。 翻訳処理において、対象言語の語順に合わせてこれらの順序が変更される可能性があるため、順序は変わる場合があります。式に不備がある場合、実行は中止されます。キャッシュはチェックポイントとして保存され凍結されるため、支払済みの処理内容は失われることはありません。

    このようなオプション値を持つオプションの場合、後続のファイル引数が値として扱われることに注意してください。デフォルトの表記法を使用する場合は、`--xlate-template=`（末尾に `=` を付加）と記述します。

- **--xlate-frontmatter**

    先頭の `---` ... `---` ブロックを YAML フロントマターとして扱う：翻訳およびフェーズ 2 のコンテキストスライスから除外し、そのフラットな `key: value` 値を安全策として匿名化ルール（カテゴリ `var`）に追加します。 入力ファイルが複数ある場合、収集された値は累積されます（隠蔽を優先します）。

    閉じタグ `---` の後には常に空行を挿入してください。段落形式のマッチパターンを使用する場合、本文に直接続くフロントマターは、除外処理では抑制できない1つのまたがりブロックを形成します（その場合は警告が表示されます）。 値自体は匿名化されますが、フロントマター自体は翻訳のために送信されてしまいます。

- **--xlate-glossary**=_glossary_

    翻訳に使用する用語集IDを指定します。このオプションは、DeepL エンジンを使用する場合にのみ使用できます。用語集 ID は、DeepL アカウントから取得する必要があり、特定の用語の一貫した翻訳を保証します。

- **--xlate-dryrun**

    翻訳APIを呼び出さないでください。代わりに、進行状況表示を通じて、各ペイロードが（匿名化およびマスキング後に）送信されるのと同じ状態で正確に表示してください。これは、マシンから送信される内容を確認したり、実行コストを見積もったりするのに役立ちます。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    STDERR出力で翻訳結果をリアルタイムで確認できます。`From`のペイロードは、匿名化およびマスキング処理後の送信時のまま表示されます。

- **--xlate-stripe**

    [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)モジュールを使うと、一致した部分をゼブラストライプで表示することができます。これは、マッチした部分が背中合わせに接続されている場合に便利です。

    カラーパレットは端末の背景色に応じて切り替わります。明示的に指定したい場合は、 **--xlate-stripe-light** または **--xlate-stripe-dark** を使ってください。

- **--xlate-mask**

    マスキング機能を実行し、変換されたテキストを復元せずにそのまま表示します。

- **--match-all**

    ファイルの全文を対象領域に設定します。

- **--lineify-cm**
- **--lineify-colon**

    `cm`と`colon`形式の場合、出力は一行ごとに分割され、整形されます。従って、行の一部だけが変換される場合、期待された結果は得られません。これらのフィルタは、行の一部を通常の行単位の出力に変換することによって破損した出力を修正します。

    現在の実装では、行の複数の部分が翻訳された場合、それらは独立した行として出力されます。

# CACHE OPTIONS

**xlate**モジュールは、各ファイルの翻訳テキストをキャッシュしておき、実行前に読み込むことで、サーバーに問い合わせるオーバーヘッドをなくすことができます。デフォルトのキャッシュ戦略`auto`では、対象ファイルに対してキャッシュファイルが存在する場合にのみキャッシュデータを保持します。

**--xlate-cache=clear**を使用して、キャッシュ管理を開始するか、既存のキャッシュデータをすべてクリーンアップします。このオプションを実行すると、キャッシュファイルが存在しない場合は新しいキャッシュファイルが作成され、その後は自動的にメンテナンスされます。

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
- **--xlate-update**

    このオプションは、キャッシュ・ファイルを更新する必要がない場合でも、強制的に更新します。

# COMMAND LINE INTERFACE

配布物に含まれている `xlate` コマンドを使えば、コマンドラインから簡単にこのモジュールを使うことができます。使い方は `xlate` のマニュアルページを参照してください。

`xlate`コマンドは`--to-lang`, `--from-lang`, `--engine`, `--file`のようなGNUスタイルの長いオプションをサポートしています。`xlate -h`を使うと利用可能な全てのオプションが表示されます。

`xlate`コマンドはDocker環境と協調して動作するため、手元に何もインストールされていなくても、Dockerが利用可能であれば使用することができます。`-D`または`-C`オプションを使用してください。

Dockerの操作は[App::dozo](https://metacpan.org/pod/App%3A%3Adozo)で処理され、スタンドアロンコマンドとしても使用できます。`dozo`コマンドは、永続的なコンテナ設定のための`.dozorc`設定ファイルをサポートします。

また、様々なドキュメントスタイルに対応したmakefileが提供されているので、特別な指定なしに他言語への翻訳が可能です。`-M`オプションを使用してください。

Docker と `make` オプションを組み合わせて、Docker 環境で `make` を実行することもできます。

`xlate -C` のように実行すると、現在作業中の git リポジトリがマウントされたシェルが起動します。

詳しくは["SEE ALSO"](#see-also)セクションの日本語記事を読んでください。

# EMACS

Emacsエディタから`xlate`コマンドを使うには、リポジトリに含まれる`xlate.el`ファイルを読み込みます。`xlate-region`関数は指定された領域を翻訳します。デフォルトの言語は`EN-US`で、prefix引数で言語を指定できます。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepLサービスの認証キーを設定します。

- OPENAI\_API\_KEY

    レガシーな**gpty**エンジンで使用されるOpenAI認証キー。 `llm`ベースの**gpt5**エンジンもこの変数を読み取りますが、`llm keys set openai`で保存されたキーも機能します。

- GREPLE\_XLATE\_CACHE

    デフォルトのキャッシュ戦略を設定します（["CACHE OPTIONS"](#cache-options)を参照）。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

使用しているエンジン用のコマンドラインツールをインストールします：`llm`（**gpt5**エンジン用）、`deepl`（DeepL用）、`gpty`（レガシーGPTエンジン用）。

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm)、[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - xlateがコンテナ操作に使用する汎用Dockerランナー。

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    ターゲット・テキスト・パターンの詳細については、**greple** のマニュアルを参照してください。**--inside**、**--outside**、**--include**、**--exclude**オプションを使用して、マッチング範囲を制限します。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    `-Mupdate` モジュールを使って、**greple** コマンドの結果によってファイルを変更することができます。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    **sdif**を使うと、**-V**オプションでコンフリクトマーカの書式を並べて表示することができます。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    **--xlate-stripe**オプションで**stripe**モジュールを使用します。

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Dockerコンテナイメージ。

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh` ライブラリは `xlate` スクリプトと [App::dozo](https://metacpan.org/pod/App%3A%3Adozo) のオプション解析に使われます。

- [https://llm.datasette.io/](https://llm.datasette.io/)

    **gpt5**エンジンがLLMモデルにアクセスするために使用する`llm`コマンド。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python ライブラリと CLI コマンド。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python ライブラリ

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI コマンドラインインタフェース

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

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
