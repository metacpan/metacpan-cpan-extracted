package App::JobLog::Log::Format;
$App::JobLog::Log::Format::VERSION = '1.042';
# ABSTRACT: pretty printer for log


use Exporter 'import';
our @EXPORT_OK = qw(
  display
  duration
  single_interval
  summary
  wrap
);

use Modern::Perl;
use App::JobLog::Config qw(
  day_length
  is_workday
  precision
);
use App::JobLog::Log::Synopsis qw(collect :merge);
use Text::WrapI18N qw();
use App::JobLog::TimeGrammar qw(parse);

use constant TAG_COLUMN_LIMIT => 10;
use constant MARGIN           => 5;

# minimum width of description column
use constant MIN_WIDTH       => 20;
use constant DURATION_FORMAT => '%0.' . precision . 'f';


sub summary {
    my ( $phrase, $test, $hidden, $do_notes ) = @_;

    # we skip flex days if the events are at all filtered
    my $skip_flex = !$do_notes && ( $test || 0 );
    $test //= sub { $_[0] };
    my ( $start, $end ) = parse $phrase;
    my $show_year = $start->year < $end->year;
    unless ($skip_flex) {

     # if we are chopping off any of the first and last days we ignore flex time
        $skip_flex = 1
          unless $do_notes || _break_of_dawn($start) && _witching_hour($end);
    }
    my $method = $do_notes ? 'find_notes' : 'find_events';
    my $events = App::JobLog::Log->new->$method( $start, $end );
    my @days = @{ _days( $start, $end, $skip_flex, $do_notes ) };
    my @periods =
      $hidden->{vacation} ? () : App::JobLog::Vacation->new->periods;

    # drop the vacation days that can't be relevant
    unless ( $hidden->{vacation} ) {
        my $e =
          App::JobLog::Log::Event->new(
            App::JobLog::Log::Line->new( time => $start ) );
        $e->end = $end;
        for ( my $i = 0 ; $i < @periods ; $i++ ) {
            my $p = $periods[$i];
            if ( $skip_flex && $p->flex || !$p->conflicts($e) ) {
                splice @periods, $i, 1;
                $i--;
            }
        }
    }

    # collect events into days
    my @gathered;
    for my $big_e (@$events) {
        for my $e ( $big_e->split_days ) {
            if ( $e = $test->($e) ) {
                push @gathered, shift @days
                  while @days && $days[0]->end < $e->start;
                for my $d (@days) {
                    if ( $e->intersects( $d->pseudo_event ) ) {
                        push @{ $d->events }, $e;
                        last;
                    }

                    # I believe these is_open bits are mistaken
                    # last if $e->is_open;
                    unless ($do_notes) {
                        last if $d->start > $e->end;
                    }
                }
            }
        }
    }
    unshift @days, @gathered;

    # add in vacation times
    for my $p (@periods) {
        for my $d (@days) {
            if ( is_workday( $d->start ) && $p->conflicts( $d->pseudo_event ) )
            {
                my $clone = $p->clone;
                if ( $clone->fixed ) {
                    push @{ $d->events }, $clone->overlap( $d->start, $d->end );
                }
                else {
                    $clone->start = $d->start->clone;
                    if ( $clone->flex ) {
                        $d->{deferred} = $clone;
                    }
                    else {
                        $clone->end =
                          $clone->start->clone->add( hours => day_length );
                        push @{ $d->vacation }, $clone;
                    }
                }
            }
        }
    }

    # delete empty days
    for ( my $i = 0 ; $i < @days ; $i++ ) {
        my $d = $days[$i];
        if ( $d->is_empty && !is_workday( $d->start ) ) {
            splice @days, $i, 1;
            $i--;
        }
    }

    # fix deferred flex time and ensure events are chronologically ordered
    for my $d (@days) {
        my $flex   = $d->{deferred};
        my @events = @{ $d->events };
        if ($flex) {
            delete $d->{deferred};
            my $tr = $d->time_remaining;
            if ( $tr > 0 ) {
                $flex->end = $flex->start->clone->add( seconds => $tr );
                push @events, $flex;
            }
        }
        $d->{events} = [ sort { $a->cmp($b) } @events ] if @events > 1;
    }

    return \@days, $show_year;
}

# whether the date is the first moment in its day
sub _break_of_dawn {
    my ($date) = @_;
    return $date->hour == 0 && $date->minute == 0 && $date->second == 0;
}

# whether the date is the last moment in its day
sub _witching_hour {
    my ($date) = @_;
    return $date->hour == 23 && $date->minute == 59 && $date->second == 59;
}

# create a list of days about which we wish to collect information
sub _days {
    my ( $start, $end, $skip_flex, $doing_notes ) = @_;
    my @days;
    my $b1 = $start;
    my $b2 = $start->clone->add( days => 1 )->truncate( to => 'day' );
    while ( $b2 < $end ) {
        push @days,
          App::JobLog::Log::Day->new(
            start     => $b1,
            end       => $b2,
            skip_flex => $skip_flex,
            $doing_notes ? ( notes => 1 ) : (),
          );
        $b1 = $b2;
        $b2 = $b2->clone->add( days => 1 );
    }
    push @days,
      App::JobLog::Log::Day->new(
        start     => $b1,
        end       => $end,
        skip_flex => $skip_flex,
        $doing_notes ? ( notes => 1 ) : (),
      );
    return \@days;
}


sub display {
    my ( $days, $merge_level, $hidden, $screen_width, $show_year ) = @_;

    if (@$days) {
        collect $_, $merge_level for @$days;
        my @synopses = map { @{ $_->synopses } } @$days;

        my $columns = {
            time => single_interval($merge_level) && !$hidden->{time},
            date => !$hidden->{date},
            tags => !$hidden->{tags},
            description => !$hidden->{description},
            duration    => !$hidden->{duration},
        };
        $show_year &&= $columns->{date};
        my $format = _define_format( \@synopses, $columns, $screen_width );

        # keep track of various durations
        my $times = {
            total    => 0,
            untagged => 0,
            expected => 0,
            vacation => 0,
            tags     => {}
        };

        # display synopses and add up durations
        for my $d (@$days) {
            $d->times($times);
            $d->display( $format, $columns, $screen_width, $show_year );
        }

        unless ( $hidden->{totals} ) {
            my ( $m1, $m2 ) =
              ( length 'TOTAL HOURS', length duration( $times->{total} ) );
            my @keys = keys %{ $times->{tags} };
            push @keys, 'UNTAGGED' if $times->{untagged};
            push @keys, 'VACATION' if $times->{vacation};
            for my $tag (@keys) {
                my $l = length $tag;
                $m1 = $l if $l > $m1;
            }
            $format = sprintf "  %%-%ds %%%ds\n", $m1, $m2;
            printf $format, 'TOTAL HOURS', duration( $times->{total} );
            printf $format, 'VACATION',    duration( $times->{vacation} )
              if $times->{vacation};
            if ( %{ $times->{tags} } ) {
                printf $format, 'UNTAGGED', duration( $times->{untagged} )
                  if $times->{untagged};
                for my $key ( sort keys %{ $times->{tags} } ) {
                    my $d = $times->{tags}{$key};
                    printf $format, $key, duration($d);
                }
            }
        }
    }
    else {
        say 'No events in interval specified.';
    }
}

# generate printf format for synopses
# returns format and wrap widths for tags and descriptions
sub _define_format {
    my ( $synopses, $hash, $screen_width ) = @_;

    #determine maximum width of each column
    my $widths;
    for my $s (@$synopses) {
        if ( $hash->{tags} ) {
            my $w1 = $hash->{widths}{tags} || 0;
            my $ts = $s->tag_string;
            if ( $screen_width > -1 && length $ts > TAG_COLUMN_LIMIT ) {
                my $wrapped = wrap( $ts, TAG_COLUMN_LIMIT );
                $ts = '';
                for my $line (@$wrapped) {
                    $ts = $line if length $line > length $ts;
                }
            }
            my $w2 = length $ts;
            $hash->{widths}{tags} = $w2 if $w2 > $w1;
        }
        if ( $hash->{time} ) {
            my $w1 = $hash->{widths}{time} || 0;
            my $w2 = length $s->time_fmt;
            $hash->{widths}{time} = $w2 if $w2 > $w1;
        }
        if ( $hash->{duration} ) {
            my $w1 = $hash->{widths}{duration} || 0;
            my $w2 = length duration( $s->duration );
            $hash->{widths}{duration} = $w2 if $w2 > $w1;
        }
    }
    my $margins = 0;
    if ( $hash->{tags} && $hash->{widths}{tags} ) {
        $margins++;
        $hash->{formats}{tags} = sprintf '%%-%ds', $hash->{widths}{tags};

# there seems to be a bug in Text::Wrap that requires tinkering with the column width
        $hash->{widths}{tags}++;
    }
    if ( $hash->{time} && $hash->{widths}{time} ) {
        $margins++;
        $hash->{formats}{time} = sprintf '%%%ds', $hash->{widths}{time};
    }
    if ( $hash->{duration} && $hash->{widths}{duration} ) {
        $margins++;
        $hash->{formats}{duration} = sprintf '%%%ds', $hash->{widths}{duration};
    }
    if ( $hash->{description} ) {
        if ( $screen_width == -1 ) {
            $hash->{formats}{description} = '%s';
        }
        else {
            $margins++;
            my $max_description = $screen_width;
            for my $col (qw(time duration tags)) {
                $max_description -= $hash->{widths}{$col} || 0;
            }
            $max_description -= $margins * 2;    # left margins
            $max_description -= MARGIN;          # margin on the right
            $max_description = MIN_WIDTH if $max_description < MIN_WIDTH;
            $hash->{widths}{description} = $max_description;
            $hash->{formats}{description} = sprintf '%%-%ds', $max_description;
        }
    }

    my $format = '';
    for my $col (qw(time duration tags description)) {
        my $f = $hash->{formats}{$col};
        $format .= "  $f" if $f;
    }
    return $format;
}


sub wrap {
    my ( $text, $columns ) = @_;
    my @ar;
    eval {
        $Text::WrapI18N::columns = $columns;
        my $s = Text::WrapI18N::wrap( '', '', $text );
        @ar = $s =~ /^.*$/mg;
    };
    return \@ar unless $@;
    return [$text];
}


sub single_interval {
    $_[0] == MERGE_ADJACENT
      || $_[0] == MERGE_ADJACENT_SAME_TAGS
      || $_[0] == MERGE_NONE;
}


sub duration { sprintf DURATION_FORMAT, $_[0] / ( 60 * 60 ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Log::Format - pretty printer for log

=head1 VERSION

version 1.042

=head1 DESCRIPTION

This module handles word wrapping, date formatting, and the like.

=head1 METHODS

=head2 time_remaining

Obtains a properly filtered list of L<App::JobLog::Log::Day> objects for
a given time expression, code reference to event filtering closure, and
hash specifying fields to hide in report. Returns reference to list of days
and whether the year should be shown in dates.

If C<undef> is passed in as the code reference a dummy closure is constructed
that returns the argument passed in unmodified.

=head2 display

Augments L<App::JobLog::Log::Day> objects with appropriate L<App::JobLog::Log::Synopsis> objects
given the merge level and hidden fields. Expects a reference to a list of days, the merge level, 
a reference to the hidden columns hash, the width of the screen in columns, and whether the year
should be displayed when showing dates. Prints synopses to STDOUT along with aggregate
statistics for the interval.

=head2 wrap

Wraps C<wrap> from L<Text::Wrap>. Expects a string and a number of columns.
Returns a reference to an array of substrings wrapped to fit the columns.

=head2

Whether times should be displayed given the merge level.

=head2 duration

Work time formatter.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
