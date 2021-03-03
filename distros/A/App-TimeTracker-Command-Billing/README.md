# NAME

App::TimeTracker::Command::Billing - Add a billing point as a tag to tasks

# VERSION

version 1.001

# DESCRIPTION

Add a billing point to each task. Could be based on the current date (eg '2019/Q4' or '2019/11') or on some project name.

# CONFIGURATION

## plugins

Add `Billing` to the list of plugins.

## billing

add a hash named `billing`, containing the following keys:

### required

Set to a true value if 'billing' should be a required command line option

### prefix

If set, add this prefix to the billing point when storing it as tag. Useful to discern regular tags from billing point pseudo tags.

### default

Set to the method to calculate the default billing point. Currently there is only one method implemented, `strftime`

### strftime

When using `default = strftime`, specify the [DateTime::strftime](https://metacpan.org/pod/DateTime%3A%3Astrftime) format. Some examples:

- `%Y/%m` -> 2019/12
- `%Y/Q%{quarter}` -> 2019/Q4

# NEW COMMANDS

no new commands

# CHANGES TO OTHER COMMANDS

## start, continue, append

### --billing

    ~/perl/Your-Project$ tracker start --billing offer-42

Add a tag 'offer-42', which you can later use to filter all tasks
belonging to an offer / sub-project etc

If you set up a `default` using `strftime` you can automatically add
a billing tag for eg the current month or quarter. This is very
helpful for mapping tasks to maintainance contracts.

    cat .tracker.json
    "billing":{
        "required":false,
        "default": "strftime",
        "strftime": "%Y/Q%{quarter}"
    }

    ~/perl/Your-Project$ tracker start
    Started working on Your-Project (2019/Q4) at 22:26:07

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
