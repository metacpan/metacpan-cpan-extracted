package DBICTest::Schema::Revision;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('revisions');
__PACKAGE__->add_columns(qw/
    revision_id grouping identifier recorded metadata
/);
__PACKAGE__->set_primary_key('revision_id');

1;


