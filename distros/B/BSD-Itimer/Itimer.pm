# File:		Itimer.pm
# Author:	Daniel Hagerty, hag@linnaean.org
# Date:		Sun Jul  4 17:05:49 1999
# Description:	Perl interface to BSD derived {g,s}etitimer functions
#
# Copyright (c) 1999 Daniel Hagerty. All rights reserved. This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.
#
# $Id: Itimer.pm,v 1.1 1999/07/06 02:56:10 hag Exp $

package BSD::Itimer;

use strict;
use Carp;

use Exporter;
use DynaLoader;
use AutoLoader;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

###

# This version number is incremented explicitly by the human.
$VERSION = '0.8';

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     ITIMER_PROF
	     ITIMER_REAL
	     ITIMER_REALPROF
	     ITIMER_VIRTUAL
	     getitimer
	     setitimer
	     );

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined BSD::Itimer macro $constname";
	}
    }
    {
	no strict "refs";
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

bootstrap BSD::Itimer $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

BSD::Itimer - Perl extension for accessing interval timers

=head1 SYNOPSIS

  use BSD::Itimer;
  my($interval_sec, $interval_usec, $current_sec, $current_usec) =
    getitimer(ITIMER_REAL);
  my($interval_sec, $interval_usec, $current_sec, $current_usec) =
    setitimer(ITIMER_REAL, $interval_sec, $interval_usec,
	      $current_sec, $current_usec));

=head1 DESCRIPTION

This module provides access to the interval timers many operating
systems provide from perl.  Interval timers conceptually have
microsecond resolution (hardware typically limits actual granularity),
with the ability to reschedule the timer on a fixed repeating
interval.  There are usually several timers available with a different
concept of "time".

=head1 OVERVIEW

The interval timer is accessed by two exported functions, getitimer
and setitimer.  Most Unix systems have three interval timers available
for program use.  The current BSD::Itimer implementation knows about
the following timers, where implemented:

B<ITIMER_REAL> - This timer decrements in real time.  A SIGALRM is
delivered when this timer expires.

B<ITIMER_VIRTUAL> - This timer decrements in real time when the
calling process is running.  Delivers SIGVTALRM when it expires.

B<ITIMER_PROF> - This timer runs when the calling process is running,
and when the operating system is operating on behalf of the calling
process.  A SIGPROF is delivered when the timer expires.

B<ITIMER_REALPROF> - This timer is available under Solaris only.
Consult the setitimer(2) manual page for more information.

Interval timers are represented as four item integer lists.  The
first two integers comprise the second and microsecond parts of the
timer's repeat interval.  The second pair represent the second and
microsecond parts of the current timer value.

The getitimer function expects a single argument naming the timer to
fetch.  It returns a four element list, or an empty list on failure.

The setitimer function expects a argument naming the timer to set, and
a four element list representing the interval.  It returns the
previous setting of the timer, or an empty list on failure.  Setting a
timer's repeat interval to 0 will cancel the timer after its next
delivery.  Setting it's current value to 0 will immediately cancel the
timer.

=head1 SEE ALSO

perl(1), setitimer(2)

=head1 AUTHOR

Daniel Hagerty <hag@linnaean.org>

=head1 COPYRIGHT

Copyright (c) 1999 Daniel Hagerty. All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 BUGS

Could use a friendly interface.

=cut
