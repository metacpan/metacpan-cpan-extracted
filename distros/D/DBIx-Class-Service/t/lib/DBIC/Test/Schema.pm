package DBIC::Test::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;
__PACKAGE__->load_components(qw/ServiceManager/);
__PACKAGE__->load_services({ 'DBIC::Test::Service' => [qw/
  User
/] });


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-03-27 19:43:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DVS9TIh6RIGUlxz7B8XXSQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
