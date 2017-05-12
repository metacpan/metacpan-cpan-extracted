package TestApp::Schema;

use strict;
use warnings;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes('Session');

1;
