package # hide from PAUSE
    DBICTest::Schema;

use base qw/DBIx::Class::Schema/;

no warnings qw/qw/;

__PACKAGE__->load_classes(qw/Artist CD Track Tag Producer CD_to_Producer/);
__PACKAGE__->load_components(qw/Schema::Preview/);

1;
