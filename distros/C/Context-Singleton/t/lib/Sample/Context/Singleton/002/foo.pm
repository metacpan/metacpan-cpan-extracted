
use strict;
use warnings;

package Sample::Context::Singleton::002::foo;

our $VERSION = v1.0.0;

use Sample::Context::Singleton;

contrive '002-foo' => (
    value => '002-foo',
);

1;
