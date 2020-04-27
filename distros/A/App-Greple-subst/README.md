# NAME

subst - Greple module for text search and substitution

# VERSION

Version 2.13

# SYNOPSIS

greple -Msubst --dict _dictionary_ \[ options \]

    --dict      dictionary file
    --dictdata  dictionary data

    --check=[ng,ok,any,outstand,all]
    --select=N
    --linefold
    --stat
    --with-stat
    --stat-style=[default,dict]
    --diff
    --diffcmd command
    --replace
    --create
    --[no-]warn-overlap
    --[no-]warn-include

# DESCRIPTION

This **greple** module supports check and substitution of text file
using a dictionary file.

Dictionary file is given by **--dict** option and contains pattern and
expected string pairs.

    greple -Msubst --dict DICT

If the dictionary file contains following data:

    colou?r      color
    cent(er|re)  center

Then above command find the first pattern which does not match the
second string, that is "colour" and "centre" in this case.

Field "//" in dictionary file is ignored, so this file can be written
like this:

    colou?r      //  color
    cent(er|re)  //  center

You can use same file by **greple**'s **-f** option and string after
"//" is ignored as a comment in that case.

    greple -f DICT ...

Option **--dictdata** can be used to provide dictionary data in command
line.

    greple --dictdata $'colou?r color\ncent(er|re) center\n'

## Overlapped pattern

When the matched string is same or shorter than previously matched
string by another pattern, it is simply ignored (**--no-warn-include**
by default).  So, if you have to declare conflicted patterns, put the
longer pattern in front.

If the matched string overlaps with previously matched string, it is
warned (**--warn-overlap** by default) and ignored.

## Terminal color

This version uses [Getopt::EX::termcolor](https://metacpan.org/pod/Getopt::EX::termcolor) module.  It sets option
**--light-screen** or **--dark-screen** depending on the terminal on
which the command run, or **BRIGHTNESS** environment variable.

Some terminals (eg: "Apple\_Terminal" or "iTerm") are detected
automatically and no action is required.  Otherwise set **BRIGHTNESS**
environment to 0 (black) to 100 (white) digit depending on terminal
background color.

# OPTIONS

- **--check**=_outstand_|_ng_|_ok_|_any_|_all_|_none_

    Option **--check** takes argument from _ng_, _ok_, _any_,
    _outstand_, _all_ and _none_.

    With default value _outstand_, command will show information about
    both expected and unexpected words only when unexpected word was found
    in the same file.

    With value _ng_, command will show information about unexpected
    words.  With value _ok_, you will get information about expected
    words.  Both with value _any_.

    Value _all_ and _none_ make sense only when used with **--stat**
    option, and display information about never matched pattern.

- **--select**=_N_

    Select _N_th entry from the dictionary.  Argument is interpreted by
    [Getopt::EX::Numbers](https://metacpan.org/pod/Getopt::EX::Numbers) module.  Range can be defined like
    **--select**=_1:3,7:9_.  You can get numbers by **--stat** option.

- **--linefold**

    If the target data is folded in the middle of text, use **--linefold**
    option.  It creates regex patterns which matches string spread across
    lines.  Substituted text does not include newline, though.  Because it
    confuses regex behavior somewhat, avoid to use if possible.

- **--stat**
- **--with-stat**

    Print statistical information.  Works with **--check** option.

    Option **--with-stat** print statistics after normal output, while
    **--stat** print only statistics.

- **--stat-style**=\[_default_|_dict_\]

    Using **--stat-style=dict** option with **--stat** and **--check=any**,
    you can get dictionary style output for your working document.

- **--subst**

    Substitute unexpected matched pattern to expected string.  Newline
    character in the matched string is ignored.  Pattern without
    replacement string is not changed.

- **--diff**
- **--diffcmd**=_command_

    Option **-diff** produce diff output of original and converted text.

    Specify diff command name used by **--diff** option.  Default is "diff
    \-u".

- **--replace**

    Replace the target file by converted result.  Original file is renamed
    to backup name with ".bak" suffix.

- **--create**

    Create new file and write the result.  Suffix ".new" is appended to
    original filename.

- **--\[no-\]warn-overlap**

    Warn overlapped pattern.
    Default on.

- **--\[no-\]warn-include**

    Warn included pattern.
    Default off.

# DICTIONARY

This module includes example dictionaries.  They are installed share
directory and accessed by **--exdict** option.

    greple -Msubst --exdict jtca-katakana-guide-3.dict

- **--exdict** _dictionary_

    Use _dictionary_ flie in the distribution as a dictionary file.

- **--exdictdir**

    Show dictionary directory.

- **--exdict** jtca-katakana-guide-3.dict
- **--jtca-katakana-guide**

    Created from following guideline document.

        外来語（カタカナ）表記ガイドライン 第3版
        制定：2015年8月
        発行：2015年9月
        一般財団法人テクニカルコミュニケーター協会 
        Japan Technical Communicators Association
        https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf

- **--exdict** jtf-style-guide-3.dict
- **--jtf-style-guide**

    Created from following guideline document.

        JTF日本語標準スタイルガイド（翻訳用）
        第3.0版
        2019年8月20日
        一般社団法人 日本翻訳連盟（JTF）
        翻訳品質委員会
        https://www.jtf.jp/jp/style_guide/pdf/jtf_style_guide.pdf

- **--exdict** sccc2.dict
- **--sccc2**

    Dictionary used for "C/C++ セキュアコーディング 第2版" published in
    2014.

        https://www.jpcert.or.jp/securecoding_book_2nd.html

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::subst
    or
    $ curl -sL http://cpanmin.us | perl - App::Greple::subst

# SEE ALSO

[https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/kaz-utashiro/greple-subst](https://github.com/kaz-utashiro/greple-subst)

https://www.jtca.org/standardization/katakana\_guide\_3\_20171222.pdf

https://www.jtf.jp/jp/style\_guide/styleguide\_top.html,
https://www.jtf.jp/jp/style\_guide/pdf/jtf\_style\_guide.pdf

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright (C) 2017-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
