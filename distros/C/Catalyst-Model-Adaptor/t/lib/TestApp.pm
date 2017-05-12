package TestApp;
use strict;
use warnings;

use Catalyst;

# Note __PACKAGE__->config->{'Model::NoArgs} -> not configured :)
__PACKAGE__->config->{'Model::SomeClass'}{args}  = { foo => 'bar'  };
__PACKAGE__->config->{'Model::Factory'}{args}    = { foo => 'baz'  };
__PACKAGE__->config->{'Model::PerRequest'}{args} = { foo => 'quux' };
__PACKAGE__->setup;

1;
