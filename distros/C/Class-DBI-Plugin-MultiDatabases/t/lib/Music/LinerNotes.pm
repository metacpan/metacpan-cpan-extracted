package Music::LinerNotes;

use strict;
use base qw(Music::DBI);

__PACKAGE__->table('liner_notes');
__PACKAGE__->columns(All => qw/cdid notes/);

1;
