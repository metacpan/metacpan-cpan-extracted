package Cron::Toolkit::Tree::Matcher;
use strict;
use warnings;
use Time::Moment;
use List::Util                  qw(any);
use Cron::Toolkit::Tree::Utils qw(quartz_dow);
use List::Util                  qw(max min);

sub new {
   my ( $class, %args ) = @_;
   return bless {
      tree        => $args{tree},
      utc_offset  => $args{utc_offset} // 0,
      owner       => $args{owner},             # New: For bounds access
      _time_cache => {},
   }, $class;
}

sub match {
   my ( $self, $epoch_seconds ) = @_;
   return 0 unless defined $epoch_seconds;

   my $tm_utc   = Time::Moment->from_epoch($epoch_seconds);
   my $tm_local = $tm_utc->with_offset_same_instant( $self->{utc_offset} );

   my @fields      = @{ $self->{tree}{children} };
   my @field_types = qw(second minute hour dom month dow year);

   foreach my $i ( 0 .. 6 ) {
      my $field = $fields[$i] or next;
      next if $field->{type} eq 'wildcard';
      my $value = $self->_field_value( $tm_local, $field_types[$i] );

      # Visitor-wired: Traverse for match
      my $visitor = Cron::Toolkit::Tree::MatchVisitor->new( value => $value, tm => $tm_local );
      return 0 unless $field->traverse($visitor);
   }
   return 1;
}

sub _find_next {
   my ( $self, $start_epoch, $end_epoch, $step, $direction ) = @_;

   print STDERR "=== FIND NEXT DEBUG ===\n"                                                  if $ENV{Cron_DEBUG};
   print STDERR "Start: $start_epoch, End: $end_epoch, Step: $step, Direction: $direction\n" if $ENV{Cron_DEBUG};

   my $begin_epoch     = $self->{owner}{begin_epoch} // $start_epoch;    # Fallback to method start if unset
   my $end_epoch_obj   = $self->{owner}{end_epoch};
   my $effective_start = $direction > 0 ? max( $start_epoch, $begin_epoch ) : min( $start_epoch, $begin_epoch );
   my $effective_end   = $direction > 0 ? ( $end_epoch_obj // $end_epoch )  : ( $end_epoch_obj // $end_epoch );

   my $tm_start = Time::Moment->from_epoch($effective_start)->with_offset_same_instant( $self->{utc_offset} );
   my $tm_end   = defined $effective_end ? Time::Moment->from_epoch($effective_end)->with_offset_same_instant( $self->{utc_offset} ) : undef;

   print STDERR "TM Start: " . $tm_start->strftime('%Y-%m-%d %H:%M:%S') . " ($tm_start->epoch)\n"                       if $ENV{Cron_DEBUG};
   print STDERR "TM End: " . ( $tm_end ? $tm_end->strftime('%Y-%m-%d %H:%M:%S') : 'unbounded' ) . " ($tm_end->epoch)\n" if $ENV{Cron_DEBUG};

   my $current        = $direction > 0  ? $tm_start->plus_seconds(1)                                                     : $tm_start->minus_days(1)->at_midnight;
   my $search_end     = defined $tm_end ? ( $direction > 0 ? $tm_end->plus_days(1)->at_midnight : $tm_end->at_midnight ) : undef;
   my $iterations     = 0;
   my $max_iterations = 400;

   print STDERR "Search: Current=" . $current->strftime('%Y-%m-%d %H:%M:%S') . ", Search End=" . ( $search_end ? $search_end->strftime('%Y-%m-%d %H:%M:%S') : 'unbounded' ) . "\n" if $ENV{Cron_DEBUG};

   my $is_second_step = $step == 1;

   while (1) {    # Always enter; break on bounds/max
      $iterations++;
      if ( $iterations > $max_iterations ) {
         print STDERR "Max iterations ($max_iterations) reached\n" if $ENV{Cron_DEBUG};
         return undef;
      }
      if ( defined $search_end && ( $direction > 0 ? $current->epoch > $search_end->epoch : $current->epoch < $search_end->epoch ) ) {
         last;    # Out of bounds
      }

      my @possible_times;
      if ($is_second_step) {
         @possible_times = ($current);
      }
      else {
         my $current_day = $current->at_midnight;
         my $cache_key   = $current_day->epoch;
         @possible_times =
           exists $self->{_time_cache}{$cache_key}
           ? @{ $self->{_time_cache}{$cache_key} }
           : do {
            my @times = $self->_generate_possible_times($current_day);
            $self->{_time_cache}{$cache_key} = \@times;
            @times;
           };
         print STDERR "Testing day: " . $current_day->strftime('%Y-%m-%d') . ", Generated " . scalar(@possible_times) . " times\n" if $ENV{Cron_DEBUG};
      }

      my @sorted_times = $direction > 0 ? sort { $a->epoch <=> $b->epoch } @possible_times : sort { $b->epoch <=> $a->epoch } @possible_times;
      for my $tm (@sorted_times) {

         # Skip if beyond bounds
         if ( defined $effective_end && ( $direction > 0 ? $tm->epoch > $effective_end : $tm->epoch < $effective_end ) ) {
            next;
         }

         # Match check against effective start (include boundary)
         if ( $self->match( $tm->epoch ) && ( $direction > 0 ? $tm->epoch >= $effective_start : $tm->epoch <= $effective_start ) ) {
            print STDERR "MATCH at " . $tm->strftime('%Y-%m-%d %H:%M:%S') . " (epoch $tm->epoch)\n" if $ENV{Cron_DEBUG};
            return $tm->epoch;
         }
      }

      $current = $direction > 0 ? $current->plus_seconds($step) : $current->minus_seconds($step);
      print STDERR "Next iteration: Current=" . $current->strftime('%Y-%m-%d %H:%M:%S') . "\n" if $ENV{Cron_DEBUG};
   }

   print STDERR "No match found in window\n" if $ENV{Cron_DEBUG};
   return undef;
}

sub _field_value {
   my ( $self, $tm, $type ) = @_;
   return $tm->second                    if $type eq 'second';
   return $tm->minute                    if $type eq 'minute';
   return $tm->hour                      if $type eq 'hour';
   return $tm->day_of_month              if $type eq 'dom';
   return $tm->month                     if $type eq 'month';
   return quartz_dow( $tm->day_of_week ) if $type eq 'dow';
   return $tm->year                      if $type eq 'year';
}

sub _generate_possible_times {
   my ( $self, $day ) = @_;
   my @fields = @{ $self->{tree}{children} };

   my @seconds = $self->_expand_field( $fields[0], 'second' );
   my @minutes = $self->_expand_field( $fields[1], 'minute' );
   my @hours   = $self->_expand_field( $fields[2], 'hour' );

   my @times;
   for my $hour (@hours) {
      for my $minute (@minutes) {
         for my $second (@seconds) {
            push @times, $day->with_hour($hour)->with_minute($minute)->with_second($second);
         }
      }
   }

   return @times > 1000 ? @times[ 0 .. 999 ] : @times;
}

sub _expand_field {
   my ( $self, $field, $field_type ) = @_;
   my $type = $field->{type};

   my @range = $field_type eq 'hour' ? ( 0 .. 23 ) : ( 0 .. 59 );
   return @range if $type eq 'wildcard' || $type eq 'unspecified';

   if ( $type eq 'single' ) {
      return ( $field->{value} );
   }
   elsif ( $type eq 'range' ) {
      my ( $min, $max ) = map { $_->{value} } @{ $field->{children} };
      return ( $min .. $max );
   }
   elsif ( $type eq 'list' ) {
      return map { $_->{value} } @{ $field->{children} };
   }
   elsif ( $type eq 'step' ) {
      my $base       = $field->{children}[0];
      my $step       = $field->{children}[1]{value};
      my @base_range = $base->{type} eq 'wildcard' ? @range : $self->_expand_field( $base, $field_type );
      return grep { ( $_ - $base_range[0] ) % $step == 0 } @base_range;
   }

   return (0);
}

1;
