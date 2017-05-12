package Music::CD;

use strict;
use base qw(Music::DBI);

__PACKAGE__->table('cd');
__PACKAGE__->columns(All => qw/cdid artist title year/);
__PACKAGE__->has_a(artist => 'Music::Artist');
__PACKAGE__->might_have(liner_notes => 'Music::LinerNotes' => qw/notes/);



1;