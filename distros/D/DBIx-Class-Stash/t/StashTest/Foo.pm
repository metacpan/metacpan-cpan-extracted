package StashTest::Foo;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Stash Core/);
__PACKAGE__->table('foo');
__PACKAGE__->add_columns(qw/ id body /);
__PACKAGE__->set_primary_key('id');

1;

