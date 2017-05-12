package Data::Quantity::Finance::CreditCardNumber;

use Data::Quantity::Number::Number '-isasubclass';

use vars qw( $VERSION );
$VERSION = 0.001;

=head1

Based on Business::CreditCard by Jon Orwant.

=cut

# $quantity->init( $n_val );
sub init {
  my $num_q = shift;
  
  my $n_val = shift;
  if ( $num_q->checksum_value( $n_val ) ) {
    $n_val =~ s/\D//g;
  }
  $num_q->value( $n_val );
}

# $n_val = $quantity->value;
# $quantity->value( $n_val );
# to prevent scientfic notation from being returned
sub value {
  my $num_q = shift;
  my $value = $num_q->SUPER::value( @_ );
  defined($value) ? sprintf( '%.0f', $value ) : undef;
}

sub checksum_value {
  my $class_or_item = shift;
  my $number = shift;
  
  $number =~ s/\D//g;
  return 0 unless ( length($number) >= 13 && 0+$number );
  
  my ($i, $sum, $weight);
  for ($i = 0; $i < length($number) - 1; $i++) {
      $weight = substr($number, -1 * ($i + 2), 1) * (2 - ($i % 2));
      $sum += (($weight < 10) ? $weight : ($weight - 9));
  }
  
  substr($number, -1) == (10 - $sum % 10) % 10;
}

sub formatted_value {
  my $class_or_item = shift;
  my $number = my $original = shift;
  $number =~ s/\D//g;
  return $original unless ( length($number) >= 13 and 0+$number );
  $number =~ s/(....)/$1\-/g;
  $number =~ s/\-$//g;
  $number;
}

sub readable_value {
  my $class_or_item = shift;
  my $number = my $original = shift;
  $number =~ s/\D//g;
  return $original unless ( length($number) >= 13 and 0+$number );
  my $tail = join '', ( $number =~ /(\d)(\d)(\d)(\d)$/ );
  $number = ('*' x ( length($number) - length($tail) )) . $tail;
  $number =~ s/(....)/$1\-/g;
  $number =~ s/\-$//g;
  $number;
}

use vars qw( %CardFlavors @CardFlavorKeys );
%CardFlavors = (
  '4' => 'VISA',
  '5' => 'MasterCard',
  '6' => 'Discover',
  '37' => 'American Express',
  '3' => "Dining or entertainment card",
);
@CardFlavorKeys = sort { length($b) <=> length($a) } keys %CardFlavors;

sub flavor_value {
  my $class_or_item = shift;
  my $number = shift;

  $number =~ s/\D//g;

  return "Unrecognized" unless ( length($number) >= 13 and 0+$number );
  foreach ( @CardFlavorKeys ) {
    return( $CardFlavors{ $_ } ) if ( $number =~ /^$_/ );
  }
  return "Unknown";
}

1;
