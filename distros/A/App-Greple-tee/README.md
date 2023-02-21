[![Actions Status](https://github.com/kaz-utashiro/App-Greple-tee/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/App-Greple-tee/actions)
# NAME

App::Greple::tee - module to replace matched text by the external command result

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple's **-Mtee** module sends matched text part to the specified
command, and replace them by the command result.

External command is specified as following arguments after the module
option ending with `--`.  For example, next command call command
`tr` command with `a-z A-Z` arguments for the matched word in the
data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Above command effectively convert all matched words from lower-case to
upper-case.  Actually this example is not useful because **greple** can
do the same thing more effectively with **--cm** option.

By default, the command is executed only once and all data is sent to
the same command.  Data are mapped line by line, so the number of
lines of input and output data must be identical.

Using **--discrete** option, individual command is called for each
matched part.  You can notice the difference by following commands.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

In this case, lines of input and output data can be differ.

# OPTIONS

- **--discrete**

    Invoke new command for every matched part.

# EXAMPLE

First of all, use the **teip** command for anything that can be done
with it.

Next command will find some indented part in LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

You can reformat this part by using **tee** module with **ansifold**
command:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.
    

# SEE ALSO

- [https://github.com/greymd/teip](https://github.com/greymd/teip)

    This module is inspired by the command named **teip**.  Unlike **teip**
    command, this module does not have a performace advantage.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
