#!perl -T

use Test::More tests => 7;

BEGIN {
    use_ok( 'Data::Grid' ) || print "Bail out!
";
    use_ok( 'Data::Grid::Excel' ) || print "Bail out!
";
    use_ok( 'Data::Grid::Excel::XLSX' ) || print "Bail out!
";
    use_ok( 'Data::Grid::CSV' ) || print "Bail out!
";
    use_ok( 'Data::Grid::Table' ) || print "Bail out!
";
    use_ok( 'Data::Grid::Row' ) || print "Bail out!
";
    use_ok( 'Data::Grid::Cell' ) || print "Bail out!
";
}

diag( "Testing Data::Grid $Data::Grid::VERSION, Perl $], $^X" );
