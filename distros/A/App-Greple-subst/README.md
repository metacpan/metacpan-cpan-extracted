# NAME

subst - Greple module for text search and substitution

# VERSION

Version 2.07

# SYNOPSIS

greple -Msubst --dict _dictionary_ \[ options \]

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

## Overlapped pattern

When the matched string is same or shorter than previously matched
string by another pattern, it is simply ignored (**--no-warn-include**
by default).  So, if you have to declare conflicted patterns, put the
longer pattern in front.

If the matched string overlaps with previously matched string, it is
warned (**--warn-overlap** by default) and ignored.

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

    greple -Msubst --exdict katakana-guide-3.dict

- **--exdict** _dictionary_
- **--exdictdir**

    Use _dictionary_ flie in the distribution as a dictionary file.

- **--jtca-katakana-guide**

    Shortcut for "**--exdict** [jtca-katakana-guide-3.dict](https://metacpan.org/pod/jtca-katakana-guide-3.dict)".

    Created from following guideline document.

        外来語（カタカナ）表記ガイドライン 第3版
        制定：2015年8月
        発行：2015年9月
        一般財団法人テクニカルコミュニケーター協会 
        Japan Technical Communicators Association
        https://www.jtca.org/standardization/katakana_guide_3_20171222.pdf

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::subst
    or
    $ curl -sL http://cpanmin.us | perl - App::Greple::subst

# LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/kaz-utashiro/greple-subst](https://github.com/kaz-utashiro/greple-subst)

# AUTHOR

Kazumasa Utashiro
