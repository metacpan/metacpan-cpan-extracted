package Storage::SQLite;

use Moo::Role;
with qw(Storage::Common);

sub connect_info { 'dbi:SQLite::memory:', undef, undef, { RaiseError => 1 } }

1;
