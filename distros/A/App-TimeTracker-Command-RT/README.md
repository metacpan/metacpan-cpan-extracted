# NAME

App::TimeTracker::Command::RT - App::TimeTracker RT plugin

# VERSION

version 3.000

# DESCRIPTION

This plugin takes a lot of hassle out of working with Best Practical's
RequestTracker available for free from
[http://bestpractical.com/rt/](http://bestpractical.com/rt/).

It can set the description and tags of the current task based on data
entered into RT, set the owner of the ticket and update the
time-worked as well as time-left in RT. If you also use the `Git` plugin, this plugin will
generate very nice branch names based on RT information.

# CONFIGURATION

## plugins

Add `RT` to the list of plugins. 

## rt

add a hash named `rt`, containing the following keys:

### server \[REQUIRED\]

The server name RT is running on.

### username \[REQUIRED\]

Username to connect with. As the password of this user might be distributed on a lot of computer, grant as little rights as needed.

### password \[REQUIRED\]

Password to connect with.

### timeout

Time in seconds to wait for an connection to be established. Default: 300 seconds (via RT::Client::REST)

### set\_owner\_to

If set, set the owner of the current ticket to the specified value during `start` and/or `stop`.

### update\_time\_worked

If set, updates the time worked on this task also in RT.

### update\_time\_left

If set, updates the time left property on this task also in RT using the time worked tracker value.

# NEW COMMANDS

none

# CHANGES TO OTHER COMMANDS

## start, continue

### --rt

    ~/perl/Your-Project$ tracker start --rt 1234

If `--rt` is set to a valid ticket number:

- set or append the ticket subject in the task description ("Rev up FluxCompensator!!")
- add the ticket number to the tasks tags ("RT1234")
- if `Git` is also used, determine a save branch name from the ticket number and subject, and change into this branch ("RT1234\_rev\_up\_fluxcompensator")
- set the owner of the ticket in RT (if `set_owner_to` is set in config)
- updates the status of the ticket in RT (if `set_status/start` is set in config)

## stop

If &lt;update\_time\_worked> is set in config, adds the time worked on this task to the ticket.
If &lt;update\_time\_left> is set in config, reduces the time left on this task to the ticket.
If &lt;set\_status/stop> is set in config, updates the status of the ticket

# AUTHOR

Thomas Klausner <domm@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2019 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
