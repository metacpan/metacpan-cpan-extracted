package DBICTest::Schema::RevisionData;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('revision_data');
__PACKAGE__->add_columns(qw/
    revision_data_id revision_id datum datum_value
/);
__PACKAGE__->set_primary_key('revision_data_id');

1;


