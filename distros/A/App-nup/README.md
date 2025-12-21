[![Actions Status](https://github.com/tecolicom/App-nup/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tecolicom/App-nup/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-nup.svg)](https://metacpan.org/release/App-nup)
# NAME

nup - N-up output wrapper for optex -Mup

# SYNOPSIS

    nup [ options ] file ...
    nup -e [ options ] command ...

    -h,   --help             show help
          --version          show version
    -d,   --debug            debug mode
    -n,   --dryrun           dry-run mode
    -e,   --exec             execute command mode
    -V,   --parallel         parallel view mode
    -F,   --fold             fold mode (disable page mode)
    -H,   --header           show file headers (default: on)
    -G,   --grid=#           grid layout (e.g., 2x3)
    -C,   --pane=#           number of columns
    -R,   --row=#            number of rows
          --height=#         page height in lines
    -S,   --pane-width=#     pane width (default: 85)
    --bs, --border-style=#   border style (default: heavy-box)
    --ls, --line-style=#     line style (none/truncate/wrap/wordwrap)
          --pager=#          pager command (empty to disable)
          --no-pager         disable pager

# VERSION

Version 0.01

# DESCRIPTION

**nup** is a simple wrapper script for `optex -Mup`.  It provides a
convenient way to view files or run commands with N-up output
formatting using the [App::optex::up](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Aup) module.

**nup** automatically detects the mode based on the first argument:
if it is an existing file, file view mode is used; if it is an
executable command, command mode is used.  Use `-e` option to
force command mode when needed.

# OPTIONS

## General Options

- **-h**, **--help**

    Show help message.

- **--version**

    Show version.

- **-d**, **--debug**

    Enable debug mode.

- **-n**, **--dryrun**

    Dry-run mode. Show the command without executing.

- **-e**, **--exec**

    Force command execution mode. Normally the mode is auto-detected,
    but use this option when you want to execute a file as a command.

- **-V**, **--parallel**

    Enable parallel view mode for ansicolumn.  In this mode, each file
    is displayed in its own column without pagination, similar to
    `--fold`.  Automatically enabled when multiple files are
    specified.  Single file or stdin input results in single column
    output.

- **-F**, **--fold**

    Enable fold mode (disable page mode).  In fold mode, the entire
    content is split evenly across columns without pagination.  Page
    mode is the default.

- **-H**, **--header**

    Show filename headers in file view mode. Enabled by default.
    Use `--no-header` to disable.

## Layout Options

- **-G** _CxR_, **--grid**=_CxR_

    Set grid layout. For example, `-G2x3` creates 2 columns and 3 rows.

- **-C** _N_, **--pane**=_N_

    Set the number of columns (panes).

- **-R** _N_, **--row**=_N_

    Set the number of rows.

- **--height**=_N_

    Set the page height in lines.

- **-S** _N_, **--pane-width**=_N_

    Set the pane width in characters. Default is 85.

## Style Options

- **--border-style**=_STYLE_, **--bs**=_STYLE_

    Set the border style. Default is `heavy-box`.

- **--line-style**=_STYLE_, **--ls**=_STYLE_

    Set the line style. Available: `none`, `truncate`, `wrap`, `wordwrap`.

## Pager Options

- **--pager**=_COMMAND_

    Set the pager command. Default is `$PAGER` or `less`.
    Use `--pager=` (empty) or `--no-pager` to disable pager.

- **--no-pager**

    Disable pager.

# EXAMPLES

    nup man nup                # view manual in multi-column
    nup -C2 man perl           # 2 columns
    nup -G2x2 man perl         # 2x2 grid (4-up)
    nup -F man perl            # fold mode (no pagination)
    nup file1.txt file2.txt    # view files side by side
    nup -e ./script.sh         # force command mode for a file

# INSTALLATION

Using [cpanminus](https://metacpan.org/pod/App::cpanminus):

    cpanm -n App::nup

# SEE ALSO

[App::optex::up](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Aup), [optex](https://metacpan.org/pod/optex)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2025 Kazumasa Utashiro.

This software is released under the MIT License.
[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)
