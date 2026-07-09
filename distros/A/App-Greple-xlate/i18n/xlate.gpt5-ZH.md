# NAME

App::Greple::xlate - greple 的翻译支持模块

# SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

# VERSION

Version 2.01

# DESCRIPTION

**Greple** **xlate** 模块查找所需的文本块，并将其替换为翻译后的文本。主要引擎是 GPT-5.5（`llm/gpt5.pm`），它会调用 [llm](https://llm.datasette.io/) 命令；同时还包含 DeepL（`deepl.pm`）和基于旧版 **gpty** 的引擎。

翻译会按文件缓存，因此对未更改的文本重新运行命令不会产生任何成本。当文档被编辑时，只有已更改的段落会再次发送到 API；上下文感知引擎还会接收周围的翻译、变更周边的原始源文本，以及已编辑段落的上一版本，因此新的翻译会保持既有措辞（见 **--xlate-context-window**）。敏感字符串可以在传输前隐藏（见 ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)）。

如果你想翻译以 Perl 的 pod 风格编写的文档中的普通文本块，请像这样将 **greple** 命令与 `--xlate-engine gpt5` 和 `perl` 模块一起使用：

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

在此命令中，模式字符串 `^([\w\pP].*\n)+` 表示以字母数字和标点符号开头的连续行。该命令会高亮显示将被翻译的区域。选项 **--all** 用于生成完整文本。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

然后添加 `--xlate` 选项以翻译所选区域。接着，它会找到所需的部分并将其替换为翻译引擎的输出。

默认情况下，原文与译文会以与 [git(1)](http://man.he.net/man1/git) 兼容的“冲突标记”格式打印。使用 `ifdef` 格式，你可以轻松通过 [unifdef(1)](http://man.he.net/man1/unifdef) 命令获取所需部分。输出格式可由 **--xlate-format** 选项指定。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

如果你想翻译整篇文本，使用 **--match-all** 选项。这是指定匹配整篇文本的模式 `(?s).+` 的快捷方式。

冲突标记格式的数据可用 [sdif](https://metacpan.org/pod/App%3A%3Asdif) 命令配合 `-V` 选项以并列样式查看。由于逐字符串比较没有意义，建议使用 `--no-cdif` 选项。如果不需要为文本着色，指定 `--no-textcolor`（或 `--no-tc`）。

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

处理按指定的单位进行，但对于多行非空文本的序列，会合并为一行。该操作按如下方式执行：

- 移除每行开头和结尾的空白。
- 如果一行以全角标点符号结尾，则与下一行连接。
- 如果一行以全角字符结尾且下一行以全角字符开头，则连接这些行。
- 如果行的结尾或开头不是全角字符，则在中间插入一个空格字符后再连接。

缓存数据基于规范化后的文本进行管理，因此即使进行了不影响规范化结果的修改，缓存的翻译数据仍然有效。

该规范化过程仅对第一个（第 0 个）以及偶数序号的模式执行。因此，如果指定了如下两个模式，则与第一个模式匹配的文本会在规范化后处理，与第二个模式匹配的文本则不执行规范化。

    greple -Mxlate -E normalized -E not-normalized

因此，对于需要将多行合并为一行来处理的文本，使用第一个模式；对于预格式化文本，使用第二个模式。如果第一个模式中没有可匹配的文本，则使用诸如 `(?!)` 之类不匹配任何内容的模式。

# MASKING

有时会有不想被翻译的文本部分。例如，Markdown 文件中的标签。DeepL 建议在这种情况下，将需要排除的文本部分转换为 XML 标签，进行翻译后再恢复。为支持此流程，可以指定从翻译中屏蔽的部分。

    --xlate-setopt maskfile=MASKPATTERN

这将把文件的每一行 `MASKPATTERN` 解释为正则表达式，翻译与其匹配的字符串，并在处理后还原。以 `#` 开头的行将被忽略。

复杂的模式可以使用反斜杠转义换行写在多行上。

通过 **--xlate-mask** 选项可以查看文本经屏蔽转换后的样子。

屏蔽可保护标记不被翻译。若要向翻译服务本身隐藏敏感字符串，请参见 ["ANONYMIZATION AND TEMPLATES"](#anonymization-and-templates)；两者可以一起使用。

此接口为实验性质，将来可能会改变。

# ANONYMIZATION AND TEMPLATES

敏感字符串可以在发送到翻译 API 之前被隐藏，并在输出中恢复。可使用三种匿名化规则来源：字典文件（**--xlate-anonymize**）、文档本身中的内联标记（**--xlate-anonymize-mark**）以及 YAML front matter 值（**--xlate-frontmatter**）。在传输期间，每个字符串都会被替换为诸如 `<person id=1 />` 之类的类别标签。隐藏目标仅限于 API 传输：本地缓存文件存储的是已恢复的纯文本。使用 **--xlate-dryrun** 可以准确检查将被传输的内容。

对于表单类文档（季度报告等），请预先定义参与者，并在正文中引用它们：

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

每种语言只需使用 `--xlate-template` 翻译一次模板（当值保存在文件中时还需使用 `--xlate-frontmatter`），然后用 **pandoc-embedz** 独立模式渲染每个案例——外部配置中 `global:` 下的值完全不会到达翻译 API：

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

对于内联标记，提供宏定义配置可使同一个已翻译模板渲染为真实姓名或脱敏版本：

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

    对每个匹配区域启动翻译过程。

    没有该选项时，**greple** 的行为与普通搜索命令相同。因此，你可以在实际执行之前确认文件的哪些部分将成为翻译对象。

    命令结果输出到标准输出，如有需要可重定向到文件，或考虑使用 [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) 模块。

    选项 **--xlate** 会以 **--color=never** 选项调用 **--xlate-color** 选项。

    使用 **--xlate-fold** 选项时，转换后的文本按指定宽度折行。默认宽度为 70，可由 **--xlate-fold-width** 选项设置。为行内操作预留四列，因此每行最多可容纳 74 个字符。

- **--xlate-engine**=_engine_

    指定要使用的翻译引擎。

    目前可用的引擎如下所示

    - **gpt5**: gpt-5.5 (via the `llm` command)
    - **deepl**: DeepL API (via the `deepl` command)
    - **gpt3**: gpt-3.5-turbo (legacy, via the `gpty` command)
    - **gpt4o**: gpt-4o-mini (legacy, via the `gpty` command)

    引擎模块会先在后端命名空间中搜索（`llm`，然后是 `gpty`），再直接在 `App::Greple::xlate` 下搜索。因此，`gpt5` 会加载 `App::Greple::xlate::llm::gpt5`，后者调用 `llm` 命令；而 `gpt4o` 则回退到 `App::Greple::xlate::gpty::gpt4o`。使用 `--xlate-setopt backend=gpty` 可强制指定特定后端。

- **--xlate-labor**
- **--xlabor**

    不调用翻译引擎，而是期望由你手动完成。准备好要翻译的文本后，它们会被复制到剪贴板。你需要将其粘贴到表单中，将结果复制回剪贴板并按回车。

- **--xlate-to** (Default: `EN-US`)

    指定目标语言。LLM 引擎接受模型能够理解的任何语言名称或代码；它会被插入到翻译提示中。使用 **DeepL** 引擎时，可以通过 `deepl languages` 命令获取可用语言。

- **--xlate-from** (Default: `ORIGINAL`)

    用于 `conflict`、`colon` 和 `ifdef` 输出格式中原文的标签。使用 **DeepL** 引擎时，非默认值也会作为源语言传递。

- **--xlate-format**=_format_ (Default: `conflict`)

    指定原文与译文的输出格式。

    除 `xtxt` 外，以下格式均假定要翻译的部分是由多行构成。实际上也可以只翻译一行中的一部分，但指定为非 `xtxt` 的格式将不会产生有意义的结果。

    - **conflict**, **cm**

        原文与转换后的文本以 [git(1)](http://man.he.net/man1/git) 冲突标记格式输出。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        可以通过下一条 [sed(1)](http://man.he.net/man1/sed) 命令恢复原始文件。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        原文与译文以 Markdown 的自定义容器样式输出。

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        上述文本在 HTML 中会被转换为如下形式。

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        冒号数量默认是 7。如果指定了类似 `:::::` 的冒号序列，则使用该序列替代 7 个冒号。

    - **ifdef**

        原文与转换后的文本以 [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 格式输出。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        你可以通过 **unifdef** 命令仅提取日文文本：

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        原文和转换后的文本以一个空行分隔打印。对于`space+`，还会在转换后的文本后输出一个换行符。

    - **xtxt**

        如果格式是`xtxt`（译文）或未知，则只打印译文。

- **--xlate-maxlen**=_chars_ (Default: 0)

    指定一次发送到 API 的文本最大长度。默认值 0 表示引擎自身的限制：对于 DeepL 免费账户服务，API 为 128K（**--xlate**），剪贴板接口为 5000（**--xlate-labor**）。如果使用 Pro 服务，您可以更改这些值。

- **--xlate-maxline**=_n_ (Default: 0)

    指定一次发送到 API 的文本最大行数。

    如果希望逐行翻译，将此值设为 1。此选项优先于`--xlate-maxlen`选项。

- **--xlate-prompt**=_text_

    指定要发送给翻译引擎的自定义提示。此选项适用于 LLM 引擎（`gpt3`、`gpt4o`、`gpt5`），但不适用于 DeepL。你可以通过向 AI 模型提供特定指令来自定义翻译行为。如果提示包含 `%s`，它将被替换为目标语言名称。

- **--xlate-context**=_text_

    指定要发送给翻译引擎的附加上下文信息。此选项可多次使用以提供多个上下文字符串。上下文信息有助于翻译引擎理解背景并生成更准确的译文。

- **--xlate-context-window**=_n_

    (Context-aware engines only, e.g. `gpt5` on the llm backend)
    重新翻译已更改的块时，作为参考上下文传递的周边已翻译块数量（默认 2）。上下文还包括更改区域周围的原始源文本（标题、列表结构、图注），以及在可用时从缓存中恢复的更改文本的先前版本，以便保留未更改的措辞。设为 0 可完全禁用上下文感知翻译。请注意，每个更改区域都会在其自己的 API 调用中翻译，并且上下文可能会向系统提示添加最多约 8000 个字符，因此上下文感知翻译会以一些额外成本换取一致性。

- **--xlate-cache-seed**=_file_

    从另一个文档的缓存文件初始化新文档的缓存。适用于周期性报告：用上一期的缓存为新一期的缓存做种子，这样未更改的段落就不会被重新翻译，已编辑的段落也会保留上一期的措辞。只有当目标缓存为空时才会使用该种子；否则会忽略并给出警告。在默认的 `--xlate-cache=auto` 下，指定种子也意味着创建新文档的缓存文件。

- **--xlate-anonymize**=_file_

    在敏感字符串发送到翻译 API 之前将其匿名化，并在输出中恢复。字典文件为每个项目提供一个条目：采用 JSON（规范的、可由机器生成）

        [ { "category": "person",  "text": "山田太郎" },
          { "category": "company", "regex": "アクメ(株式会社)?" } ]

    或采用简单行格式（`category pattern`，`/.../` 用于正则表达式）。每个项目都会被替换为一个类别标签，例如 `<person id=1 />`；相同字符串始终获得相同标签，因此模型可以跟踪谁是谁。未知的 JSON 字段会被忽略，因此生成器（例如提取实体的本地 LLM）可以添加自己的注释。类别 `lit` 为保留项。本地缓存文件仍存储已恢复的纯文本：隐藏目标仅限于 API 传输。

    字典可以由外部工具生成——例如由本地模型提取敏感实体：

        llm -m <local-model> \
            -s 'Extract sensitive entities as a JSON array of objects
                with "category" and "text" fields.' \
            < report.md > report.anon.json
        greple -Mxlate --xlate-anonymize=report.anon.json ...

    文件中的 UTF-8 BOM 可以被容忍。front matter 行格式中的值只有在其单独成行时才可以带有尾随注释，不能在值后面添加。

- **--xlate-anonymize-mark**\[=_regex_\]

    从文档本身的内联标记收集匿名化条目。像 `{{ person("山田太郎") }}` 这样标记首次出现处，整个文档范围内该字符串的每次出现都会被匿名化。标记本身会保留在源文本和译文中，因此文档也可以由 Jinja2 风格的宏处理器处理（定义 `person` 宏以打印或遮蔽名称）。自定义 _regex_ 必须包含 `(?<category>...)` 和 `(?<text>...)` 命名捕获。

    请注意，对于这种带可选值的选项，后续的文件参数会被当作该值：使用默认记法时，请写成 `--xlate-anonymize-mark=`（带有尾随的 `=`）。

    可以配置替代记法，例如用于 `@@person:NAME@@` 风格标记的 `--xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@'`，或在渲染后的 Markdown 中保持不可见的 HTML 注释形式。标记规则按文档收集：在一个输入文件中标记的字符串不会在同一次运行的另一个文件中被隐藏（与 front matter 值不同，后者会跨文件累积）。

- **--xlate-template**\[=_regex_\]

    将模板表达式（默认：Jinja2 `{{ ... }}`、`{% ... %}`、`{# ... #}`）视为不透明占位符：指示模型原样复制它们，并按块验证响应中包含完全相同的表达式，且每个表达式出现次数相同。它们的顺序可以改变，因为翻译可能会合理地重新排列它们以符合目标语言的语序。表达式损坏会中止运行；缓存会被设为检查点并冻结，因此不会丢失任何已付费的内容。

    请注意，对于像这样的可选值选项，后面的文件参数会被当作该值：使用默认记法时请写成 `--xlate-template=`（带有尾随的 `=`）。

- **--xlate-frontmatter**

    将开头的 `---` ... `---` 块视为 YAML front matter：将其排除在翻译以及第 2 阶段上下文切片之外，并将其扁平的 `key: value` 值添加到匿名化规则（类别 `var`）中作为安全网。对于多个输入文件，收集到的值会累积（宁可偏向隐藏）。

    始终在结束的 `---` 之后留一个空行。使用段落样式的匹配模式时，直接衔接到正文文本的 front matter 会形成一个横跨二者的块，排除机制无法抑制它（在这种情况下会打印警告）；这些值仍会被匿名化，但 front matter 本身会被发送去翻译。

- **--xlate-glossary**=_glossary_

    指定用于翻译的术语库（glossary）ID。此选项仅在使用 DeepL 引擎时可用。术语库 ID 应从您的 DeepL 账户获取，以确保特定术语的一致翻译。

- **--xlate-dryrun**

    不要调用翻译 API；而是通过进度显示，逐一展示每个 payload 的确切内容，就像它会被传输时一样（经过匿名化和 masking 之后）。这对于检查哪些内容离开本机以及估算一次运行的成本很有用。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    在 STDERR 输出中实时查看翻译结果。`From` payload 会按传输时的形式显示，即经过匿名化和 masking 之后。

- **--xlate-stripe**

    使用[App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)模块以斑马条纹方式显示匹配部分。当匹配部分首尾相接时很有用。

    颜色调色板会根据终端的背景颜色切换。若要显式指定，可使用**--xlate-stripe-light**或**--xlate-stripe-dark**。

- **--xlate-mask**

    执行遮罩功能，并按转换后文本原样显示而不进行还原。

- **--match-all**

    将整个文件的文本设为目标区域。

- **--lineify-cm**
- **--lineify-colon**

    在`cm`和`colon`格式的情况下，输出会按行拆分并格式化。因此，如果仅需要翻译某行的一部分，将无法获得预期结果。这些过滤器会将因部分行翻译而破坏的输出修复为正常的逐行输出。

    在当前实现中，如果一行中的多个部分被翻译，它们会作为独立的行输出。

# CACHE OPTIONS

**xlate**模块可为每个文件存储翻译的缓存文本，并在执行前读取，以消除向服务器请求的开销。使用默认的缓存策略`auto`时，仅当目标文件存在缓存文件时才维护缓存数据。

使用**--xlate-cache=clear**启动缓存管理或清理所有现有缓存数据。使用此选项执行后，如果不存在缓存文件将创建新的缓存文件，并在此后自动维护。

- --xlate-cache=_strategy_
    - `auto` (Default)

        如果缓存文件存在则进行维护。

    - `create`

        创建空的缓存文件并退出。

    - `always`, `yes`, `1`

        只要目标是普通文件，无论如何都维护缓存。

    - `clear`

        先清除缓存数据。

    - `never`, `no`, `0`

        即使存在，也绝不使用缓存文件。

    - `accumulate`

        在默认行为下，未使用的数据会从缓存文件中移除。如果你不想删除它们并希望保留在文件中，请使用`accumulate`。
- **--xlate-update**

    此选项会强制更新缓存文件，即使没有必要。

# COMMAND LINE INTERFACE

你可以通过使用发行版中包含的`xlate`命令，从命令行轻松使用该模块。用法请参见`xlate`手册页。

命令 `xlate` 支持 GNU 风格的长选项，例如 `--to-lang`、`--from-lang`、`--engine` 和 `--file`。使用 `xlate -h` 查看所有可用选项。

`xlate`命令与 Docker 环境协同工作，因此即使本地未安装任何东西，只要有 Docker 可用就能使用。请使用`-D`或`-C`选项。

Docker 操作由[App::dozo](https://metacpan.org/pod/App%3A%3Adozo)处理，它也可以作为独立命令使用。`dozo`命令支持`.dozorc`配置文件以持久化容器设置。

此外，由于提供了适用于各种文档样式的 makefile，无需特殊指定即可翻译成其他语言。请使用`-M`选项。

你也可以将 Docker 和`make`选项组合使用，以便在 Docker 环境中运行`make`。

像`xlate -C`这样运行会启动一个挂载了当前工作 git 仓库的 shell。

请阅读["SEE ALSO"](#see-also)章节中的日文文章以了解详情。

# EMACS

加载仓库中包含的`xlate.el`文件，以便在 Emacs 编辑器中使用`xlate`命令。`xlate-region`函数会翻译给定区域。默认语言是`EN-US`，你可以通过带前缀参数调用来指定语言。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    设置你的 DeepL 服务认证密钥。

- OPENAI\_API\_KEY

    OpenAI 认证密钥，由旧版 **gpty** 引擎使用。基于 `llm` 的 **gpt5** 引擎也会读取此变量，但使用 `llm keys set openai` 存储的密钥同样可用。

- GREPLE\_XLATE\_CACHE

    设置默认缓存策略（参见 ["CACHE OPTIONS"](#cache-options)）。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

安装你所使用引擎的命令行工具：**gpt5** 引擎使用 `llm`，DeepL 使用 `deepl`，旧版 GPT 引擎使用 `gpty`。

[https://llm.datasette.io/](https://llm.datasette.io/)

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

## MODULES

[App::Greple::xlate::llm](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Allm), [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::dozo](https://metacpan.org/pod/App%3A%3Adozo) - 由 xlate 用于容器操作的通用 Docker 运行器

## RELATED MODULES

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    关于目标文本模式的详细信息请参见**greple**手册。使用**--inside**、**--outside**、**--include**、**--exclude**选项限制匹配区域。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    你可以使用`-Mupdate`模块根据**greple**命令的结果来修改文件。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    使用**sdif**与**-V**选项并排显示冲突标记格式。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    通过**--xlate-stripe**选项使用 Greple **stripe**模块。

## RESOURCES

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker 容器镜像。

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    用于在`xlate`脚本和[App::dozo](https://metacpan.org/pod/App%3A%3Adozo)中进行选项解析的`getoptlong.sh`库。

- [https://llm.datasette.io/](https://llm.datasette.io/)

    **gpt5** 引擎用于访问 LLM 模型的 `llm` 命令。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python 库和 CLI 命令。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python 库

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 命令行界面

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    用于仅将必要部分通过 DeepL API 翻译并替换的 Greple 模块（日文）

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    使用 DeepL API 模块生成 15 种语言的文档（日文）

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    使用 DeepL API 的自动翻译 Docker 环境（日文）

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
