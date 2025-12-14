# NAME

App::Greple::xlate - greple 的翻译支持模块

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate::gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

# VERSION

Version 0.9920

# DESCRIPTION

**Greple** **xlate** 模块查找所需的文本块，并将其替换为翻译后的文本。目前已实现 DeepL（`deepl.pm`）、ChatGPT 4.1（`gpt4.pm`）和 GPT-5（`gpt5.pm`）模块作为后端引擎。

如果你想翻译以 Perl 的 pod 风格编写的文档中的普通文本块，可像这样将 **greple** 命令与 `xlate::deepl` 和 `perl` 模块一起使用：

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

在此命令中，模式字符串 `^([\w\pP].*\n)+` 表示以字母数字和标点符号开头的连续行。该命令会高亮显示将被翻译的区域。选项 **--all** 用于生成完整文本。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

然后添加 `--xlate` 选项以翻译所选区域。接着，它会找到所需的部分并将其替换为 **deepl** 命令的输出。

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

这会将文件 \`MASKPATTERN\` 的每一行作为正则表达式解释，翻译匹配的字符串，并在处理后恢复。以 `#` 开头的行会被忽略。

复杂的模式可以使用反斜杠转义换行写在多行上。

通过 **--xlate-mask** 选项可以查看文本经屏蔽转换后的样子。

此接口为实验性质，将来可能会改变。

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

    指定要使用的翻译引擎。如果直接指定引擎模块，例如 `-Mxlate::deepl`，则无需使用此选项。

    目前可用的引擎如下所示

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** 的接口不稳定，目前无法保证能正确工作。

    - **gpt5**: gpt-5

- **--xlate-labor**
- **--xlabor**

    不调用翻译引擎，而是期望由你手动完成。准备好要翻译的文本后，它们会被复制到剪贴板。你需要将其粘贴到表单中，将结果复制回剪贴板并按回车。

- **--xlate-to** (Default: `EN-US`)

    指定目标语言。使用 **DeepL** 引擎时，可以通过 `deepl languages` 命令获取可用语言。

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

    指定一次发送到 API 的文本最大长度。默认值按 DeepL 免费账户服务设置：API 为 128K（**--xlate**），剪贴板接口为 5000（**--xlate-labor**）。如果使用 Pro 服务，您可以更改这些值。

- **--xlate-maxline**=_n_ (Default: 0)

    指定一次发送到 API 的文本最大行数。

    如果希望逐行翻译，将此值设为 1。此选项优先于`--xlate-maxlen`选项。

- **--xlate-prompt**=_text_

    指定要发送给翻译引擎的自定义提示词。此选项仅在使用 ChatGPT 引擎（gpt3、gpt4、gpt4o）时可用。您可以通过向 AI 模型提供特定指令来自定义翻译行为。如果提示词包含`%s`，将被替换为目标语言名称。

- **--xlate-context**=_text_

    指定要发送给翻译引擎的附加上下文信息。此选项可多次使用以提供多个上下文字符串。上下文信息有助于翻译引擎理解背景并生成更准确的译文。

- **--xlate-glossary**=_glossary_

    指定用于翻译的术语库（glossary）ID。此选项仅在使用 DeepL 引擎时可用。术语库 ID 应从您的 DeepL 账户获取，以确保特定术语的一致翻译。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    在 STDERR 输出中实时查看翻译结果。

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

Docker 操作由 `dozo` 脚本处理，也可以作为独立命令使用。`dozo` 脚本支持使用 `.dozorc` 配置文件来持久化容器设置。

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

    OpenAI 认证密钥。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

你需要安装 DeepL 和 ChatGPT 的命令行工具。

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

[App::Greple::xlate::gpt5](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt5)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker 容器镜像。

- [https://github.com/tecolicom/getoptlong](https://github.com/tecolicom/getoptlong)

    `getoptlong.sh` 库用于在 `xlate` 和 `dozo` 脚本中进行选项解析。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python 库和 CLI 命令。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python 库

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 命令行界面

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    关于目标文本模式的详细信息请参见**greple**手册。使用**--inside**、**--outside**、**--include**、**--exclude**选项限制匹配区域。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    你可以使用`-Mupdate`模块根据**greple**命令的结果来修改文件。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    使用**sdif**与**-V**选项并排显示冲突标记格式。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    通过**--xlate-stripe**选项使用 Greple **stripe**模块。

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

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
