package FakeORM::Table;
use strict;
use warnings;

sub new  { my ( $class, $name ) = @_; return bless { name => $name }, $class }
sub name { return $_[0]->{name} }

1;
