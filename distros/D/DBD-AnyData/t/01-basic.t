#!perl -w
$| = 1;

use strict;

use Cwd;
use File::Path;
use File::Spec;
use Test::More;

my $using_dbd_gofer = ( $ENV{DBI_AUTOPROXY} || "" ) =~ /^dbi:Gofer.*transport=/i;

my @formats = qw(CSV Pipe Tab Fixed Paragraph ARRAY);
eval { require AnyData; };
plan skip_all => "Use must download and install AnyData before you can install DBD::AnyData!" if $@;

my $dir = File::Spec->catdir( getcwd(), 'test_output' );

rmtree $dir;
END { rmtree $dir }
mkpath $dir;

use_ok("DBI");
use_ok("DBD::AnyData");

for my $driver ('DBD::AnyData')
{
    note "$driver";
    for my $format (@formats)
    {
        note sprintf "  %10s ... ", $format;
        test( $driver, $format );
    }
}

done_testing();

sub test
{
    my ( $driver, $format ) = @_;
    return $driver =~ /dbd/i
      ? test_dbd($format)
      : test_ad($format);
}

sub test_ad { }

sub test_dbd
{
    my $format = shift;
    my $dbh = DBI->connect( "dbi:AnyData:(RaiseError=>1):", undef, undef, { f_dir => $dir } );
    ok( $dbh, "connect" );
    my $tbl = "test_" . $format;
    my $file = File::Spec->catfile( $dir, $tbl );
    unlink $file if -e $file;
    my $flags = { pattern => 'A5 A8 A3' };

    $dbh->func( $tbl, $format, $file, $flags, 'ad_catalog' )
      unless $format =~ /XML|HTMLtable|ARRAY/;

    # CREATE A TEMPORARY TABLE FROM DBI/SQL COMMANDS
    # INSERT, UPDATE, and DELETE ROWS
    #

    ok( $dbh->do("CREATE TABLE $tbl (name TEXT, country TEXT,sex TEXT)"), "CREATE $tbl" );
    ok( $dbh->do("INSERT INTO $tbl VALUES ('Sue','fr','f')"),             "INSERT 1. row into $tbl" );
    ok( $dbh->do("INSERT INTO $tbl VALUES ('Tom','fr','f')"),             "INSERT 2. row into $tbl" );
    ok( $dbh->do("INSERT INTO $tbl VALUES ('Bev','en','f')"),             "INSERT 3. row into $tbl" );
    ok( $dbh->do("UPDATE $tbl SET sex='m' WHERE name = 'Tom'"),           "UPDATE $tbl" );
    ok( $dbh->do("DELETE FROM $tbl WHERE name = 'Bev'"),                  "DELETE FROM $tbl" );
    #  print $dbh->func('SELECT * FROM test','ad_dump');
    if ( $format ne 'ARRAY' )
    {
        if ( $format =~ /XML|HTMLtable/ )
        {
            $dbh->func( $tbl, $format, $file, $flags, 'ad_export' );    # save to disk
        }
        $dbh->func( $tbl, 'ad_clear' );                                 # clear from memory
        $dbh->func( $tbl, $format, $file, $flags, 'ad_import' );        # read from disk
    }
    my %val;
    $val{single_select} = $dbh->selectrow_array(                        # display single value
                                                 qq/SELECT sex FROM $tbl WHERE name = 'Sue'/
                                               );
    is( 'f', $val{single_select}, "Single select" );
    my $sth = $dbh->prepare(                                            # display multiple rows
                             qq/SELECT name FROM $tbl WHERE country = ?/
                           );
    $sth->execute('fr');
    while ( my ($name) = $sth->fetchrow )
    {
        $val{select_multiple} .= $name;
    }
    is( "SueTom", $val{select_multiple}, "Multiple select" );
    $sth = $dbh->prepare("SELECT * FROM $tbl");                         # display column names
    $sth->execute();
    $val{names} = join ',', @{ $sth->{NAME_lc} };
    is( "name,country,sex", $val{names}, "Names" );
    $val{rows} = $sth->rows;                                            # display number of rows
    is( 2, $val{rows}, "rows" );

    if ( $format ne 'ARRAY' )
    {
        my $str = $dbh->func(                                           # convert to
                              'ARRAY', [ [ "a", "b" ], [ 1, 2 ] ], $format, undef, undef, $flags, 'ad_convert'
                            );
        $str =~ s/\s+/,/ if $format eq 'Fixed';
        my $ary = $dbh->func(                                           # convert from
                              $format, [$str], 'ARRAY', undef, $flags, 'ad_convert'
                            );
        is( 'a', $ary->[0]->[0], "ad_convert" );
    }
    return "ok";
}
__END__
