# NAME

App::Greple::tee - 用外部命令结果替换匹配文本的模块

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple的**-Mtee**模块将匹配的文本部分发送到给定的过滤命令，并以命令结果替换它们。这个想法来自于名为**teip**的命令。它就像绕过部分数据到外部过滤命令。

过滤命令在模块声明之后（`-Mtee`），以两个破折号结束（`--`）。例如，下一个命令调用`tr`命令，参数为`a-z A-Z`，用于数据中的匹配字。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上述命令将所有匹配的单词从小写转换为大写。事实上，这个例子本身并不那么有用，因为**greple**可以用**--cm**选项更有效地做同样的事情。

默认情况下，该命令是作为一个单独的进程执行的，所有匹配的数据被混合在一起发送给它。如果匹配的文本不以换行结尾，就会在前面添加，后面删除。数据是逐行映射的，所以输入和输出数据的行数必须是相同的。

使用**--discrete**选项，每一个匹配的零件都被调用单独的命令。你可以通过以下命令来区分。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

使用**--discrete**选项时，输入和输出数据的行数不一定相同。

# OPTIONS

- **--discrete**

    为每个匹配的零件单独调用新的命令。

# WHY DO NOT USE TEIP

首先，只要你能用**teip**命令做，就使用它。它是一个优秀的工具，比**greple**快得多。

因为**greple**是为处理文档文件而设计的，它有许多适合于它的功能，如匹配区控制。也许值得使用**greple**来利用这些功能。

另外，**teip**不能将多行数据作为一个单元来处理，而**greple**可以在由多行组成的数据块上执行单个命令。

# EXAMPLE

下一个命令将找到包含在Perl模块文件中的[perlpod(1)](http://man.he.net/man1/perlpod)风格文件内的文本块。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

你可以通过DeepL，通过执行上述命令与**-Mtee**模块相结合，调用**deepl**命令，像这样翻译它们。

    greple -Mtee deepl text --to JA - -- --discrete ...

因为**deepl**对单行输入效果更好，你可以把命令部分改成这样。

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

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
    

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::Tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3ATee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate).

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
