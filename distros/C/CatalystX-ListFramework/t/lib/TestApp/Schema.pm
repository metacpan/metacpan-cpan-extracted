package TestApp::Schema;
use strict;
use warnings;
use base qw/DBIx::Class::Schema/;

my @classes = (qw/Artist Album Track Copyright/);

__PACKAGE__->load_classes(@classes);
        
1;


