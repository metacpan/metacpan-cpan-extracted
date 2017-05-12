
### US Dollars

package Data::Quantity::Finance::Currency::USD;

use Data::Quantity::Finance::Currency;
@ISA = 'Data::Quantity::Finance::Currency';

use Class::MakeMethods (
  'Standard::Inheritable:scalar' => 'symbol',
  'Standard::Inheritable:scalar' => 'fixed_decimal',
);

Data::Quantity::Finance::Currency::USD->scale('US Dollars');
Data::Quantity::Finance::Currency::USD->symbol('$');
Data::Quantity::Finance::Currency::USD->fixed_decimal(2);

Data::Quantity::Finance::Currency::USD->scale();
Data::Quantity::Finance::Currency::USD->symbol();
Data::Quantity::Finance::Currency::USD->fixed_decimal();

# $n_val = Data::Quantity::Finance::Currency::USD->numeric_value( $candidate_n_val );
sub numeric_value {
  my $class_or_item = shift;
  my $n_val = shift;
  
  my $symbol = $class_or_item->symbol;
  my $fixed_decimal = $class_or_item->fixed_decimal;
  
  if ( $n_val =~ /^\-?\d+$/ ) {
    return $n_val;
  }
  
  $n_val =~ s/\Q$symbol\E//;
  
  $n_val = Data::Quantity::Number::Number->numeric_value( $n_val );
  return unless ( defined $n_val );
  
  return $n_val * ( 10 ** $fixed_decimal );
}

# $string = $quantity->readable_value($n_val);
# $string = Data::Quantity::Finance::Currency::USD->readable_value($n_val);
sub readable_value {
  my $class_or_item = shift;
  my $n_val = shift;
  
  return unless ( $n_val =~ /\d/ );
  
  my $symbol = $class_or_item->symbol;
  my $fixed_decimal = $class_or_item->fixed_decimal;
  
  $n_val = $n_val / ( 10 ** $fixed_decimal );
  
  my $signer = '-' if $n_val < 0;
    
  return $signer . $symbol . Data::Quantity::Number::Number->readable_value( $n_val, $fixed_decimal );
}

1;
