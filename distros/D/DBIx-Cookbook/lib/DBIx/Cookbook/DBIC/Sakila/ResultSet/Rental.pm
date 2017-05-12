package DBIx::Cookbook::DBIC::Sakila::ResultSet::Rental;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub search_null_rentals {

  my ($self, $inventory_id, $customer_id) = @_;

  my $rs = do {
    my $where = {
		 inventory_id => $inventory_id,
		 customer_id  => $customer_id,
		 return_date  => undef
		};
    my $attr = {};

    $self->search($where, $attr);
  };
}

1;
