package App::tt;
use strict;
use warnings;

our $VERSION = '0.10';

1;

=encoding utf8

=head1 NAME

App::tt - Time tracking application

=head1 VERSION

0.10

=head1 DESCRIPTION

L<App::tt> is an application that can track how much time you spend on an
project from command line.

It is inspired by L<App::TimeTracker> and share the same log file format,
but it has (in my humble opinion) a simpler interface and easier to install.

=head1 SYNOPSIS

The application is built up by specifying an L<action|/ACTIONS> and
optional arguments.

  $ tt <action> [options]
  $ tt help <action>
  $ tt <action> -h

Available actions: L</edit>, L</log>, L</register>, L</start>, L</status>
(default) and L</stop>.

Basic usage;

  # Start to track time
  $ cd $HOME/git/my-project
  $ tt start
  # Work, work, work, cd ..., do other stuff
  $ tt stop

A bit more complex:

  # Start to work on an event and add a tag
  $ tt start -t ISSUE-999 -p some-project-at-work
  # Add another tag to the same event and add a --comment
  $ tt stop -t GITHUB-1005 "Today I was mostly in meetings"

=head1 ACTIONS

Each action can tak C<-h> for more details. Example:

  $ tt start -h

=head2 edit

This command can be used to rewrite one all all the log entries.

  # Edit the last entry with your favorite $EDITOR
  $ tt edit

  # Edit a given file with your favorite $EDITOR
  $ tt edit ~/.TimeTracker/2017/12/20171220-092000_rg.trc

  # Rewrite all the log entries with a perl script
  # See source code before running this action. (Internals might change)
  $ cat rewrite.pl | tt edit

DISCLAIMER! Backup your files before running this action!

=head2 export

This will export a given set of records as CSV.

  $ tt log         # this month
  $ tt log -2      # two months ago
  $ tt log year    # log for year
  $ tt log -1y     # last year
  $ tt log -p foo  # Filter by project name

=head2 log

This command will report how much time you have spent on various
events.

  $ tt log         # this month
  $ tt log -2      # two months ago
  $ tt log year    # log for year
  $ tt log -1y     # last year
  $ tt log -p foo  # Filter by project name

=head2 register

This command is used to import data from other sources. "project-name" default to
"-p" or current git project, "some description" default to "-d" and tags can be
specified by -t foo -t bar

  $ tt register 2016-06-28T09:00:00 17:00:00 "project-name" "some description" "foo,bar"
  $ echo "2016-06-28T09:00:00\t2016-06-28T17:00:00\tproject-name\tsome description\tfoo,bar" | tt register

=head2 start

This command will start tracking a new event. It will also stop the
current event if any event is in process. This action takes the
"-p" and "-t" switches. "-p" (project) is not required if you start
from a git repository.

  # Specify a tag and custom project name
  $ tt start -t ISSUE-999 some-project-name

  # Started working at 08:00 instead of now
  $ tt start 08:00

=head2 status

This is the default action and will return the current status:
Are you working on something or not?

  $ tt status

=head2 stop

This command will stop tracking the current event.

  # Add more tags to the current event
  $ tt stop -t meetings -t not_fun

  # Stop working at 16:00 instead of now
  $ tt stop 16:00

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
