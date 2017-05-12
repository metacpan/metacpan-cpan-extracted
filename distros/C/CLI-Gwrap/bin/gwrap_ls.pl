#!/usr/bin/perl

use strict;
use warnings;
use 5.008;

#===============================================================================
#
#      PODNAME:  gwrap_ls.pl
#     ABSTRACT:  ls wrapped in CLI::Gwrap.pm
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  07/09/2013 12:26:16 PM
#===============================================================================


use CLI::Gwrap qw(
    check
    radio
    string
    hash
    integer
    float
    incremental
);

our $VERSION = '0.030'; # VERSION

my $gwrap = CLI::Gwrap->new(
    command     => 'ls',
    description => 'list directory contents',
    columns     => 4,
    help        => '--help',
    persist     => 1,
    main_opt    => hash(
        [
            '',             # this option has no name
            'pattern(s)',   # alias (description)
        ],
        # 'hover' help
        qq[shell glob pattern(s) to match file or directory names],
    ),
    opts     => [
        check(
            'all',  # option name
            'do not ignore entries starting with .',
        ),

        check(
            [
                'C',        # option name
                'columns'], # either a long name or help for a short name

            'list entries by columns'
        ),

        check(
            [
                'd', 'directories',
            ],
            'list directory entries instead of contents, and do not dereference symbolic link',
        ),

        check(
            [
                'f', 'no sort',
            ],
            'do not sort, enable -aU, disable -ls --color',
        ),

        check(
            [
                'F', 'classify',
            ],
            'append indicator (one of */=>@|) to entries',
        ),

        check(
            'file-type',
            'like -F, except do not append \'*\''
        ),

        check(
            'group-directories-first',
            'group directories before files',
        ),

        check(
            [
                'h', 'human-readable',
            ],
            'with -l, print sizes in human readable format (e.g., 1K 234M 2G)',
        ),

        hash(
            'hide',
            'do not list implied entries matching shell PATTERN (overridden by -a or -A)',
        ),

        check(
            ['i', 'inode'],
            'print the index number of each file',
        ),

        check(
            ['k', 'kibibytes'],
            'use 1024-byte blocks',
        ),

        check(
            ['l', 'long listing'],
            'use a long listing format',
        ),

        check(
            ['L', 'dereference'],
            'when showing file information for a symbolic link, show information for the file the link references rather than for the link itself',
        ),

        check(
            [
                'n', 'numeric'
            ],
            'like -l, but list numeric user and group IDs',
        ),

        check(
            [
                'r', 'reverse'
            ],
            'reverse order while sorting',
        ),
        check(
            [
                'R', 'recursive'
            ],
            'list subdirectories recursively',
        ),
        check(
            ['s', 'print size'],
            'print the allocated size of each file, in blocks',
        ),

        check(
            [
                'S', 'sort by size',
            ],
            'sort by file size',
        ),

        radio(
            'sort',
            'sort by WORD instead of name: none -U, extension -X, size -S, time -t, version -v',
            choices => [ 'none', 'extension', 'size', 'time', 'version'],
        ),

        check(
            [
                't', 'sort by time'
            ],
            'sort by modification time, newest first',
        ),

        check(
            ['U', 'no sort'],
            'do not sort; list entries in directory order',
        ),

        check(
            ['1', 'one per line'],
            'list one file per line',
        ),

        check(
            'help',
            'display this help and exit',
        ),

        check(
            'version',
            'output version information and exit',
        ),
    ],

    advanced    => [
        check(
            'almost-all',
            'do not list implied . and ..',
        ),

        check(
            'author',
            'with -l, print the author of each file',
        ),

        check(
            ['b', 'escape'],
            'print C-style escapes for nongraphic characters',
        ),

        check(
            ['B', 'ignore-backups'],
            'do not list implied entries ending with ~',
        ),

        radio(
            'block-size',
            'scale sizes by SIZE before printing them. E.g., \'--block-size=M\' prints sizes in units of 1,048,576 bytes. SIZE is an integer and optional unit (example: 10M is 10*1024*1024). Units are K, M, G, T, P, E, Z, Y (powers of 1024) or KB, MB, ... (powers of 1000).',
            choices => ['KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
        ),

        check(
            ['c', 'ctime'],
            'with -lt: sort by, and show, ctime (time of last modification of file status information) with -l: show ctime and sort by name otherwise: sort by ctime, newest first',
        ),

        radio(
            'color',
            qq[colorize the output. Defaults to 'always' or can be 'never' or 'auto'],
            choices => [
                'never',    # the choices
                'always',
                'auto',
            ],
        ),

        check(
            ['D', 'dired'],
            'generate output designed for Emacs dired mode',
        ),

        radio(
            'format',
            'across -x, commas -m, horizontal -x, long -l, single-column -1, verbose -l, vertical -C',
            choices => ['across', 'commas', 'horizontal', 'long', 'single-column', 'verbose', 'vertical'],
        ),

        check(
            'full-time',
            'like -l --time-style=full-iso',
        ),

        check(
            ['g', 'no owner'],
            'like -l, but do not list owner',
        ),

        check(
            ['G', 'no-group'],
            'in a long listing, don\'t print group names',
        ),

        check(
            ['H', 'dereference-command-line'],
            'follow symbolic links listed on the command line',
        ),

        check(
            'dereference-command-line-symlink-to-dir',
            'follow each command line symbolic link that points to a directory',
        ),

        hash(
            ['I', 'ignore'],
            'do not list implied entries matching shell PATTERN',
        ),

        radio(
            'indicator-style',
            'append indicator with style WORD to entry names: none (default), slash (-p), file-type (--file-type), classify (-F)',
            choices => ['none', 'slash', 'file-type', 'classify'],
        ),

        check(
            ['m', 'fill width'],
            'fill width with a comma separated list of entries',
        ),

        check(
            ['N', 'literal'],
            'print raw entry names (don\'t treat e.g. control characters specially)',
        ),

        check(
            ['o', 'long, no group'],
            'like -l, but do not list group information',
        ),

        check(
            ['p', 'append / to dirs'],
            'append / indicator to directories',
        ),

        check(
            ['q', 'hide-control-chars'],
            'print ? instead of non graphic characters',
        ),

        check(
            ['Q', 'quote-name'],
            'enclose entry names in double quotes',
        ),

        radio(
            'quoting-style',
            'use quoting style for entry names: literal, locale, shell, shell-always, c, escape',
            choices => ['literal', 'locale', 'shell', 'shell-always', 'c', 'escape'],
        ),

        check(
            ['si', 'powers of 1000'],
            'like -h, but use powers of 1000 not 1024',
        ),

        check(
            ['show-control-chars'],
            'show non graphic characters as-is (default unless program is \'ls\' and output is a terminal)',
        ),

        radio(
            'time',
            'with -l, show time as WORD instead of modification time: atime -u, access -u, use -u, ctime -c, or status -c; use specified time as sort key if --sort=time',
            choices => ['atime', 'access', 'use', 'ctime', 'status'],
        ),

        string(
            'time-style',
            'with -l, show times using style: full-iso, long-iso, iso, locale, +FORMAT. FORMAT is interpreted like \'date\'; if FORMAT is FORMAT1<newline>FORMAT2, FORMAT1 applies to non-recent files and FORMAT2 to recent files; if STYLE is prefixed with \'posix-\', STYLE takes effect only outside the POSIX locale',
        ),

        integer(
            ['T', 'tabsize'],
            'assume tab stops at each COLS instead of 8',
        ),

        check(
            'u',
            'with -lt: sort by, and show, access time with -l: show access time and sort by name other‐wise: sort by access time',
        ),

        check(
            ['v', 'natural sort'],
            'natural sort of (version) numbers within text',
        ),

        integer(
            ['w', 'width'],
            'assume screen width instead of current value',
        ),

        check(
            ['x', 'by lines'],
            'list entries by lines instead of by columns',
        ),

        check(
            ['X', 'alphabetically by extension'],
            'sort alphabetically by entry extension',
        ),

        check(
            'lcontext',
            '(SELinux) Display security context. Enable -l. Lines will probably be too wide for most displays.',
        ),

        check(
            ['Z', 'context'],
            '(SELinux) Display security context so it fits on most displays. Displays only mode, user, group, security context and file name.',
        ),

        check(
            'scontext',
            '(SELinux) Display only security context and file name.',
        ),

    ],
)->run;

exit 0;




=pod

=head1 NAME

gwrap_ls.pl - ls wrapped in CLI::Gwrap.pm

=head1 VERSION

version 0.030

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__



LS(1)                                          User Commands                                          LS(1)



NAME
       ls - list directory contents

SYNOPSIS
       ls [OPTION]... [FILE]...

DESCRIPTION
       List information about the FILEs (the current directory by default).  Sort entries alphabetically if
       none of -cftuvSUX nor --sort is specified.

       Mandatory arguments to long options are mandatory for short options too.

       -a, --all
              do not ignore entries starting with .

       -A, --almost-all
              do not list implied . and ..

       --author
              with -l, print the author of each file

       -b, --escape
              print C-style escapes for nongraphic characters

       --block-size=SIZE
              scale sizes by SIZE before printing them.  E.g., '--block-size=M' prints sizes  in  units  of
              1,048,576 bytes.  See SIZE format below.

       -B, --ignore-backups
              do not list implied entries ending with ~

       -c     with  -lt:  sort  by,  and show, ctime (time of last modification of file status information)
              with -l: show ctime and sort by name otherwise: sort by ctime, newest first

       -C     list entries by columns

       --color[=WHEN]
              colorize the output.  WHEN defaults to 'always' or can be 'never' or 'auto'.  More info below

       -d, --directory
              list directory entries instead of contents, and do not dereference symbolic links

       -D, --dired
              generate output designed for Emacs' dired mode

       -f     do not sort, enable -aU, disable -ls --color

       -F, --classify
              append indicator (one of */=>@|) to entries

       --file-type
              likewise, except do not append '*'

       --format=WORD
              across -x, commas -m, horizontal -x, long -l, single-column -1, verbose -l, vertical -C

       --full-time
              like -l --time-style=full-iso

       -g     like -l, but do not list owner

       --group-directories-first
              group directories before files.

              augment with a --sort option, but any use of --sort=none (-U) disables grouping

       -G, --no-group
              in a long listing, don't print group names

       -h, --human-readable
              with -l, print sizes in human readable format (e.g., 1K 234M 2G)

       --si   likewise, but use powers of 1000 not 1024

       -H, --dereference-command-line
              follow symbolic links listed on the command line

       --dereference-command-line-symlink-to-dir
              follow each command line symbolic link that points to a directory

       --hide=PATTERN
              do not list implied entries matching shell PATTERN (overridden by -a or -A)

       --indicator-style=WORD
              append indicator with style WORD to  entry  names:  none  (default),  slash  (-p),  file-type
              (--file-type), classify (-F)

       -i, --inode
              print the index number of each file

       -I, --ignore=PATTERN
              do not list implied entries matching shell PATTERN

       -k, --kibibytes
              use 1024-byte blocks

       -l     use a long listing format

       -L, --dereference
              when  showing  file  information  for a symbolic link, show information for the file the link
              references rather than for the link itself

       -m     fill width with a comma separated list of entries

       -n, --numeric-uid-gid
              like -l, but list numeric user and group IDs

       -N, --literal
              print raw entry names (don't treat e.g. control characters specially)

       -o     like -l, but do not list group information

       -p, --indicator-style=slash
              append / indicator to directories

       -q, --hide-control-chars
              print ? instead of non graphic characters

       --show-control-chars
              show non graphic characters as-is (default unless program is 'ls' and output is a terminal)

       -Q, --quote-name
              enclose entry names in double quotes

       --quoting-style=WORD
              use quoting style WORD for entry names: literal, locale, shell, shell-always, c, escape

       -r, --reverse
              reverse order while sorting

       -R, --recursive
              list subdirectories recursively

       -s, --size
              print the allocated size of each file, in blocks

       -S     sort by file size

       --sort=WORD
              sort by WORD instead of name: none -U, extension -X, size -S, time -t, version -v

       --time=WORD
              with -l, show time as WORD instead of modification time: atime -u, access -u, use  -u,  ctime
              -c, or status -c; use specified time as sort key if --sort=time

       --time-style=STYLE
              with  -l,  show times using style STYLE: full-iso, long-iso, iso, locale, +FORMAT.  FORMAT is
              interpreted like 'date'; if FORMAT is FORMAT1<newline>FORMAT2, FORMAT1 applies to  non-recent
              files  and  FORMAT2  to  recent files; if STYLE is prefixed with 'posix-', STYLE takes effect
              only outside the POSIX locale

       -t     sort by modification time, newest first

       -T, --tabsize=COLS
              assume tab stops at each COLS instead of 8

       -u     with -lt: sort by, and show, access time with -l: show access time and sort  by  name  other‐
              wise: sort by access time

       -U     do not sort; list entries in directory order

       -v     natural sort of (version) numbers within text

       -w, --width=COLS
              assume screen width instead of current value

       -x     list entries by lines instead of by columns

       -X     sort alphabetically by entry extension

       -1     list one file per line

       SELinux options:

       --lcontext
              Display security context.   Enable -l. Lines will probably be too wide for most displays.

       -Z, --context
              Display security context so it fits on most displays.  Displays only mode, user, group, secu‐
              rity context and file name.

       --scontext
              Display only security context and file name.

       --help display this help and exit

       --version
              output version information and exit

       SIZE is an integer and optional unit (example: 10M is 10*1024*1024).  Units are K, M, G, T, P, E, Z,
       Y (powers of 1024) or KB, MB, ... (powers of 1000).

       Using  color  to  distinguish  file  types is disabled both by default and with --color=never.  With
       --color=auto, ls emits color codes only when standard  output  is  connected  to  a  terminal.   The
       LS_COLORS environment variable can change the settings.  Use the dircolors command to set it.

   Exit status:
       0      if OK,

       1      if minor problems (e.g., cannot access subdirectory),

       2      if serious trouble (e.g., cannot access command-line argument).

AUTHOR
       Written by Richard M. Stallman and David MacKenzie.

REPORTING BUGS
       Report ls bugs to bug-coreutils@gnu.org
       GNU coreutils home page: <http://www.gnu.org/software/coreutils/>
       General help using GNU software: <http://www.gnu.org/gethelp/>
       Report ls translation bugs to <http://translationproject.org/team/>

COPYRIGHT
       Copyright  ©  2012  Free  Software  Foundation,  Inc.   License  GPLv3+:  GNU GPL version 3 or later
       <http://gnu.org/licenses/gpl.html>.
       This is free software: you are free to change and redistribute it.  There is  NO  WARRANTY,  to  the
       extent permitted by law.

SEE ALSO
       The  full  documentation  for ls is maintained as a Texinfo manual.  If the info and ls programs are
       properly installed at your site, the command

              info coreutils 'ls invocation'

       should give you access to the complete manual.



GNU coreutils 8.17                              January 2013                                          LS(1)
