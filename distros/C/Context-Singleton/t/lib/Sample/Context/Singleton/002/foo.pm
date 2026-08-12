
use strict;
use warnings;

package Sample::Context::Singleton::002::foo;

our $VERSION = v1.0.0;

use Sample::Context::Singleton;

contrive q (002-foo) => (
	value => q (002-foo),
);

1;
