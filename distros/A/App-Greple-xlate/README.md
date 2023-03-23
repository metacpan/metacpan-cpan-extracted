[![Actions Status](https://github.com/kaz-utashiro/App-Greple-xlate/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/App-Greple-xlate/actions)
# NAME

App::Greple::xlate - translation support module for greple

# SYNOPSIS

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.20

# DESCRIPTION

**Greple** **xlate** module find text blocks and replace them by the
translated text.  Currently only DeepL service is supported by the
**xlate::deepl** module.

If you want to translate normal text block in [pod](https://metacpan.org/pod/pod) style document,
use **greple** command with `xlate::deepl` and `perl` module like
this:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

Pattern `^(\w.*\n)+` means consecutive lines starting with
alpha-numeric letter.  This command show the area to be translated.
Option **--all** is used to produce entire text.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Then add `--xlate` option to translate the selected area.  It will
find and replace them by the **deepl** command output.

By default, original and translated text is printed in the "conflict
marker" format compatible with [git(1)](http://man.he.net/man1/git).  Using `ifdef` format, you
can get desired part by [unifdef(1)](http://man.he.net/man1/unifdef) command easily.  Format can be
specified by **--xlate-format** option.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

If you want to translate entire text, use **--match-all** option.
This is a short-cut to specify the pattern matches entire text
`(?s).+`.

# OPTIONS

- **--xlate**
- **--xlate-color**
- **--xlate-fold**
- **--xlate-fold-width**=_n_ (Default: 70)

    Invoke the translation process for each matched area.

    Without this option, **greple** behaves as a normal search command.  So
    you can check which part of the file will be subject of the
    translation before invoking actual work.

    Command result goes to standard out, so redirect to file if necessary,
    or consider to use [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate) module.

    Option **--xlate** calls **--xlate-color** option with **--color=never**
    option.

    With **--xlate-fold** option, converted text is folded by the specified
    width.  Default width is 70 and can be set by **--xlate-fold-width**
    option.  Four columns are reserved for run-in operation, so each line
    could hold 74 characters at most.

- **--xlate-engine**=_engine_

    Specify the translation engine to be used.  You don't have to use this
    option because module `xlate::deepl` declares it as
    `--xlate-engine=deepl`.

- **--xlate-labor**
- **--xlabor**

    Insted of calling translation engine, you are expected to work for.
    After preparing text to be translated, they are copied to the
    clipboard.  You are expected to paste them to the form, copy the
    result to the clipboard, and hit return.

- **--xlate-to** (Default: `EN-US`)

    Specify the target language.  You can get available languages by
    `deepl languages` command when using **DeepL** engine.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specify the output format for original and translated text.

    - **conflict**, **cm**

        Print original and translated text in [git(1)](http://man.he.net/man1/git) conflict marker format.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        You can recover the original file by next [sed(1)](http://man.he.net/man1/sed) command.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Print original and translated text in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef` format.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        You can retrieve only Japanese text by the **unifdef** command:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Print original and translated text separated by single blank line.

    - **xtxt**

        If the format is `xtxt` (translated text) or unkown, only translated
        text is printed.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Specify the maximum length of text to be sent to the API at once.
    Default value is set as for free account service: 128K for the API
    (**--xlate**) and 5000 for the clipboard interface (**--xlate-labor**).
    You may be able to change these value if you are using Pro service.

- **--**\[**no-**\]**xlate-progress** (Default: True)

    See the tranlsation result in real time in the STDERR output.

- **--match-all**

    Set the whole text of the file as a target area.

# CACHE OPTIONS

**xlate** module can store cached text of translation for each file and
read it before execution to eliminate the overhead of asking to
server.  With the default cache strategy `auto`, it maintains cache
data only when the cache file exists for target file.

- --cache-clear

    The **--cache-clear** option can be used to initiate cache management
    or to refresh all existing cache data. Once executed with this option,
    a new cache file will be created if one does not exist and then
    automatically maintained afterward.

- --xlate-cache=_strategy_
    - `auto` (Default)

        Maintain the cache file if it exists.

    - `create`

        Create empty cache file and exit.

    - `always`, `yes`, `1`

        Maintain cache anyway as far as the target is normal file.

    - `clear`

        Clear the cache data first.

    - `never`, `no`, `0`

        Never use cache file even if it exists.

    - `accumulate`

        By default behavior, unused data is removed from the cache file.  If
        you don't want to remove them and keep in the file, use `accumulate`.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Set your authentication key for DeepL service.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python library and CLI command.

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

    See the **greple** manual for the detail about target text pattern.
    Use **--inside**, **--outside**, **--include**, **--exclude** options to
    limit the matching area.

- [App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate)

    You can use `-Mupdate` module to modify files by the result of
    **greple** command.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    Use **sdif** to show conflict marker format side by side with **-V**
    option.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
