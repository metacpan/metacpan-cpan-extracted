[![Build Status](https://travis-ci.com/kaz-utashiro/App-week.svg?branch=master)](https://travis-ci.com/kaz-utashiro/App-week) [![MetaCPAN Release](https://badge.fury.io/pl/App-week.svg)](https://metacpan.org/release/App-week)
# NAME

week - colorful calendar command

# SYNOPSIS

**week** \[ -M_module_ \] \[ option \] \[ date \]

Options:

    -n      Display n months surronding today (default 3).
    -A n    Display n months after current month.
    -B n    Display n months before current month (default 1).
    -C[n]   Display n months before and after current month (default 4).
    -y      Display year calendar.
    -Y[n]   Display n years of calendar
    -c n    Display calendar in n column (default 3).

Color options:

    --colormap  Specify colormap
    --rgb24     Use 24bit RGB color ANSI sequence

Module options:

    --mono
    --lavender
    --green
    --pastel

# VERSION

Version 0.10

# DESCRIPTION

By default, **week** command display the previous, current and next
month surrounding today, just like **-3** option of **cal** command.

Number of month can be given with dash.

    $ week -12

Before and after months can be specified with **-B** and **-A** option,
and **-C** for both.

    $ week -B4 -A4
    $ week -C4

Date can given like:

    $ week 2019/9/23
    $ week 9/23        # 9/23 of current year
    $ week 23          # 23rd of current month

Greater number is handled as year.  Next command display calendar of
year 1752.

    $ week 1752

Use option **-y** to show one year calendar.  Number of years can be
specified by **-Y** option, and implicitly set **-y** option.

    $ week -y          # display this year's calendar

    $ week -Y2c6       # display 2 years calendar in 6 column

    $ week -Y 1752     # display 1752 years of calendar (takes long)

# COLORMAP

Each field is labled by names.

    FRAME       Enclosing frame
    MONTH       Month name
    WEEK        Day of the week
    DAYS        Calendar
    THISMONTH   Target month name
    THISWEEK    Target day of the week
    THISDAYS    Target calendar
    THISDAY     Target date

Color for each field can be specified by **--colormap** (**--cm**)
option with **LABEL**=_colorspec_ syntax.  Default color is:

    --colormap      DAYS=L05/335 \
    --colormap      WEEK=L05/445 \
    --colormap     FRAME=L05/445 \
    --colormap     MONTH=L05/335 \
    --colormap   THISDAY=522/113 \
    --colormap  THISDAYS=555/113 \
    --colormap  THISWEEK=L05/445 \
    --colormap THISMONTH=555/113

Three digit means 216 RGB values from 000 to 555, and Lxx means 24
gray scales.  Colormap is handled by [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt::EX::Colormap) module;
use \`perldoc Getopt::EX::Colormap\` for detail.

You can add special effect afterward.  For example, put next line in
your `~/.weekrc` to blink today.  `$<move>` indicates to move
all following arguments here, so that insert this option at the end.

    option default $<move> --cm 'THISDAY=+F'

# FILES

- `~/.weekrc`

    Start up file.

# MODULES

Currently two modules are included in the distribution.  These options
can be used without any special action, because they are defined to
load appropriate module automatically in default start up module
([App::week::default](https://metacpan.org/pod/App::week::default)).

- **-Mcolors**

        --mono
        --lavender
        --green
        --pastel

- **-Mteams**

        --team teamname

        --tigers, --tigers-rev
        --giants, --giants-rev
        --lions, --lions-rev

Feel free to update these modules and send pull request to github
site.

# SEE ALSO

[https://github.com/kaz-utashiro/App-week](https://github.com/kaz-utashiro/App-week)

[https://github.com/kaz-utashiro/Getopt-EX-termcolor](https://github.com/kaz-utashiro/Getopt-EX-termcolor)

[Getopt::EX::Colormap](https://metacpan.org/pod/Getopt::EX::Colormap)

[https://qiita.com/kaz-utashiro/items/603f4bca39e397afc91c](https://qiita.com/kaz-utashiro/items/603f4bca39e397afc91c)

# AUTHOR

Kazumasa Utashiro

# LICENSE

You can redistribute it and/or modify it under the same terms
as Perl itself.

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2018- Kazumasa Utashiro
