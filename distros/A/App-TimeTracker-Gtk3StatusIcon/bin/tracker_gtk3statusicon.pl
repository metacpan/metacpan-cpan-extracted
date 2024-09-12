#!/usr/bin/env perl

use v5.24;
use strict;
use warnings;

# ABSTRACT: run App::TimeTracker::Gtk3StatusIcon
# PODNAME: tracker_gtk3statusicon.pl
our $VERSION = '1.000'; # VERSION

use App::TimeTracker::Gtk3StatusIcon;
App::TimeTracker::Gtk3StatusIcon->init('run');

__END__

=pod

=encoding UTF-8

=head1 NAME

tracker_gtk3statusicon.pl - run App::TimeTracker::Gtk3StatusIcon

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  ~$ tracker_gtk3statusicon.pl &

=head1 DESCRIPTION

Adds a small app to your system tray that shows your working status as
reported by C<App::TimeTracker>.

A green light is shown if you're working, a red light if your idling.
If you hover your mouse over the icon, the project (and tags) you're
currently working on will be displayed.

This script currently neither forks nor puts itself into the
background. The best way (IMO) to start it is via a line in your
F<.xinitrc> (or whatever system your window manager uses to
automatically startup apps).

=head1 OPTIONS AND CONFIGURATION

Currently none.

=head1 SEE ALSO

L<App::TimeTracker>

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
