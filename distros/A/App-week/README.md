[![Actions Status](https://github.com/kaz-utashiro/App-week/workflows/test/badge.svg)](https://github.com/kaz-utashiro/App-week/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-week.svg)](https://metacpan.org/release/App-week)
# NAME

week - colorful calendar command for ANSI terminal

# SYNOPSIS

**week** \[ -M_module_ \] \[ option \] \[ date \]

Options:

    -#,-m#  # months surrounding today (default 3)
    -A #    after current month
    -B #    before current month
    -C[#]   before and after current month (default 4)
    -y      year calendar
    -Y[#]   # years of calendar
    -c #    number of columns (default 3)
    -p #    print year on month-# (default current, 0 for none)
    -P      print year on all months
    -W      print week number

    --theme theme
            apply color theme

Color options:

    --colormap  specify colormap
    --rgb24     use 24bit RGB color ANSI sequence

i18n options:

    -l          list i18n options
    --i18n      enable i18n options
    --i18n-v    display with Territory/Lange information

Color modules:

    -Mcolors
    -Mnpb
    -Molympic

# VERSION

Version 1.0303

# DESCRIPTION

By default, **week** command display the previous, current and next
month surrounding today, just like **-3** option of [cal(1)](http://man.he.net/man1/cal) command.

Number of month can be given with dash, or **-m** option which can be
mixed up with other parameters.  **-c** option specifies number of
columns.

    $ week -12
    $ week -m21c7

Before and after months can be specified with **-B** and **-A** option,
and **-C** for both.

    $ week -B4 -A4
    $ week -C4

Date can given like:

    $ week 2019/9/23
    $ week 9/23        # 9/23 of current year
    $ week 23          # 23rd of current month

And also in Japanese format and era:

    $ week 2019年9月23日
    $ week 平成31年9月23日
    $ week H31.9.23
    $ week 平成31
    $ week 平31
    $ week H31

Greater number is handled as a year.  Next command displays the
calendar of the year 1752.

    $ week 1752

Use option **-y** to show one year calendar.  The number of years can
be specified by the **-Y** option (must <= 100), which will implicitly
set the **-y** option.

    $ week -y          # display this year's calendar

    $ week -Y2c6       # display 2 years calendar in 6 column

# INTERNATIONAL SUPPORT

It is possible display calendar in various language by setting `LANG`
environment.

    LANG=et_EE week

This command come with **-Mi18n** module which provides easy way to
specify language by command option.  Option **-l** displays option list
provided by **-Mi18n** module and option **--i18n** and **--i18n-v**
enables them.  See [Getopt::EX::i18n](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Ai18n).

    $ week --i18n-v --et

# JAPANESE ERA

By default, chronological year is shown on current month and every
January.  When used in Japanese locale environment, right side year is
displayed in Japanese era (wareki: 和暦) format.

# WEEK NUMBER

Using option **-W** or **--weeknumber**, week number is printed at the
end of every week line.  Week number 1 is a week which include January
1st and count up on every Sunday.

Experimentally option **-W2** print the _standard week number_ which
start with the first Sunday of the year, and **-W3** print ISO 8601
style week number.  Because ISO week start on Monday, and the command
shows a number of Sunday of the week, the result is not intuitive and
therefore, I guess, useless.  This option requires [gcal(1)](http://man.he.net/man1/gcal) command
installed.

# COLORMAP

Each field is labeled by names.

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

Besides above, color for day-of-week names (and week number) can be
specified individually by following labels.  No color is assigned to
these labels by default.

    DOW_SU  Sunday
    DOW_MO  Monday
    DOW_TU  Tuesday
    DOW_WE  Wednesday
    DOW_TH  Thursday
    DOW_FR  Friday
    DOW_SA  Saturday
    DOW_CW  Week Number

Three digit means 216 RGB values from `000` to `555`, and `L01`
.. `L24` mean 24 gray scales.  Colormap is handled by
[Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap) module; use \`perldoc Getopt::EX::Colormap\` for
detail.

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

Some modules are included in the distribution.  These options can be
used without any special action, because they are defined to load
appropriate module automatically in default start up module
([App::week::default](https://metacpan.org/pod/App%3A%3Aweek%3A%3Adefault)).

- **-Mcolors**

        --mono
        --lavender
        --green
        --pastel

- **-Mnpb** (Nippon Professional Baseball Organization)

        --tigers, --tigers-rev
        --giants, --giants-rev
        --lions, --lions-rev

- **-Molympic**

        --tokyo2020, --tokyo2020-rev
        --tokyo2020-gold, --tokyo2020-gold-rev
        --para2020, --para2020-rev

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

# INSTALL

## CPANMINUS

    $ cpanm App::week

# SEE ALSO

[App::week](https://metacpan.org/pod/App%3A%3Aweek),
[https://github.com/kaz-utashiro/App-week](https://github.com/kaz-utashiro/App-week)

[Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor),
[https://github.com/kaz-utashiro/Getopt-EX-termcolor](https://github.com/kaz-utashiro/Getopt-EX-termcolor)

[Getopt::EX::i18n](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Ai18n),
[https://github.com/kaz-utashiro/Getopt-EX-i18n](https://github.com/kaz-utashiro/Getopt-EX-i18n)

[Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap)

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

Copyright 2018-2022 Kazumasa Utashiro
