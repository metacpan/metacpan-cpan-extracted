package
    My::AttrRole;

use Moo::Role;

has attr => ( is => 'ro', required => 1 );

1;
