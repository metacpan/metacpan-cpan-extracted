#
# This file is part of DBIx-Class-Graph
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package 
  TestLib::Schema::ComplexMap;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table(qw(complex_map));
__PACKAGE__->add_columns(
    id     => { data_type => 'integer', auto_increment => 1 },
    child  => { data_type => "integer", },
    parent => { data_type => "integer", }
);

__PACKAGE__->belongs_to( child  => "TestLib::Schema::Complex" );
__PACKAGE__->belongs_to( parent => "TestLib::Schema::Complex" );
__PACKAGE__->add_unique_constraint( [qw/child parent/] );
__PACKAGE__->set_primary_key(qw(id));

1;
