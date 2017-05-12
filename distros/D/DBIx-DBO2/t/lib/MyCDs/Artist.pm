package MyCDs::Artist;

use strict;
use DBIx::DBO2::Record '-isasubclass';
require MyCDs;

use DBIx::DBO2::Fields (
  { name => 'id', field_type => 'sequential', },
  { name => 'name', field_type => 'string', length => 64, required => 1, },
  { name=>'discs', field_type=>'line_items', interface=>'restrict_delete',
    related_class=>'MyCDs::Disc', related_field=>'artist_id', },
);

1;
