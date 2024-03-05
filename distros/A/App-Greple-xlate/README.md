[![Actions Status](https://github.com/kaz-utashiro/App-Greple-xlate/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/App-Greple-xlate/actions)
# NAME

App::Greple::xlate - translation support module for greple

# SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

# VERSION

Version 0.31

# DESCRIPTION

**Greple** **xlate** module find desired text blocks and replace them by
the translated text.  Currently DeepL (`deepl.pm`) and ChatGPT
(`gpt3.pm`) module are implemented as a back-end engine.
Experimental support for gpt-4 is also included.

If you want to translate normal text blocks in a document written in
the Perl's pod style, use **greple** command with `xlate::deepl` and
`perl` module like this:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

In this command, pattern string `^(\w.*\n)+` means consecutive lines
starting with alpha-numeric letter.  This command show the area to be
translated highlighted.  Option **--all** is used to produce entire
text.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
    </p>
</div>

Then add `--xlate` option to translate the selected area.  Then, it
will find the desired sections and replace them by the **deepl**
command output.

By default, original and translated text is printed in the "conflict
marker" format compatible with [git(1)](http://man.he.net/man1/git).  Using `ifdef` format, you
can get desired part by [unifdef(1)](http://man.he.net/man1/unifdef) command easily.  Output format
can be specified by **--xlate-format** option.

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
    </p>
</div>

If you want to translate entire text, use **--match-all** option.  This
is a short-cut to specify the pattern `(?s).+` which matches entire
text.

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

    Specifies the translation engine to be used. If you specify the engine
    module directly, such as `-Mxlate::deepl`, you do not need to use
    this option.

- **--xlate-labor**
- **--xlabor**

    Instead of calling translation engine, you are expected to work for.
    After preparing text to be translated, they are copied to the
    clipboard.  You are expected to paste them to the form, copy the
    result to the clipboard, and hit return.

- **--xlate-to** (Default: `EN-US`)

    Specify the target language.  You can get available languages by
    `deepl languages` command when using **DeepL** engine.

- **--xlate-format**=_format_ (Default: `conflict`)

    Specify the output format for original and translated text.

    - **conflict**, **cm**

        Original and converted text are printed in [git(1)](http://man.he.net/man1/git) conflict marker
        format.

            <<<<<<< ORIGINAL
            original text
            =======
            translated Japanese text
            >>>>>>> JA

        You can recover the original file by next [sed(1)](http://man.he.net/man1/sed) command.

            sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

    - **ifdef**

        Original and converted text are printed in [cpp(1)](http://man.he.net/man1/cpp) `#ifdef`
        format.

            #ifdef ORIGINAL
            original text
            #endif
            #ifdef JA
            translated Japanese text
            #endif

        You can retrieve only Japanese text by the **unifdef** command:

            unifdef -UORIGINAL -DJA foo.ja.pm

    - **space**

        Original and converted text are printed separated by single blank
        line.

    - **xtxt**

        If the format is `xtxt` (translated text) or unkown, only translated
        text is printed.

- **--xlate-maxlen**=_chars_ (Default: 0)

    Specify the maximum length of text to be sent to the API at once.
    Default value is set as for free DeepL account service: 128K for the
    API (**--xlate**) and 5000 for the clipboard interface
    (**--xlate-labor**).  You may be able to change these value if you are
    using Pro service.

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

# COMMAND LINE INTERFACE

You can easily use this module from the command line by using the
`xlate` command included in the distribution. See the `xlate` help
information for usage.

The `xlate` command works in concert with the Docker environment, so
even if you do not have anything installed on hand, you can use it as
long as Docker is available.  Use `-D` or `-C` option.

Also, since makefiles for various document styles are provided,
translation into other languages is possible without special
specification.  Use `-M` option.

You can also combine the Docker and make options so that you can run
make in a Docker environment.

Running like `xlate -GC` will launch a shell with the current working
git repository mounted.

Read Japanese article in ["SEE ALSO"](#see-also) section for detail.

    xlate [ options ] -t lang file [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -s   silent mode
        -e # translation engine (default "deepl")
        -p # pattern to determine translation area
        -w # wrap line by # width
        -o # output format (default "xtxt", or "cm", "ifdef")
        -f # from lang (ignored)
        -t # to lang (required, no default)
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   terminate option parsing
    Make options
        -M   run make
        -n   dry-run
    Docker options
        -G   mount git top-level directory
        -B   run in non-interactive (batch) mode
        -R   mount read-only
        -E * specify environment variable to be inherited
        -I * specify altanative docker image (default: tecolicom/xlate:version)
        -D * run xlate on the container with the rest parameters
        -C * run following command on the container, or run shell

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef)
        *.ENGINE  translation engine (deepl or gpt3)

# EMACS

Load the `xlate.el` file included in the repository to use `xlate`
command from Emacs editor.  `xlate-region` function translate the
given region.  Default language is `EN-US` and you can specify
language invoking it with prefix argument.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    Set your authentication key for DeepL service.

- OPENAI\_API\_KEY

    OpenAI authentication key.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::xlate

## TOOLS

You have to install command line tools for DeepL and ChatGPT.

[https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

[https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl)

[App::Greple::xlate::gpt3](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Agpt3)

[https://hub.docker.com/r/tecolicom/xlate](https://hub.docker.com/r/tecolicom/xlate)

- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

    DeepL Python library and CLI command.

- [https://github.com/openai/openai-python](https://github.com/openai/openai-python)

    OpenAI Python Library

- [https://github.com/tecolicom/App-gpty](https://github.com/tecolicom/App-gpty)

    OpenAI command line interface

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

## ARTICLES

- [https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250](https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250)

    Greple module to translate and replace only the necessary parts with DeepL API (in Japanese)

- [https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6](https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6)

    Generating documents in 15 languages with DeepL API module (in Japanese)

- [https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd](https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd)

    Automatic translation Docker environment with DeepL API (in Japanese)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
