package Cron::Toolkit::Tree::Composer;
use strict;
use warnings;
use Cron::Toolkit::Tree::Utils qw(:all);

sub new {
    my ($class, %args) = @_;
    bless { locale => $args{locale} // 'en' }, $class;
}
sub describe {
    my ($self, $root, $locale) = @_;
    $locale //= $self->{locale};
    if ($locale ne 'en') {
        warn "Locale stub: English fallback.";
        $locale = 'en';
    }
   my @fields      = @{ $root->{children} };
   my @field_types = qw(second minute hour dom month dow year);
   for my $i ( 0 .. 6 ) {
      $fields[$i]{field_type} = $field_types[$i] if $fields[$i];
   }
   my $sec         = ( $fields[0]{type} eq 'single' ) ? $fields[0]{value} : undef;
   my $min         = ( $fields[1]{type} eq 'single' ) ? $fields[1]{value} : undef;
   my $hour        = ( $fields[2]{type} eq 'single' ) ? $fields[2]{value} : undef;
   my $time_prefix = format_time( $sec // 0, $min // 0, $hour // 0 );
   $time_prefix = "at $time_prefix" if $time_prefix;
   my @phrases;
   for my $field (@fields) {
      push @phrases, $self->template_for_field( $field, \@fields );
   }
   push @phrases, $time_prefix if $time_prefix;
   $self->_fuse_combos( \@phrases, \@fields );
   my @time_phrases = grep { $_ } @phrases[ 0 .. 2 ];
   my $time_str     = join( ' ', @time_phrases );
   return $time_str if $time_str =~ /^every \d+ (seconds?|minutes?|hours?)/;
   my @date_phrases = grep { $_ } @phrases[ 3 .. 6 ];
   my $date_str     = join( ' ', @date_phrases );
   $date_str = "on $date_str" if $date_str && $date_phrases[0] =~ /^(the|last)/;

   if ( defined $sec && defined $min && defined $hour && $sec == 0 && $min == 0 && $hour == 0 ) {
      $time_prefix = 'at midnight' . ( $date_str ? ' ' : '' );
   }
   return ( join( ' ', grep { $_ } ( $time_prefix, $date_str ) ) || 'every second' ) =~ s/\s+/ /gr;
}

sub _fuse_combos {
   my ( $self, $phrases, $fields ) = @_;

   # 🔥 ALL ARRAY REF FIXED
   # DOM Special + Month
   if ( $phrases->[3] && $phrases->[4] && $fields->[3]{type} =~ /^(last|lastW|nearest_weekday|step)$/ ) {
      my $data = { dom_desc => $phrases->[3], month_range => $phrases->[4] };
      $phrases->[3] = fill_template( 'dom_special_month_range', $data );
      $phrases->[4] = '';
   }

   # 🔥 FIXED: DOM Single + Month Single
   if ( $phrases->[3] && $phrases->[4] && $fields->[3]{type} eq 'single' && $fields->[4]{type} eq 'single' ) {
      my $data = { ordinal => num_to_ordinal( $fields->[3]{value} ), month => $month_names{ $fields->[4]{value} } };
      $phrases->[3] = fill_template( 'dom_single_month_single', $data );
      $phrases->[4] = '';
   }

   # DOW Nth + Month
   if ( $phrases->[5] && $phrases->[4] && $fields->[5]{type} eq 'nth' ) {
      my ( $day, $nth ) = $fields->[5]{value} =~ /(\d+)#(\d+)/;
      my $data = { nth => num_to_ordinal($nth), day => $day_names{$day}, month_range => $phrases->[4] };
      $phrases->[5] = fill_template( 'dow_nth_month_range', $data );
      $phrases->[4] = '';
   }

   # 🔥 FIXED: DOM Single + Year (Allow DOW=?)
   if (  $phrases->[3]
      && $phrases->[6]
      && $fields->[3]{type} eq 'single'
      && $fields->[6]{type} ne 'wildcard'
      && ( $fields->[5]{type} eq 'wildcard' || $fields->[5]{type} eq 'unspecified' ) )
   {
      my $data = { ordinal => num_to_ordinal( $fields->[3]{value} ), year => $fields->[6]{value} };
      $phrases->[3] = fill_template( 'dom_single_year_single', $data );
      $phrases->[6] = '';
   }
   elsif ( $phrases->[3] && $phrases->[6] && $fields->[3]{type} eq 'list' && $fields->[6]{type} ne 'wildcard' ) {
      my $data = { list => $phrases->[3], year_range => $phrases->[6] };
      $phrases->[3] = fill_template( 'dom_list_year_range', $data );
      $phrases->[6] = '';
   }

   # Step on DOM + Month
   if ( $phrases->[3] && $phrases->[4] && $fields->[3]{type} eq 'step' ) {
      my $data = { step => $fields->[3]{children}[1]{value}, start => num_to_ordinal( $fields->[3]{children}[0]{children}[0]{value} ), month_range => $phrases->[4] };
      $phrases->[3] = fill_template( 'dom_step_month_range', $data );
      $phrases->[4] = '';
   }

   # DOW Single + Month
   if ( $phrases->[5] && $phrases->[4] && $fields->[5]{type} eq 'single' ) {
      my $data = { day => $day_names{ $fields->[5]{value} }, month_range => $phrases->[4] };
      $phrases->[5] = fill_template( 'dow_single_month_range', $data );
      $phrases->[4] = '';
   }

   # DOW Range + Month
   if ( $phrases->[5] && $phrases->[4] && $fields->[5]{type} eq 'range' ) {
      my $data = { start => $day_names{ $fields->[5]{children}[0]{value} }, end => $day_names{ $fields->[5]{children}[1]{value} }, month_range => $phrases->[4] };
      $phrases->[5] = fill_template( 'dow_range_month_range', $data );
      $phrases->[4] = '';
   }

   # DOW Single + Year
   if ( $phrases->[5] && $phrases->[6] && $fields->[5]{type} eq 'single' && $fields->[6]{type} ne 'wildcard' ) {
      my $data = { day => $day_names{ $fields->[5]{value} }, year => $fields->[6]{value} };
      $phrases->[5] = fill_template( 'dow_single_year', $data );
      $phrases->[6] = '';
   }
}

sub template_for_field {
   my ( $self, $field, $fields ) = @_;
   my $type = $field->{type};
   my $ft   = $field->{field_type} // '';
   return '' if $type eq 'wildcard' || $type eq 'unspecified';
   my $data = {};
   if ( $type eq 'list' ) {
      return generate_list_desc( $ft, $field->{children} );
   }
   if ( $type eq 'single' && $ft eq 'dom' ) {
      $data->{ordinal} = num_to_ordinal( $field->{value} );
      return fill_template( 'dom_single_every', $data );
   }
   elsif ( $type eq 'single' && $ft eq 'month' ) {
      return $month_names{ $field->{value} };
   }
   elsif ( $type eq 'single' && $ft eq 'dow' ) {
      $data->{day} = $day_names{ $field->{value} };
      return fill_template( 'dow_single', $data );
   }
   elsif ( $type eq 'single' && $ft eq 'year' ) {
      $data->{year} = $field->{value};
      return fill_template( 'year_in', $data );
   }
   elsif ( $type eq 'step' ) {
      my $step = $field->{children}[1]{value};
      my $base = $field->{children}[0];
      if ( $base->{type} eq 'wildcard' ) {
         $data->{step} = $step;
         my $tmpl = "every_N_$ft";
         return fill_template( $tmpl, $data );
      }
      else {
         $data->{step}  = $step;
         $data->{start} = $base->{children}[0]{value};
         if ( $base->{type} eq 'single' ) {
            $data->{start} = $base->{value};
            return fill_template( 'step_single', $data );
         }
         else {
            $data->{end}  = $base->{children}[1]{value};
            $data->{hour} = $fields->[2]{value} || 0;
            return fill_template( 'step_range', $data );
         }
      }
   }
   elsif ( $type eq 'range' && $ft =~ /^(second|minute|hour)$/ ) {
      $data->{start} = $field->{children}[0]{value};
      $data->{end}   = $field->{children}[1]{value};
      return fill_template( "time_range_$ft", $data );
   }
   elsif ( $type eq 'range' && $ft eq 'dom' ) {
      $data->{start} = num_to_ordinal( $field->{children}[0]{value} );
      $data->{end}   = num_to_ordinal( $field->{children}[1]{value} );
      return fill_template( 'dom_range_every', $data );
   }
   elsif ( $type eq 'range' && $ft eq 'month' ) {
      $data->{start} = $month_names{ $field->{children}[0]{value} };
      $data->{end}   = $month_names{ $field->{children}[1]{value} };
      return fill_template( 'month_range', $data );
   }
   elsif ( $type eq 'range' && $ft eq 'dow' ) {
      $data->{start} = $day_names{ $field->{children}[0]{value} };
      $data->{end}   = $day_names{ $field->{children}[1]{value} };
      return fill_template( 'dow_range', $data );
   }
   elsif ( $type eq 'range' && $ft eq 'year' ) {
      $data->{start} = $field->{children}[0]{value};
      $data->{end}   = $field->{children}[1]{value};
      return fill_template( 'year_range', $data );
   }
   elsif ( $type eq 'last' && $ft eq 'dom' ) {
      if ( $field->{value} =~ /L-(\d+)/ ) {
         $data->{ordinal} = num_to_ordinal($1);
         return fill_template( 'dom_last_offset', $data );
      }
      return fill_template( 'dom_last', $data );
   }
   elsif ( $type eq 'lastW' && $ft eq 'dom' ) {
      return fill_template( 'dom_lw', $data );
   }
   elsif ( $type eq 'nth' && $ft eq 'dow' ) {
      my ( $day, $nth ) = $field->{value} =~ /(\d+)#(\d+)/;
      $data->{nth} = num_to_ordinal($nth);
      $data->{day} = $day_names{$day};
      return fill_template( 'dow_nth', $data );
   }
   elsif ( $type eq 'nearest_weekday' && $ft eq 'dom' ) {
      my ($day) = $field->{value} =~ /(\d+)W/;
      $data->{ordinal} = num_to_ordinal($day);
      return fill_template( 'dom_nearest_weekday', $data );
   }
   return '';
}
1;
