package # hide from PAUSE
    MigrationsTest::ResultSetManager;

use warnings;
use strict;

use base 'MigrationsTest::BaseSchema';

__PACKAGE__->load_classes("Foo");

1;
