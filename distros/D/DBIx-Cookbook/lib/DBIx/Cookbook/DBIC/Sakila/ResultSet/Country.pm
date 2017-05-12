package DBIx::Cookbook::DBIC::Sakila::ResultSet::Country;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# ./scripts/dbic_cmd predefined_search --starts_with C --max_id 20

sub search_country {

  my ($self, $letter, $max_id) = @_;

  my $rs = do {
    my $where = {
		 country     => { 'LIKE' => "$letter%" },
		 country_id  => { '<'    => $max_id }
		};
    my $attr = {};

    $self->search($where, $attr);
  };
}

1;
