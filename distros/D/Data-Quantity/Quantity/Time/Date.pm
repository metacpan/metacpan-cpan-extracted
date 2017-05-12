### Data::Quantity::Time::Date - A calendar day on earth during the modern epoch

### Change History
  # 2001-02-21 Added Mon dd, yy format.
  # 2001-02-07 Added yymmdd format.
  # 2000-03-29 Added Month dd, yyyy format.
  # 1999-12-05 Added mm/dd/yy format.
  # 1999-11-22 Added mm/dd/yyyy format.
  # 1999-08-13
  # 1999-03-28 Added default format and error handling for readable method
  # 1998-12-02 Created. -Simon

package Data::Quantity::Time::Date;

require 5;
use strict;
use Carp;

use Time::Local;
use Time::JulianDay;
use Time::ParseDate;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Integer '-isasubclass';

use Data::Quantity::Time::Timestamp;
use Data::Quantity::Time::Year;
use Data::Quantity::Time::MonthOfYear;
use Data::Quantity::Time::DayOfMonth;
use Data::Quantity::Time::DayOfWeek;
use Data::Quantity::Time::YearAndMonth;

# undef = Data::Quantity::Time::Date->scale();
sub scale {
  return 'Date';
}

sub type {
  return 'temporal', 'absolute';
}

# $date = Data::Quantity::Time::Date->current();
sub current {
  my $class = shift;
  my $date = $class->new_instance;
  $date->set_udt( time() );
  return $date;
}

# $quantity->init( $n_val );
sub init {
  my $num_q = shift;
  
  my $n_val = shift;
  my $numerals = $num_q->numeric_value( $n_val );
  if ( defined $numerals ) {
    $num_q->value( $numerals );
  } else {
    $num_q->set_from_string( $n_val );
  }
}

# $date->set_from_string( $value );
sub set_from_string {
  my ($date, $value) = @_;
  
  if ($value =~ /^\s*(?=1|2)(\d{4})\D?(\d{2})\D?(\d{2})\s*$/) {
    my ($year, $month, $day) = ($1, $2, $3);
    $date->set_from_raw_ymd($year, $month, $day);
  } else {
    my $udt = Time::ParseDate::parsedate($value, 'DATE_REQUIRED' => 1);
    if ($udt) {   
      $date->set_udt($udt);
    } else {
      $date->value( 0 );
    }
  }
}

# $dow_q = $date_q->dow();
sub dow {
  my $date_q = shift;
  my $j_day = $date_q->value or return;
  Data::Quantity::Time::DayOfWeek->new( day_of_week($j_day) || 7 );
}

# $y_q, $m_q, $d_q = $date_q->ymd();
sub ymd {
  my $date_q = shift;
  my $j_day = $date_q->value || return;
  my ($y, $m, $d) = inverse_julian_day($j_day);
  return (
    Data::Quantity::Time::Year->new( $y ), 
    Data::Quantity::Time::MonthOfYear->new( $m ), 
    Data::Quantity::Time::DayOfMonth->new( $d )
  );
}

# $y_q, $m_q, $d_q = $date_q->ymd();
sub raw_ymd {
  my $date_q = shift;
  my $j_day = $date_q->value || return;
  return inverse_julian_day($j_day);
}

# $date_q->set_from_raw_ymd( $y, $m, $d );
sub set_from_raw_ymd {
  my $date_q = shift;
  $date_q->value( julian_day( @_ ) );
}

# Data::Quantity::Time::Date->new_from_ymd( $y_q, $m_q, $d_q );
sub new_from_ymd {
  my $class = shift;
  my $date = $class->new_instance;
  $date->set_from_ymd( @_ );
  return $date;
}

# $date->set_from_ymd( $y_q, $m_q, $d_q );
sub set_from_ymd {
  my $date_q = shift;
  my ($y_q, $m_q, $d_q) = @_;
  my ($y, $m, $d) = map { $_->value } ($y_q, $m_q, $d_q);
  $date_q->value( julian_day($y, $m, $d) );
}

# $year_and_month_q = $date_q->year_and_month;
sub year_and_month {
  my $date_q = shift;
  my $j_day = $date_q->value or return;
  my ($y, $m, $d) = inverse_julian_day($j_day);
  return Data::Quantity::Time::YearAndMonth->new( Data::Quantity::Time::Year->new($y), Data::Quantity::Time::MonthOfYear->new($m) );
}

# $seconds_since_1970 = $date_q->first_second;
sub first_second {
  my $date_q = shift;
  my $j_day = $date_q->value or return;
  return Data::Quantity::Time::Timestamp->new( jd_secondslocal($j_day, 0, 0, 0) );
}

# $seconds_since_1970 = $date_q->last_second;
sub last_second {
  my $date_q = shift;
  my $j_day = $date_q->value or return;
  return Data::Quantity::Time::Timestamp->new( jd_secondslocal($j_day, 23, 59, 59) );
}

# $seconds_since_1970 = $date_q->get_udt;
sub get_udt {
  my $date_q = shift;
  my $j_day = $date_q->value or return;
  return jd_secondslocal($j_day, 0, 0, 0);
}

# $date_q->set_udt( $seconds_since_1970 );
sub set_udt {
  my $date_q = shift;
  my $udt = shift;
  
  $date_q->value( local_julian_day($udt) );
}

use vars qw( $default_readable_format );
$default_readable_format ||= 'mm/dd/yyyy';

# $string = $quantity->readable( @_ );
  # offer multiple modes, incl POSIX::strftime() or Time::CTime::strftime()
sub readable {
  my $date_q = shift;
  my $style = shift;
  $style ||= $default_readable_format;
  my $j_day = $date_q->value or return;
  if ( $style eq 'dd Month yy' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return join ' ', $d_q->readable, $m_q->readable, $y_q->readable;
  } elsif ( $style eq 'Month dd, yyyy' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return $m_q->readable . ' ' . $d_q->readable . ', ' . $y_q->readable;
  } elsif ( $style eq 'Mon dd, yyyy' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return $m_q->readable('short') . ' ' . $d_q->readable . ', ' . $y_q->readable;
  } elsif ( $style eq 'Mon dd, yy' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return $m_q->readable('short') . ' ' . $d_q->readable . ', ' . $y_q->two_digit_window;
  } elsif ( $style eq 'Day, Mon dd, yy' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    my $dow = $date_q->dow();
    return $dow->readable('short') . ', ' . $m_q->readable('short') . ' ' . $d_q->readable . ', ' . $y_q->two_digit_window;
  } elsif ( $style eq 'Day, Mon dd' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    my $dow = $date_q->dow();
    return $dow->readable('short') . ', ' . $m_q->readable('short') . ' ' . $d_q->readable;
  } elsif ( $style eq 'Mon dd' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return $m_q->readable('short') . ' ' . $d_q->readable;
  } elsif ( $style eq 'dd Mon yy' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return $d_q->readable . ' ' . $m_q->readable('short') . ' ' . $y_q->two_digit_window;
  } elsif ( $style eq 'Month yyyy' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return join ' ', $m_q->readable, $y_q->zero_padded;
  } elsif ( $style eq 'yyyy-mm-dd' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return join '-', $y_q->zero_padded, $m_q->zero_padded, $d_q->zero_padded;
  } elsif ( $style eq 'mm/dd/yyyy' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return join '/', $m_q->zero_padded, $d_q->zero_padded, $y_q->zero_padded;
  } elsif ( $style eq 'mm/dd/yy' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return join '/', $m_q->zero_padded, $d_q->zero_padded, $y_q->two_digit_window;
  } elsif ( $style eq 'yymmdd' ) {
    my ($y_q, $m_q, $d_q) = $date_q->ymd();
    return join '', $y_q->two_digit_window(), $m_q->zero_padded, $d_q->zero_padded;
  } else {
    croak "Unknown date readable format: '$style'";
  }
}

# $value = Data::Quantity::Time::Date->readable_value($number)
# $value = Data::Quantity::Time::Date->readable_value($number, $style)
sub readable_value {
  my $class_or_item = shift;
  my $value = shift;
  $class_or_item->new($value)->readable(@_);
}

1;

__END__

# Either textual or raw-numeric form in...
$d = Data::Quantity::Time::Date->new("13 Aug 1999"); 
$d = Data::Quantity::Time::Date->new(2451404); 

# Stored as number of days since some arbitrary day seven thousand years ago
print $d->value;
2451404

# Various human readable formats out...
print $d->readable; 
13 August 1999

print  $d->readable("yyyy-mm-dd"); 
1999-08-13

