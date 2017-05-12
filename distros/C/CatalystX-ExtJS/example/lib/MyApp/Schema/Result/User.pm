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
extends 'MyApp::Schema::Result';

__PACKAGE__->table('user');

__PACKAGE__->add_columns(
    qw(email first last)
);

1;