package # hide from PAUSE
    MigrationsTest::Schema::ArtistSubclass;

use warnings;
use strict;

use base 'MigrationsTest::Schema::Artist';

__PACKAGE__->table(__PACKAGE__->table);

1;