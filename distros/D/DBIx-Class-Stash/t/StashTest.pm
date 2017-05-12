package StashTest;
use strict;
use warnings;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw//);

__PACKAGE__->load_components(qw/Stash/);

1;

