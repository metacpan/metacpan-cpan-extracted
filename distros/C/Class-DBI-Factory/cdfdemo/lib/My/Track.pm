package My::Track;

use strict;
use base qw(My::DBI);

My::Track->table('tracks');
My::Track->columns(Primary => qw(id));
My::Track->columns(Essential => qw(id title description position duration miserableness album));
My::Track->has_a( album => 'My::Album' );

sub moniker { 'track' }
sub class_title { 'Track' }
sub class_plural { 'Tracks' }
sub class_description { 'cut: a distinct selection of music from a recording or a compact disc; "he played the first cut on the cd"; "the title track of the album"' }

1;
