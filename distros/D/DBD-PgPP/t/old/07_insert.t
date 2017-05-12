if (!defined $ENV{DBI_DSN}) {
    print "1..0 # Skipped: Cannot run test unless DBI_DSN is defined.  See the README file.\n";
    exit 0;
}

use DBI;
use strict;

print "1..4\n";
my $n = 1;

my $pgsql;
eval {
    $pgsql = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                          { RaiseError => 1 });
};
print 'not ' if $@;
print "ok $n\n"; $n++;

eval {
    $pgsql->do(q{
        INSERT INTO test (id, name, value) VALUES (1, 'foo', 'horse')
    });
    $pgsql->do(q{
        INSERT INTO test (id, name, value) VALUES (2, 'bar', 'chicken')
    });
    $pgsql->do(q{
        INSERT INTO test (id, name, value) VALUES (3, 'baz', 'pig')
    });
};
print "not " if $@;
print "ok $n\n"; $n++;

my $rows = 0;
eval {
    my $sth = $pgsql->prepare(q{SELECT COUNT(id) FROM test});
    $sth->execute;
    while (my $record = $sth->fetch()) {
        print 'rows: ', $record->[0], "\n";
        $rows = $record->[0];
    }
};
print "not " if $@ || $rows != 3;
print "ok $n\n"; $n++;

eval {
    $pgsql->disconnect;
};
print 'not ' if $@;
print "ok $n\n";

1;
