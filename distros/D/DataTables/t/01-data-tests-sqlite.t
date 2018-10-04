use Test::More;
use DataTables;
use CGI::Simple;
use DBI;
use Data::Compare qw/Compare/;
use FindBin qw/$Bin/;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite required for this test script." if $@;

plan tests => 1;

my @tests = (
    {
        expected => {
          'aaData' => [
                        [
                          'Gecko',
                          'Camino 1.5',
                          'OSX.3+',
                          '1.8',
                          'A'
                        ],
                        [
                          'Gecko',
                          'Netscape 7.2',
                          'Win 95+ / Mac OS 8.6-9.2',
                          '1.7',
                          'A'
                        ],
                        [
                          'Gecko',
                          'Netscape Browser 8',
                          'Win 98SE+',
                          '1.7',
                          'A'
                        ]
                      ],
          'iTotalDisplayRecords' => 50,
          'iTotalRecords' => 50,
          'sEcho' => '7'
        },
        params => {
            iDisplayStart => 5,
            iDisplayLength => 3,
            bSearchable_0 => 'true',
            bSearchable_1 => 'true',
            bSearchable_2 => 'true',
            sEcho => 7,
        },
    }
);

foreach my $test_href ( @tests ) {
    run_test($test_href->{params}, $test_href->{expected});
}


sub run_test {
    my $params = shift;
    my $expected = shift;

    my $q = CGI::Simple->new($params);
    
    my $dbname = $Bin . '/db/datatables_demo_data.sqlite';
    my $dbh = DBI->connect("dbi:SQLite:$dbname","","",{sqlite_unicode => 1}) or die "Couldn't connect to database: " . DBI->errstr;
    
    my $dt = DataTables->new(
        dbh => $dbh,
        query => $q,
        #where_clause => { -or => [{grade => "X"},{grade => 'X'}] },
        #where_clause => { grade => "U" },
    );
    
    #set table to select from
    $dt->tables(["demo"]);
    
    #set columns to select in same order as order of columns on page
    $dt->columns([qw/engine browser platform version grade/]);
    
    #if you wish to do something with the json yourself
    my $data = $dt->table_data;    
    
    ok( Compare($data, $expected), 'data fetched via DataTables looks like expected' );
    
} # /run_test
