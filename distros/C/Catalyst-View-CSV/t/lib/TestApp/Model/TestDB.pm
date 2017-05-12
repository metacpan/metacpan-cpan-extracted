package TestApp::Model::TestDB;

use base qw ( Catalyst::Model::DBIC::Schema );
use strict;
use warnings;

__PACKAGE__->config ( schema_class => "TestDB" );

1;
