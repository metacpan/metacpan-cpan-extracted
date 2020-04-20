use strict;
use warnings;

package Schema::Result;

use DBIx::Class::Moo::ResultClass;

has 'result' => (is=>'ro');

1;
