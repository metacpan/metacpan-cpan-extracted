package
    My::Service;

use Moo;
with 'Beam::Service';

has foo => ( is => 'ro' );

1;
