use FindBin;
use lib "$FindBin::Bin/../lib";

if (!defined $ENV{DBI_DSN}) {
    print "1..0 # Skipped: Cannot run test unless DBI_DSN is defined.  See the README file.\n";
    exit 0;
}

use DBI;
use strict;

print "1..3\n";
my $n = 1;

my $mysql;
eval {
    $mysql = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                          { RaiseError => 1, PrintError => 0 });
};
print 'not ' if $@;
print "ok $n\n"; $n++;


eval {
    my $sth = $mysql->prepare(q{SELECT * FROM unknowntable});
    $sth->execute();
};
print "not " unless defined $mysql && $mysql->errstr && $@;
print "ok $n\n"; $n++;

eval { $mysql->disconnect };
print 'not ' if $@;
print "ok $n\n";

1;
