package TestApp::Model::CDBI::User;

eval { require Class::DBI }; return 1 if $@;
@ISA = qw/TestApp::Model::CDBI/;
use strict;

__PACKAGE__->table  ( 'user' );
__PACKAGE__->columns( Primary   => qw/id/ );
__PACKAGE__->columns( Essential => qw/username password session_data/ );

1;
