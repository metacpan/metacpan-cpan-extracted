package # hide from PAUSE
    MigrationsTest::Schema::ArtistSourceName;

use warnings;
use strict;

use base 'MigrationsTest::Schema::Artist';
__PACKAGE__->table(__PACKAGE__->table);
__PACKAGE__->source_name('SourceNameArtists');

1;
