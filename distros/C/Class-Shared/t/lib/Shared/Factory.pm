package Shared::Factory;

# A factory: new() returns an object of another class, which does not inherit
# from this one.

use strict;
use warnings;

sub new { return bless {}, 'Shared::Factory::Product' }

package Shared::Factory::Product;

use strict;
use warnings;

sub hello { return 'hello from the product' }

1;
