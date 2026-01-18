# NAME

App::Greple::tee - 用外部命令结果替换匹配文本的模块

# SYNOPSIS

    greple -Mtee command -- ...

# VERSION

Version 1.04

# DESCRIPTION

Greple 的 **-Mtee** 模块将匹配到的文本片段发送给指定的过滤命令，并用该命令的结果替换。这个想法源自名为 **teip** 的命令。它就像把部分数据旁路到外部过滤命令。

过滤命令紧跟在模块声明（`-Mtee`）之后，并以两个短横线（`--`）结束。例如，下面的命令对数据中匹配到的单词调用 `tr` 命令，并传入 `a-z A-Z` 参数。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上面的命令把所有匹配到的单词从小写转换为大写。事实上，这个例子本身不太实用，因为 **greple** 使用 **--cm** 选项可以更高效地完成同样的事情。

默认情况下，命令作为单个进程执行，所有匹配到的数据混合后发送到该进程。如果匹配文本不以换行结束，会在发送前补加换行并在接收后去除。输入与输出数据按行对应，因此输入与输出的行数必须相同。

使用 **--discrete** 选项时，会为每个匹配的文本区域单独调用命令。你可以通过以下命令分辨差异。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

与 **--discrete** 选项一起使用时，输入与输出数据的行数不必相同。

# OPTIONS

- **--discrete**

    为每个匹配到的部分单独启动新命令。

- **--bulkmode**

    使用 <--discrete> 选项时，每个命令按需执行。使用 <--bulkmode> 选项时，所有转换将一次性完成。

- **--crmode**

    该选项会将每个块中间的所有换行符替换为回车符。执行命令得到的结果中包含的回车符会还原为换行符。这样就可以在不使用 **--discrete** 选项的情况下批量处理由多行组成的块。

    这与 [ansifold](https://metacpan.org/pod/ansifold) 命令的 **--crmode** 选项配合良好，该选项将以 CR 分隔的文本合并，并输出以 CR 分隔的折行。

- **--fillup**

    在传给过滤命令之前，将连续的非空行合并为一行。位宽字符（中文、日文）之间的换行会被删除，其他换行会被替换为空格。韩文（谚文/Hangul）按 ASCII 文本处理，以空格连接。

- **--squeeze**

    将两个或更多连续的换行合并为一个。

- **-ML** **--offload** _command_

    [teip(1)](http://man.he.net/man1/teip) 的 **--offload** 选项在不同的模块 [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL)（**-ML**）中实现。

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    你也可以使用 **-ML** 模块如下只处理偶数行。

        greple -Mtee cat -n -- -ML 2::2

# CONFIGURATION

模块参数可使用 **Getopt::EX::Config** 模块按以下语法设置：

    greple -Mtee::config(discrete) ...
    greple -Mtee::config(fillup,crmode) ...

这在与 shell 别名或模块文件结合时很有用。

可用的参数有：**discrete**、**bulkmode**、**crmode**、**fillup**、**squeeze**、**blocks**。

# FUNCTION CALL

您可以通过在命令名前加上 `&` 来调用 Perl 函数，而不是外部命令。

    greple -Mtee '&App::ansifold::ansifold' -w40 -- ...

该函数在派生的子进程中执行，因此必须遵循以下要求：

- 从 **STDIN** 读取匹配的文本
- 将转换后的结果打印到 **STDOUT**
- 参数通过 `@ARGV` 和 `@_` 同时传递

可以使用任何完全限定的函数名：

    greple -Mtee '&Your::Module::function' -- ...

如果模块尚未加载，将自动加载。

为方便起见，提供以下简短别名：

- **&ansicolumn**

    调用 `App::ansicolumn::ansicolumn`。

- **&ansifold**

    调用 `App::ansifold::ansifold`。

- **&cat-v**

    调用 `App::cat::v->new->run(@_)`。

使用函数调用可避免每次调用都为外部进程派生所带来的开销，当与 **--discrete** 选项一起使用时，可显著提升性能。

# LEGACIES

由于 **greple** 中已实现 **--stretch**（**-S**）选项，**--blocks** 选项已不再需要。你只需进行如下操作即可。

    greple -Mtee cat -n -- --all -SE foo

不推荐使用 **--blocks**，因为它将来可能被弃用。

- **--blocks**

    通常，符合指定搜索模式的区域会被发送到外部命令。如果指定了此选项，将处理包含该匹配区域的整个区块，而不是仅处理匹配区域。

    例如，要将包含模式 `foo` 的行发送到外部命令，需要指定能匹配整行的模式：

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    但使用 **--blocks** 选项，可以像下面这样简单完成：

        greple -Mtee cat -n -- foo --blocks

    使用 **--blocks** 选项时，本模块的行为更像 [teip(1)](http://man.he.net/man1/teip) 的 **-g** 选项。否则，其行为类似于带 **-o** 选项的 [teip(1)](http://man.he.net/man1/teip)。

    不要将 **--blocks** 与 **--all** 选项一起使用，因为该区块将变为整个数据。

# WHY DO NOT USE TEIP

首先，只要可以用 **teip** 命令做到，就用它。它是一个优秀且比 **greple** 快得多的工具。

由于 **greple** 旨在处理文档文件，它具有许多适用于此目的的功能，例如匹配区域控制。为了利用这些功能，使用 **greple** 也许是值得的。

此外，**teip** 不能将多行数据作为一个单元处理，而 **greple** 可以对由多行组成的数据块执行单独的命令。

# EXAMPLE

下面的命令将会在包含于 Perl 模块文件中的 [perlpod(1)](http://man.he.net/man1/perlpod) 风格文档里查找文本区块。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

你可以将上面的命令与调用 **deepl** 命令的 **-Mtee** 模块组合执行，通过 DeepL 服务翻译它们，如下所示：

    greple -Mtee deepl text --to JA - -- --fillup ...

不过，专用模块 [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) 在此目的上更有效。实际上，**tee** 模块的实现提示来自 **xlate** 模块。

# EXAMPLE 2

下面的命令将在 LICENSE 文档中找到一些缩进部分。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

你可以用带有 **ansifold** 命令的 **tee** 模块来重新格式化这部分。两个 **--crmode** 选项一起使用可以高效处理多行区块：

    greple -Mtee ansifold -sw40 --prefix '     ' --crmode -- --crmode --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

**--discrete** 选项也可以使用，但会启动多个进程，因此执行时间更长。

# EXAMPLE 3

考虑一种情况：你想从非表头行中 grep 字符串。例如，你可能想从 `docker image ls` 命令中搜索 Docker 镜像名称，但保留表头行。可以用下面的命令实现。

    greple -Mtee grep perl -- -ML 2: --discrete --all

选项 `-ML 2:` 取出从第二行到倒数第一行的内容，并将其发送到 `grep perl` 命令。由于输入与输出的行数发生变化，需要使用 --discrete 选项，但因为命令只执行一次，所以没有性能上的劣势。

如果尝试用 **teip** 命令做同样的事情，`teip -l 2- -- grep` 会报错，因为输出行数少于输入行数。然而，得到的结果本身并没有问题。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::ansifold](https://metacpan.org/pod/App%3A%3Aansifold), [https://github.com/tecolicom/App-ansifold](https://github.com/tecolicom/App-ansifold)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
