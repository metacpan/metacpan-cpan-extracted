package App::Gre;

use 5.006;
use strict;
use warnings;

our $VERSION = "0.12";

1;

__END__

=head1 NAME

App::Gre - A grep clone with better file filtering

=head1 SYNOPSIS

    gre [-help] [-man]
        [-A[<n>]] [-B[<n>]] [-C[<n>]] [-combos] [-d=<depth>]
        [-f=<file>] [-i] [-k] [-l] [-L] [-m] [-o] [-p=<str>]
        [-passthru] [-t] [-v] [-y<n>] [-X]
        [-[no]xbinary]
        [-[no][x][i][r][ext,abs]=<str>]
        [-[no][x][i][name,path,line1][e]=<str>]
        [-[perl,html,php,js,java,cc,...]]
        [<regexp>] [<file>...]

=head1 OPTIONS

    <regexp>           regular expression to match in files
    [<file>...]        list of files to include, if not provided will
                       be current directory.

    -h, -?, -help      help text
    -man               extra info about the script

    -A[<n>]            print n lines after the matching line, default 2
    -B[<n>]            print n lines before the matching line, default 2
    -C[<n>]            print n lines before and after the matching line, default 2
    -combos            displays builtin filter combos (-perl, -html, -php, -js)
    -d, -depth=<num>   max depth of file recursion (1 is no recursion)
    -f, -file=<file>   provide a filename, as if it was an arg on the command line
    -i, -ignorecase    case insensitive matches
    -k                 disable color
    -l                 print files that match
    -L                 print files that don't match
    -m, -multiline     multiline regexp matches
    -o, -only          only output the matching part of the line
    -p, -print=<str>   print customized parts of the match ($1, $&, etc. are available)
    -passthru          pass all lines through, but highlight matches
    -t                 print files that would be searched (ignore regexp)
    -v, -invert        select non-matching lines
    -y1                output style 1, grouped by file, and line number preceeding matches
    -y2                output style 2, classic grep style
    -y3                output style 3, no file/line info.
    -X                 disables builtin default excluding filters

    -[no]xbinary
                       filters out binary files, "no" allows binary
                       files if they were previously filtered out
    -[no][x][i]name[e]=<str>
                       include files by name, "no" filters them out,
                       "i" makes the regexp case insensitive, "e" makes
                       the match use string equality instead of regexp,
                       "x" makes it an excluding filter (excludes the
                       file when matched). with "x" it can apply to and
                       prune directories.
    -[no][x][i][e]=<str>
                       same as -[no][x][i]name[e]=<str>. Some combinations
                       won't work, such as -, and -i which have other meanings.
    -[no][x][i]path[e]=<str>
                       include files by full path name. "no", "x", "i", and
                       "e" options as described above.
    -[no][x][i][r]ext=<str>
                       include files by extension name. "no", "x", "i",
                       options as described above. by default this one
                       does string equality (actually, makes a custom
                       regexp so it can handle extensions like .tar.gz),
                       and regexp only if given the "r" option. the
                       regexp is only matched against the last component
                       of the file name after a ".", so it can't be
                       used to match ".tar.gz" files, use -name for
                       that, or the unadorned -ext option.
    -[no][x][i][r]abs=<str>
		       include files by their absolute path. "no",
		       "x", "i", "r" options as described above.
		       if you give a partial str (and "r" option
		       is not provided) the value will become the
		       absolute path.
    -[no][x][i]line1[e]=<str>
                       include files by the first line in the file.
                       "no", "x", "i", and "e" options as described above.
    -[no]{perl,html,php,js,java,cc,...}
                       builtin filter combo. for example -html is
                       equivalent to -ext=htm,html. use -combos to see
                       the full list. "no" option inverts the match.

=head1 DESCRIPTION

The main point behind this grep clone is that it can do better file
matching. For example if you want to search all files for the string
foo, except dot files (names starting with a "."), you could write
this:

    $ gre -no='^\.' foo

Only .c files:

    $ gre -ext=c yup

You can build up arbitrarily complex conditions to just search the
files you want:

    $ gre -X -ext=gz -noext=tar.gz

This would find all .gz files that aren't .tar.gz files. The -X is
necessary to disable the binary file filter.

=head1 FILE FILTERING

It's just as important to be able to filter files with regexes as
are the file contents. In fact, the default is to list files when
a regex is not given (or is the empty string).

The standard "includes" are done in order left to right. This:

    $ gre -perl -php

will list all perl and php files. This:

    $ gre -perl -noname=foo -php

will list all perl files, remove those whose name matches the regex
of foo, then add all php files. order counts. If you want all perl
and php files whose name doesn't match foo, you need this:

    $ gre -perl -php -noname=foo

The first option can either add files to nothing or remove files
from all. For example:

    $ gre -perl

will only show perl files.

    $ gre -noperl

will show all files except perl files.

There are two levels of filtering that run independent of each
other. The "includes" like -perl or -ext=c (.c extension) and the
"excludes" like -x=foo or -xbinary. why independent?  consider the
script added a default filter to remove all backup files (-x='~$')
and which will have to mix with command line filters.  The following
tries to search for bash files (files whose first line starts with
#!/bin/bash) that aren't backups:

    $ gre -x='~$' -line1='^#!/bin/bash'

It wouldn't work if they weren't independent: filters are additive,
so this would have added all files which are not backups then add
all files which are bash files (some of which may be backup files).

The reason the filters have to be additive is to let commands like
this work:

    $ gre -html -js

which will find all html and javascript files.

If I added the builtin filter after the command line arguments:

    $ gre -line1='^#!/bin/bash' -x='~$'

Then you wouldn't have a chance to disable it:

    $ gre -line1='^#!/bin/bash' -nox='~$' -x='~$'

It would still filter out the backup files.

So the "includes" and "excludes" need to be independent of each
other. The result should be intuitive. For example, if you want to
search everything except one file that's messing up the search add:

    $ gre -x=INBOX.mbox -ext=mbox qwerty

You don't have to worry about order either.

If you want to remove all the builtin excluding filters, use -X on
the command line. By default, gre will exclude backup files,
swap files, core dumps, .git directories, .svn directories, binary
files, minimized js files, and more. See the output from -combos
for the full list.

"exclude" filters also have another property which the regular
"include" filters don't have: They prune the recursive file search.
So -xe=.git will prevent any file under a .git directory from
being searched (the extra e at the end of -xe means to use
string equality not regexes for the match). Normal "inclusive"
filters do not execute on directories.

You can control the depth of the recursion with the -d option. -d1
disables recursion. -d0 is unlimited. -d2 will go 2 levels deep.

Files listed on the command line are always searched regardless of
the filters.

Symlinks are not followed. This is usually what you want and otherwise
you might end up in an infinite loop.

=head1 IDEAS

You can do multiline regexes '^sub.*^\}' (with the addition of the
-multiline option)

The script doesn't bundle options so it only uses one dash for the
long options. Many longer options have shorter equivalents, e.g.
-multiline is -m.

Options that take arguments can be given like -ext=foo or -ext foo.

=head1 OUTPUT STYLES

You can specify the output style with the -y option:

-y1 groups output by filename, with each matching line prepended
with it's line number. This is the default.

-y2 looks like classic grep output. Each line looks like file:line:match.

-y3 just has the matching line. This is the default for piped input.
goes well with the -p option sometimes.

-k will disable color output.

-o will show only the match (as opposed to the entire matching line).

-p=<str> can be used to display the output in your own way. For
example,

    $ gre '(foo)(bar)' -p='<<$2-$1>>'

-A -B -C -AE<lt>nE<gt> -BE<lt>nE<gt> -CE<lt>nE<gt> will show some
lines of context around the match. -B for before, -A after, -C both.
All of these can take an optional number parameter. If missing it
will be 2.

=head1 RC FILE

You can place default options into ~/.grerc file. the format is a
list of whitespace separated options that will be applied to every
call to gre right after the built-in filters but before command
line filters. For example:

    -xpath=template_compiles
    -xpath=templates/cache
    -xe=yui

=head1 INSTALLATION

gre is a single script with no dependencies. copy it to a place in your
$PATH and it should work as-is. The App::Gre module is just an unused
placeholder module to make it work with CPAN.

You can also run "cpan App::Gre".

=head1 SEE ALSO

grep(1) L<http://www.gnu.org/savannah-checkouts/gnu/grep/manual/grep.html>

ack(1) L<http://beyondgrep.com/>

=head1 METACPAN

L<https://metacpan.org/pod/App::Gre>

=head1 REPOSITORY

L<https://github.com/zorgnax/gre>

=head1 AUTHOR

Jacob Gelbman, E<lt>gelbman@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Jacob Gelbman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
