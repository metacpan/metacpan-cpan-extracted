package Music::Artist;

use strict;
use base qw(Music::DBI);

__PACKAGE__->table('artist');
__PACKAGE__->columns(All => qw/artistid name/);
__PACKAGE__->has_many(cds => 'Music::CD');



1;