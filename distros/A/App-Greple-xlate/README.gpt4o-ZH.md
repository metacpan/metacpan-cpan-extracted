# NAME

App::Greple::xlate - greple 的翻译支持模块  

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.9901

# DESCRIPTION

**Greple** **xlate** 模块查找所需的文本块并用翻译后的文本替换它们。当前实现了 DeepL (`deepl.pm`) 和 ChatGPT (`gpt3.pm`) 模块作为后端引擎。还包括对 gpt-4 和 gpt-4o 的实验性支持。  

如果您想翻译以 Perl 的 pod 风格编写的文档中的普通文本块，请使用 **greple** 命令与 `xlate::deepl` 和 `perl` 模块，如下所示：  

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

在这个命令中，模式字符串 `^([\w\pP].*\n)+` 意味着以字母数字和标点符号字母开头的连续行。这个命令显示要翻译的区域高亮显示。选项 **--all** 用于生成整个文本。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

然后添加 `--xlate` 选项以翻译所选区域。然后，它将找到所需的部分并用 **deepl** 命令的输出替换它们。  

默认情况下，原始文本和翻译文本以与 [git(1)](http://man.he.net/man1/git) 兼容的“冲突标记”格式打印。使用 `ifdef` 格式，您可以通过 [unifdef(1)](http://man.he.net/man1/unifdef) 命令轻松获取所需部分。输出格式可以通过 **--xlate-format** 选项指定。  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

如果您想翻译整个文本，请使用 **--match-all** 选项。这是指定模式 `(?s).+` 的快捷方式，该模式匹配整个文本。  

冲突标记格式的数据可以通过 `sdif` 命令与 `-V` 选项以并排样式查看。由于逐字符串比较没有意义，因此建议使用 `--no-cdif` 选项。如果您不需要为文本上色，请指定 `--no-textcolor`（或 `--no-tc`）。  

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
    </p>
</div>

# NORMALIZATION

处理是在指定的单位中进行的，但在多行非空文本的序列情况下，它们会一起转换为单行。此操作按如下方式执行：  

- 去除每行开头和结尾的空白。  
- 如果一行以全角标点字符结尾，则与下一行连接。  
- 如果一行以全角字符结尾且下一行以全角字符开头，则连接这些行。  
- 如果一行的结尾或开头不是全角字符，则通过插入空格字符连接它们。  

缓存数据是基于规范化文本管理的，因此即使进行的修改不影响规范化结果，缓存的翻译数据仍然有效。  

此规范化过程仅对第一个（0th）和偶数模式执行。因此，如果指定两个模式如下，匹配第一个模式的文本将在规范化后处理，而匹配第二个模式的文本将不进行规范化处理。  

    greple -Mxlate -E normalized -E not-normalized

因此，对于需要通过将多行合并为单行来处理的文本，使用第一个模式；对于预格式化文本，使用第二个模式。如果在第一个模式中没有匹配的文本，请使用一个不匹配任何内容的模式，例如 `(?!)`。

# MASKING

偶尔，有些文本部分您不希望被翻译。例如，markdown 文件中的标签。DeepL 建议在这种情况下，将要排除的文本部分转换为 XML 标签，翻译后再恢复。为了支持这一点，可以指定要从翻译中屏蔽的部分。

    --xlate-setopt maskfile=MASKPATTERN

这将把文件 \`MASKPATTERN\` 的每一行解释为正则表达式，翻译与之匹配的字符串，并在处理后恢复。以 `#` 开头的行将被忽略。

复杂的模式可以用反斜杠转义换行符在多行上书写。

通过 **--xlate-mask** 选项可以看到文本是如何通过掩码进行转换的。

此接口是实验性的，未来可能会有所更改。

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    对每个匹配区域调用翻译过程。

    没有这个选项，**greple** 的行为就像一个普通的搜索命令。因此，您可以在实际工作之前检查文件的哪个部分将成为翻译的对象。

    命令结果输出到标准输出，因此如果需要，可以重定向到文件，或者考虑使用 [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) 模块。

    选项 **--xlate** 调用 **--xlate-color** 选项，并带有 **--color=never** 选项。

    使用 **--xlate-fold** 选项时，转换的文本按指定宽度折叠。默认宽度为 70，可以通过 **--xlate-fold-width** 选项设置。四列保留用于运行操作，因此每行最多可以容纳 74 个字符。

- **--xlate-engine**=_engine_

    指定要使用的翻译引擎。如果您直接指定引擎模块，例如 `-Mxlate::deepl`，则不需要使用此选项。

    此时，以下引擎可用

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4-turbo
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** 的接口不稳定，目前无法保证正常工作。

- **--xlate-labor**
- **--xlabor**

    您需要为翻译引擎工作。在准备要翻译的文本后，它们会被复制到剪贴板。您需要将它们粘贴到表单中，复制结果到剪贴板，然后按回车。

- **--xlate-to** (Default: `EN-US`)

    指定目标语言。使用 **DeepL** 引擎时，可以通过 `deepl languages` 命令获取可用语言。

- **--xlate-format**=_format_ (Default: `conflict`)

    指定原始文本和翻译文本的输出格式。

    除了 `xtxt` 之外的以下格式假定要翻译的部分是一系列行。实际上，可以只翻译行的一部分，指定 `xtxt` 以外的格式将不会产生有意义的结果。

    - **conflict**, **cm**

        原始文本和转换文本以 [git(1)](http://man.he.net/man1/git) 冲突标记格式打印。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        您可以通过下一个 [sed(1)](http://man.he.net/man1/sed) 命令恢复原始文件。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **colon**, _:::::::_

        \`\`\`markdown
        &lt;custom-container>
        The original and translated text are output in a markdown's custom container style.
        原文和翻译的文本以Markdown的自定义容器样式输出。
        &lt;/custom-container>
        \`\`\`

            ::::::: ORIGINAL
            original text
            :::::::
            ::::::: JA
            translated Japanese text
            :::::::

        以上文本将被翻译为以下HTML。

            <div class="ORIGINAL">
            original text
            </div>
            <div class="JA">
            translated Japanese text
            </div>

        默认情况下，冒号的数量为7。如果您指定冒号序列，如`:::::`，则将使用该序列代替7个冒号。

    - **ifdef**

        原始文本和转换文本以 [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 格式打印。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        您可以通过 **unifdef** 命令仅检索日文文本：

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**
    - **space+**

        原始文本和转换后的文本之间用一个空行分隔。对于 `space+`，转换后的文本后面也会输出一个换行符。

    - **xtxt**

        如果格式为 `xtxt`（翻译文本）或未知，则仅打印翻译文本。

- **--xlate-maxlen**=_chars_ (Default: 0)

    指定一次发送到 API 的最大文本长度。默认值设置为免费 DeepL 账户服务：API（**--xlate**）为 128K，剪贴板接口（**--xlate-labor**）为 5000。如果您使用的是专业服务，可能能够更改这些值。

- **--xlate-maxline**=_n_ (Default: 0)

    指定一次发送到 API 的最大行数。

    将此值设置为1，如果您想一次翻译一行。此选项优先于`--xlate-maxlen`选项。  

- **--**\[**no-**\]**xlate-progress** (Default: True)

    在STDERR输出中实时查看翻译结果。  

- **--xlate-stripe**

    使用[App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)模块以斑马条纹的方式显示匹配的部分。当匹配的部分是连续连接时，这非常有用。

    颜色调色板根据终端的背景颜色进行切换。如果您想明确指定，可以使用 **--xlate-stripe-light** 或 **--xlate-stripe-dark**。

- **--xlate-mask**

    执行掩码功能并按原样显示转换后的文本，而不进行恢复。

- **--match-all**

    将文件的整个文本设置为目标区域。  

# CACHE OPTIONS

**xlate**模块可以为每个文件存储翻译的缓存文本，并在执行之前读取它，以消除向服务器请求的开销。使用默认的缓存策略`auto`，仅在目标文件存在缓存文件时维护缓存数据。  

使用 **--xlate-cache=clear** 来启动缓存管理或清理所有现有的缓存数据。  
一旦使用此选项执行，如果不存在缓存文件，将创建一个新的缓存文件，然后自动进行维护。

- --xlate-cache=_strategy_
    - `auto` (Default)

        如果缓存文件存在，则维护该缓存文件。  

    - `create`

        创建空的缓存文件并退出。  

    - `always`, `yes`, `1`

        只要目标是正常文件，无论如何都维护缓存。  

    - `clear`

        首先清除缓存数据。  

    - `never`, `no`, `0`

        即使缓存文件存在，也绝不使用缓存文件。  

    - `accumulate`

        根据默认行为，未使用的数据会从缓存文件中删除。如果您不想删除它们并保留在文件中，请使用`accumulate`。  
- **--xlate-update**

    此选项强制更新缓存文件，即使没有必要。

# COMMAND LINE INTERFACE

您可以通过使用分发中包含的`xlate`命令轻松地从命令行使用此模块。有关用法，请参见`xlate`手册页。

`xlate`命令与Docker环境协同工作，因此即使您手头没有安装任何东西，只要Docker可用，您也可以使用它。使用`-D`或`-C`选项。  

此外，由于提供了各种文档样式的makefile，因此可以在没有特殊说明的情况下翻译成其他语言。使用`-M`选项。  

您还可以结合Docker和make选项，以便在Docker环境中运行make。  

像`xlate -GC`这样的运行将启动一个挂载当前工作git存储库的shell。  

有关详细信息，请阅读["SEE ALSO"](#see-also)部分中的日文文章。  

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

加载存储库中包含的`xlate.el`文件，以便从Emacs编辑器使用`xlate`命令。`xlate-region`函数翻译给定区域。默认语言为`EN-US`，您可以通过调用前缀参数指定语言。  

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
    </p>
</div>

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    为DeepL服务设置您的身份验证密钥。  

- OPENAI\_API\_KEY

    OpenAI身份验证密钥。  

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

您必须安装DeepL和ChatGPT的命令行工具。  

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)  

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)  

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)  

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)  

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)  

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker容器镜像。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python库和CLI命令。  

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python库  

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI命令行接口  

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    有关目标文本模式的详细信息，请参见**greple**手册。使用**--inside**、**--outside**、**--include**、**--exclude**选项来限制匹配区域。  

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    您可以使用`-Mupdate`模块根据**greple**命令的结果修改文件。  

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    使用**sdif**以**-V**选项并排显示冲突标记格式。  

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    Greple **stripe** 模块通过 **--xlate-stripe** 选项使用。

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple模块使用DeepL API翻译和替换仅必要的部分（用日语）。  

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    使用DeepL API模块生成15种语言的文档（用日语）。  

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    自动翻译 Docker 环境与 DeepL API（用日语）

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
