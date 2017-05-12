package # Hide from PAUSE
    I18NTest::SchemaAuto;

use strict;
use warnings;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces();

1;
