
use strict;
use warnings;

package Sample::Context::Singleton::001::sum;

our $VERSION = v1.0.0;

use Sample::Context::Singleton;

contrive 'sum' => (
    dep => [ 'a', 'b' ],
    as => sub { $_[0] + $_[1] },
);

1;
