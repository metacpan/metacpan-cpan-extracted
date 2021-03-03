# NAME

App::TimeTracker::Command::Category - use categories when tracking time with App::TimeTracker

# VERSION

version 1.003

# DESCRIPTION

Define some categories, which act like 'Super-Tags', for example:
"feature", "bug", "maint", ..

# CONFIGURATION

## plugins

Add `Category` to the list of plugins.

## category

add a hash named `category`, containing the following keys:

### required

Set to a true value if 'category' should be a required command line option

### categories

A list (ARRAYREF) of category names.

### prefix

If set, add this prefix to the category when storing it as tag. Useful
to discern regular tags from category pseudo tags.

# NEW COMMANDS

## statistic

Print stats on time worked per category

    domm@t430:~/validad$ tracker statistic --last day
    From 2016-01-29T00:00:00 to 2016-01-29T23:59:59 you worked on:
                                   07:39:03
       9.9%  bug                   00:45:23
      33.2%  feature               02:32:21
      28.3%  maint                 02:09:52
      12.9%  meeting               00:59:21
      15.7%  support               01:12:06

You can use the same options as in `report` to define which tasks you
want stats on (`--from, --until, --this, --last, --ftag, --fproject, ..`)

# CHANGES TO OTHER COMMANDS

## start, continue, append

### --category

    ~/perl/Your-Project$ tracker start --category feature

Make sure that 'feature' is a valid category and store it as a tag.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
