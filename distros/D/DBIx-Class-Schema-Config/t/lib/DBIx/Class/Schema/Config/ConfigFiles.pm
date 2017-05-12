package DBIx::Class::Schema::Config::ConfigFiles;

use strict;
use warnings;

use base 'DBIx::Class::Schema::Config';

__PACKAGE__->config_files( [ ( 't/etc/config.perl' ) ] );
__PACKAGE__->load_classes;
1;
