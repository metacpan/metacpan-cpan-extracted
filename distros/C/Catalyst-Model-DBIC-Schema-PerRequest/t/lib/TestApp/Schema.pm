package TestApp::Schema;

use warnings;
use strict;

use base 'DBIx::Class::Schema';

__PACKAGE__->mk_group_accessors(inherited => qw(test_attr));
__PACKAGE__->test_attr('DB');
__PACKAGE__->load_namespaces();

1;
