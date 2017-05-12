use strict;
use Test::More;
use DBIx::TempDB;

plan skip_all => 'Need nix OS' if $^O =~ /win32/i;

my $path = File::Spec->catfile(File::Spec->tmpdir, 'foo.sqlite');
ok !-e $path, 'sqlite does not exist';

my $tmpdb = DBIx::TempDB->new('sqlite:', drop_from_child => 0, template => 'foo');
is $tmpdb->url->dbname, $path, 'dbname';

is_deeply(
  [$tmpdb->dsn],
  [
    "dbi:SQLite:dbname=$path", "", "",
    {AutoCommit => 1, AutoInactiveDestroy => 1, PrintError => 0, RaiseError => 1, sqlite_unicode => 1}
  ],
  'dsn for foo'
);

ok -e $path, 'sqlite db created';
is -s $path, 0, 'sqlite db is empty';

undef $tmpdb;
ok !-e $path, 'sqlite cleaned up';

done_testing;
