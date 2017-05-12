package SQLiteSetup;
use strict;     
use FindBin;


=head1 SQLiteSetup

Re-create the test app db file when used, or die trying.

The db file must not be locked by any running app.

=cut



recreate_db();

sub recreate_db {
    my $db_file = "$FindBin::Bin/tutorial/BookShelf/db/bookshelf.db";
    my $sql_file = "$FindBin::Bin/tutorial/database/bookdb.sql";
    if($^O eq "MSWin32") {
        $db_file =~ s|\\|/|gs;
        $sql_file =~ s|/|\\|gs;
    }
    
    unlink($db_file);
    -f $db_file and die("Could not remove existing db file ($db_file). Is there an application running, locking the file?\n");

    my $cmd = qq{dbish dbi:SQLite:dbname=$db_file < $sql_file};
    `$cmd 2>&1`;
}


1;


__END__
