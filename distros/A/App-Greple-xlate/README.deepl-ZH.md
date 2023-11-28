# NAME

App::Greple::xlate - greple的翻译支持模块

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.28

# DESCRIPTION

**Greple** **xlate** 模块可查找文本块并将其替换为翻译文本。目前，DeepL (`deepl.pm`) 和 ChatGPT (`gpt3.pm`) 模块作为后端引擎实现。

如果要翻译以 [pod](https://metacpan.org/pod/pod) 风格编写的普通文本块，可使用 **greple** 命令和 `xlate::deepl` 及 `perl` 模块，就像这样：

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

模式`^(\w.*\n)+`表示以字母-数字开头的连续行。这个命令显示要翻译的区域。选项**--all**用于生成整个文本。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

然后添加`--xlate`选项来翻译选定的区域。它将找到并替换为**-deepl**命令的输出。

默认情况下，原文和译文以与 [git(1)](http://man.he.net/man1/git) 兼容的 "冲突标记 "格式打印。使用 `ifdef` 格式，可以通过 [unifdef(1)](http://man.he.net/man1/unifdef) 命令轻松获得所需的部分。输出格式可以通过 **--xlate-format** 选项指定。

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

如果要翻译整个文本，请使用 **--match-all** 选项。这是指定匹配整个文本的模式 `(?s).+` 的快捷方式。

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

- **--xlate-labor**
- **--xlabor**

    与其说是调用翻译引擎，不如说是希望你能为之工作。在准备好要翻译的文本后，它们被复制到剪贴板上。你应该把它们粘贴到表格中，把结果复制到剪贴板上，然后点击返回。

- **--xlate-to** (Default: `EN-US`)

    指定目标语言。当使用**DeepL**引擎时，你可以通过`deepl languages`命令获得可用语言。

- **--xlate-format**=_format_ (Default: `conflict`)

    指定原始和翻译文本的输出格式。

    - **conflict**, **cm**

        以[git(1)](http://man.he.net/man1/git)冲突标记格式打印原始和翻译文本。

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        你可以通过下一个[sed(1)](http://man.he.net/man1/sed)命令恢复原始文件。

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        以 [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` 格式打印原始和翻译文本。

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        你可以通过**unifdef**命令只检索日文文本。

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        打印原始文本和翻译文本，用单个空行分开。

    - **xtxt**

        如果格式是`xtxt`（翻译文本）或不知道，则只打印翻译文本。

- **--xlate-maxlen**=_chars_ (Default: 0)

    指定一次发送到 API 的最大文本长度。默认值与 DeepL 免费账户服务一样：API (**--xlate**) 为 128K，剪贴板界面 (**--xlate-labor**) 为 5000。如果使用专业版服务，您可以更改这些值。

- **--**\[**no-**\]**xlate-progress** (Default: True)

    在STDERR输出中可以看到实时的翻译结果。

- **--match-all**

    将文件的整个文本设置为目标区域。

# CACHE OPTIONS

**xlate**模块可以存储每个文件的翻译缓存文本，并在执行前读取它，以消除向服务器请求的开销。在默认的缓存策略`auto`下，它只在目标文件的缓存文件存在时才维护缓存数据。

- --cache-clear

    **--cache-clear**选项可以用来启动缓冲区管理或刷新所有现有的缓冲区数据。一旦用这个选项执行，如果不存在一个新的缓存文件，就会创建一个新的缓存文件，然后自动维护。

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

# COMMAND LINE INTERFACE

你可以通过使用版本库中的`xlate`命令从命令行轻松使用这个模块。请参阅 `xlate` 的帮助信息了解用法。

# EMACS

加载存储库中的`xlate.el`文件，从Emacs编辑器中使用`xlate`命令。`xlate-region`函数翻译给定的区域。默认的语言是`EN-US`，你可以用前缀参数指定调用语言。

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

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

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

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
