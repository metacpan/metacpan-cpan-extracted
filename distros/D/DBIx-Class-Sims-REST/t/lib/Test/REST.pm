package Test::REST;

use 5.010_000;

use strict;
use warnings FATAL => 'all';

use DBIx::Class::Sims::REST::SQLite;
use base 'DBIx::Class::Sims::REST::SQLite';

use Test::Schema;

sub get_schema_class { 'Test::Schema' }

1;
__END__
