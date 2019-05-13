# NAME

App::TimeTracker::Command::Jira - App::TimeTracker Jira plugin

# VERSION

version 0.8

# DESCRIPTION

This plugin integrates into Atlassian Jira
[https://www.atlassian.com/software/jira](https://www.atlassian.com/software/jira).

It can set the description and tags of the current task based on data
coming from Jira, set the owner of the ticket and update the
worklog. If you also use the `Git` plugin, this plugin will
generate branch names based on Jira ticket information.

# CONFIGURATION

## plugins

Add `Jira` to the list of plugins.

## jira

add a hash named `jira`, containing the following keys:

### server \[REQUIRED\]

The URL of the Jira instance (without a trailing slash).

### username \[OPTIONAL\]

Username to connect with.

### password \[OPTIONAL\]

Password to connect with. Beware: This is stored in clear text! Better use authentication via `Config::Identity` via `JIRA::REST` where the credentials can be stored GPG encrypted.

### log\_time\_spent

If set, an entry will be created in the ticket's work log

# NEW COMMANDS ADDED TO THE DEFAULT ONES

none

# CHANGES TO DEFAULT COMMANDS

## start, continue

### --jira

    ~/perl/Your-Project$ tracker start --jira ABC-1

If `--jira` is set to a valid ticket identifier:

- set or append the ticket subject in the task description ("Adding more cruft")
- add the ticket number to the tasks tags ("ABC-1")
- if `Git` is also used, determine a save branch name from the ticket identifier and subject, and change into this branch ("ABC-1\_adding\_more\_cruft")
- updates the status of the ticket in Jira (given `set_status/start/transition` is set in config)

## stop

If `log_time_spent` is set in config, adds and entry to the worklog of the Jira ticket.
If `set_status/stop/transition` is set in config and the current Jira ticket state is `set_status/start/target_state`, updates the status of the ticket

# EXAMPLE CONFIG

    {
        "plugins" : [
            "Git",
            "Jira"
        ],
        "jira" : {
            "username" : "dingo",
            "password" : "secret",
            "log_time_spent" : "1",
            "server_url" : "http://localhost:8080",
            "set_status": {
                "start": { "transition": ["Start Progress", "Restart progress", "Reopen and start progress"], "target_state": "In Progress" },
                "stop": { "transition": "Stop Progress" }
            }
        }
    }

# AUTHOR

Michael Kröll <pepl@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Kröll.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
