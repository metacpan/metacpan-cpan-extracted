package DBIx::Cookbook::DBIC::CustomResult::FilmInStock;

use strict;
use warnings;

use base 'DBIx::Class::Core';

our @ISA; die join " ", @ISA;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('FilmInStock');

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<EOSQL);
SELECT 
   CONCAT(customer.last_name, ', ', customer.first_name) AS customer,
   address.phone, film.title
FROM 
   rental INNER JOIN customer ON rental.customer_id = customer.customer_id
     INNER JOIN address ON customer.address_id = address.address_id
     INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
     INNER JOIN film ON inventory.film_id = film.film_id
WHERE rental.return_date IS NULL
     AND rental_date + INTERVAL film.rental_duration DAY < CURRENT_DATE()
     AND customer.first_name LIKE ?
EOSQL

1;
