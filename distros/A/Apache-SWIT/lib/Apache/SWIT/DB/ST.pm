use strict;
use warnings FATAL => 'all';

package Apache::SWIT::DB::ST;
use base 'DBIx::ContextualFetch';

package Apache::SWIT::DB::ST::db;
use base 'DBIx::ContextualFetch::db';

package Apache::SWIT::DB::ST::st;
use base 'DBIx::ContextualFetch::st';

sub _disallow_references {}

1;
