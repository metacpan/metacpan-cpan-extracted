package MyService::Base;
use strict;
use base qw/Class::DBI::SQLite/;
use Class::DBI::Plugin::Factory;

__PACKAGE__->connection("dbi:SQLite:dbname=t/db","","", { AutoCommit => 1, RaiseError => 1 });

END { unlink "t/db" }
1;

