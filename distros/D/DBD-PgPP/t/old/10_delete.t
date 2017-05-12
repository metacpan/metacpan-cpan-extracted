if (!defined $ENV{DBI_DSN}) {
    print "1..0 # Skipped: Cannot run test unless DBI_DSN is defined.  See the README file.\n";
    exit 0;
}

use DBI;
use strict;

print "1..6\n";
my $n = 1;

my $pgsql;
eval {
    $pgsql = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                          { RaiseError => 1 });
};
print 'not ' if $@;
print "ok $n\n"; $n++;

eval {
    my $rows = $pgsql->do(q{DELETE FROM test WHERE id = 1});
    die 'no match' if $rows != 1;
};
print "not " if $@;
print "ok $n\n"; $n++;


my $rows = 0;
eval {
    my $sth = $pgsql->prepare(q{
        SELECT id, name FROM test WHERE id = 1
    });
    $sth->execute;
    while (my $record = $sth->fetch()) {
        ++$rows;
    }
};
print "not " if $@ || $rows > 0;
print "ok $n\n"; $n++;


eval {
    my $row = $pgsql->do(q{DELETE FROM test});
    die 'no match' if $row != 2;
};
print "not " if $@;
print "ok $n\n"; $n++;


$rows = 0;
eval {
    my $sth = $pgsql->prepare(q{SELECT id, name FROM test});
    $sth->execute;
    while (my $record = $sth->fetch()) {
        ++$rows;
    }
};
print "not " if $@ || $rows != 0;
print "ok $n\n"; $n++;

eval { $pgsql->disconnect };
print 'not ' if $@;
print "ok $n\n"; $n++;
