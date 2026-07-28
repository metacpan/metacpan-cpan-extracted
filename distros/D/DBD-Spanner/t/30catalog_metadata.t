use strict;
use warnings;
use Test::More tests => 6;
use DBI;
my $dbh = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
my $tbl_sth = $dbh->table_info(undef, undef, 'users', 'TABLE');
ok($tbl_sth, 'table_info returned statement handle');
ok($tbl_sth->execute(), 'table_info statement executed');

my $col_sth = $dbh->column_info(undef, undef, 'users', '%');
ok($col_sth, 'column_info returned statement handle');
ok($col_sth->execute(), 'column_info statement executed');

my $pk_sth = $dbh->primary_key_info(undef, undef, 'users');
ok($pk_sth, 'primary_key_info returned statement handle');
ok($pk_sth->execute(), 'primary_key_info statement executed');
