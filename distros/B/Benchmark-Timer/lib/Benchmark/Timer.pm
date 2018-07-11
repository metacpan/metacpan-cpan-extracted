package Benchmark::Timer;
require 5.005;
use strict;

use Carp;
use Time::HiRes qw( gettimeofday tv_interval );

use vars qw($VERSION);
$VERSION = sprintf "%d.%02d%02d", q/0.71.11/ =~ /(\d+)/g;

use constant BEFORE     => 0;
use constant ELAPSED    => 1;
use constant LASTTAG    => 2;
use constant TAGS       => 3;
use constant SKIP       => 4;
use constant MINIMUM    => 5;
use constant SKIPCOUNT  => 6;
use constant CONFIDENCE => 7;
use constant ERROR      => 8;
use constant STAT       => 9;

# ------------------------------------------------------------------------
# Constructor

sub new {
    my $class = shift;
    my $self = [];
    bless $self, $class;
    return $self->reset(@_);
}


# ------------------------------------------------------------------------
# Public methods

sub reset {
    my $self = shift;
    my %args = @_;

    $self->[BEFORE] = {};          # [ gettimeofday ] storage
    $self->[ELAPSED] = {};         # elapsed fractional seconds
    $self->[LASTTAG] = undef;      # what the last tag was
    $self->[TAGS] = [];            # keep list of tags in order seen
    $self->[SKIP] = 0;             # how many samples to skip
    $self->[MINIMUM] = 1;          # the minimum number of trails to run
    $self->[SKIPCOUNT] = {};       # trial skip storage
    delete $self->[CONFIDENCE];    # confidence factor
    delete $self->[ERROR];         # allowable error
    delete $self->[STAT];          # stat objects for each tag

    if(exists $args{skip}) {
        croak 'argument skip must be a non-negative integer'
            unless defined $args{skip}
               and $args{skip} !~ /\D/
               and int $args{skip} == $args{skip};
        $self->[SKIP] = $args{skip};
        delete $args{skip};
    }

    if(exists $args{minimum}) {
        croak 'argument minimum must be a non-negative integer'
            unless defined $args{minimum}
               and $args{minimum} !~ /\D/
               and int $args{minimum} == $args{minimum};
        croak 'argument minimum must greater than or equal to skip'
            unless defined $args{minimum}
               and $args{minimum} >= $self->[SKIP];
        $self->[MINIMUM] = $args{minimum};
        delete $args{minimum};
    }

    my $confidence_is_valid = 
        (defined $args{confidence}
           and $args{confidence} =~ /^\d*\.?\d*$/
           and $args{confidence} > 0
           and $args{confidence} < 100);

    my $error_is_valid = 
        (defined $args{error}
           and $args{error} =~ /^\d*\.?\d*$/
           and $args{error} > 0
           and $args{error} < 100);

    if ($confidence_is_valid && !$error_is_valid ||
        !$confidence_is_valid && $error_is_valid)
    {
        carp 'you must specify both confidence and error'
    }
    elsif ($confidence_is_valid && $error_is_valid)
    {
        $self->[CONFIDENCE] = $args{confidence};
        delete $args{confidence};

        $self->[ERROR] = $args{error};
        delete $args{error};

        # Demand load the module we need. We could just
        # require people to install it...
        croak 'Could not load the Statistics::PointEstimation module'
          unless eval {require Statistics::PointEstimation};
    }

    if(%args) {
        carp 'skipping unknown arguments';
    }

    return $self;
}


# In this routine we try hard to make the [ gettimeofday ] take place
# as late as possible to minimize Heisenberg problems. :)

sub start {
    my $self = shift;
    my $tag = shift || $self->[LASTTAG] || '_default';
    $self->[LASTTAG] = $tag;
    if(exists $self->[SKIPCOUNT]->{$tag}) {
        if($self->[SKIPCOUNT]->{$tag} > 1) {
            $self->[SKIPCOUNT]->{$tag}--;
        } else {
            $self->[SKIPCOUNT]->{$tag} = 0;
            push @{$self->[BEFORE]->{$tag}}, [ gettimeofday ];
        }
    } else {
        push @{$self->[TAGS]}, $tag;
        $self->[SKIPCOUNT]->{$tag} = $self->[SKIP] + 1;
        if($self->[SKIPCOUNT]->{$tag} > 1) {
            $self->[SKIPCOUNT]->{$tag}--;
        } else {
            $self->[SKIPCOUNT]->{$tag} = 0;
            $self->[BEFORE]->{$tag} = [ [ gettimeofday ] ]
        }
    }
}


sub stop {
    my $after = [ gettimeofday ];    # minimize overhead
    my $self = shift;
    my $tag = shift || $self->[LASTTAG] || '_default';

    croak 'must call $t->start($tag) before $t->stop($tag)'
        unless exists $self->[SKIPCOUNT]->{$tag};

    return if $self->[SKIPCOUNT]->{$tag} > 0;

    my $i = exists $self->[ELAPSED]->{$tag} ?
        scalar @{$self->[ELAPSED]->{$tag}} : 0;
    my $before = $self->[BEFORE]->{$tag}->[$i];
    croak 'timer out of sync' unless defined $before;

    # Create a stats object if we need to
    if (defined $self->[CONFIDENCE] && !defined $self->[STAT]->{$tag})
    {
      $self->[STAT]->{$tag} = Statistics::PointEstimation->new;
      $self->[STAT]->{$tag}->set_significance($self->[CONFIDENCE]);
    }

    my $elapsed = tv_interval($before, $after);

    if($i > 0) {
        push @{$self->[ELAPSED]->{$tag}}, $elapsed;
    } else {
        $self->[ELAPSED]->{$tag} = [ $elapsed ];
    }

    $self->[STAT]->{$tag}->add_data($elapsed)
      if defined $self->[STAT]->{$tag};

    return $elapsed;
}


sub need_more_samples {
    my $self = shift;
    my $tag = shift || $self->[LASTTAG] || '_default';

    carp 'You must set the confidence and error in order to use need_more_samples'
      unless defined $self->[CONFIDENCE];

    # In case this function is called before any trials are run
    return 1
      if !defined $self->[STAT]->{$tag} ||
      $self->[STAT]->{$tag}->count < $self->[MINIMUM];

    # For debugging
#    printf STDERR "Average: %.5f +/- %.5f, Samples: %d\n",
#      $self->[STAT]->{$tag}->mean(), $self->[STAT]->{$tag}->delta(),
#      $self->[STAT]->{$tag}->count;
#    printf STDERR "Percent Error: %.5f > %.5f\n",
#      $self->[STAT]->{$tag}->delta() / $self->[STAT]->{$tag}->mean() * 100,
#      $self->[ERROR];

    return (($self->[STAT]->{$tag}->delta() / $self->[STAT]->{$tag}->mean() * 100) >
      $self->[ERROR]);
}


sub report {
    my $self = shift;
    my $tag = shift || $self->[LASTTAG] || '_default';

    unless(exists $self->[ELAPSED]->{$tag}) {
        carp join ' ', 'tag', $tag, 'still running';
        return;
    }

    return $self->_report($tag);
}



sub reports {
    my $self = shift;

    if (wantarray)
    {
      my @reports;

      foreach my $tag (@{$self->[TAGS]}) {
          push @reports, $tag;
          push @reports, $self->report($tag);
      }

      return @reports;
    }
    else
    {
      my $report = '';

      foreach my $tag (@{$self->[TAGS]}) {
        $report .= $self->report($tag);
      }

      return $report;
    }
}


sub _report {
    my $self = shift;
    my $tag = shift;

    unless(exists $self->[ELAPSED]->{$tag}) {
      return "Tag $tag is still running or has not completed its skipped runs, skipping\n";
    }

    my $report = '';

    my @times = @{$self->[ELAPSED]->{$tag}};
    my $n = scalar @times;
    my $total = 0; $total += $_ foreach @times;

    if ($n == 1)
    {
      $report .= sprintf "\%d trial of \%s (\%s total)\n",
        $n, $tag, _timestr($total);
    }
    else
    {
      $report .= sprintf "\%d trials of \%s (\%s total), \%s/trial\n",
        $n, $tag, _timestr($total), _timestr($total / $n);
    }

    if (defined $self->[STAT]->{$tag})
    {
      my $delta = 0;
      $delta = $self->[STAT]->{$tag}->delta()
        if defined $self->[STAT]->{$tag}->delta();
      
      $report .= sprintf "Error: +/- \%.5f with \%s confidence\n",
        $delta, $self->[CONFIDENCE];
    }

    return $report;
}



sub result {
    my $self = shift;
    my $tag = shift || $self->[LASTTAG] || '_default';
    unless(exists $self->[ELAPSED]->{$tag}) {
        carp join ' ', 'tag', $tag, 'still running';
        return;
    }
    my @times = @{$self->[ELAPSED]->{$tag}};
    my $total = 0; $total += $_ foreach @times;
    return $total / @times;
}


sub results {
    my $self = shift;
    my @results;
    foreach my $tag (@{$self->[TAGS]}) {
        push @results, $tag;
        push @results, $self->result($tag);
    }
    return wantarray ? @results : \@results;
}



sub data {
    my $self = shift;
    my $tag = shift;
    my @results;
    if($tag) {
        if(exists $self->[ELAPSED]->{$tag}) {
            @results = @{$self->[ELAPSED]->{$tag}};
        } else {
            @results = ();
        }
    } else {
        @results = map { ( $_ => $self->[ELAPSED]->{$_} || [] ) }
                          @{$self->[TAGS]};
    }
    return wantarray ? @results : \@results;
}


# ------------------------------------------------------------------------
# Internal utility subroutines

# _timestr($sec) takes a floating-point number of seconds and formats
# it in a sensible way, commifying large numbers of seconds, and
# converting to milliseconds if it makes sense. Since Time::HiRes has
# at most microsecond resolution, no attempt is made to convert into
# anything below that. A unit string is appended to the number.

sub _timestr {
    my $sec = shift;
    my $retstr;
    if($sec >= 1_000) {
        $retstr = _commify(int $sec) . 's';
    } elsif($sec >= 1) {
        $retstr = sprintf $sec == int $sec ? '%ds' : '%0.3fs', $sec;
    } elsif($sec >= 0.001) {
        my $ms = $sec * 1_000;
        $retstr = sprintf $ms == int $ms ? '%dms' : '%0.3fms', $ms;
    } elsif($sec >= 0.000001) {
        $retstr = sprintf '%dus', $sec * 1_000_000;
    } else {
        # I'll have whatever real-time OS she's having
        $retstr = $sec . 's';
    }
    $retstr;
}


# _commify($num) inserts a grouping comma according to en-US standards
# for numbers larger than 1000. For example, the integer 123456 would
# be written 123,456. Any fractional part is left untouched.

sub _commify {
    my $num = shift;
    return unless $num =~ /\d/;
    return $num if $num < 1_000;

    my $ip  = int $num;
    my($fp) = ($num =~ /\.(\d+)/);

    $ip =~ s/(\d\d\d)$/,$1/;
    1 while $ip =~ s/(\d)(\d\d\d),/$1,$2,/;

    return $fp ? join '.', $ip, $fp : $ip;
}

# ------------------------------------------------------------------------
# Return true for a valid Perl include

1;

# ---------------------------------------------------------------------------

=head1 NAME

Benchmark::Timer - Benchmarking with statistical confidence


=head1 SYNOPSIS

  # Non-statistical usage
  use Benchmark::Timer;
  $t = Benchmark::Timer->new(skip => 1);

  for(1 .. 1000) {
      $t->start('tag');
      &long_running_operation();
      $t->stop('tag');
  }
  print $t->report;

  # --------------------------------------------------------------------

  # Statistical usage
  use Benchmark::Timer;
  $t = Benchmark::Timer->new(skip => 1, confidence => 97.5, error => 2);

  while($t->need_more_samples('tag')) {
      $t->start('tag');
      &long_running_operation();
      $t->stop('tag');
  }
  print $t->report;

=head1 DESCRIPTION

The Benchmark::Timer class allows you to time portions of code
conveniently, as well as benchmark code by allowing timings of repeated
trials. It is perfect for when you need more precise information about the
running time of portions of your code than the Benchmark module will give
you, but don't want to go all out and profile your code.

The methodology is simple; create a Benchmark::Timer object, and wrap portions
of code that you want to benchmark with C<start()> and C<stop()> method calls.
You can supply a tag to those methods if you plan to time multiple portions of
code.  If you provide error and confidence values, you can also use
C<need_more_samples()> to determine, statistically, whether you need to
collect more data.

After you have run your code, you can obtain information about the running
time by calling the C<results()> method, or get a descriptive benchmark report
by calling C<report()>.  If you run your code over multiple trials, the
average time is reported.  This is wonderful for benchmarking time-critical
portions of code in a rigorous way. You can also optionally choose to skip any
number of initial trials to cut down on initial case irregularities.

=head1 METHODS

In all of the following methods, C<$tag> refers to the user-supplied name of
the code being timed. Unless otherwise specified, $tag defaults to the tag of
the last call to C<start()>, or "_default" if C<start()> was not previously
called with a tag.

=over 4

=item $t = Benchmark::Timer->new( [options] );

Constructor for the Benchmark::Timer object; returns a reference to a
timer object. Takes the following named arguments:

=over 4

=item skip

The number of trials (if any) to skip before recording timing information.

=item minimum

The minimum number of trials to run.

=item error

A percentage between 0 and 100 which indicates how much error you are willing
to tolerate in the average time measured by the benchmark.  For example, a
value of 1 means that you want the reported average time to be within 1% of
the real average time. C<need_more_samples()> will use this value to determine
when it is okay to stop collecting data.

If you specify an error you must also specify a confidence.

=item confidence

A percentage between 0 and 100 which indicates how confident you want to be in
the error measured by the benchmark. For example, a value of 97.5 means that
you want to be 97.5% confident that the real average time is within the error
margin you have specified. C<need_more_samples()> will use this value to
compute the estimated error for the collected data, so that it can determine
when it is okay to stop.

If you specify a confidence you must also specify an error.

=back

=item $t->reset;

Reset the timer object to the pristine state it started in.
Erase all memory of tags and any previously accumulated timings.
Returns a reference to the timer object. It takes the same arguments
the constructor takes.

=item $t->start($tag);

Record the current time so that when C<stop()> is called, we can calculate an
elapsed time. 

=item $t->stop($tag);

Record timing information. If $tag is supplied, it must correspond to one
given to a previously called C<start()> call. It returns the elapsed time in
milliseconds.  C<stop()> croaks if the timer gets out of sync (e.g. the number
of C<start()>s does not match the number of C<stop()>s.)

=item $t->need_more_samples($tag);

Compute the estimated error in the average of the data collected thus far, and
return true if that error exceeds the user-specified error. If a $tag is
supplied, it must correspond to one given to a previously called C<start()>
call. 

This routine assumes that the data are normally distributed.

=item $t->report($tag);

Returns a string containing a simple report on the collected timings for $tag.
This report contains the number of trials run, the total time taken, and, if
more than one trial was run, the average time needed to run one trial and
error information.  C<report()> will complain (via a warning) if a tag is
still active.

=item $t->reports;

In a scalar context, returns a string containing a simple report on the
collected timings for all tags. The report is a concatenation of the
individual tag reports, in the original tag order. In an list context, returns
a hash keyed by tag and containing reports for each tag. The return value is
actually an array, so that the original tag order is preserved if you assign
to an array instead of a hash. C<reports()> will complain (via a warning) if a
tag is still active.

=item $t->result($tag);

Return the time it took for $tag to elapse, or the mean time it took for $tag
to elapse once, if $tag was used to time code more than once. C<result()> will
complain (via a warning) if a tag is still active.

=item $t->results;

Returns the timing data as a hash keyed on tags where each value is
the time it took to run that code, or the average time it took,
if that code ran more than once. In scalar context it returns a reference
to that hash. The return value is actually an array, so that the original
tag order is preserved if you assign to an array instead of a hash.

=item $t->data($tag), $t->data;

These methods are useful if you want to recover the full internal timing
data to roll your own reports.

If called with a $tag, returns the raw timing data for that $tag as
an array (or a reference to an array if called in scalar context). This is
useful for feeding to something like the Statistics::Descriptive package.

If called with no arguments, returns the raw timing data as a hash keyed
on tags, where the values of the hash are lists of timings for that
code. In scalar context, it returns a reference to that hash. As with
C<results()>, the data is internally represented as an array so you can
recover the original tag order by assigning to an array instead of a hash.

=back

=head1 BUGS

Benchmarking is an inherently futile activity, fraught with uncertainty
not dissimilar to that experienced in quantum mechanics. But things are a
little better if you apply statistics.

=head1 LICENSE

This code is distributed under the GNU General Public License (GPL) Version 2.
See the file LICENSE in the distribution for details.

=head1 AUTHOR

The original code (written before April 20, 2001) was written by Andrew Ho
E<lt>andrew@zeuscat.comE<gt>, and is copyright (c) 2000-2001 Andrew Ho.
Versions up to 0.5 are distributed under the same terms as Perl.

Maintenance of this module is now being done by David Coppit
E<lt>david@coppit.orgE<gt>.

=head1 SEE ALSO

L<Benchmark>, L<Time::HiRes>, L<Time::Stopwatch>, L<Statistics::Descriptive>

=cut
