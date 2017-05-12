package My::Artist;

use strict;
use base qw(My::DBI);

My::Artist->table('artists');
My::Artist->columns(Primary => qw(id));
My::Artist->columns(Essential => qw(id title description));
My::Artist->has_many( albums => 'My::Album' );

sub moniker { 'artist' }
sub class_title { 'Artist' }
sub class_plural { 'Artists' }
sub class_description { 'Artist is a broad term. This is because the activities of artistic production are many and various. Often we speak of writers, actors, dancers, musicians, filmmakers and singers as artists. A more restricted meaning is one who makes (usually visual) art, i.e. a Fine Artist. This also distinguishes Artist from one who makes objects that can be categorised as being works of Applied Art.' }

1;
