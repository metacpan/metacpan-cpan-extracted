use strict;
use warnings;
package Benchmark::Stopwatch::Pause;
use base q{Benchmark::Stopwatch};
our $VERSION = '0.04';

use Time::HiRes;
use Clone 'clone';

=head1 NAME

Benchmark::Stopwatch::Pause - simple timing of stages of your code with a pause option.

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

   #!/usr/bin/perl
   use strict;
   use Benchmark::Stopwatch::Pause;

   # a stopwatch to track the whole run of this script
   my $stopwatch_whole = Benchmark::Stopwatch::Pause->new()->start;
   
   # a stopwatch to track just select sections of the code
   my $stopwatch_pause = Benchmark::Stopwatch::Pause->new()->start->pause;

   sleep(5);

   foreach (1..3) {
      $stopwatch_whole->lap('new loop ' . $_);
      $stopwatch_pause->unpause('time code ' . $_);
      sleep(2);
      $stopwatch_pause->pause;
      sleep(1);
   }

   print $stopwatch_whole->stop->summary;
   print "---------\n";
   print $stopwatch_pause->stop->summary;

   # NAME                        TIME        CUMULATIVE      PERCENTAGE
   #  start                       5.005       5.005           35.677%
   #  new loop 1                  3.008       8.013           21.440%
   #  new loop 2                  3.008       11.021          21.440%
   #  new loop 3                  3.009       14.030          21.443%
   # ---------
   # NAME                        TIME        CUMULATIVE      PERCENTAGE
   #  start                       0.000       0.000           0.000%
   #  time code 1                 2.004       2.004           33.332%
   #  time code 2                 2.004       4.008           33.332%
   #  time code 3                 2.004       6.012           33.336%

=head1 DESCRIPTION

   This is an extention of the handy Benchmark::Stopwatch module. This is an
attempt to allow very granular timeing of very specific sections of code. The 
Stopwatch concept is carried thru in this module, while adding the ability to
pause your stopwatch as needed.

=head1 CHANGES 

Things that differ from Benchmark::Stopwatch

=over 4

=item * Laps are now look ahead

The concept of a lap is diffrent from Benchmark::Stopwatch, they are now look ahead.

In Benchmark::Stopwatch :

   # ... code that is tracked by lap 'one'
   $stopwatch->lap('one');

In Benchmark::Stopwatch::Pause :

   $stopwatch->lap('one');
   # ... code that is tracked by lap 'one'

This allows the time from unpause till pause to be tied to your unpause. 

=item * _start_ is displayed in the summary

Due to the change in the logic of what a lap is _start_ will be displayed.

=item * _stop_ is not displayed in summary

Due to the change in the logic of what a lap is _stop_ will always be a null event.

=back

=cut

=head1 METHODS

=head2 new

    my $stopwatch = Benchmark::Stopwatch::Pause->new;
    
Creates a new stopwatch.

=cut

=head2 start

    $stopwatch = $stopwatch->start;

Starts the stopwatch. Returns a reference to the stopwatch so that you can
chain.

=cut

sub start {
   my $self = shift;
   $self->{start} = $self->time;
   $self->lap('_start_');
   return $self;
}

=head2 lap

    $stopwatch = $stopwatch->lap( 'name of event' );

Notes down the time at which an event occurs. This event will later appear in
the summary.

=cut


sub lap {
    my $self = shift;
    my $name = shift;
    my $time = $self->time;

    # This differs from SUPER::lap as it now tracks the pause state
    push @{ $self->{events} }, { name  => $name,
                                 time  => $time,
                                 pause => $self->{pause},
                               };
    return $self;
}

=head2 pause

    $stopwatch = $stopwatch->pause;

Notes the time at which you paused the clock, this has the effect of pausing
the clock. This allows you to track a small portion of repeated code without
worrying about any other code.

=cut

sub pause {
    my $self = shift;
    $self->{pause} = 1;
    return $self->lap('pause'); 
}

=head2 unpause

    $stopwatch = $stopwatch->unpause( 'name of event' );

unpauses your stopwatch to allow for tracking again. 

=cut

sub unpause {
    my $self = shift;
    my $name = shift;
    $self->{pause} = 0;
    return $self->lap($name) 
}


=head2 stop

    $stopwatch = $stopwatch->stop;

Stops the stopwatch. Returns a reference to the stopwatch so you can chain.

=cut

=head2 total_time

    my $time_in_seconds = $stopwatch->total_time;

Returns the time that the stopwatch ran for in fractional seconds. If the
stopwatch has not been stopped yet then it returns time it has been running
for.

=cut


=head2 summary

    my $summary_text = $stopwatch->summary;
    -- or --
    print $stopwatch->summary;

Returns text summarizing the events that occured. 

=cut

sub summary {
    my $self = shift;
    my $data = $self->as_data;
    
    my $header_format = "%-27.26s %-11s %-15s %s\n";
    my $result_format = " %-27.26s %-11.3f %-15.3f %.3f%%\n";
   
    my $out = sprintf $header_format, qw( NAME TIME CUMULATIVE PERCENTAGE);

    foreach my $event (@{ $data->{laps} }) {
        next if $event->{pause};
        $out .= sprintf($result_format,
                        $event->{name},
                        $event->{elapsed_time},
                        $event->{apparent_elapse_time},
                        ($event->{elapsed_time} / $data->{total_effective_time}) * 100,
                       );
    }

    return $out;
}


=head2 as_data

  my $data_structure_hashref = $stopwatch->as_data;

Returns a data structure that contains all the information that was logged.
This is so that you can use this module to gather the data but then use your
own code to manipulate it.

   print Dumper($stopwatch_pause->stop->as_data);
   
would look like:
   
   {
     'total_elapsed_time' => '14.0544471740723',
     'laps' => [
                 {
                   'pause_time' => 0,
                   'pause' => undef,
                   'apparent_elapse_time' => '1.59740447998047e-05',
                   'time' => '1179438668.5038',
                   'name' => '_start_',
                   'elapsed_time' => '1.59740447998047e-05'
                 },
                 {
                   'pause_time' => '5.00632405281067',
                   'pause' => 1,
                   'apparent_elapse_time' => '1.59740447998047e-05',
                   'time' => '1179438668.50382',
                   'name' => 'pause',
                   'elapsed_time' => '5.00632405281067'
                 },
                 {
                   'pause_time' => 0,
                   'pause' => 0,
                   'apparent_elapse_time' => '2.00797200202942',
                   'time' => '1179438673.51014',
                   'name' => 'time code 1',
                   'elapsed_time' => '2.00795602798462'
                 },
                 {
                   'pause_time' => '1.0080509185791',
                   'pause' => 1,
                   'apparent_elapse_time' => '2.00797200202942',
                   'time' => '1179438675.5181',
                   'name' => 'pause',
                   'elapsed_time' => '1.0080509185791'
                 },
                 {
                   'pause_time' => 0,
                   'pause' => 0,
                   'apparent_elapse_time' => '4.01593208312988',
                   'time' => '1179438676.52615',
                   'name' => 'time code 2',
                   'elapsed_time' => '2.00796008110046'
                 },
                 {
                   'pause_time' => '1.0080668926239',
                   'pause' => 1,
                   'apparent_elapse_time' => '4.01593208312988',
                   'time' => '1179438678.53411',
                   'name' => 'pause',
                   'elapsed_time' => '1.0080668926239'
                 },
                 {
                   'pause_time' => 0,
                   'pause' => 0,
                   'apparent_elapse_time' => '6.02388095855713',
                   'time' => '1179438679.54218',
                   'name' => 'time code 3',
                   'elapsed_time' => '2.00794887542725'
                 },
                 {
                   'pause_time' => '1.00811719894409',
                   'pause' => 1,
                   'apparent_elapse_time' => '6.02388095855713',
                   'time' => '1179438681.55012',
                   'name' => 'pause',
                   'elapsed_time' => '1.00811719894409'
                 }
               ],
     'stop_time' => '1179438682.55824',
     'start_time' => '1179438668.50379',
     'total_effective_time' => '6.0238881111145'
   };
=cut 

sub as_data {
    use List::Util qw{sum};
    my $self = shift;
    my $data = {};
    
    $data->{start_time} = $self->{start};
    $data->{stop_time}  = $self->{stop} || $self->time;
    $data->{total_elapsed_time} = $data->{stop_time} - $data->{start_time} ;
    $data->{laps}       = [];

    my $laps = clone( $self->{events} );
    push @$laps , { name => '_stop_', time => $data->{stop_time}};

    my $apparent_elapse_time;
    while (scalar(@$laps) > 1 ) {
        my $a = shift @$laps;
        my $b = $laps->[0];

        $a->{elapsed_time} = $b->{time} - $a->{time};
        $a->{pause_time}   = ($a->{pause}) ? $a->{elapsed_time} : 0;
        $apparent_elapse_time += $a->{elapsed_time} - $a->{pause_time};
        $a->{apparent_elapse_time} = $apparent_elapse_time;
        
        push @{$data->{laps}},$a;
    }
    
    $data->{total_effective_time} = $data->{total_elapsed_time} - sum( map{$_->{pause_time}} @{ $data->{laps} });

    # ~IF~ you want to have the _stop_ line then uncomment this bit... 
    #push @{$data->{laps}},{ %{$laps->[0]},
    #                        pause          => 0,
    #                        pause_time     => 0,
    #                        apparent_elapse_time => $apparent_elapse_time,
    #                        elapsed_time   => $data->{total_effective_time},
    #                      } ;
    
    return $data;    
}    


=head2 as_unpaused_data

  my $data_structure_hashref = $stopwatch->as_unpaused_data;

Returns the same data structure as as_data but with out the pause laps. 

=cut

sub as_unpaused_data {
   my ($self) = @_;
   my $data = $self->as_data;
   $data->{laps} = [ grep{ ! $_->{pause} } @{ $data->{laps} } ];
   return $data;
}


=head1 AUTHOR

Ben Hengst, C<< <notbenh at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-benchmark-stopwatch-pause at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-Stopwatch-Pause>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Benchmark::Stopwatch::Pause

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Benchmark-Stopwatch-Pause>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Benchmark-Stopwatch-Pause>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Benchmark-Stopwatch-Pause>

=item * Search CPAN

L<http://search.cpan.org/dist/Benchmark-Stopwatch-Pause>

=back

=head1 ACKNOWLEDGMENTS

I couldn't have done this extention without Benchmark::Stopwatch, 
Thanks so much Edmund von der Burg C<<evdb@ecclestoad.co.uk>>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ben Hengst, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;
