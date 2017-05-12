package My::Schema::Status;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/CustomPrefetch Core/);
__PACKAGE__->table('statuses');
__PACKAGE__->add_columns(qw/id name user_id/);
__PACKAGE__->set_primary_key('id');

1;
