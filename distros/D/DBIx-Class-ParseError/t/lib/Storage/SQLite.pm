package Storage::SQLite;

use strict;
use warnings;
use Moo::Role;

sub connect_info { 'dbi:SQLite::memory:', undef, undef, { RaiseError => 1 } }

1;
