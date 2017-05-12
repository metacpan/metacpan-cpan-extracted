### Data::Quantity::Number::Number;

### Change History
  # 2000-12-01 Fixed "use of undefined value" in numeric_value
  # 1999-08-02 Stripped and corrected separators in numeric_value().
  # 1998-12-02 Created. -Simon

package Data::Quantity::Number::Number;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Abstract::Base '-isasubclass';

# $clone_q = $quantity->new_instance();
# $empty_q = Data::Quantity::Number::Number->new_instance();
sub new_instance {
  my $referent = shift;
  my $class = ref($referent) || $referent;
  my $num = ( ref($referent) ? $$referent : undef );
  my $num_q = \$num;
  bless $num_q, $class;
}

# $quantity->init( $n_val );
sub init {
  my $num_q = shift;
  
  my $n_val = shift;
  my $numerals = $num_q->numeric_value( $n_val );
  if ( defined $numerals ) {
    $num_q->value( $numerals );
  } else {
    $num_q->not_a_number( $n_val );
  }
}

# $n_val = $quantity->value;
# $quantity->value( $n_val );
sub value {
  my $num_q = shift;
  croak "object method" if ! ref $num_q;
  
  return $$num_q if ( ! scalar @_ );
  
  my $n_val = shift;
  # if ( ! defined $n_val || length($n_val) < 1 ) {
  #   $$num_q = undef;
  #   return;
  # } 
  
  $$num_q = $n_val;
}

# $quantity->not_a_number;
# $quantity->not_a_number( $value );
sub not_a_number {
  my $num_q = shift;
  if ( scalar @_ ) { $$num_q = shift; }
  bless $num_q, 'Data::Quantity::Number::NAN';
}

# $string = $quantity->readable( @_ );
sub readable {
  my $num_q = shift;
  croak "object method" if ! ref $num_q;
  $num_q->readable_value( $num_q->value(), @_ );
}

# undef = Data::Quantity::Number::Number->scale();
sub scale {
  return undef;
}

use vars qw( $ThousandsSeparator $DecimalSeparator $DefaultPlaces );
$ThousandsSeparator = ',';
$DecimalSeparator = '.';
$DefaultPlaces = undef;

# $n_val = Data::Quantity::Number::Number->numeric_value( $candidate_n_val );
sub numeric_value {
  my $class_or_item = shift;
  my $n_val = shift;
  $n_val =~ /\A
    \-? 
    (?: \d | \Q$ThousandsSeparator\E \d{3} )*
    (?: \Q$DecimalSeparator\E \d+ )? 
    (?: [eE] \-? \d+ )?
  \Z/x 
    or return undef;
  $n_val =~ s/\Q$ThousandsSeparator\E//g;
  $n_val =~ s/\Q$DecimalSeparator\E/\./g unless ( $DecimalSeparator eq '.' );
  $n_val;
}

# $string = $quantity->readable_value($n_val);
# $string = $quantity->readable_value($n_val, $places);
# $string = Data::Quantity::Number::Number->readable_value($n_val);
# $string = Data::Quantity::Number::Number->readable_value($n_val, $places);
sub readable_value {
  my $class_or_item = shift;
  my $n_val = shift;
  my $places = shift || $DefaultPlaces || undef;
  
  my ($int, $dec) = split(/\./, $n_val, 2);
  
  $int = reverse join($ThousandsSeparator, reverse($int) =~ m/(\d{1,3})/g);
  $dec = substr($dec, 0, $places) . ( '0' x ( $places - length($dec) ) ) 
			if ( defined $places );
  
  return $int . 
	( ( defined($dec) and length($dec) ) ? $DecimalSeparator . $dec : '' );
}

package Data::Quantity::Number::NAN;

use vars qw( @ISA );
push @ISA, 'Data::Quantity::Number::Number';

1;
