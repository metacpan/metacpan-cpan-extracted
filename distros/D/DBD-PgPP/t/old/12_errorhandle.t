if (!defined $ENV{DBI_DSN}) {
    print "1..0 # Skipped: Cannot run test unless DBI_DSN is defined.  See the README file.\n";
    exit 0;
}

use DBI;
use strict;

print "1..3\n";
my $n = 1;

my $pgsql;
eval {
    $pgsql = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                          { RaiseError => 1, PrintError => 0 });
};
print 'not ' if $@;
print "ok $n\n"; $n++;


eval {
    my $sth = $pgsql->prepare(q{SELECT * FROM unknowntable});
    $sth->execute();
};
print "not " unless defined $pgsql && $pgsql->errstr && $@;
print "ok $n\n"; $n++;

eval { $pgsql->disconnect };
print 'not ' if $@;
print "ok $n\n";

1;
