### Change History
  # 1999-02-21 Created. -Simon

package Data::Quantity::Abstract::Compound;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Abstract::Base '-isasubclass';

# $clone_q = $quantity->new_instance();
# $empty_q = Data::Quantity::Abstract::Compound->new_instance();
sub new_instance {
  my $referent = shift;
  my $class = ref($referent) || $referent;
  my $month_q = [ 
    map { $_->new_instance } (
      ref($referent) ? ( @$referent ) : $class->component_classes
    )
  ];
  bless $month_q, $class;
}

sub component_classes {
  die "abstract!";
}

# $quantity->init( $year, $month );
sub init {
  my $month_q = shift;
  
  @$month_q = @_;
}

1;