### Change History
  # 2001-05-03 Added 'mm/dd/yy' -Ed
  # 2001-03-06 Added even more readable formats. -Piglet
  # 2000-12-16 Added more readable formats. -Simon
  # 2000-12-01 Added 1900 to year in readable.  -Piglet
  # 1999-02-21 Created. -Simon

package Data::Quantity::Time::Timestamp;

require 5;
use strict;
use Carp;
use Time::ParseDate;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Integer '-isasubclass';

# undef = Data::Quantity::Time::Time->scale();
sub scale {
  return 'Second';
}

# $date = Data::Quantity::Time::Time->current();
sub current {
  my $class = shift;
  my $date = $class->new_instance;
  $date->set_udt( time() );
  return $date;
}

sub type {
  return 'temporal', 'absolute';
}

# $seconds_since_1970 = $moment_q->get_udt;
sub get_udt {
  my $moment_q = shift;
  my $udt = $moment_q->value or return;
  return $udt;
}

# $moment_q->set_udt( $seconds_since_1970 );
sub set_udt {
  my $moment_q = shift;
  my $udt = shift;
  $moment_q->value( $udt );
}

use vars qw( $default_readable_format );
$default_readable_format ||= 'year/mon/mday hh:mm:ss';

sub readable {
  my $moment_q = shift;
  my $udt = $moment_q->value or return;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( $udt );
  $mon += 1;
  $year += 1900;
  
  my $style = shift;
  $style ||= $default_readable_format;
  
  # zero-padding
  my ( $ss, $mm, $hh ) = ( $sec, $min, $hour );
  my ( $monmon, $dayday ) = ( $mon, $mday );
  foreach ( $ss, $mm, $hh, $monmon, $dayday ) { 
    $_ = ( '0' x ( 2 - length($_) ) ) . $_;
  }
  my($yy) = ( $year =~ /(\d\d)$/ );

  my $ampm = ( $hour > 11 ) ? 'pm' : 'am';
  my $AMPM = uc($ampm);
  my $h = ( $hour % 12 ) || 12;
  
  if ( $style eq 'year/mon/mday hh:mm:ss' ) {
    return "$year/$mon/$mday $hh:$mm:$ss";
  } elsif ( $style eq 'year/mon/mday hh:mm' ) { 
    return "$year/$mon/$mday $hh:$mm";
  } elsif ( $style eq 'year/mon/mday' ) { 
    return "$year/$mon/$mday";
  } elsif ( $style eq 'yy/mm/dd hh:mm' ) { 
    return "$yy/$monmon/$dayday $hh:$mm";
  } elsif ( $style eq 'yy/mm/dd' ) { 
    return "$yy/$monmon/$dayday";
  } elsif ( $style eq 'mm/dd/yy' ) { 
    return "$monmon/$dayday/$yy";
  } elsif ( $style eq 'yyyy-mm-dd' ) {
    return "$year-$monmon-$dayday";
  } elsif ( $style eq 'yyyy-mm-dd:hh:mm' ) {
    return "$year-$monmon-$dayday:$hh:$mm";
  } elsif ( $style =~ /^DATE: ?(.*?) TIME: ?(.*)$/ ) {
    my ($d_fmt, $t_fmt) = ($1, $2);
    my $date = Data::Quantity::Time::Date->new("$year-$mon-$mday");
    return $date->readable( $d_fmt ) . " $h:$mm$AMPM";
  } elsif ( $style eq 'h:mmPM' ) {
    return "$h:$mm$AMPM";
  } else {
    croak "Unknown timestamp readable format.";
  }
}

sub date {
  my $moment_q = shift;
  my $udt = $moment_q->value or return;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( $udt );
  $mon += 1;
  $year += 1900;
  require Data::Quantity::Time::Date;
  Data::Quantity::Time::Date->new("$year-$mon-$mday");
}

sub time {
  my $moment_q = shift;
  my $udt = $moment_q->value or return;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( $udt );
  require Data::Quantity::Time::Time;
  Data::Quantity::Time::Time->new($hour, $min, $sec);
}

# $value = Data::Quantity::Time::Date->readable_value($number)
# $value = Data::Quantity::Time::Date->readable_value($number, $style)
sub readable_value {
  my $class_or_item = shift;
  my $value = shift;
  $class_or_item->new($value)->readable(@_);
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
  
  my $udt = Time::ParseDate::parsedate($value, 'DATE_REQUIRED' => 1);
  if ($udt) {   
    $date->set_udt($udt);
  } else {
    $date->value( 0 );
  }
}

1;