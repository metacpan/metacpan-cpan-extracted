use strict;
use Test::More;
use DBIx::TempDB;

my ($create_database, $drop_database);

my $tmpdb = DBIx::TempDB->new(
  'postgresql://dummy@127.42',
  create_database_command => sub { (my $tmpdb, $create_database) = @_ },
  drop_database_command   => sub { (my $tmpdb, $drop_database)   = @_ },
  drop_from_child         => 0,
  template                => 'tmp_%X',
);

is $create_database, 'tmp_create_database_t', 'create_database_command was called';
ok !$drop_database, 'drop_database_command is not yet called';

undef $tmpdb;
is $drop_database, 'tmp_create_database_t', 'drop_database_command was called';

done_testing;
