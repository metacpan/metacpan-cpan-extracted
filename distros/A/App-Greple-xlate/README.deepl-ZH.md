# NAME

App::Greple::xlate - greple的翻译支持模块

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

    greple -Mxlate::gpt4 --xlate pattern target-file

    greple -Mxlate --xlate-engine gpt4 --xlate pattern target-file

# VERSION

Version 0.9912

# DESCRIPTION

**Greple** **xlate** 模块可找到所需的文本块，并将其替换为翻译文本。目前，DeepL (`deepl.pm`)和 ChatGPT 4.1 (`gpt4.pm`)模块是作为后端引擎实现的。

如果要翻译以 Perl 的 pod 风格编写的文档中的普通文本块，请使用 **greple** 命令，并像这样使用 `xlate::deepl` 和 `perl` 模块：

    greple -Mxlate::deepl -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

在该命令中，模式字符串 `^([\w\pP].*\n)+` 表示以字母和标点符号开头的连续行。该命令高亮显示要翻译的区域。选项 **--all** 用于生成整个文本。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

然后添加 `--xlate` 选项来翻译选定区域。然后，它会找到所需的部分，并用 **deepl** 命令输出将其替换。

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

这将把文件 \`MASKPATTERN\` 的每一行都解释为正则表达式，翻译与之匹配的字符串，并在处理后还原。以 `#` 开头的行将被忽略。

复杂的模式可以用反斜线换行写成多行。

通过 **--xlate-mask** 选项可以看到屏蔽后文本的转换效果。

此接口为试验性接口，将来可能会更改。

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

    指定要使用的翻译引擎。如果直接指定引擎模块，如 `-Mxlate::deepl`，则无需使用此选项。

    目前有以下引擎

    - **deepl**: DeepL API
    - **gpt3**: gpt-3.5-turbo
    - **gpt4**: gpt-4.1
    - **gpt4o**: gpt-4o-mini

        **gpt-4o** 的接口不稳定，目前无法保证正常工作。

- **--xlate-labor**
- **--xlabor**

    您需要做的不是调用翻译引擎，而是为其工作。准备好要翻译的文本后，它们会被复制到剪贴板。您需要将它们粘贴到表单中，将结果复制到剪贴板，然后点击回车键。

- **--xlate-to** (Default: `EN-US`)

    指定目标语言。当使用**DeepL**引擎时，你可以通过`deepl languages`命令获得可用语言。

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

    指定一次发送到 API 的最大文本长度。默认值与 DeepL 免费账户服务一样：API (**--xlate**) 为 128K，剪贴板界面 (**--xlate-labor**) 为 5000。如果使用专业版服务，您可以更改这些值。

- **--xlate-maxline**=_n_ (Default: 0)

    指定一次发送到 API 的最大文本行数。

    如果想一次翻译一行，则将该值设为 1。该选项优先于 `--xlate-maxlen` 选项。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    在STDERR输出中可以看到实时的翻译结果。

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

`xlate` 命令与 Docker 环境协同工作，因此即使你手头没有安装任何东西，只要 Docker 可用，你就可以使用它。使用 `-D` 或 `-C` 选项。

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

    OpenAI 验证密钥。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

您必须安装 DeepL 和 ChatGPT 的命令行工具。

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt4](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt4)

- [https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

    Docker 容器镜像。

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python库和CLI命令。

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python 库

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI 命令行界面

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    关于目标文本模式的细节，请参见**greple**手册。使用**--inside**, **--outside**, **--include**, **--exclude**选项来限制匹配区域。

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    你可以使用`-Mupdate`模块通过**greple**命令的结果来修改文件。

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    使用**sdif**与**-V**选项并列显示冲突标记格式。

- [App::Greple::stripe](https://metacpan.org/pod/App%3A%3AGreple%3A%3Astripe)

    通过 **--xlate-stripe** 选项查看 **stripe** 模块的使用情况。

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

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
