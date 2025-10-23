package Cron::Toolkit::Tree::MatchVisitor;
use strict;
use warnings;
use parent 'Cron::Toolkit::Tree::Visitor';
use List::Util                  qw(any);
use Cron::Toolkit::Tree::Utils qw(quartz_dow);

sub new {
   my ( $class, %args ) = @_;
   $args{value} //= 0;
   $args{tm}    //= undef;
   return $class->SUPER::new(%args);
}

sub visit {
   my ( $self, $node, @child_results ) = @_;
   my $type = $node->{type};
   if ( $type eq 'wildcard' || $type eq 'unspecified' ) {
      return 1;
   }

   my $val = 0 + $self->{value};
   if ( $type eq 'single' ) {
      return $val == ( 0 + $node->{value} ) ? 1 : 0;
   }
   elsif ( $type eq 'step_value' ) {
      return 0 + $node->{value};
   }
   elsif ( $type eq 'range' ) {
      my $min = 0 + $node->{children}[0]{value};
      my $max = 0 + $node->{children}[1]{value};
      return $val >= $min && $val <= $max ? 1 : 0;
   }
   elsif ( $type eq 'list' ) {
      my $match = 0;
      for my $child ( @{ $node->{children} } ) {
         $match = 1 if $val == ( 0 + $child->{value} );
      }
      return $match;
   }

   #elsif ( $type eq 'list' ) {
   #   return any { $val == ( 0 + $_->{value} ) } @{ $node->{children} } ? 1 : 0;
   #}
   elsif ( $type eq 'step' ) {
      my $step = 0 + $node->{children}[1]{value};
      return 0 if $step <= 0;
      return $self->_matches_step( $node->{children}[0], $step, $val );
   }
   elsif ( $type eq 'last' ) {
      return $self->_matches_last( $node, $self->{tm} );
   }
   elsif ( $type eq 'lastW' ) {
      return $self->_matches_lastw( $node, $self->{tm} );
   }
   elsif ( $type eq 'nth' ) {
      return $self->_matches_nth( $node, $self->{tm} );
   }
   elsif ( $type eq 'nearest_weekday' ) {
      return $self->_matches_nearest_weekday( $node, $self->{tm} );
   }
   return 0;
}

sub _matches_step {
   my ( $self, $base, $step, $value ) = @_;
   if ( $base->{type} eq 'wildcard' ) {
      return $value % $step == 0 ? 1 : 0;
   }
   elsif ( $base->{type} eq 'single' ) {
      my $base_val = 0 + $base->{value};
      return $value >= $base_val && ( $value - $base_val ) % $step == 0 ? 1 : 0;
   }
   elsif ( $base->{type} eq 'range' ) {
      my $min = 0 + $base->{children}[0]{value};
      my $max = 0 + $base->{children}[1]{value};
      return $value >= $min && $value <= $max && ( $value - $min ) % $step == 0 ? 1 : 0;
   }
   return 0;
}

sub _matches_last {
   my ( $self, $field, $tm ) = @_;
   my $dom           = $tm->day_of_month;
   my $days_in_month = $tm->length_of_month;
   if ( $field->{value} eq 'L' ) {
      return $dom == $days_in_month ? 1 : 0;
   }
   if ( $field->{value} =~ /L-(\d+)/ ) {
      my $offset = 0 + $1;
      return $dom == $days_in_month - $offset ? 1 : 0;
   }
   return 0;
}

sub _matches_lastw {
   my ( $self, $field, $tm ) = @_;
   my $dom           = $tm->day_of_month;
   my $days_in_month = $tm->length_of_month;
   my $candidate     = $days_in_month;
   while ( $candidate >= 1 ) {
      my $test_tm  = $tm->with_day_of_month($candidate);
      my $test_dow = quartz_dow( $test_tm->day_of_week );
      if ( $test_dow >= 2 && $test_dow <= 6 ) {
         return $dom == $candidate ? 1 : 0;
      }
      $candidate--;
   }
   return 0;
}

sub _matches_nth {
   my ( $self, $field, $tm ) = @_;
   my ( $dow, $nth ) = $field->{value} =~ /(\d+)#(\d+)/;
   $dow = 0 + $dow;
   $nth = 0 + $nth;
   my $target_dow  = $dow;
   my $actual_nth  = 0;
   my $current_dom = $tm->day_of_month;
   for ( my $d = 1 ; $d <= $current_dom ; $d++ ) {
      my $test_tm = $tm->with_day_of_month($d);
      if ( quartz_dow( $test_tm->day_of_week ) == $target_dow ) {
         $actual_nth++;
      }
   }
   my $is_target = ( quartz_dow( $tm->day_of_week ) == $target_dow );
   return $is_target && $actual_nth == $nth ? 1 : 0;
}

sub _matches_nearest_weekday {
   my ( $self, $field, $tm ) = @_;
   my ($day) = $field->{value} =~ /(\d+)W/;
   $day = 0 + $day;
   my $dom           = $tm->day_of_month;
   my $dow           = quartz_dow( $tm->day_of_week );
   my $days_in_month = $tm->length_of_month;
   return 0 if $day < 1 || $day > $days_in_month;
   my $target_tm  = $tm->with_day_of_month($day);
   my $target_dow = quartz_dow( $target_tm->day_of_week );

   if ( $target_dow >= 2 && $target_dow <= 6 ) {
      return $dom == $day ? 1 : 0;
   }
   my $before     = $target_tm->minus_days(1);
   my $after      = $target_tm->plus_days(1);
   my $before_dow = quartz_dow( $before->day_of_week );
   my $after_dow  = quartz_dow( $after->day_of_week );
   if ( $before_dow >= 2 && $before_dow <= 6 && $dom == $day - 1 ) {
      return 1;
   }
   if ( $after_dow >= 2 && $after_dow <= 6 && $dom == $day + 1 && $day + 1 <= $days_in_month ) {
      return 1;
   }
   return 0;
}

1;
