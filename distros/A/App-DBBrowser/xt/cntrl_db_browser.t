use 5.010000;
use strict;
use warnings;
use File::Basename qw( basename );
use Test::More;


for my $file ( qw(
bin/db-browser
lib/App/DBBrowser.pm
lib/App/DBBrowser/Auxil.pm
lib/App/DBBrowser/CreateDropAttach.pm
lib/App/DBBrowser/CreateDropAttach/AttachDB.pm
lib/App/DBBrowser/CreateDropAttach/CreateTable.pm
lib/App/DBBrowser/CreateDropAttach/DropTable.pm
lib/App/DBBrowser/Credentials.pm
lib/App/DBBrowser/DB.pm
lib/App/DBBrowser/DB/DB2.pm
lib/App/DBBrowser/DB/Firebird.pm
lib/App/DBBrowser/DB/Informix.pm
lib/App/DBBrowser/DB/MariaDB.pm
lib/App/DBBrowser/DB/mysql.pm
lib/App/DBBrowser/DB/ODBC.pm
lib/App/DBBrowser/DB/Oracle.pm
lib/App/DBBrowser/DB/Pg.pm
lib/App/DBBrowser/DB/SQLite.pm
lib/App/DBBrowser/From.pm
lib/App/DBBrowser/From/Cte.pm
lib/App/DBBrowser/From/Join.pm
lib/App/DBBrowser/From/Subquery.pm
lib/App/DBBrowser/From/Union.pm
lib/App/DBBrowser/GetContent.pm
lib/App/DBBrowser/GetContent/Filter.pm
lib/App/DBBrowser/GetContent/Filter/ConvertDate.pm
lib/App/DBBrowser/GetContent/Filter/SearchAndReplace.pm
lib/App/DBBrowser/GetContent/Parse.pm
lib/App/DBBrowser/GetContent/Source.pm
lib/App/DBBrowser/Opt/DBGet.pm
lib/App/DBBrowser/Opt/DBSet.pm
lib/App/DBBrowser/Opt/Get.pm
lib/App/DBBrowser/Opt/Set.pm
lib/App/DBBrowser/Table.pm
lib/App/DBBrowser/Table/CommitWriteSQL.pm
lib/App/DBBrowser/Table/Extensions.pm
lib/App/DBBrowser/Table/Extensions/Case.pm
lib/App/DBBrowser/Table/Extensions/ColAliases.pm
lib/App/DBBrowser/Table/Extensions/Columns.pm
lib/App/DBBrowser/Table/Extensions/Maths.pm
lib/App/DBBrowser/Table/Extensions/ScalarFunctions.pm
lib/App/DBBrowser/Table/Extensions/ScalarFunctions/Date.pm
lib/App/DBBrowser/Table/Extensions/ScalarFunctions/GetArguments.pm
lib/App/DBBrowser/Table/Extensions/ScalarFunctions/Numeric.pm
lib/App/DBBrowser/Table/Extensions/ScalarFunctions/Other.pm
lib/App/DBBrowser/Table/Extensions/ScalarFunctions/String.pm
lib/App/DBBrowser/Table/Extensions/ScalarFunctions/To.pm
lib/App/DBBrowser/Table/Extensions/ScalarFunctions/To/EpochTo.pm
lib/App/DBBrowser/Table/Extensions/WindowFunctions.pm
lib/App/DBBrowser/Table/InsertUpdateDelete.pm
lib/App/DBBrowser/Table/Substatement.pm
lib/App/DBBrowser/Table/Substatement/Aggregate.pm
lib/App/DBBrowser/Table/Substatement/Condition.pm
) ) {

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
        if ( $line =~ /__WARN__.+die/s ) {
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
