# NAME

App::Greple::xlate - greple的翻译支持模块

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.00

# DESCRIPTION

**Greple** **xlate** 模块会查找目标文本块并将其替换为翻译后的文本。主要引擎是 GPT-5.5 (`llm/gpt5.pm`)，它会调用 [llm](https://llm.datasette.io/) 命令； DeepL (`deepl.pm`) 以及基于 **gpty** 的旧版引擎也包含在内。

翻译结果按文件进行缓存，因此对于未更改的文本，重新运行命令无需额外成本。 当文档被编辑时，仅将更改过的段落再次发送至 API；基于上下文的引擎还会接收周围的翻译内容、更改处周围的原始源文本以及被编辑段落的上一版本，因此新翻译能保持既定的措辞（参见 **--xlate-context-window**）。 敏感字符串可在传输前进行隐藏（参见 ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)）。

若要翻译采用 Perl pod 风格编写的文档中的普通文本块，请像这样结合 `--xlate-engine gpt5` 和 `perl` 模块使用 **greple** 命令：

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

在该命令中，模式字符串 `^([\w\pP].*\n)+` 表示以字母和标点符号开头的连续行。该命令高亮显示要翻译的区域。选项 **--all** 用于生成整个文本。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

然后添加 `--xlate` 选项来翻译选定区域。随后，系统将查找目标段落并用翻译引擎的输出结果替换它们。

默认情况下，原文和译文以与 [git(1)](http://man.he.net/man1/git) 兼容的 "冲突标记 "格式打印。使用 `ifdef` 格式，可以通过 [unifdef(1)](http://man.he.net/man1/unifdef) 命令轻松获得所需的部分。输出格式可以通过 **--xlate-format** 选项指定。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

如果要翻译整个文本，请使用 **--match-all** 选项。这是指定匹配整个文本的模式 `(?s).+` 的快捷方式。

冲突标记格式数据可以通过 [sdif](https://metacpan.org/pod/App%3A%3Asdif) 命令和 `-V` 选项并排查看。由于按字符串进行比较毫无意义，因此建议使用 `--no-cdif` 选项。如果不需要给文本着色，可指定 `--no-textcolor`（或 `--no-tc`）。

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

处理是以指定单位进行的，但如果是多行非空文本序列，则会一起转换为单行。具体操作如下

- 删除每行开头和结尾的空白。
- 如果一行以全角标点符号结束，则与下一行连接。
- 如果一行以全角字符结束，而下一行以全角字符开始，则将这两行连接起来。
- 如果一行的末尾或开头不是全宽字符，则通过插入空格字符将它们连接起来。

缓存数据是根据规范化文本进行管理的，因此即使进行了不影响规范化结果的修改，缓存的翻译数据仍然有效。

此规范化处理只针对第一个（第 0 个）和偶数模式。因此，如果指定了以下两个模式，则匹配第一个模式的文本将在规范化后处理，而不对匹配第二个模式的文本执行规范化处理。

    greple -Mxlate -E normalized -E not-normalized

因此，第一种模式适用于将多行合并为一行进行处理的文本，第二种模式适用于预格式化文本。如果第一个模式中没有要匹配的文本，则使用不匹配任何内容的模式，如 `(?!)`。

# MASKING

有时，您不希望翻译文本中的某些部分。例如，markdown 文件中的标记。DeepL 建议在这种情况下，将不需要翻译的文本部分转换为 XML 标记，然后进行翻译，翻译完成后再还原。为了支持这一点，可以指定要屏蔽翻译的部分。

    --xlate-setopt maskfile=MASKPATTERN

该指令将把文件中每行以`MASKPATTERN`开头的文本视为正则表达式，匹配的字符串将被翻译，处理后自动还原。以`#`开头的行将被忽略。

复杂模式可以跨多行书写，其中换行符需用反斜杠转义。

通过 **--xlate-mask** 选项可以看到屏蔽后文本的转换效果。

屏蔽功能可防止标记被翻译。若要向翻译服务本身隐藏敏感字符串，请参阅 ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)；这两种方法可以同时使用。

此接口为试验性接口，将来可能会更改。

# ANONYMIZATION AND TEMPLATES

敏感字符串可在发送至翻译 API 之前被隐藏，并在输出中恢复。 提供三种匿名化规则来源：词典文件（**--xlate-anonymize**）、文档中的内联标记（**--xlate-anonymize-mark**）以及 YAML 前置信息值（**--xlate-frontmatter**）。 在传输过程中，每个字符串都会被替换为类别标签，例如 `<person id=1 />`。隐藏操作仅针对 API 传输：本地缓存文件中存储的是已恢复的纯文本。使用 **--xlate-dryrun** 可查看实际将要传输的内容。

对于表单文档（如季度报告等），请预先定义参与方并在正文中引用它们：

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

使用 `--xlate-template` 将模板按每种语言翻译一次 （当值保存在文件中时使用 `--xlate-frontmatter`），然后使用 **pandoc-embedz** 独立模式渲染每个案例——外部配置中 `global:` 下的值根本不会传送到翻译 API：

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

对于内联标记，提供宏定义配置可使同一翻译后的模板渲染真实名称或经过遮蔽处理的版本：

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

当文档包含 embedz 块时，将其排除在翻译之外：

    --exclude '^```embedz\n(?s:.*?)^```\n'

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    对每个匹配的区域调用翻译过程。

    如果没有这个选项，**greple**的行为就像一个普通的搜索命令。所以你可以在调用实际工作之前检查文件的哪一部分将成为翻译的对象。

    命令的结果会进入标准输出，所以如果需要的话，可以重定向到文件，或者考虑使用[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)模块。

    选项**--xlate**调用**--xlate-color**选项与**--color=never**选项。

    使用**--xlate-fold**选项，转换后的文本将按指定的宽度进行折叠。默认宽度为70，可以通过**--xlate-fold-width**选项设置。四列是为磨合操作保留的，所以每行最多可以容纳74个字符。

- **--xlate-engine**=_engine_

    指定要使用的翻译引擎。

    目前有以下引擎

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    引擎模块首先在后端命名空间中搜索（`llm`，然后是 `gpty`），然后直接在 `App::Greple::xlate` 下搜索。 因此，`gpt5` 会加载 `App::Greple::xlate::llm::gpt5`，后者调用 `llm` 命令，而 `gpt4o` 则回退到 `App::Greple::xlate::gpty::gpt4o`。使用 `--xlate-setopt backend=gpty` 可强制指定特定后端。

- **--xlate-labor**
- **--xlabor**

    您需要做的不是调用翻译引擎，而是为其工作。准备好要翻译的文本后，它们会被复制到剪贴板。您需要将它们粘贴到表单中，将结果复制到剪贴板，然后点击回车键。

- **--xlate-to** (Default: `EN-US`)

    指定目标语言。LLM引擎接受模型所理解的任何语言名称或代码；该语言将被插值到翻译提示中。使用**DeepL**引擎时，可通过`deepl languages`命令获取可用语言列表。

- **--xlate-from** (Default: `ORIGINAL`)

    在 `conflict`、`colon` 和 `ifdef` 输出格式中，用于源文本的标签。使用 **DeepL** 引擎时，非默认值也会作为源语言传递。

- **--xlate-format**=_format_ (Default: `conflict`)

    指定原始和翻译文本的输出格式。

    除 `xtxt` 以外的以下格式都假定要翻译的部分是行的集合。事实上，可以只翻译一行的一部分，但指定 `xtxt` 以外的格式不会产生有意义的结果。

    - **conflict**, **cm**

        原始文本和转换后的文本以 [git(1)](http://man.he.net/man1/git) 冲突标记格式打印。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        你可以通过下一个[sed(1)](http://man.he.net/man1/sed)命令恢复原始文件。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        原文和译文以 markdown 的自定义容器样式输出。

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        以上文本将在 HTML 中翻译为以下内容。

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        冒号数默认为 7。如果指定冒号序列，如 `:::::`，则会使用它来代替 7 个冒号。

    - **ifdef**

        原始文本和转换后的文本以 [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 格式打印。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        你可以通过**unifdef**命令只检索日文文本。

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        原始文本和转换后的文本在打印时以单行空行隔开。对于 `space+`，它还会在转换后的文本后输出一个换行符。

    - **xtxt**

        如果格式是`xtxt`（翻译文本）或不知道，则只打印翻译文本。

- **--xlate-maxlen**=_chars_ (Default: 0)

    指定一次发送至 API 的文本最大长度。 默认值 0 表示引擎自身的限制：对于 DeepL 免费账户服务，API（**--xlate**）的限制为 128K，剪贴板接口（**--xlate-labor**）的限制为 5000。 如果您使用的是 Pro 服务，则可能可以更改这些值。

- **--xlate-maxline**=_n_ (Default: 0)

    指定一次发送到 API 的最大文本行数。

    如果想一次翻译一行，则将该值设为 1。该选项优先于 `--xlate-maxlen` 选项。

- **--xlate-prompt**=_text_

    指定要发送给翻译引擎的自定义提示词。此选项适用于 LLM 引擎（`gpt3`、`gpt4o`、`gpt5`），但不适用于 DeepL。 您可以通过向 AI 模型提供具体指令来自定义翻译行为。如果提示语中包含 `%s`，它将被目标语言名称替换。

- **--xlate-context**=_text_

    指定要发送给翻译引擎的其他上下文信息。此选项可多次使用，以提供多个上下文字符串。上下文信息有助于翻译引擎理解背景并生成更准确的翻译。

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    在重新翻译已修改的块时，作为参考上下文传递的周围已翻译块的数量（默认值为 2）。该上下文还包括已修改区域周围的原始源文本（标题、列表结构、图注），以及（如有）从缓存中恢复的已修改文本的先前版本，以便保留未更改的措辞。 设置为 0 可完全禁用基于上下文的翻译。请注意，每个已更改区域都会通过单独的 API 调用进行翻译，且上下文可能会使系统提示符增加约 8000 个字符，因此基于上下文的翻译是在牺牲部分额外成本的同时换取一致性。

- **--xlate-cache-seed**=_file_

    从另一个文档的缓存文件初始化新文档的缓存。这对于定期报告非常有用：使用上一期报告的缓存作为新期报告缓存的初始值，这样未更改的段落就不会被重新翻译，而编辑过的段落则会保留上一期报告的措辞。 仅当目标缓存为空时才会使用该初始化数据；否则将忽略该参数并发出警告。使用默认的 `--xlate-cache=auto` 时，指定初始化数据也意味着会创建新文档的缓存文件。

- **--xlate-anonymize**=_file_

    在将敏感字符串发送至翻译 API 之前对其进行匿名化处理，并在输出中恢复其原始内容。词典文件为每个项目提供一条条目：以 JSON 格式（规范的、可由机器生成）

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    或以简单行格式（`category pattern`，`/.../` 用于正则表达式）。 每个项目都被替换为类别标签，例如 `<person id=1 />`；相同的字符串始终获得相同的标签，因此模型可以追踪“谁是谁”。未知 JSON 字段将被忽略，因此生成器（例如提取实体的本地 LLM）可以添加自己的注释。 类别 `lit` 被保留。本地缓存文件仍会存储恢复后的纯文本：隐藏操作仅针对 API 传输。

    词典可由外部工具生成——例如用于提取敏感实体的本地模型：

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    文件中允许存在 UTF-8 BOM。前置信息行格式的值仅可在单独一行末尾带有尾注，不可紧跟在值之后。

- **--xlate-anonymize-mark**\[=_regex_\]

    从文档本身的内联标记中收集匿名化条目。 将首次出现的位置标记为 `{{ person("山田太郎") }}`，该字符串在整个文档中的所有出现位置均会被匿名化。标记本身会保留在源文档和译文中，因此文档也可通过 Jinja2 风格的宏处理器进行处理（定义 `person` 宏以打印或屏蔽名称）。 自定义的 _regex_ 必须包含名为 `(?<category>...)` 和 `(?<text>...)` 的命名捕获。

    请注意，对于此类可选值的选项，后续的文件参数将被视为该值：在使用默认表示法时，应写为 `--xlate-anonymize-mark=`（末尾跟一个 `=`）。

    可以配置其他表示法，例如 `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'` 用于 `@@person:NAME@@` 风格的标记，或者一种在渲染后的 Markdown 中不可见的 HTML 注释形式。 标记规则按文档收集：在一个输入文件中被标记的字符串不会在同一运行中的另一个文件中被隐藏（这与在前置信息中累积的值不同）。

- **--xlate-template**\[=_regex_\]

    将模板表达式（默认：Jinja2 `{{ ... }}`、`{% ... %}`、`{# ... #}`）视为不透明占位符：指示模型将其原样复制，并按块验证响应中是否包含完全相同的表达式，且每个表达式出现的次数完全一致。 这些表达式的顺序可能会发生变化，因为翻译过程中会根据目标语言的词序对其进行合理重新排序。若遇到错误的表达式，运行将终止；此时缓存会被检查点保存并冻结，因此已付费的内容不会丢失。

    请注意，对于此类可选值选项，后续的文件参数将被视为该值：在使用默认表示法时，应写为 `--xlate-template=`（末尾跟 `=`）。

- **--xlate-frontmatter**

    将开头的 `---` ... `---` 块视为 YAML 前置信息：将其排除在翻译和第二阶段上下文切片之外，并将其中平铺的 `key: value` 值添加到匿名化规则（类别 `var`）中作为安全保障。 当存在多个输入文件时，收集的值会累积（宁可多隐瞒也不要少隐瞒）。

    在闭合的 `---` 之后始终留出一行空行。若采用段落风格的匹配模式，直接与正文相连的前置信息将形成一个跨段块，该块无法被排除规则抑制（此时会输出警告）； 这些值仍会被匿名化，但前置信息本身仍会被发送进行翻译。

- **--xlate-glossary**=_glossary_

    指定用于翻译的词汇表 ID。该选项仅在使用 DeepL 引擎时可用。词汇表 ID 应从您的 DeepL 账户获取，可确保特定术语翻译的一致性。

- **--xlate-dryrun**

    请勿调用翻译 API；而是通过进度显示，将每个有效载荷（经过匿名化和遮蔽处理后）以实际传输时的原样展示。这有助于检查系统输出的内容，并估算每次运行的成本。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    可在 STDERR 输出中实时查看翻译结果。`From` 有效负载以传输时的形式显示，即经过匿名化和屏蔽处理后的状态。

- **--xlate-stripe**

    使用 [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) 模块以斑马线方式显示匹配部分。当匹配部分背靠背连接时，这种方式非常有用。

    调色板会根据终端的背景颜色进行切换。如果要明确指定，可以使用 **--xlate-stripe-light** 或 **--xlate-stripe-dark**。

- **--xlate-mask**

    执行屏蔽功能并显示转换后的文本，无需还原。

- **--match-all**

    将文件的整个文本设置为目标区域。

- **--lineify-cm**
- **--lineify-colon**

    对于 `cm` 和 `colon` 格式，输出是逐行分割和格式化的。因此，如果只翻译一行的一部分，就无法获得预期的结果。这些过滤器可以修复将一行的部分内容翻译成正常的逐行输出而损坏的输出。

    在当前的实现中，如果一行的多个部分被翻译，它们将作为独立的行输出。

# CACHE OPTIONS

**xlate**模块可以存储每个文件的翻译缓存文本，并在执行前读取它，以消除向服务器请求的开销。在默认的缓存策略`auto`下，它只在目标文件的缓存文件存在时才维护缓存数据。

使用 **--xlate-cache=clear** 启动缓存管理或清理所有现有缓存数据。使用该选项后，如果缓存文件不存在，就会创建一个新的缓存文件，然后自动维护。

- --xlate-cache=_strategy_
    - `auto` (Default)

        如果缓存文件存在，则维护该文件。

    - `create`

        创建空缓存文件并退出。

    - `always`, `yes`, `1`

        只要目标文件是正常文件，就维持缓存。

    - `clear`

        先清除缓存数据。

    - `never`, `no`, `0`

        即使缓存文件存在，也不使用它。

    - `accumulate`

        根据默认行为，未使用的数据会从缓存文件中删除。如果你不想删除它们并保留在文件中，使用`accumulate`。
- **--xlate-update**

    即使没有必要，该选项也会强制更新缓存文件。

# COMMAND LINE INTERFACE

你可以使用发行版中的 `xlate` 命令，在命令行中轻松使用该模块。有关用法，请参阅 `xlate` man 页。

`xlate` 命令支持 GNU 风格的长选项，如 `--to-lang`、`--from-lang`、`--engine` 和 `--file`。使用 `xlate -h` 查看所有可用选项。

`xlate` 命令与 Docker 环境协同工作，因此即使你手头没有安装任何东西，只要 Docker 可用，你就可以使用它。使用 `-D` 或 `-C` 选项。

Docker 操作由 [App::dozo](https://metacpan.org/pod/App%3A%3Adozo) 处理，该命令也可作为独立命令使用。`dozo` 命令支持用于持久化容器设置的 `.dozorc` 配置文件。

此外，由于提供了各种文档样式的 makefile，因此无需特别说明即可翻译成其他语言。使用 `-M` 选项。

你还可以把 Docker 和 `make` 选项结合起来，这样就能在 Docker 环境中运行 `make`。

像 `xlate -C` 这样运行，会启动一个挂载了当前工作 git 仓库的 shell。

详情请阅读 ["SEE ALSO"](#see-also) 部分的日文文章。

# EMACS

加载存储库中的`xlate.el`文件，从Emacs编辑器中使用`xlate`命令。`xlate-region`函数翻译给定的区域。默认的语言是`EN-US`，你可以用前缀参数指定调用语言。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    为DeepL 服务设置你的认证密钥。

- OPENAI\_API\_KEY

    OpenAI 认证密钥，由旧版 **gpty** 引擎使用。 基于 `llm` 的 **gpt5** 引擎也会读取此变量，但存储在 `llm keys set openai` 中的密钥同样有效。

- GREPLE\_XLATE\_CACHE

    设置默认缓存策略（参见 ["CACHE OPTIONS"](#cache-options)）。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

安装您所用引擎对应的命令行工具：`llm` 用于 **gpt5** 引擎，`deepl` 用于 DeepL，`gpty` 用于旧版 GPT 引擎。

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - xlate 用于容器操作的通用 Docker 运行程序

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    关于目标文本模式的细节，请参见**greple**手册。使用**--inside**, **--outside**, **--include**, **--exclude**选项来限制匹配区域。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    你可以使用`-Mupdate`模块通过**greple**命令的结果来修改文件。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    使用**sdif**与**-V**选项并列显示冲突标记格式。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    通过 **--xlate-stripe** 选项查看 **stripe** 模块的使用情况。

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker 容器镜像。

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh` 库，用于在 `xlate` 脚本和 [App::dozo](https://metacpan.org/pod/App%3A%3Adozo) 中进行选项解析。

- [https://llm.datasette.io/](https://llm.datasette.io/)

    **gpt5**引擎用于访问LLM模型的`llm`命令。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python库和CLI命令。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python 库

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 命令行界面

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    使用 DeepL API（日语）翻译并仅替换必要部分的 Greple 模块

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    利用 DeepL API 模块生成 15 种语言的文档（日语）

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    利用 DeepL API 自动翻译 Docker 环境（日语）

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
