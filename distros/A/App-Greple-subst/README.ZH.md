# NAME

subst - 用于文本搜索和替换的Greple模块

# VERSION

Version 2.33

# SYNOPSIS

greple -Msubst --dict _dictionary_ \[ 选项 \]。

    Dictionary:
      --dict      dictionary file
      --dictdata  dictionary data

    Check:
      --check=[ng,ok,any,outstand,all,none]
      --select=N
      --linefold
      --stat
      --with-stat
      --stat-style=[default,dict]
      --stat-item={match,expect,number,ok,ng,dict}=[0,1]
      --subst
      --[no-]warn-overlap
      --[no-]warn-include

    File Update:
      --diff
      --diffcmd command
      --create
      --replace
      --overwrite

# DESCRIPTION

这个**greple**模块支持基于字典数据的文本文件的检查和替换。

字典文件由**-dict**选项给出，每一行都包含匹配的模式和预期的字符串对。

    greple -Msubst --dict DICT

如果字典文件包含以下数据。

    colou?r      color
    cent(er|re)  center

上述命令找到第一个与第二个字符串不匹配的模式，即本例中的 "颜色 "和 "中心"。

字典数据中的字段`//`被忽略，所以这个文件可以这样写。

    colou?r      //  color
    cent(er|re)  //  center

你可以通过**greple**的**-f**选项使用同一个文件，在这种情况下，`/`后面的字符串作为注释被忽略。

    greple -f DICT ...

选项**--dictdata**可以用来在命令行中提供字典数据。

    greple --dictdata $'colou?r color\ncent(er|re) center\n'

以尖锐符号（`#`）开始的字典条目是一个注释，被忽略。

## Overlapped pattern

当匹配的字符串与之前被另一个模式匹配的字符串相同或更短时，它将被简单地忽略（默认为**--no-warn-include**）。因此，如果你必须声明冲突的模式，请将较长的模式放在前面。

如果匹配的字符串与先前匹配的字符串重叠，则会被警告（默认为**--warn-overlap**）并被忽略。

## Terminal color

这个版本使用[Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor)模块。它设置选项**--light-screen**或**--dark-screen**，这取决于运行命令的终端，或**TERM\_BGCOLOR**环境变量。

一些终端（例如："Apple\_Terminal "或 "iTerm"）会被自动检测，不需要任何操作。否则，根据终端的背景颜色，将**TERM\_BGCOLOR**环境设置为#000000（黑色）至#FFFFFF（白色）的数字。

# OPTIONS

- **--dict**=_file_

    指定字典文件。

- **--dictdata**=_data_

    用文本指定字典数据。

- **--check**=`outstand`|`ng`|`ok`|`any`|`all`|`none`

    选项**--检查**的参数来自`ng`、`ok`、`any`、`outstand`、`all`和`none`。

    在默认值`outstand`下，只有在同一文件中发现意外字词时，命令才会显示预期和意外字词的信息。

    如果默认值为`ng`，命令将显示意外字词的信息。当值为`ok`时，你将得到关于预期词的信息。用值`any`时都是如此。

    值`all`和`none`只有在与**--stat**选项一起使用时才有意义，并显示从未匹配的模式的信息。

- **--select**=_N_

    从字典中选择第_N_个条目。参数由[Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers)模块解释。范围可以像**--select**=`1:3,7:9`那样定义。你可以通过**--stat**选项获得数字。

- **--linefold**

    如果目标数据被折叠在文本中间，使用**--linefold**选项。它可以创建与跨行的字符串相匹配的反义词模式。但是，被替换的文本不包括换行。因为它在一定程度上混淆了regex行为，如果可能的话，请避免使用。

- **--stat**
- **--with-stat**

    打印统计信息。与**--check**选项一起工作。

    选项**--with-stat**在正常输出后打印统计信息，而**--stat**只打印统计信息。

- **--stat-style**=`default`|`dict`

    将**--stat-style=dict**选项与**--stat**和**--check=any**一起使用，你可以为你的工作文件获得字典式输出。

- **--stat-item** _item_=\[0,1\]

    指定在统计信息中显示哪个项目。默认值是。

        match=1
        expect=1
        number=1
        ng=1
        ok=1
        dict=0

    如果你不需要看到模式字段，就像这样使用。

        --stat-item match=0

    可以同时设置多个参数。

        --stat-item match=number=0,ng=1,ok=1

- **--subst**

    将意外匹配的模式替换为预期的字符串。匹配字符串中的换行符被忽略。没有替换字符串的模式不会被改变。

- **--\[no-\]warn-overlap**

    警告重叠的模式。默认打开。

- **--\[no-\]warn-include**

    警告包含的模式。默认为关闭。

## FILE UPDATE OPTIONS

- **--diff**
- **--diffcmd**=_command_

    选项**--diff**产生原始文本和转换后文本的差异输出。

    指定**--diff**选项使用的diff命令名称。默认为 "diff -u"。

- **--create**

    创建新文件并写入结果。后缀".new "将附加到原始文件名上。

- **--replace**

    用转换后的结果替换目标文件。原始文件被重命名为后缀为".bak "的备份名。

- **--overwrite**

    用转换后的结果覆盖目标文件，没有备份。

# DICTIONARY

这个模块包括字典的例子。它们被安装在共享目录中，通过**--exdict**选项访问。

    greple -Msubst --exdict jtca-katakana-guide-3.dict

- **--exdict** _dictionary_

    使用分布中的_dictionary_ flie作为字典文件。

- **--exdictdir**

    显示字典目录。

- **--exdict** jtca-katakana-guide-3.dict
- **--jtca-katakana-guide**

    从以下指导性文件中创建。

        外来語（カタカナ）表記ガイドライン 第3版
        制定：2015年8月
        発行：2015年9月
        一般財団法人テクニカルコミュニケーター協会 
        Japan Technical Communicators Association
        https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf

- **--jtca**

    定制的**--jtca-katakana-guide**。原始字典是由已发表的数据自动生成的。本词典是为实际使用而定制的。

- **--exdict** jtf-style-guide-3.dict
- **--jtf-style-guide**

    从以下指导性文件中创建。

        JTF日本語標準スタイルガイド（翻訳用）
        第3.0版
        2019年8月20日
        一般社団法人 日本翻訳連盟（JTF）
        翻訳品質委員会
        https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf

- **--jtf**

    定制的**--jtf-style-guide**。原始字典是由公布的数据自动生成的。这个字典是为实际使用而定制的。

- **--exdict** sccc2.dict
- **--sccc2**

    词典用于2014年出版的 "C/C++ セキュアコーディング 第2版"。

        https://www.jpcert.or.jp/securecoding_book_2nd.html

- **--exdict** ms-style-guide.dict
- **--ms-style-guide**

    词典根据微软本地化风格指南生成。

        https://www.microsoft.com/ja-jp/language/styleguides

    数据从这篇文章中生成。

        https://www.atmarkit.co.jp/news/200807/25/microsoft.html

- **--microsoft**

    Customized **--ms-style-guide**。原始词典是由已发表的数据自动生成的。本词典是为实际使用而定制的。

    修正后的字典可以找到[这里](https://github.com/kaz-utashiro/greple-subst/blob/master/share/ms-amend.dict)。如果你有更新的要求，请提出问题或发送pull-request。

# JAPANESE

本模块是为支持日语文本编辑而制作的。

## KATAKANA

日本的KATAKANA词有很多变体来描述同一个词，所以统一很重要，但这是很累人的工作。在下一个例子中。

    イ[エー]ハトー?([ヴブボ]ォ?)  //  イーハトーヴォ

左边的模式匹配了所有下面的词。

    イエハトブ
    イーハトヴ
    イーハトーヴ
    イーハトーヴォ
    イーハトーボ
    イーハトーブ

这个模块有助于检测和纠正它们。

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::subst

# SEE ALSO

[https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/kaz-utashiro/greple-subst](https://github.com/kaz-utashiro/greple-subst)

[https://github.com/kaz-utashiro/greple-update](https://github.com/kaz-utashiro/greple-update)

[https://www.jtca.org/standardization/katakana\_guide\_3\_20171222.pdf](https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf)

[https://www.jtf.jp/jp/style\_guide/styleguide\_top.html](https://www.jtf.jp/jp/style_guide/styleguide_top.html), [https://www.jtf.jp/jp/style\_guide/pdf/jtf\_style\_guide.pdf](https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf)

[https://www.microsoft.com/ja-jp/language/styleguides](https://www.microsoft.com/ja-jp/language/styleguides), [https://www.atmarkit.co.jp/news/200807/25/microsoft.html](https://www.atmarkit.co.jp/news/200807/25/microsoft.html)

[文化庁 國語施策・日本語教育 國語施策情報 內閣告示・內閣訓令 外來語の表記](https://www.bunka.go.jp/kokugo_nihongo/sisaku/joho/joho/kijun/naikaku/gairai/index.html)

[https://qiita.com/kaz-utashiro/items/85add653a71a7e01c415](https://qiita.com/kaz-utashiro/items/85add653a71a7e01c415)

[イーハトーブ](https://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%BC%E3%83%8F%E3%83%88%E3%83%BC%E3%83%96)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2017-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
