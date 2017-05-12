package My::Genre;

use strict;
use base qw(My::DBI);

My::Genre->table('genres');
My::Genre->columns(Primary => qw(id));
My::Genre->columns(Essential => qw(id title description));
My::Genre->has_many( albums => 'My::Album' );

sub moniker { 'genre' }
sub class_title { 'Genre' }
sub class_plural { 'Genres' }
sub class_description { '(from Latin genus, type, kind): works of literature tend to conform to certain types, or kinds. Thus we will describe a work as belonging to, for example, one of the following genres: epic, pastoral, satire, elegy. All the resources of linguistic patterning, both stylistic and structural, contribute to a sense of a work\'s genre. Generic boundaries are often fluid; literary meaning will often be produced by transgressing the normal expectations of genre' }

1;
