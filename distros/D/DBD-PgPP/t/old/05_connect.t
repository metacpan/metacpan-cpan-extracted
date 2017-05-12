if (!defined $ENV{DBI_DSN}) {
    print "1..0 # Skipped: Cannot run test unless DBI_DSN is defined.  See the README file.\n";
    exit 0;
}

use DBI;
use strict;

print "1..1\n";
my $n = 1;
eval {
    my $dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                           { RaiseError => 1 });
    $dbh->disconnect;
};
print 'not ' if $@;
print "ok $n\n";
