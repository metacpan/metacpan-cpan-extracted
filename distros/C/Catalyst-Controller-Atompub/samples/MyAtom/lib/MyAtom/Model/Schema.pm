package # hide from PAUSE
    MyAtom::Model::Schema;
use strict;
use base qw(DBIx::Class::Schema::Loader);
__PACKAGE__->loader_options(relationships => 1);
1;
