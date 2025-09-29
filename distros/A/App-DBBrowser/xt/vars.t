use 5.10.1;
use strict;
use warnings;

my @modules;

BEGIN {
    my @modules = qw(
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
    );
}


use Test::Vars tests => @modules + 1;


vars_ok( 'lib/App/DBBrowser/GetContent/Filter/SearchAndReplace.pm', ignore_vars => { '$c' => 1, '$sf' => 1 } ); ##


for my $module ( @modules ) {
    vars_ok( $module, ignore_vars => { '$sf' => 1 } );
}
