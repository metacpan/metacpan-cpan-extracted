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
    -l      Display I18N options (See below)

    --theme theme
            Apply color theme

Color options:

    --colormap  Specify colormap
    --rgb24     Use 24bit RGB color ANSI sequence

I18N options:

    -l          Display I18N options
    --i18n      Enable I18n options
    --i18n-v    Display with Territory/Lange information

Color modules:

    -Mcolors
    -Mteams
    -Molympic

# VERSION

Version 0.13

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

Greater number is handled as year.  Next command displays the calendar of
the year 1752.

    $ week 1752

Use option **-y** to show one year calendar.  The number of years can be
specified by the **-Y** option, which will implicitly set the **-y** option.

    $ week -y          # display this year's calendar

    $ week -Y2c6       # display 2 years calendar in 6 column

    $ week -Y 1752     # display 1752 years of calendar (takes long)

It is possible display calendar in various language by setting `LANG`
environment.

    LANG=et_EE week

This command is come with **-Mi18n** module which provides easy way to
specify language by command option.  Option **-l** displays option list
provided by **-Mi18n** module and option **--i18n** and **--i18n-v**
enables them.

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

Besides above, color for day-of-week names can be specified
individually by following labels.  No color is assigned to these
labels by default.

    DOW_SU
    DOW_MO
    DOW_TU
    DOW_WE
    DOW_TH
    DOW_FR
    DOW_SA

Three digit means 216 RGB values from 000 to 555, and Lxx means 24
gray scales.  Colormap is handled by [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt::EX::Colormap) module;
use \`perldoc Getopt::EX::Colormap\` for detail.

You can add special effect afterward.  For example, put next line in
your `~/.weekrc` to blink today.  `$<move>` indicates to move
all following arguments here, so that insert this option at the end.

    option default $<move> --cm 'THISDAY=+F'

# I18N

- **--i18n**
- **--i18n-v**

    Both of these enables I18N options and Territory/Language information
    will be shown if used **--i18n-v**.

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

        --tigers, --tigers-rev
        --giants, --giants-rev
        --lions, --lions-rev

- **-Molympic**

        --tokyo2020, --tokyo2020-rev

- **--theme**

    Option **--theme** is defined in default module, and choose given theme
    option according to the background color of the terminal. If you have
    next setting in your `~/.weekrc`:

        option --theme tokyo2020

    Option **--tokyo2020** is set for light terminal, and
    **--tokyo2020-rev** is set for dark terminal.

Feel free to update these modules and send pull request to github
site.

# FILES

- `~/.weekrc`

    Start up file.  Use like this:

        option default --i18n-v --theme tokyo2020

# SEE ALSO

[https://github.com/kaz-utashiro/App-week](https://github.com/kaz-utashiro/App-week)

[https://github.com/kaz-utashiro/Getopt-EX-termcolor](https://github.com/kaz-utashiro/Getopt-EX-termcolor)

[https://github.com/kaz-utashiro/Getopt-EX-i18n](https://github.com/kaz-utashiro/Getopt-EX-i18n)

[Getopt::EX::Colormap](https://metacpan.org/pod/Getopt::EX::Colormap)

[https://qiita.com/kaz-utashiro/items/603f4bca39e397afc91c](https://qiita.com/kaz-utashiro/items/603f4bca39e397afc91c)

[https://qiita.com/kaz-utashiro/items/38cb50a4d0cd34b6cce6](https://qiita.com/kaz-utashiro/items/38cb50a4d0cd34b6cce6)

[https://qiita.com/kaz-utashiro/items/be37a4d703f9d2208ed1](https://qiita.com/kaz-utashiro/items/be37a4d703f9d2208ed1)

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
