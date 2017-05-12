use strict;
use Test::More;
use DBIx::TempDB;

plan skip_all => 'cpanm DBD::SQLite' unless eval 'require DBD::SQLite;1';
plan skip_all => 'Need nix OS' if $^O =~ /win32/i;

my $tmpdb = DBIx::TempDB->new('sqlite:');
my $dbh   = DBI->connect($tmpdb->dsn);

eval {
  $tmpdb->execute(<<'HERE') };
-- comment
create table users (name text);
insert into users (name) values ('batman');
insert into users (name) values ('bruce');

-- comment
insert into users values ('wayne');

-- comment
create table whatever (foo text);
-- comment
HERE

ok !$@, 'multiple statements ok' or diag $@;

my $sth = $dbh->prepare("select name from users where name = 'batman'");
$sth->execute;
eval { $sth->fetchrow_arrayref->[0] };
ok !$@, 'and multiple statements was actually executed' or diag $@;

done_testing;
