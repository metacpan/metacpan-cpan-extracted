package # hide from PAUSE
    Test;

use strict;
use warnings;

use File::Spec;
use File::Temp;
use Schema;

our $tmp_dir = File::Temp->newdir();
our $dbfile  = File::Spec->catdir($tmp_dir,'test.db');
our $dsn     = "dbi:SQLite:${dbfile}";
our $schema  = Schema->connect($dsn);

sub initialize
{
    unlink($dbfile) if -e $dbfile;

    my $dbh = $schema->storage->dbh;

    if ($ENV{"DBICTEST_SQLT_DEPLOY"}) {
        $schema->deploy;
    }
    else {
        open IN, "t/sql/sqlite.sql";

        my $sql;
        { local $/ = undef; $sql = <IN>; }
        close IN;

        $dbh->do($_) for split(/\n\n/, $sql);
    }

    return($schema);
}

1;
