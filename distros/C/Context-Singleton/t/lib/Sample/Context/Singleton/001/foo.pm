
use strict;
use warnings;

package Sample::Context::Singleton::001::foo;

our $VERSION = v1.0.0;

use Sample::Context::Singleton;

contrive q (001-foo) => (
	value => q (001-foo),
);

1;
