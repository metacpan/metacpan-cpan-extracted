package ProxyTest::Log;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ProxyTable Core/);
__PACKAGE__->table('log');
__PACKAGE__->add_columns(qw/ id body /);
__PACKAGE__->set_primary_key('id');

1;

