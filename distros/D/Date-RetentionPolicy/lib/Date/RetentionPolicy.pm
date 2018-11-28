package Date::RetentionPolicy;
$Date::RetentionPolicy::VERSION = '0.01';
use Moo;
use Scalar::Util 'looks_like_number';
use DateTime;
use DateTime::Format::Flexible;

# ABSTRACT: Prune a list of dates down to the ones you want to keep


has retain         => ( is => 'rw', required => 1 );
has time_zone      => ( is => 'rw', default => sub { 'floating' } );
has reach_factor   => ( is => 'rw', default => sub { .5 } );
has reference_date => ( is => 'rw' );
has auto_sync      => ( is => 'rw' );

sub reference_date_or_default {
	my $self= shift;
	# Use override, else 'now' rounded up to next day boundary of timezone
	my $start= $self->reference_date;
	return $start->clone if ref $start;
	return $self->_coerce_date($start) if defined $start;
	return DateTime->now(time_zone => $self->time_zone)
		 ->add(days => 1, seconds => -1)->truncate(to => 'day');
	return $start;
}


sub prune {
	my ($self, $list)= @_;
	my $processed= $self->_sort_and_mark_retention($list);
	# Divide the elements into two lists.  Make a set of which indexes
	# we're keeping, then iterate the original list to preserve the caller's
	# list order.
	my (@retain, @prune);
	my %keep= map +($_->[1] => 1), grep $_->[2], @$processed;
	push @{ $keep{$_}? \@retain : \@prune }, $list->[$_]
		for 0..$#$list;
	@$list= @retain;
	return \@prune;
}

sub _sort_and_mark_retention {
	my ($self, $list, $trace)= @_;
	# Each list element needs to be a date object, (but preserve the original)
	# and the list needs to be sorted in cronological order.
	my @sorted= sort { $a->[0] <=> $b->[0] }
		# tuple of [ Epoch, ListIndex, KeepBoolean ].
		# A hash would be more readable but there could be a lot of these.
		map [ $self->_coerce_to_epoch($list->[$_]), $_, 0 ],
			0..$#$list;
	# Never prune things newer than the reference date
	my $ref_date= $self->reference_date_or_default;
	for (my $i= $#sorted; $i >= 0 && $sorted[$i][0] > $ref_date->epoch; --$i) {
		$sorted[$i][2]= 1;
	}
	# Set the boolean to true for each element that a rule wants to keep
	$self->_mark_for_retention($ref_date, $_, \@sorted, $trace)
		for @{ $self->retain };
	return \@sorted;
}

sub _mark_for_retention {
	my ($self, $reference_date, $rule, $list, $trace)= @_;
	my ($interval, $history, $reach_factor)= @{$rule}{'interval','history','reach_factor'};
	$reach_factor=   $self->reach_factor unless defined $reach_factor;
	my $next_date=   $reference_date->clone->subtract(%$history)->add(%$interval);
	my $epoch=       $next_date->epoch;
	my $search_idx=  0;
	my $next_epoch=  $next_date->add(%$interval)->epoch;
	my $radius=      -($epoch - $next_epoch) * $reach_factor;
	my $drift=       0; # only used for auto_sync
	my $rule_key;
	
	# The epoch variables track the current date interval, and the _idx
	# variables track our position in the list.
	while ($epoch-abs($drift) <= $reference_date->epoch && $search_idx < @$list) {
		my $best;
		for (my $i= $search_idx; $i < @$list and $list->[$i][0] < $epoch+$drift+$radius; ++$i) {
			if ($list->[$i][0] >= $epoch+$drift-$radius
				and (!defined $best or abs($list->[$i][0] - ($epoch+$drift)) < abs($list->[$best][0] - ($epoch+$drift)))
			) {
				$best= $i;
			}
			# update the start_idx for next interval iteration
			$search_idx= $i+1 if $list->[$i][0] < $next_epoch-$radius*2;
		}
		if (defined $best) {
			$list->[$best][2]= 1; # mark as a keeper
			# If option enabled, drift toward the time we found, so that gap between next
			# is closer to $interval
			$drift= $list->[$best][0] - $epoch
				if $self->auto_sync;
		}
		if ($trace) {
			$rule_key= join ',', map "$_=$interval->{$_}", keys %$interval
				unless defined $rule_key;
			if (!$trace->{$rule_key}) {
				$trace->{$rule_key}{idx}= scalar keys %$trace;
				$trace->{$rule_key}{radius}= $radius;
				$trace->{$rule_key}{name}= $rule_key;
			}
			push @{$trace->{$rule_key}{interval}}, { epoch => $epoch, best => $best, drift => $drift };
		}
		$epoch= $next_epoch;
		$next_epoch= $next_date->add(%$interval)->epoch;
		
		# if auto_sync enabled, cause drift to decay back toward 0
		$drift= int($drift * 7/8)
			if $drift;
	}
}


sub visualize {
	my ($self, $list)= @_;
	my $trace= {};
	my $processed= $self->_sort_and_mark_retention($list, $trace);
	$processed->[$_][1]= $_ for 0..$#$processed; # change indexes to index within processed list
	my @claimed;
	my @things= @$processed;
	my @columns;
	my %rule_to_col;
	# Convert each trace to a similar arrayref structure as the processed items, for sorting
	for my $rule_trace (sort { $a->{idx} <=> $b->{idx} } values %$trace) {
		push @columns, { name => $rule_trace->{name}, width => 20 };
		$rule_to_col{$rule_trace->{name}}= $#columns;
		for (@{ $rule_trace->{interval} }) {
			push @{$claimed[$_->{best}]}, $rule_trace->{name} if defined $_->{best};
			push @things,
				[ $_->{epoch} + $_->{drift} + $rule_trace->{radius}, 'ival-newest', $rule_trace->{name} ],
				[ $_->{epoch} + $_->{drift},                         'ival',        $rule_trace->{name} ],
				[ $_->{epoch} + $_->{drift} - $rule_trace->{radius}, 'ival-oldest', $rule_trace->{name} ];
		}
	}
	push @columns, { name => 'timestamp', width => 20 };
	@things= sort { $a->[0] <=> $b->[0] } @things;
	
	# Walk from oldest to newest, displaying timestamps alongside the epock interval points
	my $cur_time= 0;
	my @in_interval= ( 0 ) x @columns;
	my @row= map $_->{name}, @columns;
	my $format= join(' ', map '%-'.$_->{width}.'s', @columns)."\n";
	my $out= '';
	my $emit= sub {
		# if in_interval, display a vertical bar as a graphic
		for (0..$#in_interval) {
			$row[$_] ||= '|' if $in_interval[$_];
		}
		$out .= sprintf $format, @row;
		@row= ('') x @columns;
	};
	for (@things) {
		$emit->() if $cur_time != $_->[0];
		$cur_time= $_->[0];
		if ($_->[1] eq 'ival') {
			$row[ $rule_to_col{ $_->[2] } ]= $self->_coerce_date($_->[0]);
		} elsif ($_->[1] eq 'ival-newest') {
			$row[ $rule_to_col{ $_->[2] } ]= '---';
			--$in_interval[ $rule_to_col{ $_->[2] } ];
		} elsif ($_->[1] eq 'ival-oldest') {
			$row[ $rule_to_col{ $_->[2] } ]= '---';
			++$in_interval[ $rule_to_col{ $_->[2] } ];
		} else {
			$row[-1]= $self->_coerce_date($_->[0]).($_->[2]? ' +':' x');
			if ($claimed[$_->[1]]) {
				$row[-1] .= '  '.join ', ', @{ $claimed[$_->[1]] };
			}
		}
	}
	$emit->();
	return $out;
}

sub _coerce_date {
	my ($self, $thing)= @_;
	my $date= ref $thing && ref($thing)->can('set_time_zone')? $_->clone
		: looks_like_number($thing)? DateTime->from_epoch(epoch => $thing)
		: DateTime::Format::Flexible->parse_datetime($thing);
	$date->set_time_zone($self->time_zone);
	return $date;
}

sub _coerce_to_epoch {
	my ($self, $thing)= @_;
	return $thing if !ref $thing && looks_like_number($thing);
	return $self->_coerce_date($thing)->epoch;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::RetentionPolicy - Prune a list of dates down to the ones you want to keep

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $rp= Date::RetentionPolicy->new(
    retain => [
      { interval => { hours => 6 }, history => { months => 3 } },
      { interval => { days  => 1 }, history => { months => 6 } },
      { interval => { days  => 7 }, history => { months => 9 } },
    ]
  );
  
  my $dates= [ '2018-01-01 03:23:00', '2018-01-01 09:45:00', ... ];
  my $pruned= $rp->prune($dates);
  for (@$pruned) {
    # delete the backup dated $_
    ...
  }

=head1 DESCRIPTION

Often when making backups of a thing, you want to have more frequent snapshots
for recent dates, but don't need that frequency further back in time, and want
to delete some of the older ones to save space.

The problem of deciding which snapshots to delete is non-trivial because
backups often don't complete on a timely schedule (despite being started on
a schedule) or have discontinuities from production mishaps, and it would be
bad if your script wiped out the only backup in an interval just because it
didn't look like one of the "main" timestamps.  Also it would be bad if the
jitter from the time zone or time of day that you run the pruning process
caused the script to round differently and delete the backups it had
previously decided to keep.

This module uses an algorithm where you first define the intervals which
should retain a backup, then assign the existing timestamps to those intervals
(possibly reaching across the interval boundary a bit in order to preserve
a nearby timestamp; see L<reach_factor>) thus making an intelligent decision
about which timestamps to keep.

=head1 DATES

This module currently depends on DateTime, but I'm happy to accept patches
to allow it to work with other Date classes.

=head1 ATTRIBUTES

=head2 retain

An arrayref of specifications for what to preserve.  Each element should be a
hashref containing C<history> and C<interval>.  C<history> specifies how far
backward from L</reference_date> to apply the intervals, and C<interval>
specifies the time difference between the backups that need preserved.

As an example, consider

  retain => [
    { interval => { days => 1 }, history => { days => 20 } },
    { interval => { hours => 1 }, history => { hours => 48 } },
  ]

This will attempt to preserve timestamps near the marks of L</reference_date>,
an hour before that, an hour before that, and so on for the past 48 hours.
It will also attempt to preserve L</reference_date>, a day before that, a day
before that, and so on for the past 20 days.

There is another setting called L</reach_factor> that determines how far from
the desired timestamp the algorithm will look for something to preserve.  The
default C<reach_factor> of C<0.5> means that it will scan from half an interval
back in time until half an interval forward in time looking for the closest
timestamp to preserve.  In some cases, you may want a narrower or wider search
distance, and you can set C<reach_factor> accordingly.  You can also supply it
as another hash key for a retain rule for per-rule customization.

  retain => [
    { interval => { days => 1 }, history => { days => 20 }, reach_factor => .75 }
  ]

=head2 time_zone

When date strings are involved, parse them as this time zone before converting
to an epoch value used in the calculations.  The default is C<'floating'>.

=head2 reach_factor

The multiplier for how far to look in each direction from an interval point.
See discussion in L</retain>.

=head2 reference_date

The end-point from which all intervals will be calculated.  There is no
default, to allow L</reference_date_or_default> to always pick up the current
time when called.

=head2 reference_date_or_default

Read-only.  Return (a clone of) L</reference_date>, or if it isn't set, return
the current date in the designated L</time_zone> rounded up to the next day
boundary.

=head2 auto_sync

While walking backward through time intervals looking for backups, adjust the
interval endpoint to be closer to whatever match it found.  This might allow
the algorithm to essentially adjust the C<reference_date> to match whatever
schedule your backups are running on.  This is not enabled by default.

=head1 METHODS

=head1 prune

  my $pruned_arrayref= $self->prune( \@times );

C<@times> may be an array of epoch numbers, DateTime objects, or date strings
in any format recognized by L<DateTime::Format::Flexible>.  Epochs are
currently the most efficient type of argument since that's what the algorithm
operates on.

=head2 visualize

  print $rp->visualize( \@list );

This method takes a list of timestamps, sorts and marks them for retention,
and then returns printable text showing the retention intervals and which
increment it decided to keep.  The text is simple ascii-art, and requires
a monospace font to display correctly.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
