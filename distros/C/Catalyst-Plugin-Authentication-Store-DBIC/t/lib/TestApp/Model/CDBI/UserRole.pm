package TestApp::Model::CDBI::UserRole;

eval { require Class::DBI }; return 1 if $@;
@ISA = qw/TestApp::Model::CDBI/;
use strict;

__PACKAGE__->table  ( 'user_role' );
__PACKAGE__->columns( Primary   => qw/id/ );
__PACKAGE__->columns( Essential => qw/user role/ );

1;
