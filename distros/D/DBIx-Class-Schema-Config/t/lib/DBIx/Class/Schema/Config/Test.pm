package DBIx::Class::Schema::Config::Test;

use strict;
use warnings;

use base 'DBIx::Class::Schema::Config';

__PACKAGE__->config_paths( [ ( 't/etc/config' ) ] );
__PACKAGE__->load_classes;
1;
