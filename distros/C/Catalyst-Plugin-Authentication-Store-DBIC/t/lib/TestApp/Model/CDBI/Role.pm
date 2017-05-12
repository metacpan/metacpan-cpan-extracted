package TestApp::Model::CDBI::Role;

eval { require Class::DBI }; return 1 if $@;
@ISA = qw/TestApp::Model::CDBI/;
use strict;

__PACKAGE__->table  ( 'role' );
__PACKAGE__->columns( Primary   => qw/id/ );
__PACKAGE__->columns( Essential => qw/role/ );

1;
