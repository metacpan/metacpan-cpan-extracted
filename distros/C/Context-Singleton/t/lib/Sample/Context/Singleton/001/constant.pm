
use strict;
use warnings;

package Sample::Context::Singleton::001::constant;

our $VERSION = v1.0.0;

use Sample::Context::Singleton;

contrive 'constant' => (
    value => '42',
);

1;
