package Aspect::Library::ZoneTimer;

use 5.008002;
use strict;
use warnings;
use Carp                   ();
use Params::Util      1.00 ();
use Aspect::Modular   1.00 ();
use Aspect::Advice::Around ();
use Time::HiRes     1.9718 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.10';
	@ISA     = 'Aspect::Modular';
}

sub get_advice {
	my $self    = shift;
	my %params  = @_;
	my $zones   = $params{zones};
	my $handler = $params{handler};

	# Check params
	unless ( Params::Util::_HASH($zones) ) {
		Carp::croak("Did not provide a set of zones");
	}
	unless ( Params::Util::_CODELIKE($handler) ) {
		Carp::croak("Did not provide a handler function");
	}

	# Variables to be shared between all advice closures
	my @STACK   = (); # Storage for timing data
	my $DISABLE = 0;  # Prevent recursion in the report handler

	# Create one advice for each zone
	my @advice = ();
	foreach ( sort keys %$zones ) {
		my $zone     = $_;
		my $pointcut = $zones->{$zone};
		push @advice, Aspect::Advice::Around->new(
			lexical  => $self->lexical,
			pointcut => $pointcut,
			code     => sub {
				# Shortcut if we are inside the same zone
				# or inside the handler.
				if ( $DISABLE or @STACK and $STACK[-1]->[0] eq $zone ) {
					$_->proceed;
					return;
				}

				# Execute the function and capture timing
				my $error = '';
				SCOPE: {
					local $@;
					push @STACK, [ $zone, { } ];
					my @start = Time::HiRes::gettimeofday();
					eval {
						$_->proceed;
					};
					$error = $@;
					my @stop  = Time::HiRes::gettimeofday();
					my $frame = pop @STACK;
					my $total = $frame->[1];

					# Use our own interval math, generating a value
					# in integer microseconds, to avoid potential
					# floating point bugs in Time::HiRes::tv_interval.
					my $interval = ( $stop[0]  * 1000000 + $stop[1]  )
						     - ( $start[0] * 1000000 + $start[1] );

					if ( @STACK ) {
						# Calculate the exclusive time for the
						# current stack frame and merge up to 
						# the totals already in our parent.
						my $parent = $STACK[-1]->[1];
						foreach my $z ( keys %$total ) {
							$interval -= $total->{$z};
							$parent->{$z} += $total->{$z};
						}
						$parent->{$zone} += $interval;

					} else {
						# Calculate the exclusive time for the current
						# zone and add it to any reentered zone
						# beneath us.
						foreach my $z ( keys %$total ) {
							$interval -= $total->{$z};
						}
						$total->{$zone} += $interval;

						# Send the report to the handler, including
						# our start and stop times in case they are
						# handy for the report.
						$DISABLE++;
						eval {
							$handler->(
								$zone,
								\@start,
								\@stop,
								$total,
							);
						};
						$DISABLE--;
					}
				}

				# Pass through any exceptions
				die $error if $error;
				return;
			},
		);
	}

	return @advice;
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::ZoneTimer - Generate named time cost breakdowns

=head1 SYNOPSIS

  use Aspect;
  use Aspect::Library::ZoneTimer;
  
  use Aspect;
  
  aspect ZoneTimer => (
      zones => {
          main      => call 'MyProgram::main' & highest,
          search    => call 'MyProgram::search',
          widgets   => call qr/^MyProgram::widget_.*/,
          templates => call 'MyProgram::render',
          dbi       => call qr/^DB[DI]::.*?\b(?:prepare|execute|fetch.*)$/,
          system    => (
              call qr/^IPC::System::Simple::(?:run|runx|capture)/
              |
              call 'IPC::Run3::run3'
              |
              call qr/^Capture::Tiny::(?:capture|tee).*/
          )
      },
      handler => sub {
          my $top       = shift; # "main"
          my $start     = shift; # [ 1279763446, 796875 ]
          my $stop      = shift; # [ 1279763473, 163153 ]
          my $exclusive = shift; # { main => 23123412, dbi => 3231231 }
   
          print "Profiling from zone $top\n";
          print "Started recording at " . scalar(localtime $start->[0]) . "\n";
          print "Stopped recording at " . scalar(localtime $stop->[0])  . "\n";
          foreach my $zone ( sort keys %$exclusive ) {
              print "Spent $exclusive->{$zone} microseconds in zone $zone\n";
          }
      },
  );

=head1 DESCRIPTION

While a full profiler like L<Devel::NYTProf> is great for development and
analysis, it is generally far too slow and generates too much data to run
it on a production machine.

B<Aspect::Library::ZoneTimer> is designed to provide some of the same
benefits of a regular profiler, but in a way that can be deployed onto
one or many production servers.

The B<ZoneTimer> aspect lets you break up your program into a series of
named "zones" based on the areas in which you expect your program will
expend the most wallclock time.

In the example above, we expect that most of the program time will be spent
either parsing Perl files using L<PPI> (which we know to be slow) or
waiting for a response from our database of some kind. We also define a top
zone that we expect to enter as soon as the program starts to do useful
work.

Each zone is defined by a L<Aspect::Pointcut|pointcut> that identifies the
key functions that serve as entry points for that area of the program.

As your program executes, the B<ZoneTimer> will watch at these zone entry
points, and track the progress of your program as it moves between the
different zones.

The wallclock time for the execution is tallied up both inclusive and
exclusive for each zone, and when the top-most zone exits the results are
handed off to a handler callback so you can write the times to disk,
save them to a database, or send them to a local or remote syslog.

For maximum accuracy, the start/stop times and the exclusive totals are
provided in two different formats.

Start and stop times are provided as a reference to a two-element C<ARRAY>
exactly as returned by L<Time::HiRes|Time::HiRes::gettimeofday()>.

The profile totals are provided as a reference to a C<HASH> where the keys
are the zone names, and the values are the exclusive wallclock time for the
zone in microseconds.

All timer math is done internally with these integer microseconds to prevent
floating point bugs creeping into the results, and ZoneTimer will avoid
manipulating these 

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Aspect-Library-Timer>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Aspect>, L<Aspect::Library::Timer>

=head1 COPYRIGHT

Copyright 2010 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
