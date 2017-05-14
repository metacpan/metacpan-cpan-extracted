package # hide from PAUSE
    CdbiTreeTest::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/Test/);

1;
