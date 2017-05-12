package OLTest::Schema::TestVersion;

use strict;
use warnings;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ OptimisticLocking PK::Auto Core /);
__PACKAGE__->table('test_version');
__PACKAGE__->add_columns( qw/ id col1 col2 version / );

__PACKAGE__->set_primary_key('id');
__PACKAGE__->optimistic_locking_strategy('version');

1;
