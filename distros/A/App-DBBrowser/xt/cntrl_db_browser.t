use 5.010000;
use strict;
use warnings;
use File::Basename qw( basename );
use Test::More;


for my $file (
    'bin/db-browser',
    'lib/App/DBBrowser.pm',
    'lib/App/DBBrowser/AttachDB.pm',
    'lib/App/DBBrowser/Auxil.pm',
    'lib/App/DBBrowser/CreateTable.pm',
    'lib/App/DBBrowser/Credentials.pm',
    'lib/App/DBBrowser/DB.pm',
    'lib/App/DBBrowser/DB/MariaDB.pm',
    'lib/App/DBBrowser/DB/mysql.pm',
    'lib/App/DBBrowser/DB/Pg.pm',
    'lib/App/DBBrowser/DB/SQLite.pm',
    'lib/App/DBBrowser/GetContent.pm',
    'lib/App/DBBrowser/GetContent/Filter.pm',
    'lib/App/DBBrowser/Join.pm',
    'lib/App/DBBrowser/Opt.pm',
    'lib/App/DBBrowser/OptDB.pm',
    'lib/App/DBBrowser/Table.pm',
    'lib/App/DBBrowser/Table/Functions.pm',
    'lib/App/DBBrowser/Table/Substatements.pm',
    'lib/App/DBBrowser/Table/WriteAccess.pm',
    'lib/App/DBBrowser/Union.pm' ) {

    my $data_dumper   = 0;
    my $warnings      = 0;
    my $use_lib       = 0;
    my $warn_to_fatal = 0;

    open my $fh, '<', $file or die $!;
    while ( my $line = <$fh> ) {
        if ( $line =~ /^\s*use\s+Data::Dumper/s ) {
            $data_dumper++;
        }
        if ( $line =~ /^\s*use\s+warnings\s+FATAL/s ) {
            $warnings++;
        }
        if ( $line =~ /^\s*use\s+lib\s/s ) {
            $use_lib++;
        }
        if ( $line =~ /__WARN__/s ) {
            $warn_to_fatal++;
        }
    }
    close $fh;

    is( $data_dumper,   0, 'OK - Data::Dumper in "'         . basename( $file ) . '" disabled.' );
    is( $warnings,      0, 'OK - warnings FATAL in "'       . basename( $file ) . '" disabled.' );
    is( $use_lib,       0, 'OK - no "use lib" in "'         . basename( $file ) . '"' );
    is( $warn_to_fatal, 0, 'OK - no "warn to fatal" in "'   . basename( $file ) . '"' );
}


done_testing();
