package # hide from PAUSE 
    DigestTest::Schema;

use base qw/DBIx::Class::Schema/;

no warnings qw/qw/;

__PACKAGE__->load_classes(qw/ Test Test2/);

1;
