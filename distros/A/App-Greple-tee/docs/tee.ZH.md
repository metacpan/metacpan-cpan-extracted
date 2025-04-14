# NAME

App::Greple::tee - 用外部命令结果替换匹配文本的模块

# SYNOPSIS

    greple -Mtee command -- ...

# VERSION

Version 1.02

# DESCRIPTION

Greple的**-Mtee**模块将匹配的文本部分发送到给定的过滤命令，并以命令结果替换它们。这个想法来自于名为**teip**的命令。它就像绕过部分数据到外部过滤命令。

过滤命令在模块声明之后（`-Mtee`），以两个破折号结束（`--`）。例如，下一个命令调用`tr`命令，参数为`a-z A-Z`，用于数据中的匹配字。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上述命令将所有匹配的单词从小写转换为大写。事实上，这个例子本身并不那么有用，因为**greple**可以用**--cm**选项更有效地做同样的事情。

默认情况下，命令作为单个进程执行，所有匹配的数据会混合发送到该进程。如果匹配的文本不是以换行结束，则会在发送前添加，并在接收后删除。输入和输出数据是逐行映射的，因此输入和输出的行数必须相同。

使用 **--discrete** 选项时，每个匹配的文本区域都会调用单独的命令。你可以通过以下命令来区分。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

使用**--discrete**选项时，输入和输出数据的行数不一定相同。

# OPTIONS

- **--discrete**

    为每个匹配的零件单独调用新的命令。

- **--bulkmode**

    使用 <--discrete> 选项时，每条命令都会按需执行。回车符
    <--bulkmode> option causes all conversions to be performed at once.

- **--crmode**

    该选项将每个程序块中间的换行符替换为回车符。执行命令的结果中包含的回车符将还原为换行符。因此，可以批量处理由多行组成的数据块，而无需使用 **--discrete**选项。

- **--fillup**

    将一连串非空行合并为一行，然后再传递给过滤命令。宽窄字符之间的换行符会被删除，其他换行符会被空格替换。

- **--squeeze**

    将两个或多个连续换行符合并为一个。

- **-ML** **--offload** _command_

    [teip(1)](http://man.he.net/man1/teip) 的 **--offload** 选项在不同的模块 [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL) (**-ML**) 中实现。

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    你也可以使用 **-ML** 模块只处理偶数行，如下所示。

        greple -Mtee cat -n -- -ML 2::2

# LEGACIES

由于 **greple** 中已经实现了 **--stretch** (**-S**) 选项，因此不再需要 **-blocks** 选项。只需执行以下操作即可。

    greple -Mtee cat -n -- --all -SE foo

不建议使用 **--blocks**，因为它将来可能会被废弃。

- **--blocks**

    通常，与指定搜索模式匹配的区域将被发送到外部命令。如果指定了该选项，将处理的不是匹配区域，而是包含该区域的整个块。

    例如，要将包含`foo`模式的行发送到外部命令，需要指定与整行匹配的模式：

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    但如果使用 **-blocks** 选项，就可以简单地完成如下操作：

        greple -Mtee cat -n -- foo --blocks

    使用 **-blocks** 选项时，该模块的行为更类似于 [teip(1)](http://man.he.net/man1/teip) 的 **-g** 选项。否则，其行为类似于带有 **-o** 选项的 [teip(1)](http://man.he.net/man1/teip)。

    不要将 **--blocks** 与 **--all** 选项一起使用，因为块将是整个数据。

# WHY DO NOT USE TEIP

首先，只要你能用**teip**命令做，就使用它。它是一个优秀的工具，比**greple**快得多。

因为**greple**是为处理文档文件而设计的，它有许多适合于它的功能，如匹配区控制。也许值得使用**greple**来利用这些功能。

另外，**teip**不能将多行数据作为一个单元来处理，而**greple**可以在由多行组成的数据块上执行单个命令。

# EXAMPLE

下一个命令将找到包含在Perl模块文件中的[perlpod(1)](http://man.he.net/man1/perlpod)风格文件内的文本块。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

你可以通过DeepL，通过执行上述命令与**-Mtee**模块相结合，调用**deepl**命令，像这样翻译它们。

    greple -Mtee deepl text --to JA - -- --fillup ...

不过，专用模块[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)对这个目的更有效。事实上，**tee**模块的实现提示来自**xlate**模块。

# EXAMPLE 2

接下来的命令会发现LICENSE文件中有一些缩进的部分。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

你可以通过使用**tee**模块和**ansifold**命令来重新格式化这部分内容。

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

离散选项会启动多个进程，因此进程的执行时间会更长。因此，你可以使用 `--separate '\r'`选项和 `ansifold`，后者会使用 CR 字符而不是 NL 字符生成单行。

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

然后通过[tr(1)](http://man.he.net/man1/tr)命令或其他命令将CR字符转换成NL。

    ... | tr '\r' '\n'

# EXAMPLE 3

考虑一下要从非标题行中搜索字符串的情况。例如，你可能想搜索 `docker image ls` 命令中的 Docker 镜像名称，但要保留标题行。你可以通过以下命令来实现。

    greple -Mtee grep perl -- -ML 2: --discrete --all

选项 `-ML 2:` 检索倒数第二行，并将其发送给 `grep perl` 命令。需要使用选项 --discrete 是因为输入和输出的行数会发生变化，但由于命令只执行一次，因此不会影响性能。

如果尝试用 **teip** 命令做同样的事情，`teip -l 2- -- grep` 会出错，因为输出行数少于输入行数。不过，得到的结果没有问题。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# BUGS

在连接韩文文本时，`-fillup` 选项将删除韩文字符之间的空格。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
