package MyCDs::Track;

use strict;
use DBIx::DBO2::Record '-isasubclass';

use DBIx::DBO2::Fields (
  { name => 'id', field_type => 'sequential', },
  { name => 'disc_id', field_type => 'number', required => 1 },
  { name => 'name', field_type => 'string' },
  { name => 'duration', field_type => 'number' },
  # { name => 'artist_ids', field_type => 'string' },
  # { name => 'genre_id', field_type => 'number' },
);

1;
