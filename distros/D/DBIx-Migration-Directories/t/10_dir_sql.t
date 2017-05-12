#!perl

use strict;
use warnings;

use Test::More qw(no_plan);
use DBIx::Migration::Directories;
use lib 't/tlib';
use Test::DummyDBI;

my $dbh = Test::DummyDBI->new;
my $m = DBIx::Migration::Directories->new(
    dbh     => $dbh, 
    schema  => 'TestSchema',
    base    => 't/tetc',
);

my $tf = "t/tetc/TestSchema/_generic/001/03_bad.sql";

my @sql = $m->dir_sql('001');

is_deeply(
    [$m->dir_sql('001')],
    [
        \"t/tetc/TestSchema/_generic/001/01test.sql",
        "CREATE TABLE foo_test (\n  id INT NOT NULL PRIMARY KEY\n)",
        \"t/tetc/TestSchema/_common/001/02insert.sql",
        "INSERT INTO foo_test VALUES (1)",
        "INSERT INTO foo_test VALUES (2)",
        "INSERT INTO foo_test VALUES (3)"
    ],
    'basic dir_sql'
);

eval { $m->dir_sql('100'); };
like($@, qr/^opendir\(".+?"\) failed:/, 'no such directory');

if(open(my $fh, '>', $tf)) {
    pass('open test file');
    print $fh "test\n";
    close($fh);
    chmod(0000, $tf);

    SKIP: {
      if(open(my $fh2, '<', $tf)) {
        skip 'root has access to everything', 1;
      }

      eval { $m->dir_sql('001'); };
    
      like($@, qr/^open\(".+?"\) failed:/, 'bad file in directory');
    }
    
    chmod(0700, $tf);
    unlink($tf);    
} else {
    fail('open test file');
    fail('bad file in directory');
}

is($m->run_sql(@sql), 1, 'run_sql passes if $dbh->do() passes');
$dbh->bad_rv;
is($m->run_sql(@sql), undef, 'run_sql failes if $dbh->do() fails');
$dbh->good_rv;

delete $m->{_current_version};
delete $m->{current_version};
@sql = $m->version_update_sql(1, 2);
like($sql[0], qr/^\s*INSERT /, 'version_update: inserts if there is no current version');

delete $m->{_current_version};
$m->{current_version} = 1;
@sql = $m->version_update_sql(1, 2);
like($sql[0], qr/^\s*UPDATE /, 'version_update: updates if there is a current version');

$m->{current_version} = 1;
$m->{_current_version} = undef;
@sql = $m->version_update_sql(1, 2);
like($sql[0], qr/^\s*INSERT /, 'version_update: _current_version of undef overrides current_version');


