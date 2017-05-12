package OLTest::Schema::TestAll;

use strict;
use warnings;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ OptimisticLocking PK::Auto Core /);
__PACKAGE__->table('test_all');
__PACKAGE__->add_columns(
	qw/ id col1 col2 col3 /
);

__PACKAGE__->set_primary_key(qw/id/);
__PACKAGE__->optimistic_locking_strategy('all');

1;
