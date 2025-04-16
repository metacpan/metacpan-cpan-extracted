# NAME

App::Greple::xlate - greple的翻译支持模块

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9909

# DESCRIPTION

**Greple** **xlate** 模块查找所需的文本块，并用翻译后的文本替换它们。目前作为后端引擎实现的有 DeepL（`deepl.pm`）和 ChatGPT（`gpt3.pm`）模块。还包括对 gpt-4 和 gpt-4o 的实验性支持。

如果您想要将Perl的pod样式文档中的普通文本块翻译成中文，请使用以下命令：**greple**，并结合`xlate::deepl`和`perl`模块，如下所示：

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

在这个命令中，模式字符串 `^([\w\pP].*\n)+` 表示以字母数字和标点符号字母开头的连续行。这个命令显示需要翻译的区域高亮显示。选项 **--all** 用于生成整个文本。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

然后添加`--xlate`选项来翻译所选区域。然后，它会找到所需的部分，并用**deepl**命令的输出替换它们。

默认情况下，原始文本和翻译后的文本以与[git(1)](http://man.he.net/man1/git)兼容的"冲突标记"格式打印。使用`ifdef`格式，您可以通过[unifdef(1)](http://man.he.net/man1/unifdef)命令轻松获取所需部分。输出格式可以通过**--xlate-format**选项指定。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

如果您想要翻译整个文本，请使用**--match-all**选项。这是指定模式`(?s).+`（匹配整个文本）的快捷方式。

冲突标记格式数据可以通过`sdif`命令的`-V`选项以并排样式查看。由于逐个字符串比较没有意义，建议使用`--no-cdif`选项。如果不需要给文本上色，请指定`--no-textcolor`（或`--no-tc`）。

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

处理是按指定单位进行的，但在多行非空文本序列的情况下，它们会一起转换为单行。此操作执行如下：

- 去除每行开头和结尾的空格。
- 如果一行以全角标点符号结尾，请与下一行连接。
- 如果一行以全角字符结尾，下一行以全角字符开始，则连接这两行。
- 如果一行的结尾或开头不是全角字符，则通过插入空格字符将它们连接起来。

缓存数据是基于规范化文本进行管理的，因此即使进行了不影响规范化结果的修改，缓存的翻译数据仍然有效。

这个规范化过程仅针对第一个（0号）和偶数编号的模式执行。因此，如果指定了两个模式如下，匹配第一个模式的文本将在规范化后进行处理，而匹配第二个模式的文本将不会进行规范化处理。

    greple -Mxlate -E normalized -E not-normalized

因此，使用第一个模式来处理将多行合并为单行的文本，并使用第二个模式来处理预格式化文本。如果第一个模式中没有要匹配的文本，请使用一个不匹配任何内容的模式，例如 `(?!)`。

# MASKING

偶尔，有些文本部分您不希望被翻译。例如，在 markdown 文件中的标签。DeepL 建议在这种情况下，要排除的文本部分应转换为 XML 标签，进行翻译，然后在翻译完成后恢复。为了支持这一点，可以指定要屏蔽翻译的部分。

    --xlate-setopt maskfile=MASKPATTERN

这将把文件 \`MASKPATTERN\` 的每一行解释为一个正则表达式，翻译匹配的字符串，并在处理后恢复。以 `#` 开头的行将被忽略。

复杂的模式可以用反斜杠转义换行写在多行上。

如何通过掩码转换文本可以通过**--xlate-mask**选项来查看。

此界面是实验性的，未来可能会发生变化。

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    为每个匹配的区域调用翻译过程。

    如果没有此选项，**greple**将作为普通搜索命令运行。因此，在调用实际工作之前，您可以检查文件的哪个部分将成为翻译的对象。

    命令结果输出到标准输出，如果需要，请重定向到文件，或考虑使用[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)模块。

    选项**--xlate**调用**--xlate-color**选项，并带有**--color=never**选项。

    使用**--xlate-fold**选项，转换后的文本将按指定的宽度折叠。默认宽度为70，可以通过**--xlate-fold-width**选项设置。四列用于run-in操作，因此每行最多可以容纳74个字符。

- **--xlate-engine**=_engine_

    指定要使用的翻译引擎。如果直接指定引擎模块，如`-Mxlate::deepl`，则不需要使用此选项。

    目前，可用的引擎如下：

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** 的接口不稳定，目前无法保证能正常工作。

- **--xlate-labor**
- **--xlabor**

    不需要调用翻译引擎，你需要亲自进行翻译。在准备好待翻译的文本后，将其复制到剪贴板。你需要将其粘贴到表单中，将结果复制到剪贴板，并按回车键。

- **--xlate-to** (Default: `EN-US`)

    指定目标语言。使用**DeepL**引擎时，可以通过`deepl languages`命令获取可用语言。

- **--xlate-format**=_format_ (Default: `conflict`)

    指定原始和翻译文本的输出格式。

    除了`xtxt`之外的以下格式假定要翻译的部分是一系列行。实际上，可以只翻译一行的一部分，并且指定除`xtxt`之外的格式不会产生有意义的结果。

    - **conflict**, **cm**

        原始文本和转换后的文本以[git(1)](http://man.he.net/man1/git)冲突标记格式打印。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        您可以通过下一个[sed(1)](http://man.he.net/man1/sed)命令恢复原始文件。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`html

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        &lt;div style="background-color: #f4f4f4; color: #333; border-left: 6px solid #c0392b; padding: 10px; margin: 10px 0;">

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        默认情况下冒号的数量为7。如果您指定像`:::::`这样的冒号序列，则会使用该序列代替7个冒号。

    - **ifdef**

        原始文本和转换后的文本以[cpp(1)](http://man.he.net/man1/cpp) `#ifdef`格式打印。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        您可以通过**unifdef**命令仅检索日语文本：

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        Original text:

    - **xtxt**

        如果格式为`xtxt`（翻译文本）或未知，则仅打印翻译文本。

- **--xlate-maxlen**=_chars_ (Default: 0)

    将以下文本逐行翻译成中文。

- **--xlate-maxline**=_n_ (Default: 0)

    指定一次发送到API的最大文本行数。

    如果要逐行翻译，请将此值设置为1。此选项优先于`--xlate-maxlen`选项。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    将以下文本翻译成中文。

- **--xlate-stripe**

    使用 [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe) 模块以斑马线条纹的方式显示匹配部分。当匹配部分连接在一起时，这是很有用的。

    颜色调色板会根据终端的背景颜色进行切换。如果您想要明确指定，可以使用选项 **--xlate-stripe-light** 或 **--xlate-stripe-dark**。

- **--xlate-mask**

    执行掩码函数并显示转换后的文本，不进行恢复。

- **--match-all**

    在 STDERR 输出中实时查看翻译结果。

# CACHE OPTIONS

将整个文件的文本设置为目标区域。

使用**--xlate-cache=clear**来启动缓存管理或清除所有现有的缓存数据。一旦使用此选项执行，如果不存在缓存文件，将会创建一个新的缓存文件，然后自动进行维护。

- --xlate-cache=_strategy_
    - `auto` (Default)

        **--cache-clear** 选项可用于初始化缓存管理或刷新所有现有的缓存数据。执行此选项后，如果不存在缓存文件，则会创建一个新的缓存文件，然后自动进行维护。

    - `create`

        如果缓存文件存在，则维护缓存文件。

    - `always`, `yes`, `1`

        创建空的缓存文件并退出。

    - `clear`

        只要目标是普通文件，就始终维护缓存。

    - `never`, `no`, `0`

        首先清除缓存数据。

    - `accumulate`

        即使存在缓存文件，也不要使用缓存文件。
- **--xlate-update**

    此选项强制更新缓存文件，即使没有必要。

# COMMAND LINE INTERFACE

您可以通过在分发中包含的 `xlate` 命令轻松地从命令行中使用此模块。请查看 `xlate` 手册页以了解用法。

`xlate`命令与Docker环境配合使用，因此即使您手头没有安装任何东西，只要Docker可用，您就可以使用它。使用`-D`或`-C`选项。

此外，由于提供了各种文档样式的makefile，因此可以在不进行特殊指定的情况下将其翻译成其他语言。使用`-M`选项。

您还可以结合 Docker 和 `make` 选项，这样您就可以在 Docker 环境中运行 `make`。

像 `xlate -C` 这样运行将启动一个带有当前工作 git 仓库挂载的 shell。

请阅读["SEE ALSO"](#see-also)部分的日文文章以获取详细信息。

# EMACS

您可以通过使用存储库中包含的 `xlate` 命令从命令行轻松使用此模块。有关用法，请参阅 `xlate` 帮助信息。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    加载存储库中包含的 `xlate.el` 文件以从 Emacs 编辑器中使用 `xlate` 命令。`xlate-region` 函数翻译给定的区域。默认语言为 `EN-US`，您可以使用前缀参数调用它来指定语言。

- OPENAI\_API\_KEY

    OpenAI身份验证密钥。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

您需要安装DeepL和ChatGPT的命令行工具。

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

为 DeepL 服务设置您的身份验证密钥。

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker容器镜像。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    [App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python库

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI命令行界面

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    DeepL Python 库和 CLI 命令。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    有关目标文本模式的详细信息，请参阅 **greple** 手册。使用 **--inside**、**--outside**、**--include**、**--exclude** 选项来限制匹配区域。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    您可以使用 `-Mupdate` 模块根据 **greple** 命令的结果修改文件。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** 模块使用**--xlate-stripe**选项。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    使用DeepL API进行翻译和替换仅必要的部分的Greple模块（日语）

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    使用DeepL API模块在15种语言中生成文档（日语）

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    带有DeepL API的自动翻译Docker环境（日语）

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
