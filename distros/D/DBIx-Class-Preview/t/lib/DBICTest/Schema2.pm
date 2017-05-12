package # hide from PAUSE
    DBICTest::Schema2;

use base qw/DBIx::Class::Schema/;

no warnings qw/qw/;

__PACKAGE__->load_classes(qw/Artist CD Friend/);

1;
