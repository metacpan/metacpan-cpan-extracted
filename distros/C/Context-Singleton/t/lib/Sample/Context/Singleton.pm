
use strict;
use warnings;

package Sample::Context::Singleton;

our $VERSION = v1.0.0;

use Context::Singleton (
    load_path => [ 'Sample::Context::Singleton::001' ],
    with_import => 1,
);

1;
