# NAME

optex - General purpose command option wrapper

# SYNOPSIS

**optex** _command_ \[ **-M**_module_ \] ...

or _command_ -> **optex** symlink, or

**optex** _options_ \[ -l | -m \] ...

    --link,   --ln  create symlink
    --unlink, --rm  remove symlink
    --ls            list link files
    --rc            list rc files
    --nop, -x       disable option processing
    --[no]module    disable module option on arguments

# DESCRIPTION

**optex** is a general purpose option handling wrapper utilizing Perl
module [Getopt::EX](https://metacpan.org/pod/Getopt::EX).  It enables user to define their own option
aliases for any commands on the system, and provide module style
extendible capability.

Target command is given as an argument:

    % optex command

or symbolic link file linked to **optex**:

    command -> optex

If the configuration file `~/.optex.d/`_command_`.rc` exists, it is
read before execution and command arguments are pre-processed using
that configuration.

## OPTION ALIASES

Think of macOS's `date` command, which does not have `-I[TIMESPEC]`
option.  Using **optex**, these can be implemented by preparing
following setting in `~/.optex.d/date.rc` file.

    option -I        -Idate
    option -Idate    +%F
    option -Iseconds +%FT%T%z
    option -Iminutes +%FT%H:%M%z
    option -Ihours   +%FT%H%z

    option --iso-8601         -I
    option --iso-8601=date    -Idate
    option --iso-8601=seconds -Iseconds
    option --iso-8601=minutes -Iminutes
    option --iso-8601=hours   -Ihours

Then next command will work as expected.

    % optex date -Iseconds

If a symbolic link `date -> optex` is found in command search
path, you can use it just same as standard command, but with
unsupported options.

    % date -Iseconds

Common configuration is stored in `~/.optex.d/default.rc` file, and
those rules are applied to all commands executed through **optex**.

Actually, `--iso-8601` option can be defined simpler as this:

    option --iso-8601 -I$<shift>

This works fine almost always, but fails with sole `--iso-8601`
option preceding other option like this:

    % date --iso-8601 -u

## COMMAND ALIASES

Command aliases can be set in the configuration file like this:

    [alias]
        pgrep = [ "greple", "-Mperl", "--code" ]

Read CONFIGURATION FILE section.

## MACROS

Complex string can be composed using macro `define`.  Next example is
an awk script to count vowels in the text, to be declared in file
`~/.optex.d/awk.rc`.

    define __delete__ /[bcdfgkmnpsrtvwyz]e( |$)/
    define __match__  /ey|y[aeiou]*|[aeiou]+/
    define __count_vowels__ <<EOS
    {
        s = tolower($0);
        gsub(__delete__, " ", s);
        for (count=0; match(s, __match__); count++) {
            s=substr(s, RSTART + RLENGTH);
        }
        print count " " $0;
    }
    EOS
    option --vowels __count_vowels__

This can be used like this:

    % awk --vowels /usr/share/dict/words

When setting complex option, `expand` directive is useful.  `expand`
works almost same as `option`, but effective only within the file
scope, and not available for command line option.

    expand repository   ( -name .git -o -name .svn -o -name RCS )
    expand no_dots      ! -name .*
    expand no_version   ! -name *,v
    expand no_backup    ! -name *~
    expand no_image     ! -iname *.jpg  ! -iname *.jpeg \
                        ! -iname *.gif  ! -iname *.png
    expand no_archive   ! -iname *.tar  ! -iname *.tbz  ! -iname *.tgz
    expand no_pdf       ! -iname *.pdf

    option --clean \
            repository -prune -o \
            -type f \
            no_dots \
            no_version no_backup \
            no_image \
            no_archive \
            no_pdf

    % find . --clean -print

## MODULES

**optex** also supports module extension.  In the example of `date`,
module file is found at `~/.optex.d/date/` directory.  If default
module, `~/.optex.d/date/default.pm` exists, it is loaded
automatically on every execution.

This is a normal Perl module, so package declaration and the final
true value is necessary.  Between them, you can put any kind of Perl
code.  For example, next program set environment variable `LANG` to
`C` before executing `date` command.

    package default;
    $ENV{LANG} = 'C';
    1;

    % /bin/date
    2017年 10月22日 日曜日 18時00分00秒 JST

    % date
    Sun Oct 22 18:00:00 JST 2017

Other modules are loaded using `-M` option.  Unlike other options,
`-M` have to be placed at the beginning of argument list.  Module
files in `~/.optex.d/date/` directory are used only for `date`
command.  If the module is placed on `~/.optex.d/` directory, it can
be used from all commands.

If you want use `-Mes` module, make a file `~/.optex.d/es.pm` with
following content.

    package es;
    $ENV{LANG} = 'es_ES';
    1;

    % date -Mes
    domingo, 22 de octubre de 2017, 18:00:00 JST

When the specified module was not found in library path, **optex**
ignores the option and stops argument processing immediately.  Ignored
options are passed through to the target command.

Module is also used with subroutine call.  Suppose
`~/.optex.d/env.pm` module look like:

    package env;
    sub setenv {
        while (($a, $b) = splice @_, 0, 2) {
            $ENV{$a} = $b;
        }
    }
    1;

Then it can be used in more generic fashion.  In the next example,
first format is easy to read, but second one is more easy to type
because it does not have special characters to be escaped.

    % date -Menv::setenv(LANG=de_DE) # need shell quote
    % date -Menv::setenv=LANG=de_DE  # alternative format
    So 22 Okt 2017 18:00:00 JST

Option aliases can be also declared in the module, at the end of file,
following special literal `__DATA__`.  Using this, you can prepare
multiple set of options for different purposes.  Think about generic
**i18n** module:

    package i18n;
    1;
    __DATA__
    option --cn -Menv::setenv(LANG=zh_CN) // 中国語 - 簡体字
    option --tw -Menv::setenv(LANG=zh_TW) // 中国語 - 繁体字
    option --us -Menv::setenv(LANG=en_US) // 英語
    option --fr -Menv::setenv(LANG=fr_FR) // フランス語
    option --de -Menv::setenv(LANG=de_DE) // ドイツ語
    option --it -Menv::setenv(LANG=it_IT) // イタリア語
    option --jp -Menv::setenv(LANG=ja_JP) // 日本語
    option --kr -Menv::setenv(LANG=ko_KR) // 韓国語
    option --br -Menv::setenv(LANG=pt_BR) // ポルトガル語 - ブラジル
    option --es -Menv::setenv(LANG=es_ES) // スペイン語
    option --ru -Menv::setenv(LANG=ru_RU) // ロシア語

This can be used like:

    % date -Mi18n --tw
    2017年10月22日 週日 18時00分00秒 JST

You can declare autoload module in your `~/.optex.d/optex.rc` like:

    autoload -Mi18n --cn --tw --us --fr --de --it --jp --kr --br --es --ru

Then you can use them without module option.  In this case, option
`--ru` is replaced by `-Mi18n --ru` automatically.

    % date --ru
    воскресенье, 22 октября 2017 г. 18:00:00 (JST)

# STANDARD MODULES

Standard modules are installed at `App::optex`, and they can be
addressed with and without `App::optex` prefix.

- -M**help**

    Print available option list.  Option name is printed with substitution
    form, or help message if defined.  Use **-x** option to omit help
    message.

    Option **--man** or **-h** will print document if available.  Option
    **-l** will print module path.  Option **-m** will show the module
    itself.  When used after other modules, print information about the
    last declared module.  Next command show the document about **second**
    module.

        optex -Mfirst -Msecond -Mhelp --man

- -M**debug**

    Print debug messages.

# OPTIONS

These options are not effective when **optex** was executed from
symbolic link.

- **--link**, **--ln** \[ _command_ \]

    Create symbolic link in `~/.optex.d/bin` directory.

- **--unlink**, **--rm** \[ **-f** \] \[ _command_ \]

    Remove symbolic link in `~/.optex.d/bin` directory.

- **--ls** \[ **-l** \] \[ _command_ \]

    List symbolic link files in `~/.optex.d/bin` directory.

- **--rc** \[ **-l** \] \[ **-m** \] \[ _command_ \]

    List rc files in `~/.optex.d` directory.

- **--nop**, **-x** _command_

    Stop option manipulation.  Use full pathname otherwise.

- **--**\[**no**\]**module**

    **optex** deals with module option (-M) on target command by default.
    However, there is a command which also uses same option for own
    purpose.  Option **--nomodule** disables that behavior.  Other option
    interpretation is still effective, and there is no problem using
    module option in rc or module files.

# CONFIGURATION FILE

When starting up, **optex** reads configuration file
`~/.optex.d/config.toml` which is supposed to be written in TOML
format.

## PARAMETERS

- **no-module**

    Set commands for which **optex** does not interpret module option
    **-M**.  If the target command is found in this list, it is executed as
    if option **--no-module** is given to **optex**.

        no-module = [
            "greple",
            "pgrep",
        ]

- **alias**

    Set command aliases.  Example:

        [alias]
            pgrep = [ "greple", "-Mperl", "--code" ]
            hello = "echo -n 'hello world!'"

    Command alias can be invoked either from symbolic link and command
    argument.

# FILES AND DIRECTORIES

- `PERLLIB/App/optex`

    System module directory.

- `~/.optex.d/`

    Personal root directory.

- `~/.optex.d/config.toml`

    Configuration file.

- `~/.optex.d/default.rc`

    Common startup file.

- `~/.optex.d/`_command_`.rc`

    Startup file for _command_.

- `~/.optex.d/`_command_`/`

    Module directory for _command_.

- `~/.optex.d/`_command_`/default.pm`

    Default module for _command_.

- `~/.optex.d/bin`

    Default directory to store symbolic links.

    This is not necessary, but it seems a good idea to make special
    directory to contain symbolic links for **optex**, placing it in your
    command search path.  Then you can easily add/remove it from the path,
    or create/remove symbolic links.

# ENVIRONMENT

- OPTEX\_ROOT

    Override default root directory `~/.optex.d`.

- OPTEX\_CONFIG

    Override default configuration file `OPTEX_ROOT/config.toml`.

- OPTEX\_MODULE\_PATH

    Set module paths separated by colon (`:`).  These are inserted before
    standard path.

- OPTEX\_BINDIR

    Override default symbolic link directory `OPTEX_ROOT/bin`.

# SEE ALSO

[Getopt::EX](https://metacpan.org/pod/Getopt::EX), [Getopt::EX::Loader](https://metacpan.org/pod/Getopt::EX::Loader), [Getopt::EX::Module](https://metacpan.org/pod/Getopt::EX::Module)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2017-2018 Kazumasa Utashiro
