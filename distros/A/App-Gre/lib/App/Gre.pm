package App::Gre;

use 5.006;
use strict;
use warnings;

our $VERSION = "0.15";

1;

__END__

=head1 NAME

App::Gre - A grep clone using Perl regexp's with better file filtering, defaults, speed, and presentation

=head1 FEATURES

=over

=item * Uses only Perl regexp's.

=item * Searches file names with regexp's as well as their contents,
recursively starting with current directory.

=item * Speed is accomplished by only searching files you want to
search (see "gre -c").

=item * Presentation is colorful and readable.

=back

=head1 SYNOPSIS

    gre [-h] [-c]
        [-A[<n>]] [-B[<n>]] [-C[<n>]] [-d<n>]
        [-f=<file>] [-i] [-k] [-l] [-L] [-m] [-o] [-p=<str>]
        [-r=<regexp>] [-R=<regexp>] [-t] [-u] [-v] [-y<n>] [-x]
        [-[no]xbinary]
        [-[no][x][i][r][ext]=<str>]
        [-[no][x][i][name,path,line1][e]=<str>]
        [-[perl,html,php,js,java,cc,...]]
        [<regexp>] [<file>...]

=head1 OPTIONS

    <regexp>           regular expression to match in files
    [<file>...]        list of files to include, if not provided will
                       be current directory.

    -A[<n>]            print n lines after the matching line, default 2
    -B[<n>]            print n lines before the matching line, default 2
    -C[<n>]            print n lines before and after the matching line, default 2
    -c                 displays builtin filter combos (-perl, -html, -php, -js)
    -d<n>              max depth of file recursion (1 is no recursion)
    -f=<file>          provide a filename, as if it was an arg on the command line
    -h, -?, -help      help text
    -i                 case insensitive matches
    -k                 disable color
    -l                 print files that match
    -L                 print files that don't match
    -m                 multiline regexp matches
    -o                 only output the matching part of the line
    -p=<str>           print customized parts of the match ($1, $&, etc. are available)
    -r=<regexp>        provide a regexp, as if it was an arg on the command line
    -R=<regexp>        like -r but line must not match regexp
    -t                 print files that would be searched (ignore regexp)
    -u                 passthrough all lines, but highlight matches
    -v                 select non-matching lines
    -x                 disables builtin default excluding filters
    -y1                output style 1, grouped by file, and line number preceeding matches
    -y2                output style 2, classic grep style
    -y3                output style 3, no file/line info
    -[no]xbinary       filters out binary files
    -[no][x][i]name[e]=<str>
                       include files by name*
    -[no][x][i]path[e]=<str>
                       include files by full path name*
    -[no][x][i][r]ext=<str>
                       include files by extension name*
    -[no][x][i]line1[e]=<str>
                       include files by the first line in the file*
    -[no]{perl,html,php,js,java,cc,...}
                       include files matching builtin filter combo*

=head1 DESCRIPTION


This grep clone is capable of filtering file names as well as file
contents with regexps.  For example if you want to search all files
whose name contains "bar" for the string "foo", you could write
this:

    $ gre -name=bar foo

Only .c files:

    $ gre -ext=c foo

You can build up arbitrarily complex conditions to just search the
files you want:

    $ gre -ext=html -noext=min.html foo

This would find all .html files that aren't .min.html files.

=head1 FILE FILTERING

It's just as important to be able to filter files with regexp's as
are the file contents. In fact, the default is to list files when
a regexp is not given (or is the empty string).

The standard "includes" are done in order left to right. This:

    $ gre -perl -php

will list all perl and php files. This:

    $ gre -perl -noname=foo -php

will list all perl files, remove those whose name matches the regexp
of foo, then add all php files. Order counts. Those php files might
have "foo" in their name. If you want all perl and php files whose
name doesn't match "foo", you need this:

    $ gre -perl -php -noname=foo

The first option can either add files to nothing or remove files
from all. For example:

    $ gre -perl

will only show perl files.

    $ gre -noperl

will show all files except perl files.

There are two levels of filtering that run independent of each
other. One level is the "includes" filters like -perl, -nophp, or
-ext=c.  The second level is the "excludes" filters like -xname=foo
or -xbinary.

Why are they independent?  Consider if the
script had a default filter to remove all backup files (-xname='~$')
which would have to mix with additional command line filters.  The following
would try to search for bash files (files whose first line starts with
#!/bin/bash) that aren't backups:

    $ gre -xname='~$' -line1='^#!/bin/bash'

It wouldn't work if they weren't independent: filters are additive,
so this would have added all files which are not backups then add
all files which are bash files (some of which may be backup files).

The reason the filters have to be additive is to let commands like
this work:

    $ gre -html -js

which will find all html and javascript files.

If I added the builtin filters after the command line arguments:

    $ gre -line1='^#!/bin/bash' -xname='~$'

Then you wouldn't have a chance to disable it:

    $ gre -line1='^#!/bin/bash' -noxname='~$' -xname='~$'

It would still filter out the backup files.

The result should be intuitive. For example, if you want to
search everything except one file that's messing up the search add:

    $ gre -xname=INBOX.mbox -ext=mbox qwerty

and you wouldn't have to worry about order of these filters.

If you want to remove all the builtin "exclude" filters, use -x on
the command line. By default, gre will exclude backup files, swap
files, core dumps, .git directories, .svn directories, binary files,
minimized js files, and more. See the output of -c for the full
list.

"exclude" filters also have another property which the regular
"include" filters don't have: They prune the recursive file search.
So -xnamee=.git will prevent any file under a .git directory from
being searched (the extra e at the end of -xname means to use
string equality not regexp's for the match). Normal "include"
filters do not execute on directories.

You can control the depth of the recursion with the -d option.  -d0
is for unlimited recursion (the default), -d1 disables recursion,
-d2 will only let recursion go two levels deep.

Files listed on the command line are always searched regardless of
the filters.

Symlinks are not followed. This is usually what you want and otherwise
you might end up in an infinite loop.

=head1 IDEAS

You can do multiline regexp's '^sub.*^\}' (with the addition of the
-m option)

The script doesn't bundle options so it only uses one dash for the
long options.

Options that take arguments can be given like -ext=foo or -ext foo.

Option names for file filters can include:

=over

=item * "no" filters files out,

=item * "i" makes the regexp case insensitive,

=item * "e" makes the match use string equality instead of regexp,

=item * "r" makes the match use regexp instead of string equality,

=item * "x" makes it an excluding filter

=back

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
    -xnamee=yui

=head1 INSTALLATION

gre is a single script with no dependencies. Copy it to a place in your
$PATH and it should work as-is. The App::Gre module is just an unused
placeholder module to make it work with CPAN.

You can also run "cpan App::Gre" to install it.

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
