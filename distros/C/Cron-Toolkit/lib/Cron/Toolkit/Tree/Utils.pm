package Cron::Toolkit::Tree::Utils;
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK = qw(
  format_time num_to_ordinal field_unit join_parts fill_template is_midnight time_suffix quartz_dow
  quartz_dow_normalize unix_dow_normalize %aliases
  ordinal_list step_ordinal complex_join normalize validate generate_list_desc %limits %dow_map_unix
  %month_map %dow_map_quartz %month_names %day_names %nth_names %unit_labels %ordinal_suffix %joiners %templates
);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );
our %month_map = (
   JAN => 1,
   JANUARY => 1,
   FEB => 2,
   FEBRUARY => 2,
   MAR => 3,
   MARCH => 3,
   APR => 4,
   APRIL => 4,
   MAY => 5,
   JUN => 6,
   JUNE => 6,
   JUL => 7,
   JULY => 7,
   AUG => 8,
   AUGUST => 8,
   SEP => 9,
   SEPTEMBER => 9,
   OCT => 10,
   OCTOBER => 10,
   NOV => 11,
   NOVEMBER => 11,
   DEC => 12,
   DECEMBER => 12
);
our %dow_map_quartz = (
   SUN => 1,
   SUNDAY => 1,
   MON => 2,
   MONDAY => 2,
   TUE => 3,
   TUESDAY => 3,
   WED => 4,
   WEDNESDAY => 4,
   THU => 5,
   THURSDAY => 5,
   FRI => 6,
   FRIDAY => 6,
   SAT => 7,
   SATURDAY => 7
);
our %dow_map_unix = (
   SUN => 7,
   SUNDAY => 7,
   MON => 1,
   MONDAY => 1,
   TUE => 2,
   TUESDAY => 2,
   WED => 3,
   WEDNESDAY => 3,
   THU => 4,
   THURSDAY => 4,
   FRI => 5,
   FRIDAY => 5,
   SAT => 6,
   SATURDAY => 6
);
our %month_names = (
   1 => 'January',
   2 => 'February',
   3 => 'March',
   4 => 'April',
   5 => 'May',
   6 => 'June',
   7 => 'July',
   8 => 'August',
   9 => 'September',
   10 => 'October',
   11 => 'November',
   12 => 'December'
);
our %day_names = ( 1 => 'Sunday', 2 => 'Monday', 3 => 'Tuesday', 4 => 'Wednesday', 5 => 'Thursday', 6 => 'Friday', 7 => 'Saturday' );
our %nth_names = ( 1 => 'first', 2 => 'second', 3 => 'third', 4 => 'fourth', 5 => 'fifth' );
our %unit_labels = (
   second => [ 'second', 'seconds' ],
   minute => [ 'minute', 'minutes' ],
   hour => [ 'hour', 'hours' ],
   dom => [ 'day', 'days' ],
   month => [ 'month', 'months' ],
   dow => [ 'day of the week', 'days of the week' ],
   year => [ 'year', 'years' ]
);
our %limits = (
   second => [ 0, 59 ],
   minute => [ 0, 59 ],
   hour => [ 0, 23 ],
   dom => [ 1, 31 ],
   month => [ 1, 12 ],
   dow => [ 1, 7 ],
   year => [ 1970, 2099 ]
);

our %aliases = (
    '@yearly' => '0 0 0 1 1 ? *',
    '@annually' => '0 0 0 1 1 ? *',
    '@monthly' => '0 0 0 L ? * *',
    '@weekly' => '0 0 0 ? * ? *',
    '@daily' => '0 0 0 * * ? *',
    '@midnight' => '0 0 0 * * ? *',
    '@hourly' => '0 0 * * * ? *',
);

our %ordinal_suffix = ( 1 => 'st', 21 => 'st', 31 => 'st', 2 => 'nd', 22 => 'nd', 3 => 'rd', 23 => 'rd', map { $_ => 'th' } grep { !/1[123]$/ } 4 .. 30 );
our %joiners = ( list => 'and', range => 'through' );
our %templates = (
   every_N_second => 'every {step} seconds',
   every_N_minute => 'every {step} minutes',
   every_N_hour => 'every {step} hours',
   dom_single_every => 'on the {ordinal} of every month',
   dom_range_every => 'the {start} through {end} of every month',
   dom_list => '{list} of every month',
   dom_last => 'on the last day of every month',
   dom_lw => 'on the last weekday of every month',
   dow_single => 'every {day}',
   dow_range => 'every {start} through {end}',
   dow_list => '{list}',
   dow_nth => 'on the {nth} {day} of every month',
   month_range => 'from {start} to {end}',
   year_in => 'every day in {year}',
   year_range => 'every day from {start} to {end}',
   dom_last_offset => 'on the {ordinal} last day of every month',
   dom_nearest_weekday => 'on the nearest weekday to the {ordinal} of every month',
   step_range => 'every {step} minutes from {start} to {end} past {hour}',
   step_single => 'every {step} hours starting at {start}',
   dom_special_month_range => 'the {dom_desc} of {month_range}',
   dow_nth_month_range => 'on the {nth} {day} of {month_range}',
   dom_single_year_single => 'on the {ordinal} of every month in {year}',
   dom_list_year_range => 'on the {list} of every month {year_range}',
   dow_range_year_range => 'every {start} through {end} {year_range}',
   dow_list_year_range => 'every {list} {year_range}',
   dom_step_month_range => 'every {step} days starting on the {start} {month_range}',
   dow_single_month_range => 'every {day} {month_range}',
   dow_range_month_range => 'every {start} through {end} {month_range}',
   dom_single_month_single => 'on the {ordinal} of every month in {month}',
   dow_single_year => 'every {day} in {year}',
);
sub plural_unit {
   my ( $unit, $count ) = @_;
   return $count == 1 ? $unit : $unit . 's';
}
sub generate_list_desc {
   my ( $field_type, $children ) = @_;
   return '' unless $children && @$children;
   # COLLAPSE CONSECUTIVE FOR DOM (1,2,3,4,5 → first through fifth)
   if ( $field_type eq 'dom' ) {
      my @values = sort { $a->{value} <=> $b->{value} } grep { $_->{type} eq 'single' } @$children;
      if ( @values == 5 && $values[0]{value} == 1 && $values[-1]{value} == 5 ) {
         return "the first through fifth of every month";
      }
   }
   my @descs = map {
          $_->{type} eq 'single'
        ? $field_type eq 'dom'
           ? num_to_ordinal( $_->{value} )
           : $field_type eq 'dow' ? $day_names{ $_->{value} }
         : $field_type eq 'month' ? $month_names{ $_->{value} } || $_->{value}
         : $_->{value}
        : $_->to_english($field_type)
   } @$children;
   my $list = join_parts(@descs);
   return
       $field_type eq 'dom' ? "the $list of every month"
     : $field_type eq 'dow' ? "every $list"
     : $field_type eq 'month' ? "in $list"
     : $list;
}
sub fill_template { my ( $id, $data ) = @_; my $tpl = $templates{$id} or return ''; $tpl =~ s/{(\w+)}/$data->{$1}||''/ge; return $tpl; }
sub num_to_ordinal { my $n = shift // return ''; return $nth_names{$n} // "$n${ordinal_suffix{$n}//''}"; }
sub join_parts {
   my @p = grep { defined && length } @_;
   return @p == 0 ? '' : @p == 1 ? $p[0] : @p == 2 ? "$p[0] $joiners{list} $p[1]" : join( ', ', @p[ 0 .. $#p - 1 ] ) . " $joiners{list} $p[-1]";
}
sub format_time {
   my ( $s, $m, $h ) = @_;
   $h //= 0;
   $m //= 0;
   $s //= 0;
   return '' unless $h =~ /^\d+$/ && $m =~ /^\d+$/ && $s =~ /^\d+$/;
   my $h12 = $h % 12;
   $h12 = 12 if $h12 == 0;
   return sprintf '%d:%02d:%02d %s', $h12, $m, $s, ( $h >= 12 ) ? 'PM' : 'AM';
}
sub is_midnight { my ( $h, $m, $s ) = @_; return $h == 0 && $m == 0 && $s == 0; }
sub time_suffix { my $h = shift; return $h == 0 ? 'midnight' : $h == 12 ? 'noon' : ''; }
sub field_unit { my ( $f, $c ) = @_; $c //= 1; my ( $s, $p ) = @{ $unit_labels{$f} }; return $c == 1 ? $s : $p; }
sub quartz_dow { my ($iso_dow) = @_; return $iso_dow == 7 ? 1 : $iso_dow + 1; }
sub unix_dow_normalize {
   my $dow = shift;
   while ( my ( $name, $num ) = each %dow_map_unix ) { $dow =~ s/\b\Q$name\E\b/$num/gi; }
   if ( $dow =~ /\// ) { # step pattern special handling
      my ( $base, $step ) = split( '/', $dow );
      $base =~ s/\b(\d)\b/$1+1/eeg;
      $base =~ s/\b0\b|8/1/g;
      $dow = join( '/', ( $base, $step ) );
   }
   else {
      $dow =~ s/\b(\d)\b/$1+1/eeg;
      $dow =~ s/\b0\b|8/1/g;
   }
   return $dow;
}
sub quartz_dow_normalize {
   my $dow = shift;
   while ( my ( $name, $num ) = each %dow_map_quartz ) { $dow =~ s/\b\Q$name\E\b/$num/gi; }
   return $dow;
}
sub ordinal_list {
   join( ', ', map { num_to_ordinal($_) } @_ );
}
sub step_ordinal { my $n = shift; return $n . ( $n == 1 ? 'st' : $n == 2 ? 'nd' : $n == 3 ? 'rd' : 'th' ); }
sub complex_join { join( ', ', @_ ) . ' at {time}'; }
sub normalize {
   my ($expr) = @_;
   $expr = uc $expr;
   $expr =~ s/\s+/ /g;
   $expr =~ s/^\s+|\s+$//g;
   while ( my ( $name, $num ) = each %month_map ) { $expr =~ s/\b\Q$name\E\b/$num/gi; }
   while ( my ( $name, $num ) = each %dow_map_quartz ) { $expr =~ s/\b\Q$name\E\b/$num/gi; }
   my @fields = split / /, $expr;
   die "QUARTZ: Expected 6-7 fields, got " . scalar(@fields) unless @fields == 6 || @fields == 7;
   push @fields, '*' if @fields == 6;
   return join( ' ', @fields );
}
sub validate {
   my ( $expr, $field_type ) = @_;
   $field_type ||= 'all';
   die "Syntax: Invalid chars in $field_type: $expr" if $expr =~ /[^0-9*,\/\-L#W?]/i;
   return 1 if $expr eq '*' || $expr eq '?';
   die "Syntax: Malformed $field_type: $expr" if $expr =~ /^L(W?)-[^0-9]/;
   if ( $expr =~ /^(\d+)(?:[\/\-#W])?(\d*)$/ ) {
      my ( $val1, $val2 ) = ( $1, $2 || 0 );
      my ( $min, $max ) = @{ $limits{$field_type} };
      die "$field_type $val1 out of range [$min-$max]" if $val1 < $min || $val1 > $max;
      die "$field_type nth $val2 invalid (max 5)" if $field_type eq 'dow' && $expr =~ /#\d+/ && $val2 > 5;
   }
   # Check for invalid ranges (e.g., 5-1 where start > end)
   if ( $expr =~ /^(\d+)-(\d+)$/ ) {
      my ( $start, $end ) = ( $1, $2 );
      my ( $min, $max ) = @{ $limits{$field_type} };
      die "invalid $field_type range: $start-$end (start must be <= end)" if $start > $end;
      die "$field_type $start out of range [$min-$max]" if $start < $min || $start > $max;
      die "$field_type $end out of range [$min-$max]" if $end < $min || $end > $max;
   }
   return 1;
}
1;
