package # hide from PAUSE 
    FrozenTest::Schema;

use base qw/DBIx::Class::Schema/;
our $VERSION = 1.0;

__PACKAGE__->load_classes('Source');

1;
