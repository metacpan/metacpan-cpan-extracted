#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyApp::Schema::Result::User;

use Moose;
extends 'DBIx::Class::Core';

__PACKAGE__->table('user');

__PACKAGE__->add_columns(
	id => { is_auto_increment => 1, data_type => 'integer' },
    qw(email first last)
);

__PACKAGE__->set_primary_key('id');

1;