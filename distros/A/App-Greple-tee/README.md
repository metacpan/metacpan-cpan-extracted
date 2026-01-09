[![Actions Status](https://github.com/kaz-utashiro/App-Greple-tee/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kaz-utashiro/App-Greple-tee/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-tee.svg)](https://metacpan.org/release/App-Greple-tee)
# NAME

App::Greple::tee - module to replace matched text by the external command result

# SYNOPSIS

    greple -Mtee command -- ...

# VERSION

Version 1.03

# DESCRIPTION

Greple's **-Mtee** module sends matched text part to the given filter
command, and replace them by the command result.  The idea is derived
from the command called **teip**.  It is like bypassing partial data to
the external filter command.

Filter command follows module declaration (`-Mtee`) and terminates by
two dashes (`--`).  For example, next command call command `tr`
command with `a-z A-Z` arguments for the matched word in the data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Above command convert all matched words from lower-case to upper-case.
Actually this example itself is not so useful because **greple** can do
the same thing more effectively with **--cm** option.

By default, the command is executed as a single process, and all
matched data is sent to the process mixed together.  If the matched
text does not end with newline, it is added before sending and removed
after receiving.  Input and output data are mapped line by line, so
the number of lines of input and output must be identical.

Using **--discrete** option, individual command is called for each
matched text area.  You can tell the difference by following commands.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Lines of input and output data do not have to be identical when used
with **--discrete** option.

# OPTIONS

- **--discrete**

    Invoke new command individually for every matched part.

- **--bulkmode**

    With the <--discrete> option, each command is executed on demand.  The
    <--bulkmode> option causes all conversions to be performed at once.

- **--crmode**

    This option replaces all newline characters in the middle of each
    block with carriage return characters.  Carriage returns contained in
    the result of executing the command are reverted back to the newline
    character. Thus, blocks consisting of multiple lines can be processed
    in batches without using the **--discrete** option.

    This works well with [ansifold](https://metacpan.org/pod/ansifold) command's **--crmode** option, which
    joins CR-separated text and outputs folded lines separated by CR.

- **--fillup**

    Combine a sequence of non-blank lines into a single line before
    passing them to the filter command.  Newline characters between wide
    width characters (Japanese, Chinese) are deleted, and other newline
    characters are replaced with spaces.  Korean (Hangul) is treated
    like ASCII text and joined with space.

- **--squeeze**

    Combines two or more consecutive newline characters into one.

- **-ML** **--offload** _command_

    [teip(1)](http://man.he.net/man1/teip)'s **--offload** option is implemented in the different
    module [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL) (**-ML**).

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    You can also use the **-ML** module to process only even-numbered lines
    as follows.

        greple -Mtee cat -n -- -ML 2::2

# CONFIGURATION

Module parameters can be set with **Getopt::EX::Config** module using
the following syntax:

    greple -Mtee::config(discrete) ...
    greple -Mtee::config(fillup,crmode) ...

This is useful when combined with shell aliases or module files.

Available parameters are: **discrete**, **bulkmode**, **crmode**,
**fillup**, **squeeze**, **blocks**.

# LEGACIES

The **--blocks** option is no longer needed now that the **--stretch**
(**-S**) option has been implemented in **greple**.  You can simply
perform the following.

    greple -Mtee cat -n -- --all -SE foo

It is not recommended to use **--blocks** as it may be deprecated in
the future.

- **--blocks**

    Normally, the area matching the specified search pattern is sent to
    the external command. If this option is specified, not the matched
    area but the entire block containing it will be processed.

    For example, to send lines containing the pattern `foo` to the
    external command, you need to specify the pattern which matches to
    entire line:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    But with the **--blocks** option, it can be done as simply as follows:

        greple -Mtee cat -n -- foo --blocks

    With **--blocks** option, this module behave more like [teip(1)](http://man.he.net/man1/teip)'s
    **-g** option.  Otherwise, the behavior is similar to [teip(1)](http://man.he.net/man1/teip) with
    the **-o** option.

    Do not use the **--blocks** with the **--all** option, since the block
    will be the entire data.

# WHY DO NOT USE TEIP

First of all, whenever you can do it with the **teip** command, use
it. It is an excellent tool and much faster than **greple**.

Because **greple** is designed to process document files, it has many
features that are appropriate for it, such as match area controls. It
might be worth using **greple** to take advantage of those features.

Also, **teip** cannot handle multiple lines of data as a single unit,
while **greple** can execute individual commands on a data chunk
consisting of multiple lines.

# EXAMPLE

Next command will find text blocks inside [perlpod(1)](http://man.he.net/man1/perlpod) style document
included in Perl module file.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

You can translate them by DeepL service by executing the above command
convined with **-Mtee** module which calls **deepl** command like this:

    greple -Mtee deepl text --to JA - -- --fillup ...

The dedicated module [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) is more effective
for this purpose, though.  In fact, the implementation hint of **tee**
module came from **xlate** module.

# EXAMPLE 2

Next command will find some indented part in LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

You can reformat this part by using **tee** module with **ansifold**
command.  Using both **--crmode** options together allows efficient
processing of multi-line blocks:

    greple -Mtee ansifold -sw40 --prefix '     ' --crmode -- --crmode --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

The **--discrete** option can also be used but will start multiple
processes, so it takes longer to execute.

# EXAMPLE 3

Consider a situation where you want to grep for strings from
non-header lines. For example, you may want to search for Docker image
names from the `docker image ls` command, but leave the header line.
You can do it by following command.

    greple -Mtee grep perl -- -ML 2: --discrete --all

Option `-ML 2:` retrieves the second to last lines and sends
them to the `grep perl` command.  The option --discrete is required
because the number of lines of input and output changes, but since the
command is only executed once, there is no performance drawback.

If you try to do the same thing with the **teip** command,
`teip -l 2- -- grep` will give an error because the number of output
lines is less than the number of input lines. However, there is no
problem with the result obtained.

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
