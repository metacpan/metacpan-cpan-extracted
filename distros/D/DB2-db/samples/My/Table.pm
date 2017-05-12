package My::Table;

use DB2::Table;

our @ISA = qw(DB2::Table);

sub schema_name { 'DB2DB' }

