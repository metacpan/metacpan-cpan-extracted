[![Actions Status](https://github.com/kaz-utashiro/App-Greple-tee/workflows/test/badge.svg)](https://github.com/kaz-utashiro/App-Greple-tee/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-tee.svg)](https://metacpan.org/release/App-Greple-tee)
# NAME

App::Greple::tee - module to replace matched text by the external command result

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple's **-Mtee** module sends matched text part to the given filter
command, and replace them by the command result.  The idea is derived
from the command called **teip**.  It is like bypassing partial data to
the external filter command.

Filter command is specified as following arguments after the module
option ending with `--`.  For example, next command call command
`tr` command with `a-z A-Z` arguments for the matched word in the
data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Above command convert all matched words from lower-case to upper-case.
Actually this example is not useful because **greple** can do the same
thing more effectively with **--cm** option.

By default, the command is executed as a single process, and all
matched data is sent to it mixed together.  If the matched text does
not end with newline, it is added before and removed after.  Data are
mapped line by line, so the number of lines of input and output data
must be identical.

Using **--discrete** option, individual command is called for each
matched part.  You can notice the difference by following commands.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Lines of input and output data do not have to be identical when used
with **--discrete** option.

# OPTIONS

- **--discrete**

    Invoke new command for every matched part.

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

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

You can translate them by DeepL service by executing above command
with **-Mtee** module calling **deepl** command like this:

    greple -Mtee deepl text --to JA - -- --discrete ...

Because **deepl** works better for single line input, you can change
command part as this:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

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
command:

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

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
