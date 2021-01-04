# dusage

`dusage` is a utility to generate disk space usage reports.

## Overview

Guarding disk space is one of the main problems of system management.

Long long time ago, I created `dusage` by converting an old
`awk`/`sed`/`sh` script to keep track of disk usage to a new Perl
program, adding new features and options, including a manual page.

Provided a list of paths, `dusage` filters the output of `du` to find
the amount of disk space used for each of the paths, collecting the
values in one `du` run. It adds the new value to the list, shifting old
values up. It then generates a nice report of the amount of disk space
occupied in each of the specified paths, together with the amount it
grew (or shrank) since the previous run, and since seven runs ago.
When run daily, `dusage` outputs daily and weekly reports.

## Warning

This program was written in 1990 for Perl 3.0. Later I updated some
parts for Perl 5. As a result, the source is sometimes ugly.

## Availability

### Source Code

* [GitHub](https://github.com/sciurius/dusage)

## Issue Tracking

* Please use the GitHub issue tracker.

## Requirements

* Perl version 5 or higher

## Author

* [Johan Vromans](https://johan.vromans.org/)

## License

This source code can be used on the same licensing terms as Perl.

