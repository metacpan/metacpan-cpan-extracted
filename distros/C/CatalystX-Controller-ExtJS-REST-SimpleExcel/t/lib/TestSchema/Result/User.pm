#
# This file is part of CatalystX-Controller-ExtJS-REST-SimpleExcel
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package
  TestSchema::Result::User;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(Core));

__PACKAGE__->table('user');

__PACKAGE__->add_columns(

    id => { data_type => 'integer' },
    name => { data_type => 'character varying' },
    password => { data_type => 'character varying', is_nullable => 1 },
    
);

__PACKAGE__->set_primary_key('id');

1;