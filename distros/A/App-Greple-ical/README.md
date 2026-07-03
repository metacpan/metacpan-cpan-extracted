[![Actions Status](https://github.com/kaz-utashiro/greple-ical/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kaz-utashiro/greple-ical/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-ical.svg)](https://metacpan.org/release/App-Greple-ical)
# NAME

ical - Module to support Apple macOS Calendar data

# SYNOPSIS

greple -Mical \[ options \]

    --simple  print data in one line
    --detail  print one line data with description if available

# SAMPLES

greple -Mical PATTERN

greple -Mical --simple PATTERN

greple -Mical --detail PATTERN

# DESCRIPTION

This module searches Apple macOS Calendar data.

Recent versions of macOS store calendar data in a SQLite database
(`Calendar.sqlitedb` under `~/Library/Group Containers/group.com.apple.calendar`),
instead of individual `.ics` files which older versions used.  This
module reads the database with the **sqlite3** command and converts
each event to a `VEVENT`-like paragraph, which is then searched by
**greple** in paragraph mode:

     BEGIN:VEVENT
     DTSTART:20260903T163000
     DTEND:20260903T190000
     SUMMARY:映画：ローマの休日
     LOCATION:Theater X
     END:VEVENT

Used without options, matched events are printed in the above format.

With **--simple** option, summarize content in single line:

     2026/09/03 16:30-19:00 映画：ローマの休日 @[Theater X]

With **--detail** option, print summarized line with description data
if it is attached.  The result is sorted.

# REQUIREMENTS

The **sqlite3** command is required (standard on macOS).

The terminal application needs the **Full Disk Access** privilege to
read the calendar database.  If you get an "Operation not permitted"
error, add your terminal application in: System Settings ->
Privacy & Security -> Full Disk Access, and restart the terminal.

# TIPS

Use `-dfn` option to observe the command running status.

Use `-ds` option to see statistics information.

# SEE ALSO

RFC2445

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2017-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
