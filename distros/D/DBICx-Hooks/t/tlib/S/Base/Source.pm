package S::Base::Source;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->load_components('+DBICx::Hooks');

1;