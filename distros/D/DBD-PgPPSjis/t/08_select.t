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

my $rows = 0;
eval {
    my $sth = $pgsql->prepare(q{SELECT id, name FROM test});
    $sth->execute;
    while (my $record = $sth->fetch()) {
        if (defined($record->[0]) && defined($record->[1])) {
            ++$rows;
        }
    }
};
print "not " if $@ || $rows != 3;
print "ok $n\n"; $n++;


$rows = 0;
eval {
    my $sth = $pgsql->prepare(q{SELECT id, name FROM test WHERE ? = ?});
    $sth->execute(1,0);
    while (my $record = $sth->fetch()) {
        ++$rows;
    }
};
print "not " if $@ || $rows != 0;
print "ok $n\n"; $n++;


$rows = 0;
eval {
    my $sth = $pgsql->prepare(q{SELECT id, name FROM test WHERE id = ?});
    $sth->execute(1);
    while (my $record = $sth->fetch()) {
        if (defined($record->[0]) && defined($record->[1])) {
            ++$rows;
        }
    }
};
print "not " if $@ || $rows != 1;
print "ok $n\n"; $n++;


$rows = 0;
eval {
    my $sth = $pgsql->prepare(q{SELECT id, name FROM test WHERE name=?});
    $sth->execute('foo');
    while (my $record = $sth->fetch()) {
        if (defined($record->[0]) && defined($record->[1])) {
            ++$rows;
        }
    }
};
print "not " if $@ || $rows != 1;
print "ok $n\n"; $n++;

eval { $pgsql->disconnect };
print 'not ' if $@;
print "ok $n\n";
