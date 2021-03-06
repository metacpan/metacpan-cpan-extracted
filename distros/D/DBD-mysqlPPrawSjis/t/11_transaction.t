use FindBin;
use lib "$FindBin::Bin/../lib";

if (!defined $ENV{DBI_DSN}) {
    print "1..0 # Skipped: Cannot run test unless DBI_DSN is defined.  See the README file.\n";
    exit 0;
}

use DBI;
use strict;

print "1..6\n";

my $mysql;
eval {
    $mysql = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                          { RaiseError => 1, AutoCommit => 0 });
};
print 'not ' if $@;
print "ok 1\n";

my $rows = 0;
eval {
    my $sth = $mysql->prepare(q{
        SELECT id, name FROM test
    });
    $sth->execute;
    while (my $record = $sth->fetch()) {
        ++$rows;
    }
};
print "ok 2\n";


eval {
    my $row = $mysql->do(q{
        INSERT INTO test (id, name, value) VALUES (4, 'hoge', 'mufufu')
    });
    die 'no match' if $row != 1;
};
print "not " if $@;
print "ok 3\n";


my $rows2 = 0;
eval {
    $mysql->rollback();
    my $sth = $mysql->prepare(q{SELECT id, name FROM test});
    $sth->execute;
    while (my $record = $sth->fetch()) {
        ++$rows2;
    }
};
print "not " if $@ || $rows != $rows2;
print "ok 4\n";

my $rows3 = 0;
eval {
    $mysql->do(q{
        INSERT INTO test (id, name, value) VALUES (5, 'hoge', 'mufufu')
    });
    $mysql->commit;
    my $sth = $mysql->prepare(q{SELECT id, name FROM test});
    $sth->execute;
    while (my $record = $sth->fetch()) {
        ++$rows3;
    }
};
print "not " if $@ || ($rows2 + 1) != $rows3;
print "ok 5\n";


eval { $mysql->disconnect };
print 'not ' if $@;
print "ok 6\n";
