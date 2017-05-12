# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use strict ;

use vars qw{ *set1 *set2 *set3 *set4 *set5 *set6 *set7 *set8 *set9 *set10
             *set11 *set12 *set13 *set14 *set15 *set16 *set17 *set18 *set19 *set20
             *set1_ *set20c *set13h *set13h2 %set15h
             @TestData @TestFields %TestCheck %hTestFields1 %hTestIds1 @TestSetup @TestIds
             @Table $Driver $DSN $User $Password
             @drivers %Drivers 
             $dbh $drv %errcnt $err $rc $contcnt $lasttest
             $errors $fatal $loaded
             $Join $SQLJoin $CreateNULL $EmptyIsNull
             *rs $rs @rs %rs
             $nocleanup
             $QuoteIdentifier} ;


use Data::Dumper;


BEGIN { $| = 1;  $fatal = 1 ; print "\nLoading...                "; }

END {
    print "not ok 1\n" unless $loaded ;
    print "\nTest terminated with fatal error! Look at test.log\n" if ($fatal) ;
    }


use DBIx::Recordset ;
use DBIx::Recordset::FileSeq ;
use DBIx::Recordset::DBSeq ;

$loaded = 1;
print "ok\n";

######################### End of black magic.


my $configfile = 'test/Config.pl' ;

#################################################

sub printlog
    {
    print $_[0] ;
    print LOG $_[0] ;
    }


sub printlogf
    {
    my $txt = shift ;
    if (!$txt)
        {
        $txt = "  - $contcnt " ;
        $contcnt++ ;
        }
    else
        {
        $lasttest = $txt ;
        $contcnt = 2 ;
        }

    printlog ($txt  . '... ' . (' ' x (35 - length ($txt)))) ;
    }



sub sigwarn
    {
    my $msg = shift ;

    print LOG "WARN: $msg\n" ;
    }

$SIG{__WARN__} = \&sigwarn ;

#################################################

sub Check 

    {
    my ($ids, $fields, $set, $idfield, $hash) = @_ ;
    my $id ;
    my $field ;
    my $i ;
    my $n ;
    my $is ;
    my $should ;
    my %setid ;
    my $dat ;
    my $v ;
    my $k ;

    local $^W = 0 ;

    print LOG "IDS EXPECTED: @$ids\n" ;
    
    $idfield ||= 'id' ;

    if (($dat = $$set[0]) && defined ($hash))
        {
        $n = $#$fields + 1 ;
        $i = 0 ;
        $v = $$dat{$idfield} ;
        print LOG "Check Hash $idfield = $v : $$hash{$idfield}\n" ;
        while (($k, $v) = each (%$dat))
            {
            $i++ ;
            print LOG "Field: $k Array: $v Hash: $$hash{$k}\n" ;
            if ($v ne $$hash{$k})
                {
                printlog "ERROR in $lasttest\n" ;
                printlog "Field: $k Array: $v Hash: $$hash{$k}\n" ;
                $errors++ ;
                return 1 ;
                }
            }

        if ($i != $n)
            {
            printlog "ERROR in $lasttest\n" ;
            printlog "Wrong number of fields in ::Row (get $i, expected $n)\n" ;
            $errors++ ;
            return 1 ;
            } 

        $i = 0 ;
        while (($k, $v) = each (%$hash))
            {
            $i++ ;
            if ($v ne $$dat{$k})
                {
                printlog "ERROR in $lasttest\n" ;
                printlog "Field: $k Array: $$dat{$k} Hash: $v\n" ;
                $errors++ ;
                return 1 ;
                }
            }

        if ($i != $n)
            {
            printlog "ERROR in $lasttest\n" ;
            printlog "Wrong number of fields in ::CurrRow (get $i, expected $n)\n" ;
            $errors++ ;
            return 1 ;
            } 

        }

    $i = 0 ;
    $n = $#$ids + 1 ;
    while ($dat = $$set[$i])
        {
#	    print LOG "\tV ";
	    $v = $$dat{$idfield} ;
#	    print LOG "  <$v>  ";
        $v =~ s/^(.*?)\s*$/$1/ ; 
#	    print LOG "  <$v>  \n";
        $setid{$v} = $i ;
        print LOG "idfield =$idfield;$v;$i; \n" ;
        print LOG "CHK-DAT:" ;
        while (($k, $v) = each (%$dat))
            { $v ||= '' ; print LOG "$k=$v; " ; }
        #print "$idfield = $$dat{$idfield} = $i\n" ;
        $i++ ;
        print LOG "\n" ;
        }

    #print "get $i, expected $n\n" ;

    if ($i < $n)
        {
        printlog "ERROR in $lasttest\n" ;
        printlog "Got too few rows (got $i, expected $n)\n" ;
        $errors++ ;
        return 1 ;
        } 
    
    if ($i > $n)
        {
        printlog "ERROR in $lasttest\n" ;
        printlog "Got too many rows (got $i, expected $n)\n" ;
        $errors++ ;
        return 1 ;
        } 
    
    foreach $id (@$ids)
      {
	  $dat = $$set[$setid{$id}] ;
	  print LOG "id =$id;$setid{$id};dat = " . Dumper($dat) . "\n" ;
	  foreach $field (@$fields)
	    {
            if (exists ($TestCheck{$id}{$field}))
                {
                $should = $TestCheck{$id}{$field} ;
		print LOG "should-bound-a via $id and $field\n" ;
                }
            else
                {
                $should = $TestCheck{$TestCheck{$id}{'id'}}{$field} ;
		print LOG "should-bound-b\n" ;
                }
    
	    if (!defined ($should) && !$EmptyIsNull) {
		$should = 'NULL' ;
		print LOG "should-bound-c\n" ;
	    }

            if (defined ($$dat{$field}) || $EmptyIsNull) 
                {
                $$dat{$field} =~ /^(.*?)\s*$/ ;
                $is = $1 ; 
		print LOG "\$is = $1 because \$dat->{$field} = $$dat{$field}\n";
                }
            else
                {
                $is = 'NULL' ;
                }

            print LOG "CHK-OK-a?: $idfield = $id; $field = <$is>; Should = <$should>\n" ;
             
            if ($should ne $is)
                {
                printlog "ERROR in $lasttest\n" ;
                printlog "$idfield     = $id\n" ;
                printlog "The field named $field\n" ;
                printlog "has value $is\n" ;
                printlog "When it should have value $should\n" ;
                $errors++ ;
                return 1 ;
                }
            }
        }


    return 0 ;
    }

#################################################

sub CheckField 

    {
    my ($name, $is, $should) = @_ ;
    
    if (defined ($is) || $EmptyIsNull) 
        {
        $is =~ /^(.*?)\s*$/ ;
        $is = $1 ; 
        }
    else
        {
        $is = 'NULL' ;
        }
    $should = 'NULL' if (!defined ($should) && !$EmptyIsNull) ;

    print LOG "CHK-OK-b?: $name = <$is>; Should = <$should>\n" ;
     
    if ($should ne $is)
        {
        printlog "ERROR in $lasttest\n" ;
        printlog "Field  = $name\n" ;
        printlog "Is     = $is\n" ;
        printlog "Should = $should\n" ;
        $errors++ ;
        return 1 ;
        }

    return 0 ;
    }


#################################################

sub AddTestRow

    {
    my ($tabno, $dat, $key) = @_ ;

    my $ex = 0 ;
    my $id ;
    my $v ;
    my $k ;

    $key ||= 'id' ;
    
    $id = undef ;
    $ex = exists ($$dat{$key}) ;
    if ($ex)
        { $id = $$dat{$key}  ; }
    else
        { $id = $$dat{"*$key"} ; }
    $id =~ s/\'(.*?)\'/$1/ ; 
    while (($k, $v) = each (%$dat))
        {
        if (defined ($v) && $v eq 'NULL')
            {
            $v = undef ;
            }
        else
            {
            $v =~ s/\'(.*?)\'/$1/ if ($v) ; 
            }
        $TestCheck{$id}{$k} = $v ;
        print LOG "TEST-DAT: Table $Table[$tabno] \$TestCheck{$id}{$k} = " . ($v || '') . "\n" ;
        if ($ex)
            {
            #$hTestFields{$k} = 1 ;
            $hTestFields1{$k} = 1 ;
            }
        }
    #if ($ex)
        {
        #$hTestIds{$id} = 1 ;
        $hTestIds1{$id} = 1 ;
        }

    delete $$dat{"*$key"} ;
    

    {
    local $^W= 0 ;
    my @names = map { ($_ =~ /\s/)?"\"$_\"":$_ } keys(%$dat) ;
    $k = join (',', @names) ;
    $v = join (',', values(%$dat)) ;
    }

    my $t = $Table[$tabno]  ;
    $t = ($t =~ /\s/)?"\"$t\"":$t ;

    push (@TestSetup, "INSERT INTO $t ($k) VALUES ($v)") if ($v && $k) ;

    }



sub AddTestRowAndId

    {
    my ($tabno, $dat, $key) = @_ ;
    
    my $id ;

    local %hTestIds1 ;
    local %hTestFields1 ;

    AddTestRow ($tabno, $dat, $key) ;

    foreach $id (@{$TestIds[$tabno]})
        {
        $hTestIds1{$id} = 1 ;
        }
            
    my @ids = keys %hTestIds1 ;
    $TestIds[$tabno] = \@ids ;
    }

sub DelTestRowAndId

    {
    my ($tabno, $id) = @_ ;
    
    my $tid ;

    delete $TestCheck{$id} ;

    local %hTestIds1 ;

    foreach $tid (@{$TestIds[$tabno]})
        {
        $hTestIds1{$tid} = 1 if ($tid ne $id) ;
        }
            
    my @ids = keys %hTestIds1 ;
    $TestIds[$tabno] = \@ids ;
    }

#################################################

sub AddTestData

    {
    my ($tabno, $key) = @_ ;

    my $dat ;

    local %hTestIds1 ;
    local %hTestFields1 ;
    my $ex = 0 ;

    $key ||= 'id' ;
    
    foreach $dat (@{$TestData[$tabno]})
        {
        AddTestRow ($tabno, $dat, $key) ;
        }
    
    
    my @ids = keys %hTestIds1 ;
    $TestIds[$tabno] = \@ids ;
    my @fld = keys %hTestFields1 ;
    $TestFields[$tabno] = \@fld ;
    }


#################################################

sub DropTestTables   {
    my ($_dbh, @tlist) =@_;
    return unless ($dbh and @tlist);
    foreach (@tlist) 
      {
	  if ($QuoteIdentifier)
            {
		if (!$_dbh->do( "DROP TABLE \"$_\""))
		  {
		      $_dbh->do( 'DROP TABLE "'. uc ($_) . '"') ;
		  }
            }
	  else
            {
		$_dbh->do( "DROP TABLE $_");
            }
    
      };
    print LOG '-- Dropped ', join(', ', @tlist), "\n" ;
}

 
#################################################

sub DoTest

    {

    $Driver      = $_[0] ;
    $DSN         = $_[1]  ; 
    $User        = $_[2] ;
    $Password    = $_[3] ;

    $Join    =  DBIx::Compat::GetItem ($Driver, 'SupportJoin') ;
    $SQLJoin =  DBIx::Compat::GetItem ($Driver, 'SupportSQLJoin') ;
    $CreateNULL = DBIx::Compat::GetItem ($Driver, 'NeedNullInCreate') ;
    $EmptyIsNull= DBIx::Compat::GetItem ($Driver, 'EmptyIsNull') ;
    $QuoteIdentifier= DBIx::Compat::GetItem ($Driver, 'QuoteIdentifier') ;

    @Table       = ('dbixrs1', 'dbixrs2', 'dbixrs3', 'dbixrs4', 'dbix_rs5', 'dbix_rs6', 'dbixseq', 'dbixrsdel') ;

    push @Table, 'DBIXRS 8' if ($QuoteIdentifier) ;

    $errors = 0 ;

    printlog "\nUsing the following parameters for testing:\n" ;
    printlog "  DBD-Driver:  $Driver\n" ;
    printlog "  Database:    $DSN\n" ;
    printlog "  User:        " . ($User || '') . "\n" ;
    printlog "  Password:    " . ($Password || '') . "\n" ;
    

    my $t ;
    for $t (@Table)
        {
        printlog "  Table:       $t\n" ;
        }

    #printlog "host:        $Host\n" ;

    printlog "\n" ;


    $dbh = DBI->connect ("$DSN",$User, $Password) or die "Cannot connect to $DSN ($DBI::errstr)" ;

    printlog "  Driver does not support joins, skiping tests with multiple tables\n\n" if (!$Join) ;

no strict ;
    printlog "  DBI-Version: " . $DBI::VERSION . "\n" ;
    printlog "  DBD-Version: " . ${"DBD\:\:$Driver\:\:VERSION"} . "\n\n" ;
use strict ;

    printlogf "Creating the testtables";
    print LOG "\n--------------------\n" ;
    @TestSetup =
        (
        "CREATE TABLE $Table[0] ( id INT $CreateNULL, name CHAR (20) $CreateNULL, value1 INT $CreateNULL, addon " . ($Driver eq 'mysql'?'TEXT':'CHAR(20)') . " $CreateNULL)",
        "CREATE TABLE $Table[1] ( id INTEGER $CreateNULL, name2 VARCHAR(20) $CreateNULL, value2 INTEGER $CreateNULL, $Table[3]_id INTEGER $CreateNULL)",
        "CREATE TABLE $Table[2] ( value1 INTEGER $CreateNULL, txt " . ($Driver eq 'mysql'?'TEXT':'CHAR(20)') . " $CreateNULL )",
        "CREATE TABLE $Table[3] ( id INTEGER $CreateNULL, typ CHAR(20) $CreateNULL)",
        "CREATE TABLE $Table[4] ( id INTEGER $CreateNULL, txt5 CHAR(20) $CreateNULL, up__rs5_id INTEGER $CreateNULL,  a__rs6_id INTEGER $CreateNULL,  b__rs6_id INTEGER $CreateNULL)",
        "CREATE TABLE $Table[5] ( id INTEGER $CreateNULL, txt6 CHAR(20) $CreateNULL)",
        "CREATE TABLE $Table[6] ( name varchar (32) $CreateNULL, cnt INTEGER $CreateNULL, maxcnt integer)",
        "CREATE TABLE $Table[7] ( id integer, dbixrsdel_id integer)",
        ) ;

    push @TestSetup, "CREATE TABLE \"$Table[8]\" ( id integer, \"id 2\" integer)" if ($QuoteIdentifier) ;

    @TestData =
        (
            [
                { 'id' => 1 ,  'name' => "'First Name'",    'value1' => 9991,  'addon' => "'Is'" },
                { 'id' => 2 ,  'name' => "'Second Name'",   'value1' => 9992,  'addon' => "'it'" },
                { 'id' => 3 ,  'name' => "'Third Name'",    'value1' => 9993,  'addon' => "'it ok?'" },
                { 'id' => 4 ,  'name' => "'Fourth Name'",   'value1' => 9994,  'addon' => "'Or not??'" },
                { 'id' => 5 ,  'name' => "'Fivth Name'",    'value1' => 9995,  'addon' => "'Is'" },
                { 'id' => 6 ,  'name' => "'Sixth Name'",    'value1' => 9996,  'addon' => "'it'" },
                { 'id' => 7 ,  'name' => "'Seventh Name'",  'value1' => 9997,  'addon' => "'it ok?'" },
                { 'id' => 8 ,  'name' => "'Eighth Name'",   'value1' => 9998,  'addon' => "'Or not??'" },
                { 'id' => 9 ,  'name' => "'Ninth Name'",    'value1' => 9999,  'addon' => "'Is'" },
                { 'id' => 10,  'name' => "'Tenth Name'",    'value1' => 99910, 'addon' => "'it'" },
                { 'id' => 11,  'name' => "'Eleventh Name'", 'value1' => 99911, 'addon' => "'it ok?'" },
                { 'id' => 12,  'name' => "'Twelvth Name'",  'value1' => 99912, 'addon' => "''" },
                { 'id' => 13,  'name' => "'Thirdteenth Name'",  'value1' => 'NULL', 'addon' => 'NULL' },
                { 'id' => 14,  'name' => "'Fourteenth Name'",  'value1' => 0, 'addon' => 'NULL' },
                { 'id' => 15,  'name' => "15",  'value1' => 15, 'addon' => 'NULL' },
                { 'id' => 16,  'name' => "15",  'value1' => 15, 'addon' => 'NULL' },
                { 'id' => 17,  'name' => 1,  'value1' => 2, 'addon' => 'NULL' },
                { 'id' => 18,  'name' => 3,  'value1' =>  42, 'addon' => '42' },
                { 'id' => 19,  'name' => 2,  'value1' =>  42, 'addon' => '42' },
                { 'id' => 20,  'name' => 2,  'value1' =>  3, 'addon' => '42' },

            ],
            [
                { 'id' => 1 ,  'name2' => "'First Name in Tab2'",  'value2' => 29991, "$Table[3]_id" => 1  },
                { 'id' => 2 ,  'name2' => "'Second Name in Tab2'", 'value2' => 29992, "$Table[3]_id" => 2  },
                { 'id' => 3 ,  'name2' => "'Third Name in Tab2'",  'value2' => 29993, "$Table[3]_id" => 3  },
                { 'id' => 4 ,  'name2' => "'Fourth Name in Tab2'", 'value2' => 29994, "$Table[3]_id" => 4  },
            ],
            [
                { '*id' => 1 ,  'txt' => "'First Item   (9991 )'", 'value1' => 9991, },
                { '*id' => 2 ,  'txt' => "'Second Item  (9992 )'", 'value1' => 9992, },
                { '*id' => 3 ,  'txt' => "'Third Item   (9993 )'", 'value1' => 9993, },
                { '*id' => 4 ,  'txt' => "'Fourth Item  (9994 )'", 'value1' => 9994, },
                { '*id' => 5 ,  'txt' => "'Fivth Item   (9995 )'", 'value1' => 9995, },
                { '*id' => 6 ,  'txt' => "'Sixth Item   (9996 )'", 'value1' => 9996, },
                { '*id' => 7 ,  'txt' => "'Seventh Item (9997 )'", 'value1' => 9997, },
                { '*id' => 8 ,  'txt' => "'Eighth Item  (9998 )'", 'value1' => 9998, },
                { '*id' => 9 ,  'txt' => "'Ninth Item   (9999 )'", 'value1' => 9999, },
                { '*id' => 10,  'txt' => "'Tenth Item   (99910)'", 'value1' => 99910,},
                { '*id' => 11,  'txt' => "'Eleventh Item(99911)'", 'value1' => 99911,},
                { '*id' => 12,  'txt' => "'Twelvth Item (99912)'", 'value1' => 99912,},
            ],

            [
                { 'id' => 1 , 'typ' => "'First item Type 1'" },
                { 'id' => 1 , 'typ' => "'First item Type 2'" },
                { 'id' => 1 , 'typ' => "'First item Type 3'" },
                { 'id' => 2 , 'typ' => "'Second item Type 1'" },
                { 'id' => 2 , 'typ' => "'Second item Type 2'" },
                { 'id' => 2 , 'typ' => "'Second item Type 3'" },
                { 'id' => 2 , 'typ' => "'Second item Type 4'" },
                { 'id' => 3 , 'typ' => "'Third item Type 1'" },
    #            { 'id' => 4 , 'typ' => "'Fours item Type 1'" },
            ],
            [
                { 'id' => 1 ,  'txt5' => "'1 in Tab5'",  "up__rs5_id" => 'NULL', "a__rs6_id" => 1,  "b__rs6_id" => 1   },
                { 'id' => 2 ,  'txt5' => "'2 in Tab5'",  "up__rs5_id" => 1,      "a__rs6_id" => 2,  "b__rs6_id" => 1   },
                { 'id' => 3 ,  'txt5' => "'3 in Tab5'",  "up__rs5_id" => 1,      "a__rs6_id" => 3,  "b__rs6_id" => 1   },
                { 'id' => 4 ,  'txt5' => "'4 in Tab5'",  "up__rs5_id" => 1,      "a__rs6_id" => 4,  "b__rs6_id" => 1   },
                { 'id' => 5 ,  'txt5' => "'5 in Tab5'",  "up__rs5_id" => 2,      "a__rs6_id" => 5,  "b__rs6_id" => 1   },
                { 'id' => 6 ,  'txt5' => "'6 in Tab5'",  "up__rs5_id" => 2,      "a__rs6_id" => 6,  "b__rs6_id" => 1   },
                { 'id' => 7 ,  'txt5' => "'7 in Tab5'",  "up__rs5_id" => 3,      "a__rs6_id" => 7,  "b__rs6_id" => 1   },
                { 'id' => 8 ,  'txt5' => "'8 in Tab5'",  "up__rs5_id" => 4,      "a__rs6_id" => 8,  "b__rs6_id" => 1   },
                { 'id' => 9 ,  'txt5' => "'9 in Tab5'",  "up__rs5_id" => 4,      "a__rs6_id" => 9,  "b__rs6_id" => 1   },
            ],
            [
                { 'id' => 1 ,  'txt6' => "'1 in Tab6'",   },
                { 'id' => 2 ,  'txt6' => "'2 in Tab6'",   },
                { 'id' => 3 ,  'txt6' => "'3 in Tab6'",   },
                { 'id' => 4 ,  'txt6' => "'4 in Tab6'",   },
                { 'id' => 5 ,  'txt6' => "'5 in Tab6'",   },
                { 'id' => 6 ,  'txt6' => "'6 in Tab6'",   },
                { 'id' => 7 ,  'txt6' => "'7 in Tab6'",   },
                { 'id' => 8 ,  'txt6' => "'8 in Tab6'",   },
                { 'id' => 9 ,  'txt6' => "'9 in Tab6'",   },
            ],
            [],
            [
                { id => 1, dbixrsdel_id => 2 },
                { id => 2, dbixrsdel_id => 3 },
                { id => 3, dbixrsdel_id => 4 },
                { id => 4, dbixrsdel_id => 1 },
            ],
        ) ;


    $TestData[8] = [ 
                { 'id' => 1 ,  'id 2' => 12,   },
                { 'id' => 2 ,  'id 2' => 13    },
                ] if ($QuoteIdentifier) ;


    my $i ;

    for ($i = 0; $i <= $#Table; $i++)
        {
        AddTestData ($i) if ($i != 3 && $TestData[$i]) ;
        }

    AddTestData (3, 'typ') ;

    #@AllTestIds = keys %hTestIds ;
    #@AllTestFields = keys %hTestFields ;

    my %count = ();
    my $element ;
    foreach $element (@{$TestFields[0]}) { $count{$element}++ }
    foreach $element (@{$TestFields[1]}) { $count{$element}++ }
    my @TestFields0_1 = keys %count ;


    #goto skip1 ;

    my $st ;
    my $rc ;
    print LOG "--- \"Table does not exist\" warnings may appear here. Please ignore.\n" ;
    DropTestTables($dbh, @Table);
 

    foreach $st (@TestSetup)
        {
        $rc = $dbh -> do ($st) ;
        print LOG "$st ->($rc)\n" ;
        if (!$rc && $st =~ /^\S/)
            {
            die "Cannot do $st ($DBI::errstr)" ;
            } 
        }

    skip1:

    #$dbh->commit () ;
#    $dbh->disconnect ; # or die "Cannot disconnect from $DSN ($DBI::errstr)" ;

#    undef $dbh ;

    printlog "ok\n";

    #########################################################################################
    #
    # Start Tests
    #

    $errors = 0 ;

    # ---------------------

    printlogf "Setup Object for $Table[0]";
    print LOG "\n--------------------\n" ;

    $set1 = DBIx::Recordset->New ($dbh, $Table[0], $User, $Password) or die "not ok\n" ;
    tie @set1, 'DBIx::Recordset', $set1 ;
    tie %set1, 'DBIx::Recordset::CurrRow', $set1 ;


    printlog "ok\n";

    printlogf "SQLSelect All";
    print LOG "\n--------------------\n" ;

    $set1 -> SQLSelect ()  or die "not ok ($DBI::errstr)" ;

    Check ($TestIds[0], $TestFields[0], \@set1, undef, \%set1) or print "ok\n" ;

    #$^W = 1 ;

    DBIx::Recordset::Undef ('set1') ;

    # ---------------------

    printlogf "Setup Object for $Table[1]";
    print LOG "\n--------------------\n" ;

    $set2 = tie @set2, 'DBIx::Recordset', { '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[1]} or die "not ok ($DBI::errstr)" ;
    tie %set2, 'DBIx::Recordset::CurrRow', $set2 ;

    printlog "ok\n";

    printlogf "SQLSelect All";
    print LOG "\n--------------------\n" ;

    $set2 -> SQLSelect ()  or die "not ok ($DBI::errstr)" ;

    Check ($TestIds[1], $TestFields[1], \@set2, undef, \%set2) or print "ok\n" ;

    DBIx::Recordset::Undef ('set2') ;

    # ---------------------

    if ($Join)
        {
        printlogf "Setup Object for $Table[0], $Table[1]";
        print LOG "\n--------------------\n" ;

        $set3 = DBIx::Recordset->New ($dbh, "$Table[0], $Table[1]", $User, $Password) or die "not ok\n" ;
        tie @set3, 'DBIx::Recordset', $set3 ;
        tie %set3, 'DBIx::Recordset::CurrRow', $set3 ;

        printlog "ok\n";

        printlogf "SQLSelect All";
        print LOG "\n--------------------\n" ;

        if ($Driver eq 'mSQL')
            {
            my @f ;
            my $f ;
            my $fl ;
        
            foreach $fl (@{$TestFields[0]}) 
                {
                push @f, "$Table[0].$fl" ;
                }
            foreach $fl (@{$TestFields[1]}) 
                {
                push @f, "$Table[1].$fl" ;
                }
            $f = join (',', @f) ;

            $set3 -> SQLSelect ("$Table[0].id=$Table[1].id", $f)  or die "not ok ($DBI::errstr)" ;
            }
        else
            {    
            $set3 -> SQLSelect ("$Table[0].id=$Table[1].id")  or die "not ok ($DBI::errstr)" ;
            }

        Check ($TestIds[1], \@TestFields0_1, \@set3) or print "ok\n" ;

        DBIx::Recordset::Undef ('set3') ;

        # ---------------------

        printlogf "Setup Object for $Table[0], $Table[2]";
        print LOG "\n--------------------\n" ;

        $set4 = tie @set4, 'DBIx::Recordset', { '!DataSource'   =>  $dbh,
                                                '!Username'     =>  $User,
                                                '!Password'     =>  $Password,
                                                '!Table'        =>  "$Table[0], $Table[2]"} or die "not ok ($DBI::errstr)" ;

        tie %set4, 'DBIx::Recordset::CurrRow', $set4 ;

        printlog "ok\n";

        printlogf "SQLSelect All";
        print LOG "\n--------------------\n" ;

        if ($Driver eq 'mSQL')
            {        
            $set4 -> SQLSelect ("$Table[0].value1=$Table[2].value1", "$Table[0].id, $Table[0].name, $Table[2].txt")  or die "not ok ($DBI::errstr)" ;
            }
        else
            {
            $set4 -> SQLSelect ("$Table[0].value1=$Table[2].value1", "id, name, txt")  or die "not ok ($DBI::errstr)" ;
            }

        Check ($TestIds[2], ['id', 'name', 'txt'], \@set4) or print "ok\n" ;

        DBIx::Recordset::Undef ('set4') ;

        # ---------------------

        printlogf "Setup Object for $Table[0], $Table[3]";
        print LOG "\n--------------------\n" ;

        $set5 = DBIx::Recordset->New ($dbh, "$Table[0], $Table[3]", $User, $Password) or die "not ok\n" ;
        tie @set5, 'DBIx::Recordset', $set5 ;
        tie %set5, 'DBIx::Recordset::CurrRow', $set5 ;

        printlog "ok\n";

        printlogf "SQLSelect All";
        print LOG "\n--------------------\n" ;

        if ($Driver eq 'mSQL')
            {        
            $set5 -> Select ("$Table[0].id=$Table[3].id", "$Table[0].name, $Table[3].typ") or die "not ok ($DBI::errstr)" ;
            }
        else
            {
            $set5 -> Select ("$Table[0].id=$Table[3].id", "name, typ") or die "not ok ($DBI::errstr)" ;
            }

        Check ($TestIds[3], ['name', 'typ'], \@set5, 'typ') or print "ok\n" ;

        DBIx::Recordset::Undef ('set5') ;
        } # if ($Join)

    # ---------------------

    printlogf "Setup Object for $Table[0]";
    print LOG "\n--------------------\n" ;

    $set1 = tie @set1, 'DBIx::Recordset', { '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[0]} or die "not ok ($DBI::errstr)" ;
    tie %set1, 'DBIx::Recordset::CurrRow', $set1 ;

    printlog "ok\n";

    # ---------------------

    printlogf "Select id (where as hash)";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({'id'=>2, '$operator'=>'='})  or die "not ok ($DBI::errstr)" ;

    Check ([2], $TestFields[0], \@set1, undef, \%set1) or print "ok\n" ;

    # ---------------------

    printlogf "Select id (where as string)";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ('id=4')  or die "not ok ($DBI::errstr)" ;

    Check ([4], $TestFields[0], \@set1) or print "ok\n" ;


    # ---------------------


    printlogf "Select name";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({name => 'Third Name', '$operator'=>'='})  or die "not ok ($DBI::errstr)" ;

    Check ([3], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    if ($Join)
        {
        printlogf "Select $Table[0].name";
        print LOG "\n--------------------\n" ;

        $set1 -> Select ({"$Table[0].name" => 'Fourth Name', '$operator'=>'='})  or die "not ok ($DBI::errstr)" ;

        Check ([4], $TestFields[0], \@set1) or print "ok\n" ;

        # ---------------------

        printlogf "Select $Table[1].name2 id=id";
        print LOG "\n--------------------\n" ;

        *set1_ = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  "$Table[0], $Table[1]",
                                            '!Fields'       =>  "$Table[0].id, $Table[0].name, $Table[0].value1, $Table[0].addon",
                                           "'$Table[1].name2" => 'Second Name in Tab2',
                                           "\\$Table[0].id" => "$Table[1].id",
                                           '$operator'=>'='})  or die "not ok ($DBI::errstr)" ;

        Check ([2], $TestFields[0], \@set1_) or print "ok\n" ;

        # ---------------------

        printlogf "Select $Table[1].value2 id=id";
        print LOG "\n--------------------\n" ;

        $set1_ -> Select ({"\#$Table[1].value2" => '29993',
                               "\\$Table[0].id" => "$Table[1].id",
                               '$operator' => '='})  or die "not ok ($DBI::errstr)" ;


        Check ([3], $TestFields[0], \@set1_) or print "ok\n" ;

        DBIx::Recordset::Undef ('set1_') ;
        }

    # ---------------------

    printlogf "Select multiply values";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({name => "Second Name\tFirst Name",
                           '$operator' => '='})  or die "not ok ($DBI::errstr)" ;


    
    Check ([1,2], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "Select multiply values array ref";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({name => ["Second Name", "Third Name"],
                           '$operator' => '='})  or die "not ok ($DBI::errstr)" ;


    
    Check ([2, 3], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "Select multiply values & operators";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({id          => [5,7],
                     '*id'        => ['>=', '<='],
                     '$valueconj' => 'and'})  or die "not ok ($DBI::errstr)" ;


    
    Check ([5, 6, 7], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------
    printlogf "Select \$valuesplit";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({value1 => "9991 9992\t9993",
                           '$valuesplit' => ' |\t',
                           '$operator' => '='})  or die "not ok ($DBI::errstr)" ;


    Check ([1,2,3], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "Select multiply fields 1";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({'+name&value1' => "9992",
                           '$operator' => '='})  or die "not ok ($DBI::errstr)" ;


    Check ([2], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "Select multiply fields 2";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({'+name&value1' => 15,
                           '$operator' => '='})  or die "not ok ($DBI::errstr)" ;


    Check ($Driver eq 'CSV'?[3]:[15, 16], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "Select multiply fields & values";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({'+name&value1' => "2\t3",
                           '$operator' => '='})  or die "not ok ($DBI::errstr)" ;


    Check ($Driver eq 'CSV'?[1,2]:[17,19,19,20], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    $set1 -> Search ({id => 1,name => 'First Name',addon => 'Is'})  or die "not ok ($DBI::errstr)" ;

    printlogf "MoreRecords yes";
    print LOG "\n--------------------\n" ;

    if (!$set1 -> MoreRecords)
        {
        printlog "ERROR in $lasttest: MoreRecords returns false\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }

    # ---------------------

    printlogf "Search";
    print LOG "\n--------------------\n" ;


    Check ([1], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "Search";
    print LOG "\n--------------------\n" ;

    $set1 -> Search ({id => 1,name => 'First Name',addon => 'Is'})  or die "not ok ($DBI::errstr)" ;


    Check ([1], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "MoreRecords no";
    print LOG "\n--------------------\n" ;

    if ($set1 -> MoreRecords)
        {
        printlog "ERROR in $lasttest: MoreRecords returns true\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }

    # ---------------------

    if ($Driver ne 'CSV')
        {
        printlogf "Search with subexpr";
        print LOG "\n--------------------\n" ;

        $set1 -> Search ({'$expr' => { id => 2, '*id' => '>' }, name => 'S', '*name' => '>'})  or die "not ok ($DBI::errstr)" ;


        Check ([3, 6, 7, 10, 12, 13], $TestFields[0], \@set1) or print "ok\n" ;
        }

    # ---------------------

    printlogf "Search first two";
    print LOG "\n--------------------\n" ;

    $set1 -> Search ({'$start'=>0,'$max'=>2, '$order'=>'id'})  or die "not ok ($DBI::errstr)" ;


    Check ([1,2], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "MoreRecords with \$max";
    print LOG "\n--------------------\n" ;

    if ($set1 -> MoreRecords)
        {
        printlog "ERROR in $lasttest: MoreRecords returns true\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }

    # ---------------------


    printlogf "MoreRecords(1) with \$max ";
    print LOG "\n--------------------\n" ;

    if (!$set1 -> MoreRecords(1))
        {
        printlog "ERROR in $lasttest: MoreRecords returns false\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }

    # ---------------------

    printlogf "MoreRecords with \$max 2";
    print LOG "\n--------------------\n" ;

    if ($set1 -> MoreRecords)
        {
        printlog "ERROR in $lasttest: MoreRecords returns true\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }



    # ---------------------

    printlogf "New Search for more";
    print LOG "\n--------------------\n" ;

    *set6 = DBIx::Recordset -> Search ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  $Table[0],
                                        '$start'        =>  2,
                                        '$max'          =>  2,
                                        '$next'         =>  1,
                                        '$order'        =>  'id',
                                        "id"            =>  "1\t2\t3\t4\t5\t6" }) or die "not ok ($DBI::errstr)" ;

    Check ([5,6], $TestFields[0], \@set6) or print "ok\n" ;


    # ---------------------


    printlogf "MoreRecords(1) with \$max no";
    print LOG "\n--------------------\n" ;

    if ($set6 -> MoreRecords(1))
        {
        printlog "ERROR in $lasttest: MoreRecords returns true\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }

    DBIx::Recordset::Undef ('set6') ;


    # ---------------------

    printlogf "New Search for more 2";
    print LOG "\n--------------------\n" ;

    *set6 = DBIx::Recordset -> Search ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  $Table[0],
                                        '$start'        =>  2,
                                        '$max'          =>  2,
                                        '$next'         =>  1,
                                        '$order'        =>  'id',
                                        "id"            =>  "1\t2\t3\t4\t5\t6" }) or die "not ok ($DBI::errstr)" ;

    my @data ;
    push @data, $set6[0] ;
    push @data, $set6[1] ;
    push @data, $set6[2] ;
    push @data, $set6[2] ;
    push @data, $set6[2] ;

    Check ([5,6], $TestFields[0], \@data) or print "ok\n" ;


    # ---------------------


    printlogf "MoreRecords(1) with \$max no 2";
    print LOG "\n--------------------\n" ;

    if ($set6 -> MoreRecords(1))
        {
        printlog "ERROR in $lasttest: MoreRecords returns true\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }

    DBIx::Recordset::Undef ('set6') ;

# ---------------------

    printlogf "Search next ones";
    print LOG "\n--------------------\n" ;

    $set1 -> Search ({'$start'=>0,'$max'=>2, '$next'=>1, '$order'=>'id'})  or die "not ok ($DBI::errstr)" ;

    Check ([3,4], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "Search prevs one";
    print LOG "\n--------------------\n" ;

    $set1 -> Search ({'$start'=>2,'$max'=>1, '$prev'=>1, '$order'=>'id'})  or die "not ok ($DBI::errstr)" ;

    Check ([2], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------


    printlogf "Search last ones";
    print LOG "\n--------------------\n" ;

    $set1 -> Search ({'$start'=>5,'$max'=>5, '$next'=>1, '$order'=>'id'})  or die "not ok ($DBI::errstr)" ;

    Check ([11, 12, 13, 14, 15], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    printlogf "Search goto last";
    print LOG "\n--------------------\n" ;

    $set1 -> Search ({'$start'=>5,'$max'=>5, '$last'=>1, '$order'=>'id'})  or die "not ok ($DBI::errstr)" ;

    Check ([16, 17, 18, 19, 20], $TestFields[0], \@set1) or print "ok\n" ;

    # ---------------------

    if ($Driver eq 'mSQL')
        {
	printlogf "Select NULL values";
	print LOG "\n--------------------\n" ;

	$set1 -> Select ({value1 => undef})  or die "not ok ($DBI::errstr)" ;


	Check ([13], $TestFields[0], \@set1) or print "ok\n" ;
	}
    else
	{
	printlogf "Select NULL values";
	print LOG "\n--------------------\n" ;

	$set1 -> Select ({value1 => 'xyz', '*value1' => 'is null'})  or die "not ok ($DBI::errstr)" ;


	Check ([13], $TestFields[0], \@set1) or print "ok\n" ;
    
	if ($Driver ne 'CSV')
	    {
	    #---------------------

	    printlogf "Select NOT NULL values";
	    print LOG "\n--------------------\n" ;

	    $set1 -> Select ({value1 => 'xyz', '*value1' => 'is not null'})  or die "not ok ($DBI::errstr)" ;


	    Check ([(1..12), (14..20)], $TestFields[0], \@set1) or print "ok\n" ;
	    }
	}	    
    #---------------------

    printlogf "Select empty values";
    print LOG "\n--------------------\n" ;

    if (!$EmptyIsNull)
	{
	$set1 -> Select ({addon => ''})  or die "not ok ($DBI::errstr)" ;


	Check ([12], $TestFields[0], \@set1) or print "ok\n" ;
	}
    else
	{
	printlog "skipping test on this plattform\n" ;
	}


    # ---------------------

    printlogf "Select 0";
    print LOG "\n--------------------\n" ;

    $set1 -> Select ({value1 => 0})  or die "not ok ($DBI::errstr)" ;


    Check ([14], $TestFields[0], \@set1) or print "ok\n" ;



    DBIx::Recordset::Undef ('set1') ;

    # ---------------------

    if ($Driver ne 'Sybase')
        {
	*set1 = DBIx::Recordset -> Setup ({'!DataSource' => $dbh,
						'!Username'     =>  $User,
						'!Password'     =>  $Password,
						'!Table'        =>  $Table[0],
						'!IgnoreEmpty'  =>  1}) or  die "not ok ($DBI::errstr)" ;

	printlogf "Select NULL values Ig-1";
	print LOG "\n--------------------\n" ;

	$set1 -> Select ({value1 => undef})  or die "not ok ($DBI::errstr)" ;


	Check ($TestIds[0], $TestFields[0], \@set1) or print "ok\n" ;

	# ---------------------

	printlogf "Select empty values Ig-1";
	print LOG "\n--------------------\n" ;

	if (!$EmptyIsNull)
	    {
	    $set1 -> Select ({addon => ''})  or die "not ok ($DBI::errstr)" ;


	    Check ([12], $TestFields[0], \@set1) or print "ok\n" ;
	    }
	else
	    {
	    printlog "skipping test on this plattform\n" ;
	    }

	# ---------------------

	printlogf "Select 0 Ig-1";
	print LOG "\n--------------------\n" ;

	$set1 -> Select ({value1 => 0})  or die "not ok ($DBI::errstr)" ;


	Check ([14], $TestFields[0], \@set1) or print "ok\n" ;



	DBIx::Recordset::Undef ('set1') ;

	# ---------------------

	*set1 = DBIx::Recordset -> Setup ({'!DataSource' => $dbh,
						'!Username'     =>  $User,
						'!Password'     =>  $Password,
						'!Table'        =>  $Table[0],
						'!IgnoreEmpty'  =>  2}) or  die "not ok ($DBI::errstr)" ;

	printlogf "Select NULL values Ig-2";
	print LOG "\n--------------------\n" ;

	$set1 -> Select ({value1 => undef})  or die "not ok ($DBI::errstr)" ;


	Check ($TestIds[0], $TestFields[0], \@set1) or print "ok\n" ;

	# ---------------------

	printlogf "Select empty values Ig-2";
	print LOG "\n--------------------\n" ;

	$set1 -> Select ({addon => ''})  or die "not ok ($DBI::errstr)" ;


	Check ($TestIds[0], $TestFields[0], \@set1) or print "ok\n" ;

	# ---------------------

	printlogf "Select 0 Ig-2";
	print LOG "\n--------------------\n" ;

	$set1 -> Select ({value1 => 0})  or die "not ok ($DBI::errstr)" ;


	Check ([14], $TestFields[0], \@set1) or print "ok\n" ;



	DBIx::Recordset::Undef ('set1') ;
	}

    # ---------------------
    if ($Join)
        {
        my $t0 ;
        my $t2 ;
 
        if ($Driver eq 'mSQL')
            {
            $t0 = "$Table[0]." ;
            $t2 = "$Table[2]." ;
            }
        else
            {
            $t0 = '' ;
            $t2 = '' ;
            }

        printlogf "New Search";
        print LOG "\n--------------------\n" ;

        *set6 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  "$Table[0], $Table[2]",
                                            '!TabRelation'  =>  "$Table[0].value1=$Table[2].value1",
                                            '!Fields'       =>  "$t0\lid, $t0\lname, $t2\ltxt",
                                            "$t0\lid"       =>  "2\t4" }) or die "not ok ($DBI::errstr)" ;

        Check ([2,4], ['id', 'name', 'txt'], \@set6) or print "ok\n" ;

        # ---------------------

        printlogf "Search cont";
        print LOG "\n--------------------\n" ;

        $set6 -> Search ({"$t0\lname"            =>  "Fourth Name" }) or die "not ok ($DBI::errstr)" ;

        Check ([4], ['id', 'name', 'txt'], \@set6) or print "ok\n" ;

        # ---------------------

        printlogf "Search \$operator <";
        print LOG "\n--------------------\n" ;

        $set6 -> Search ({"$t0\lid"       =>  3,
                          '$operator'     =>  '<' }) or die "not ok ($DBI::errstr)" ;

        Check ([1,2], ['id', 'name', 'txt'], \@set6) or print "ok\n" ;

        # ---------------------

        printlogf "Search *id *name";
        print LOG "\n--------------------\n" ;

        $set6 -> Search ({"$t0\lid"            =>  4,
                          "$t0\lname"          =>  'Second Name',
                          "\*$t0\lid"           =>  '<',
                          "\*$t0\lname"         =>  '<>' }) or die "not ok ($DBI::errstr)" ;

        Check ([1,3], ['id', 'name', 'txt'], \@set6) or print "ok\n" ;

        # ---------------------

        printlogf "Search \$conj or";
        print LOG "\n--------------------\n" ;

        $set6 -> Search ({"$t0\lid"            =>  2,
                          "$t0\lname"          =>  'Fourth Name',
                          "\*$t0\lid"           =>  '<',
                          "\*$t0\lname"         =>  '=',
                          '$conj'              =>  'or' }) or die "not ok ($DBI::errstr)" ;

        Check ([1,4], ['id', 'name', 'txt'], \@set6) or print "ok\n" ;

        # ---------------------

        printlogf "Search multfield *<field>";
        print LOG "\n--------------------\n" ;

        $set6 -> Search ({"+$t0\lid|$t0\ldbixrs1.value1" =>  "7\t9991",
                          "$t0\lname"           =>  'Fourth Name',
                          "\*$t0\lid"            =>  '<',
                          "\*$t0\lvalue1"         =>  '=',
                          "\*$t0\lname"          =>  '<>',
                          '$conj'               =>  'and' }) or die "not ok ($DBI::errstr)" ;

        Check ([1,2,3,5,6,7,8,9,10,11,12], ['id', 'name', 'txt'], \@set6) or print "ok\n" ;

        # ---------------------



        printlogf "Search \$compconj";
        print LOG "\n--------------------\n" ;

        $set6 -> Search ({"+$t0\lid|$t0\laddon"     =>  "6\t42",
                          "$t0\lname"          =>  'Fourth Name',
                          "\*$t0\lid"           =>  '>',
                          "\*$t0\laddon"        =>  '<>',
                          "\*$t0\lname"         =>  '=',
                          '$compconj'     =>  'and',
                          '$conj'         =>  'or' }) or die "not ok ($DBI::errstr)" ;

	if (!$EmptyIsNull)
	    {
	    Check ([4,7,8,9,10,11,12], ['id', 'name', 'txt'], \@set6) or print "ok\n" ;
	    }
	else	
	    {
	    Check ([1,3,4,5,7,8,9,10,11], ['id', 'name', 'txt'], \@set6) or print "ok\n" ;
	    }


        # ---------------------

        printlogf "Order, Group, Append";
        print LOG "\n--------------------\n" ;

        $set6 -> Search 
	  ({
	    id => 5, '$order' => 'id', '$group' => 'name', 
	    '$append' => ';;', '$makesql' => 1
	   }) ;

            {
            #my $should = 'SELECT id, name, txt FROM dbixrs1, dbixrs3 WHERE (dbixrs1.value1=dbixrs3.value1) and (  ((id = 5))) GROUP BY name ORDER BY id ;;' ;
            my $should = 'SELECT id, name, txt FROM dbixrs1, dbixrs3 WHERE (dbixrs1.value1=dbixrs3.value1) and (  (  (id = ?))) GROUP BY name ORDER BY id ;; ' ; # if ($set6 -> {'*Placeholders'}) ;
            $should = 'SELECT dbixrs1.id, dbixrs1.name, dbixrs3.txt FROM dbixrs1, dbixrs3 WHERE (dbixrs1.value1=dbixrs3.value1) and (  ((id = 5))) GROUP BY name ORDER BY id ;;' if ($Driver eq 'mSQL') ;
            my $is     = $set6 -> LastSQLStatement ;
            if ($is ne $should) 
                {
                print "ERROR in $lasttest: SQL Statement wrong\n" ;
                print LOG "Is:     $is\n" ;
                print LOG "Should: $should\n" ;
            
                $errors++ ;
                }
            else
                {
                print "ok\n" ;
                }
            }
        DBIx::Recordset::Undef ('set6') ;

        # ---------------------

        if ($SQLJoin == 1)
            {
            printlogf "Search with JOIN";
            print LOG "\n--------------------\n" ;

            *set6 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                                '!Username'     =>  $User,
                                                '!Password'     =>  $Password,
                                                '!Table'        =>  "$Table[0], $Table[2]",
                                                '!TabJoin'      =>  "$Table[0] LEFT JOIN $Table[2] on ($Table[0].value1=$Table[2].value1)",
                                                '!Fields'       =>  "$t0\lid, $t0\lname, $t2\ltxt",
                                                "$t0\lid"       =>  "1\t4" }) or die "not ok ($DBI::errstr)" ;

            Check ([1,4], ['id', 'name', 'txt'], \@set6) or print "ok\n" ;
            }


        DBIx::Recordset::Undef ('set6') ;

        # ---------------------

        printlogf "New Search id_typ";
        print LOG "\n--------------------\n" ;

        *set7 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  "$Table[0], $Table[3]",
                                            '!TabRelation'  =>  "$Table[0].id=$Table[3].id",
                                            '!Fields'       =>  "$Table[0].name, $Table[3].typ"}) or die "not ok ($DBI::errstr)" ;

        Check ($TestIds[3], ['name', 'typ'], \@set7, 'typ') or print "ok\n" ;

        DBIx::Recordset::Undef ('set7') ;

        # ---------------------

        printlogf "!LongNames with !Fields";
        print LOG "\n--------------------\n" ;

        *set7 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  "$Table[0], $Table[3]",
                                            '!TabRelation'  =>  "$Table[0].id=$Table[3].id",
                                            '!LongNames'    =>  1,
                                            '!Fields'       =>  "$Table[0].id, $Table[0].name, typ"}) or die "not ok ($DBI::errstr)" ;

        my $names = $set7 -> Names ;
        my $e = $errors ;

        if ($#$names != 2)
            {
            printlog "ERROR in $lasttest: wrong number of names ($#$names)\n" ;
	    $errors++ ;
            }        
        elsif ($names -> [0] ne "$Table[0].id" || $names -> [1] ne "$Table[0].name" || $names -> [2] ne "$Table[3].typ")
            {
            printlog "ERROR in $lasttest: names not ok (@$names)\n" ;
	    $errors++ ;
            }        
            

        print "ok\n" if ($e == $errors) ;


        DBIx::Recordset::Undef ('set7') ;

        # ---------------------

        printlogf "!LongNames without !Fields";
        print LOG "\n--------------------\n" ;

        *set7 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  "$Table[0], $Table[3]",
                                            '!TabRelation'  =>  "$Table[0].id=$Table[3].id",
                                            '!LongNames'    =>  1,
                                            }) or die "not ok ($DBI::errstr)" ;

        $names = $set7 -> Names ;
        $e = $errors ;

        if ($#$names != 5)
            {
            printlog "ERROR in $lasttest: wrong number of names ($#$names)\n" ;
	    $errors++ ;
            }        
        elsif ($names -> [0] ne "$Table[0].id" || $names -> [1] ne "$Table[0].name" ||
               $names -> [2] ne "$Table[0].value1" || $names -> [3] ne "$Table[0].addon" ||
               $names -> [4] ne "$Table[3].id" || $names -> [5] ne "$Table[3].typ")
            {
            printlog "ERROR in $lasttest: names not ok (@$names)\n" ;
	    $errors++ ;
            }        
            

        print "ok\n" if ($e == $errors) ;


        DBIx::Recordset::Undef ('set7') ;

        }

    # ---------------------

    if ($QuoteIdentifier) 
        {
        printlogf "Quoted Identifiers";
        print LOG "\n--------------------\n" ;
        *set1 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  "\"$Table[8]\"",
                                                })  or die "not ok ($DBI::errstr)" ;

        Check ([1, 2], $TestFields[8], \@set1) or print "ok\n" ;


        DBIx::Recordset::Undef ('set1') ;
        }


    # ---------------------


    printlogf "New Setup";
    print LOG "\n--------------------\n" ;
    *set8 = DBIx::Recordset -> Setup  ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]"}) or die "not ok ($DBI::errstr)" ;

    print "ok\n" ;

    printlogf "SQLInsert";
    print LOG "\n--------------------\n" ;

    my %h = ('id'    => 21,
          'name2' => 'sqlinsert id 21',
          'value2'=> 1021) ;

    $set8 -> SQLInsert ('id, name2, value2', "21, 'sqlinsert id 21', 1021") or die "not ok ($DBI::errstr)" ;
    AddTestRowAndId (1, \%h) ;

    $set8 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set8) or print "ok\n" ;
    
    DBIx::Recordset::Undef ('set8') ;

    # ---------------------

    printlogf "New Insert";
    print LOG "\n--------------------\n" ;

    %h = ('id'    => 22,
          'name2' => 'sqlinsert id 22',
          'value2'=> 1022) ;


    *set9 = DBIx::Recordset -> Insert ({%h,
                                        ('!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[1]")}) or die "not ok ($DBI::errstr)" ;
    AddTestRowAndId (1, \%h) ;

    $set9 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set9) or print "ok\n" ;
    
    # ---------------------

    printlogf "Insert without quoting";
    print LOG "\n--------------------\n" ;

    %h = ('id'    => 229,
          '\name2' => "'sqlinsert id 229'",
          'value2'=> undef) ;


    $set9  -> Insert (\%h)  or die "not ok ($DBI::errstr)" ;

    $h{name2} = 'sqlinsert id 229' ;

    AddTestRowAndId (1, \%h) ;

    $set9 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set9) or print "ok\n" ;
    
    # ---------------------

    printlogf "Update";
    print LOG "\n--------------------\n" ;

    %h = ('id'    => 22,
          'name2' => 'sqlinsert id 22u',
          'value2'=> 2022) ;


    $set9 -> Update (\%h, 'id=22') or die "not ok ($DBI::errstr)" ;
    AddTestRowAndId (1, \%h) ;

    $set9 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set9) or print "ok\n" ;
    
    # ---------------------

    printlogf "Update without quoting";
    print LOG "\n--------------------\n" ;

    %h = ('id'    => 229,
          '\name2' => "'sqlinsert id 229uq'",
          'value2'=> 2022) ;


    $set9 -> Update (\%h, 'id=229') or die "not ok ($DBI::errstr)" ;

    $h{name2} = 'sqlinsert id 229uq' ;


    AddTestRowAndId (1, \%h) ;

    $set9 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set9) or print "ok\n" ;
    
    # ---------------------

    if ($Driver ne 'Sybase')
        {
	printlogf "Update to NULL";
	print LOG "\n--------------------\n" ;

	%h = ('id'    => 229,
	      'value2'=> undef) ;


	$set9 -> Update (\%h, {id=>229}) or die "not ok ($DBI::errstr)" ;
	AddTestRowAndId (1, \%h) ;

	$set9 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
	Check ($TestIds[1], $TestFields[1], \@set9) or print "ok\n" ;
	}
    
    DBIx::Recordset::Undef ('set9') ;


    # ---------------------

    printlogf "New Update";
    print LOG "\n--------------------\n" ;

    %h = ('id'    => 21,
          'name2' => 'sqlinsert id 21u',
          'value2'=> 2021) ;


    {
    local *set10 = DBIx::Recordset -> Update ({%h,
                                        ('!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[1]",
                                         '!PrimKey'      =>  'id')}) or die "not ok ($DBI::errstr)" ;
    AddTestRowAndId (1, \%h) ;

    $set10 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set10) or print "ok\n" ;
    
    }
    # We use closing block instead of Undef here
    #DBIx::Recordset::Undef ('set10') ;

    # ---------------------


    printlogf "New Delete";
    print LOG "\n--------------------\n" ;

    %h = ('id'    => 21,
          'name2' => 'ssdadadqlid 21u',
          'value2'=> 202331) ;


    *set11 = DBIx::Recordset -> Delete ({%h,
                                        ('!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[1]",
                                         '!PrimKey'      =>  'id')}) or die "not ok ($DBI::errstr)" ;
    DelTestRowAndId (1, 21) ;

    $set11 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set11) or print "ok\n" ;
    

    DBIx::Recordset::Undef ('set11') ;


    # ---------------------

    printlogf "New Execute Search (default)";
    print LOG "\n--------------------\n" ;


    *set12 = DBIx::Recordset -> Execute ({'id'  => 20,
                                       '*id' => '<',
                                       '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                       '!Table'        =>  "$Table[1]",
                                       '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;

    Check ([1, 2, 3, 4], $TestFields[1], \@set12) or print "ok\n" ;
    

    # ---------------------

    printlogf "Execute =search";
    print LOG "\n--------------------\n" ;


    *set13 = DBIx::Recordset -> Execute ({'=search' => 'ok',
                        'name'  => 'Fourth Name',
                        '!DataSource'   =>  $dbh,
                        '!Username'     =>  $User,
                        '!Password'     =>  $Password,
                        '!Table'        =>  "$Table[0]",
                        '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;

    Check ([4], $TestFields[0], \@set13) or print "ok\n" ;
    
    DBIx::Recordset::Undef ('set13') ;

    # ---------------------

    printlogf "Execute =insert";
    print LOG "\n--------------------\n" ;


    $set12 -> Execute ({'=insert' => 'ok',
                        'id'     => 31,
                        'name2'  => 'insert by exec',
                        'value2'  => 3031,
    # Execute should ignore the following params, since it is already setup
                        '!DataSource'   =>  $dbh,
                        '!Username'     =>  $User,
                        '!Password'     =>  $Password,
                        '!Table'        =>  "quztr",
                        '!PrimKey'      =>  'id99'}) or die "not ok ($DBI::errstr)" ;

    AddTestRowAndId (1, {
                        'id'     => 31,
                        'name2'  => 'insert by exec',
                        'value2'  => 3031,
                        }) ;

    $set12 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set12) or print "ok\n" ;
    
    # ---------------------

    printlogf "Execute =update";
    print LOG "\n--------------------\n" ;


    $set12 -> Execute ({'=update' => 'ok',
                        'id'     => 31,
                        'name2'  => 'update by exec'}) or die "not ok ($DBI::errstr)" ;

    AddTestRowAndId (1, {
                        'id'     => 31,
                        'name2'  => 'update by exec',
                        }) ;

    $set12 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set12) or print "ok\n" ;
    
    # ---------------------

    printlogf "Execute =insert";
    print LOG "\n--------------------\n" ;

    $set12 -> Execute ({'=insert' => 'ok',
                        'id'     => 32,
                        'name2'  => 'insert/upd by exec',
                        'value2'  => 3032}) or die "not ok ($DBI::errstr)" ;

    AddTestRowAndId (1, {
                        'id'     => 32,
                        'name2'  => 'insert/upd by exec',
                        'value2'  => 3032,
                        }) ;

    $set12 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set12) or print "ok\n" ;
    

    # ---------------------
    #
    #printlogf "Execute =update =insert 2";
    #print LOG "\n--------------------\n" ;
    #
    #$set12 -> Execute ({'=insert' => 'ok',
    #                    '=update' => 'ok',
    #                    'id'     => 32,
    #                    'name2'  => 'ins/update by exec',
    #                   'value2'  => 3032}) or die "not ok ($DBI::errstr)" ;
    #
    #AddTestRowAndId (1, {
    #                    'id'     => 32,
    #                    'name2'  => 'ins/update by exec',
    #                    'value2'  => 3032,
    #                    }) ;
    #
    #$set12 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    #Check ($TestIds[1], $TestFields[1], \@set12) or print "ok\n" ;
    #    
    # ---------------------

    printlogf "Execute =delete";
    print LOG "\n--------------------\n" ;

    $set12 -> Execute ({'=delete' => 'ok',
                        'id'     => 32,
                        'name2'  => 'ins/update by exec',
                        'value2'  => 3032}) or die "not ok ($DBI::errstr)" ;

    DelTestRowAndId (1, 32) ;

    $set12 -> SQLSelect ()  or die "not ok in SELECT ($DBI::errstr)" ;
    Check ($TestIds[1], $TestFields[1], \@set12) or print "ok\n" ;
    


    DBIx::Recordset::Undef ('set12') ;

    # ---------------------

    if ($Driver ne 'CSV')
	{
        printlogf "DeleteWithLinks";
        print LOG "\n--------------------\n" ;
        *set1 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[7],
                                                })  or die "not ok ($DBI::errstr)" ;

        $set1 -> {'*Links'}{'-dbixrsdel'}{'!OnDelete'} = DBIx::Recordset::odDELETE ; 

        Check ([1, 2, 3, 4], $TestFields[7], \@set1) or print "ok\n" ;

        printlogf "";
        print LOG "\n--------------------\n" ;
        $set1 -> DeleteWithLinks ({ 'id' => 1
                                                })  or die "not ok ($DBI::errstr)" ;

        $set1 -> Search ;

        Check ([], $TestFields[7], \@set1) or print "ok\n" ;


        DBIx::Recordset::Undef ('set1') ;
        }

    # ---------------------

    printlogf "Array Update/Insert";
    print LOG "\n--------------------\n" ;

    *set20 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[0],
                                            '$order'        =>  'id',
                                            '!PrimKey'      =>  'id',
                                            'id'            =>  7,
                                            '*id'           =>  '<' }) or die "not ok ($DBI::errstr)" ;


    Check ([1,2,3,4,5,6], $TestFields[0], \@set20) or print "ok\n" ;

    $set20[3]{name} = 'New Name on id 4' ;
    $set20[3]{value1} = 4444 ;
        
    AddTestRowAndId (0, {
                        'id'   => 4,
                        'name' => 'New Name on id 4',
                        'value1' => 4444
                        }) ;

    $set20[7]{id}    = 1234 ;
    $set20[7]{name}  = 'New rec' ;

    AddTestRowAndId (0, {
                        'id'   => 1234,
                        'name' => 'New rec',
                        }) ;

    $set20  -> Search ({'id'            =>  4}) or die "not ok ($DBI::errstr)" ;

    printlogf "";
    Check ([4], $TestFields[0], \@set20) or print "ok\n" ;
    
    $set20  -> Search ({'id'            =>  1234}) or die "not ok ($DBI::errstr)" ;

    printlogf "";
    Check ([1234], $TestFields[0], \@set20) or print "ok\n" ;
    

    # ---------------------

    printlogf "Array Update/Insert -> Flush";
    print LOG "\n--------------------\n" ;

    $set20[0]{id}    = 1234 ;
    $set20[0]{name}  = 'New rec 1234' ;

    *set20c = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[0],
                                            '$order'        =>  'id',
                                            '!PrimKey'      =>  'id',
                                            'id'            =>  1234}) or die "not ok ($DBI::errstr)" ;

    Check ([1234], $TestFields[0], \@set20c) or print "ok\n" ;

    printlogf "Dirty";
    print LOG "\n--------------------\n" ;

    if ($set20->Dirty) 
        {
        print LOG "DIRTY: ok\n";
        print "ok\n" ;
        } 
    else 
        {
	printlog "ERROR in $lasttest: not set\n" ;
        $errors++;
        }
      
    # write it to the db
    print LOG "Flush\n" ;
    $set20 -> Flush () ;
      
    printlogf "";
    if (!$set20->Dirty) 
        {
        print LOG "DIRTY: ok\n";
        print "ok\n" ;
        } 
    else 
        {
	printlog "ERROR in $lasttest: set\n" ;
        $errors++;
        }
  
    
    
    AddTestRowAndId (0, {
                        'id'   => 1234,
                        'name' => 'New rec 1234',
                        }) ;
    
    
    #$set20c -> Search ({'id'            =>  1234}) or die "not ok ($DBI::errstr)" ;
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set20c') ;
    *set20c = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[0],
                                            '!PrimKey'      =>  'id',
                                            'id'            =>  1234}) or die "not ok ($DBI::errstr)" ;
    
    printlogf "Array Update/Insert -> Flush 2";
    Check ([1234], $TestFields[0], \@set20c) or print "ok\n" ;
    
    
    printlogf "Array Insert Hashref";
    print LOG "\n--------------------\n" ;

    $set20[8] = {id => 12345, 'name' => 'New rec 12345'}  ;

    # write it to the db
    print LOG "Flush\n" ;
    $set20 -> Flush () ;
    
    AddTestRowAndId (0, {
                        'id'   => 12345,
                        'name' => 'New rec 12345',
                        }) ;
    
    
    #$set20c -> Search ({'id'            =>  12345}) or die "not ok ($DBI::errstr)" ;
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    # we try here undef instead of DBIx::Recordset::Undef ('set20c') ;
    undef *set20c ;
    
    
    *set20c = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[0],
                                            '!PrimKey'      =>  'id',
                                            'id'            =>  12345}) or die "not ok ($DBI::errstr)" ;
    
    Check ([12345], $TestFields[0], \@set20c) or print "ok\n" ;
    
    printlogf "Array Add Record";
    print LOG "\n--------------------\n" ;
    
    $set20 -> Add ({id => 123456, 'name' => 'New rec 123456'})  ;
    
    # write it to the db
    print LOG "Flush\n" ;
    $set20 -> Flush () ;
    
    AddTestRowAndId (0, {
                        'id'   => 123456,
                        'name' => 'New rec 123456',
                        }) ;
    
    
    #$set20c -> Search ({'id'            =>  123456}) or die "not ok ($DBI::errstr)" ;
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set20c') ;
    *set20c = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[0],
                                            '!PrimKey'      =>  'id',
                                            'id'            =>  123456}) or die "not ok ($DBI::errstr)" ;
    
    Check ([123456], $TestFields[0], \@set20c) or print "ok\n" ;
    
    printlogf "Array Add Empty Record (Ndx)";
    print LOG "\n--------------------\n" ;
    
    my $ndx = $set20 -> Add ()  ;
    
    $set20[$ndx]{id} = 1234567 ;
    $set20[$ndx]{name}  = 'New rec 1234567' ;

    
    # write it to the db
    print LOG "Flush\n" ;
    $set20 -> Flush () ;
    
    AddTestRowAndId (0, {
                        'id'   => 1234567,
                        'name' => 'New rec 1234567',
                        }) ;
    
    
    #$set20c -> Search ({'id'            =>  1234567}) or die "not ok ($DBI::errstr)" ;
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set20c') ;
    *set20c = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[0],
                                            '!PrimKey'      =>  'id',
                                            'id'            =>  1234567}) or die "not ok ($DBI::errstr)" ;
    
    Check ([1234567], $TestFields[0], \@set20c) or print "ok\n" ;
    
    printlogf "Array Add Empty Record (CurrRec)";
    print LOG "\n--------------------\n" ;
    
    $set20 -> Add ()  ;
    
    $set20{id} = 876 ;
    $set20{name}  = 'New rec 876' ;

    
    # write it to the db
    print LOG "Flush\n" ;
    $set20 -> Flush () ;
    
    AddTestRowAndId (0, {
                        'id'   => 876,
                        'name' => 'New rec 876',
                        }) ;
    
    
    #$set20c -> Search ({'id'            =>  876}) or die "not ok ($DBI::errstr)" ;
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set20c') ;
    *set20c = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[0],
                                            '!PrimKey'      =>  'id',
                                            'id'            =>  876}) or die "not ok ($DBI::errstr)" ;
    
    Check ([876], $TestFields[0], \@set20c) or print "ok\n" ;


    DBIx::Recordset::Undef ('set20') ;
    DBIx::Recordset::Undef ('set20c') ;

    

        {
        local *set13 = DBIx::Recordset -> Setup ({'!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  "$Table[1]",
                                            '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;
    
        # ---------------------

        printlogf "Select id (Hash)";
        print LOG "\n--------------------\n" ;

        my %set13h ;

        tie %set13h, 'DBIx::Recordset::Hash', $set13 ;
    
        $set13h[0] = $set13h{2} ;


        Check ([2], $TestFields[1], \@set13h) or print "ok\n" ;
    
        # ---------------------

        printlogf "Select name (Hash)";
        print LOG "\n--------------------\n" ;

        my %set13h2 ;

        tie %set13h2, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  "$Table[1]",
                                            '!PrimKey'      =>  'name2'} ;
    
        $set13h2[0] = $set13h2{'Third Name in Tab2'} ;


        Check ([3], $TestFields[1], \@set13h2) or print "ok\n" ;
    
        # ---------------------

        printlogf "Iterate over ::Hash";
        print LOG "\n--------------------\n" ;
        #
            {
            my $i ;
            my $v ;
            my $k ;
            my $n ;
            my @set13h ;

            $i = 0 ;
            while (($k, $v) = each %set13h)
                {
                @set13h = () ;
                $set13h[0] = $v ;
                printlogf "" if ($i > 0) ;
                Check ([$k], $TestFields[1], \@set13h) or print "ok\n" ;
                $i++ ;
                }
    
            $n = ($#{$TestIds[1]})+1 ;
            if ($i != $n)
                {
                print "ERROR in $lasttest\n" ;
                print "Not enougth records (get $i, expected $n)\n" ;
                $errors++ ;         
                }
            }

        #untie %set13h ;
        #@set13h = () ;
        #DBIx::Recordset::Undef ('set13') ;
        }

    # ---------------------
        {
        printlogf "Select name (PreFetch Hash)";
        print LOG "\n--------------------\n" ;

        my %set13h3 ;
        my @set13h3 ;

        tie %set13h3, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[0],
                                            '!PreFetch'     =>  {'*id' => '<', 'id' => 7},
                                            '!PrimKey'      =>  'id'} ;
    
        $set13h3[0] = $set13h3{2} ;


        Check ([2], $TestFields[0], \@set13h3) or print "ok\n" ;
    
        # ---------------------

        printlogf "Iterate over ::Hash PreFetch";
        print LOG "\n--------------------\n" ;
        #
            {
            my $i ;
            my $v ;
            my $k ;
            my $n ;
            my @set13h ;

            $i = 0 ;
            while (($k, $v) = each %set13h3)
                {
                @set13h = () ;
                $set13h[0] = $v ;
                printlogf "" if ($i > 0) ;
                Check ([$k], $TestFields[0], \@set13h) or print "ok\n" ;
                $i++ ;
                }
    
            $n = 6 ;
            if ($i != $n)
                {
                print "ERROR in $lasttest\n" ;
                print "Not enougth records (get $i, expected $n)\n" ;
                $errors++ ;         
                }
            }

        #untie %set13h ;
        #@set13h = () ;
        #DBIx::Recordset::Undef ('set13') ;
        }

    # ---------------------
        {
        printlogf "PreFetch Hash with merge";
        print LOG "\n--------------------\n" ;

        my %set13h3 ;

        tie %set13h3, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[3],
                                            '!PreFetch'     =>  '*',
                                            '!MergeFunc'    =>  sub { my ($a, $b) = @_ ; $a->{typ} .= ' , ' . $b->{typ} ; $a->{typ} =~ s/\s+/ /g ;   },
                                            '!PrimKey'      =>  'id'} ;
    
        my $ec = $errors ;

        CheckField ('id', $set13h3{1}{id}, 1) ;
        CheckField ('typ', $set13h3{1}{typ}, 'First item Type 1 , First item Type 2 , First item Type 3') ;
        CheckField ('id', $set13h3{2}{id}, 2) ;
        CheckField ('typ', $set13h3{2}{typ}, 'Second item Type 1 , Second item Type 2 , Second item Type 3 , Second item Type 4') ;
        CheckField ('id', $set13h3{3}{id}, 3) ;
        CheckField ('typ', $set13h3{3}{typ}, 'Third item Type 1') ;

        print "ok\n" if ($ec == $errors) ;
        }

    # ---------------------
        {
        printlogf "Hash with merge";
        print LOG "\n--------------------\n" ;

        my %set13h3 ;

        tie %set13h3, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $dbh,
                                            '!Username'     =>  $User,
                                            '!Password'     =>  $Password,
                                            '!Table'        =>  $Table[3],
                                            '!MergeFunc'    =>  sub { my ($a, $b) = @_ ; $a->{typ} .= ' , ' . $b->{typ} ; $a->{typ} =~ s/\s+/ /g ; },
                                            '!PrimKey'      =>  'id'} ;
    
        my $ec = $errors ;
        my $x ;

        $x = $set13h3{1} ;
        CheckField ('id',  $x -> {id}, 1) ;
        CheckField ('typ', $x -> {typ}, 'First item Type 1 , First item Type 2 , First item Type 3') ;
        $x = $set13h3{2} ;
        CheckField ('id', $x -> {id}, 2) ;
        CheckField ('typ', $x -> {typ}, 'Second item Type 1 , Second item Type 2 , Second item Type 3 , Second item Type 4') ;
        $x = $set13h3{3} ;
        CheckField ('id', $x -> {id}, 3) ;
        CheckField ('typ', $set13h3{3}{typ}, 'Third item Type 1') ;

        print "ok\n" if ($ec == $errors) ;
        }

    # ---------------------


    *set14 = DBIx::Recordset -> Setup ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        '!HashAsRowKey' =>  1,
                                        '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;
    

    printlogf "Select id (HashAsRowKey)";
    print LOG "\n--------------------\n" ;

   
    my @set14h = () ;
    my @set15h = () ;
    $set14h[0] = $set14{3} ;

    Check ([3], $TestFields[1], \@set14h) or print "ok\n" ;
    
    @set14h = () ;
    @set15h = () ;

    # ---------------------


    printlogf "Select name (Hash) with setup";
    print LOG "\n--------------------\n" ;

    tie %set15h, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $dbh,
                                           '!Username'     =>  $User,
                                           '!Password'     =>  $Password,
                                           '!Table'        =>  "$Table[1]",
                                           '!PrimKey'      =>  'name2'} or die "not ok ($DBI::errstr)" ;

    $set15h[0] = $set15h{'Fourth Name in Tab2'} ;

    Check ([4], $TestFields[1], \@set15h) or print "ok\n" ;
    

    # ---------------------

    printlogf "Modify Hash";
    print LOG "\n--------------------\n" ;

    $set15h{'Fourth Name in Tab2'}{value2} = 4444 ;

    tied (%set15h) -> Flush () ;

    AddTestRowAndId (1, {
                        'id'   => 4,
                        'value2' => 4444 ,
                        }) ;

    
    
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set14') ;
    *set14 = DBIx::Recordset -> Setup ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        '!HashAsRowKey' =>  1,
                                        '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;
    $set14 -> Search ({'id' => 4})  ;
    


    Check ([4], $TestFields[1], \@set14) or print "ok\n" ;
    

    # ---------------------

    printlogf "Add To Hash";
    print LOG "\n--------------------\n" ;

    $set15h{'Fifth Name in Tab2'}{id} = 5 ;
    $set15h{'Fifth Name in Tab2'}{value2} = 5555 ;

    tied (%set15h) -> Flush () ;

    AddTestRowAndId (1, {
                        'id'   => 5,
                        'name2'=> 'Fifth Name in Tab2',
                        'value2' => 5555 ,
                        }) ;

    
    
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set14') ;
    *set14 = DBIx::Recordset -> Setup ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        '!HashAsRowKey' =>  1,
                                        '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;
    $set14 -> Search ({'id' => 5})  ;

    Check ([5], $TestFields[1], \@set14) or print "ok\n" ;
    


    # ---------------------

    printlogf "Add Hashref To Hash ";
    print LOG "\n--------------------\n" ;

    $set15h{'Sixth Name in Tab2'}= {id => 6, value2 => 6666}  ;

    tied (%set15h) -> Flush () ;

    AddTestRowAndId (1, {
                        'id'   => 6,
                        'name2'=> 'Sixth Name in Tab2',
                        'value2' => 6666 ,
                        }) ;

    
    
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set14') ;
    *set14 = DBIx::Recordset -> Setup ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        '!HashAsRowKey' =>  1,
                                        '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;
    $set14 -> Search ({'id' => 6})  ;

    Check ([6], $TestFields[1], \@set14) or print "ok\n" ;
    



    # ---------------------

    printlogf "Modify PrimKey in Hash";
    print LOG "\n--------------------\n" ;

    $set15h{'Fourth Name in Tab2'}{name2} = 'New Fourth Name' ;

    tied (%set15h) -> Flush () ;

    AddTestRowAndId (1, {
                        'id'   => 4,
                        'name2' => 'New Fourth Name' ,
                        }) ;

    
    
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set14') ;
    *set14 = DBIx::Recordset -> Setup ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        '!HashAsRowKey' =>  1,
                                        '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;
    $set14 -> Search ({'id' => 4})  ;
    


    Check ([4], $TestFields[1], \@set14) or print "ok\n" ;
    

    # ---------------------

    printlogf "Add undef as PrimKey to Hash";
    print LOG "\n--------------------\n" ;


    my $ud ;

    $set15h{$ud}{id} = 531 ;
    $set15h{$ud}{value2} = 9531 ;

    tied (%set15h) -> Flush () ;

    AddTestRowAndId (1, {
                        'id'   => 531,
                        'value2' => 9531 ,
                        }) ;

    
    
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set14') ;
    *set14 = DBIx::Recordset -> Setup ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        '!HashAsRowKey' =>  1,
                                        '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;
    $set14 -> Search ({'id' => 531})  ;
    


    Check ([531], $TestFields[1], \@set14) or print "ok\n" ;
    
    # ---------------------
    printlogf "";

    $set15h{$ud}{id} = 532 ;
    $set15h{$ud}{value2} = 9532 ;

    tied (%set15h) -> Flush () ;

    $set15h{$ud}{id} = 533 ;
    $set15h{$ud}{value2} = 9533 ;

    tied (%set15h) -> Flush () ;

    AddTestRowAndId (1, {
                        'id'   => 532,
                        'value2' => 9532 ,
                        }) ;

    
    AddTestRowAndId (1, {
                        'id'   => 533,
                        'value2' => 9533 ,
                        }) ;

    
    # The resetup is neccessary to work with all, also stupid drivers (MSAccess)
    DBIx::Recordset::Undef ('set14') ;
    *set14 = DBIx::Recordset -> Setup ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        '!HashAsRowKey' =>  1,
                                        '!PrimKey'      =>  'id'}) or die "not ok ($DBI::errstr)" ;
    $set14 -> Search   ;
    


    Check ($TestIds[1], $TestFields[1], \@set14) or print "ok\n" ;
    
    # ---------------------

    printlogf "Test Syntax error";
    print LOG "\n--------------------\n" ;


    $rc = $set14 -> Update ({id => 9999}, "qwer=!§" ) and die "not ok (returns $rc)" ;
    
    if (defined ($rc))
	{
	printlog "ERROR in $lasttest: Update should return undef\n" ;
	$errors++ ;
	}
    elsif (!DBIx::Recordset -> LastError)
	{
	printlog "ERROR in $lasttest: LastError should return error message\n" ;
	$errors++ ;
	}
    elsif (!$set14 -> LastError)
	{
	printlog "ERROR in $lasttest: LastError should return error message\n" ;
	$errors++ ;
	}
    else
	{
        print "ok\n" ;
	}

    DBIx::Recordset::Undef ('set14') ;
    untie %set15h ;


    printlogf "Test error within setup";
    print LOG "\n--------------------\n" ;

    *set14 = DBIx::Recordset -> Update ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  $Table[1],
                                        '!HashAsRowKey' =>  1,
                                        '!PrimKey'      =>  'id',
					id => 9999},
                                        'qwert=!%&') ;

    if (!DBIx::Recordset -> LastError)
	{
	printlog "ERROR in $lasttest: LastError should return error message\n" ;
	$errors++ ;
	}
    elsif (!$set14 -> LastError)
	{
	printlog "ERROR in $lasttest: LastError should return error message\n" ;
	$errors++ ;
	}
    else
	{
        print "ok\n"  ;
	}

    DBIx::Recordset::Undef ('set14') ;

    # ---------------------

    printlogf "MoreRecords on empty set";
    print LOG "\n--------------------\n" ;

    *set4 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        'id' => 9753    })  or die "not ok ($DBI::errstr)" ;

    if ($set4 -> MoreRecords)
        {
        printlog "ERROR in $lasttest: MoreRecords returns true\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }

    DBIx::Recordset::Undef ('set4') ;

    # ---------------------

    printlogf "First on empty set";
    print LOG "\n--------------------\n" ;

    *set5 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        'id' => 9753    })  or die "not ok ($DBI::errstr)" ;

    if ($set5 -> First)
        {
        printlog "ERROR in $lasttest: First returns true\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }

    DBIx::Recordset::Undef ('set5') ;

# ---------------------

    printlogf "Next on empty set";
    print LOG "\n--------------------\n" ;

    *set6 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        'id' => 9753    })  or die "not ok ($DBI::errstr)" ;

    if ($set6 -> Next)
        {
        printlog "ERROR in $lasttest: Next returns true\n" ;
        $errors++ ;
        }
    else
        {
        print "ok\n" ;
        }

    DBIx::Recordset::Undef ('set6') ;

# ---------------------

    printlogf "Use First to get first record";
    print LOG "\n--------------------\n" ;

    *set7 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        '$order'=>'id',
                                        '*id' => '>=',
                                        'id' => 2    })  or die "not ok ($DBI::errstr)" ;

    {
    my $r = $set7 -> First ;
    my @r = ($r) ;
    
    Check ([2], $TestFields[1], \@r) or print "ok\n" ;
    }

    DBIx::Recordset::Undef ('set7') ;

# ---------------------

    printlogf "Use First/Next to get all records";
    print LOG "\n--------------------\n" ;

    *set8 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                          })  or die "not ok ($DBI::errstr)" ;

    {
    my $r ;
    my @r ;
    push @r, $set8 -> First ;
    push @r, $r while ($r = $set8 -> Next) ;

    Check ($TestIds[1], $TestFields[1], \@r) or print "ok\n" ;
    }

    DBIx::Recordset::Undef ('set8') ;

# ---------------------

    printlogf "Use Next to get all records";
    print LOG "\n--------------------\n" ;

    *set9 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                          })  or die "not ok ($DBI::errstr)" ;

    {
    my $r ;
    my @r ;
    push @r, $r while ($r = $set9 -> Next) ;

    Check ($TestIds[1], $TestFields[1], \@r) or print "ok\n" ;
    }

# ---------------------

    printlogf "Use Reset/Next to get all records";
    print LOG "\n--------------------\n" ;

    {
    $set9 -> Reset ;

    my $r ;
    my @r ;
    push @r, $r while ($r = $set9 -> Next) ;

    Check ($TestIds[1], $TestFields[1], \@r) or print "ok\n" ;
    }

    DBIx::Recordset::Undef ('set9') ;

# ---------------------

    printlogf "Update via assigning array ref";
    print LOG "\n--------------------\n" ;

    *set1 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        '$order'        =>  'id'    })  or die "not ok ($DBI::errstr)" ;

    Check ($TestIds[1], $TestFields[1], \@set1) or print "ok\n" ;

    
    #my @array = $set1{value2} ;
    #my $id ;
    #
    #for ($id = 0; $id <= $#array; $id++)
    #    {
    #    print LOG "CHK: array[$id] = $array[$id], should $TestCheck{$id}{value2}\n" ;
    #    if ($array[$id] != $TestCheck{$id}{value2}) 
    #        {
    #        $errors++ ;
    #        printlog ("Error array[$id] = $array[$id], should $TestCheck{$id}{value2}\n") 
    #        }
    #    }

    $set1{value2} = [1234, 2345, 3456, 4567] ;

    $set1 -> Flush ;

    AddTestRowAndId (1, {
                        'id'   => 1,
                        'value2' => '1234',
                        }) ;

    AddTestRowAndId (1, {
                        'id'   => 2,
                        'value2' => '2345',
                        }) ;

    AddTestRowAndId (1, {
                        'id'   => 3,
                        'value2' => '3456',
                        }) ;

    AddTestRowAndId (1, {
                        'id'   => 4,
                        'value2' => '4567',
                        }) ;


    DBIx::Recordset::Undef ('set1') ;

    *set1_ = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                            })  or die "not ok ($DBI::errstr)" ;

    printlogf "";
    Check ($TestIds[1], $TestFields[1], \@set1_) or print "ok\n" ;

    DBIx::Recordset::Undef ('set1_') ;

    # ---------------------

    printlogf "Update via assigning array ref 2";
    print LOG "\n--------------------\n" ;

    *set1 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        'id' => 9753    })  or die "not ok ($DBI::errstr)" ;

    Check ([], $TestFields[1], \@set1) or print "ok\n" ;


    $set1{id} = [9753, 9754, 9755, 9756] ;
    $set1{name2} = ['a', 'b', 'c', 'd'] ;
    $set1{value2} = [12340, 23450, 34560, 45670] ;

    $set1 -> Flush ;

    AddTestRowAndId (1, {
                        'id'   => 9753,
                        'name2' => 'a',
                        'value2' => '12340',
                        }) ;

    AddTestRowAndId (1, {
                        'id'   => 9754,
                        'name2' => 'b',
                        'value2' => '23450',
                        }) ;

    AddTestRowAndId (1, {
                        'id'   => 9755,
                        'name2' => 'c',
                        'value2' => '34560',
                        }) ;

    AddTestRowAndId (1, {
                        'id'   => 9756,
                        'name2' => 'd',
                        'value2' => '45670',
                        }) ;


    DBIx::Recordset::Undef ('set1') ;

    *set1_ = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[1]",
                                        'id' => "9753\t9754\t9755\t9756"    })  or die "not ok ($DBI::errstr)" ;

    printlogf "";
    Check ([9753, 9754, 9755, 9756], $TestFields[1], \@set1_) or print "ok\n" ;

    DBIx::Recordset::Undef ('set1_') ;

    # ---------------------

    printlogf "Select with sub table";
    print LOG "\n--------------------\n" ;

    *set1 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[0]",
                                        '!Links'        =>  {
                                                            'subid' => {
                                                                '!Table' => $Table[3],
                                                                '!LinkedField' => 'id',
                                                                '!PrimKey' => 'typ'
								}
                                                            },
                                        'id'            =>  2,
                                            })  or die "not ok ($DBI::errstr)" ;

    Check ([2], $TestFields[0], \@set1) or print "ok\n" ;
    printlogf "";
    Check (['Second item Type 1',          
            'Second item Type 2',
            'Second item Type 3',
            'Second item Type 4'], $TestFields[3], $set1{subid}, 'typ') or print "ok\n" ;

    printlogf "Modify sub table";
    print LOG "\n--------------------\n" ;

    $set1[0]{subid}[1]{typ} = '2.item, new Type 2' ;

    AddTestRowAndId (3, {
                        'id'   => 2,
                        'typ' => '2.item, new Type 2',
                        }, 'typ') ;

    DBIx::Recordset::Undef ('set1') ;

    *set1_ = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[0]",
                                        '!Links'        =>  {
                                                            'subid' => {
                                                                '!Table' => $Table[3],
                                                                '!LinkedField' => 'id',
								}
                                                            },
                                        'id'            =>  2,
                                            })  or die "not ok ($DBI::errstr)" ;

    Check ([2], $TestFields[0], \@set1_) or print "ok\n" ;
    printlogf "";
    Check (['Second item Type 1',          
            '2.item, new Type 2',
            'Second item Type 3',
            'Second item Type 4'], $TestFields[3], $set1_{subid}, 'typ') or print "ok\n" ;

    DBIx::Recordset::Undef ('set1_') ;

    # ---------------------
    
    printlogf "Add with sub table";
    print LOG "\n--------------------\n" ;

    *set1 = DBIx::Recordset -> Setup ({ '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[0]",
                                        '!Links'        =>  {
                                                            'subid' => {
                                                                '!Table' => $Table[3],
                                                                '!LinkedField' => 'id'
                                                                }
                                                            },
                                            })  or die "not ok ($DBI::errstr)" ;

    $set1 -> Add ;
    $set1{id}     = 9988 ;
    $set1{value}  = 998877 ;
    #$set1{subid}{id}  = 9988;
    $set1{subid}{typ} = 'Typ for 9988' ;
    #${$set1{subid}} -> Flush ;
    
    AddTestRowAndId (0, {
                        'id'   => 9988,
                        'value' => 9988772,
                        }) ;
    AddTestRowAndId (3, {
                        'id'   => 9988,
                        'typ' => 'Typ for 9988',
                        }, 'typ') ;

    DBIx::Recordset::Undef ('set1') ;

    *set1_ = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[0]",
                                        '!Links'        =>  {
                                                            'subid' => {
                                                                '!Table' => $Table[3],
                                                                '!LinkedField' => 'id'
                                                                }
                                                            },
                                        'id'            =>  9988,
                                            })  or die "not ok ($DBI::errstr)" ;

    Check ([9988], $TestFields[0], \@set1_) or print "ok\n" ;
    printlogf "";
    Check (['Typ for 9988'], $TestFields[3], $set1_{subid}, 'typ') or print "ok\n" ;

    DBIx::Recordset::Undef ('set1_') ;

    # ---------------------

    printlogf "Select sub table NULL";
    print LOG "\n--------------------\n" ;

    *set2 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                        '!Table'        =>  "$Table[0]",
                                        '!Links'        =>  {
                                                            'subv1' => {
                                                                '!Table' => $Table[2],
                                                                '!LinkedField' => 'value1'
								}
                                                            },
                                        'id'            =>  13,
                                            })  or die "not ok ($DBI::errstr)" ;

    Check ([13], $TestFields[0], \@set2) or print "ok\n" ;
    printlogf "";
    Check ([], $TestFields[0], $set2{subv1}) or print "ok\n" ;

    DBIx::Recordset::Undef ('set2') ;



    # ---------------------

    if ($SQLJoin)
        {
	printlogf "Select with linked name mode 1";
	print LOG "\n--------------------\n" ;

	*set3 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
					    '!Username'     =>  $User,
					    '!Password'     =>  $Password,
					    '!Table'        =>  "$Table[0]",
					    '!LinkName'     =>  1,
					    '!Links'        =>  {
								'subid' => {
								    '!Table' => $Table[1],
								    '!LinkedField' => 'id',
								    '!PrimKey' => 'id',
								    '!NameField' => 'value2'
								    }
								},
					    'id'            =>  "2\t5\t10",
						})  or die "not ok ($DBI::errstr)" ;

	Check ([2, 5, 10], [@{$TestFields[0]}, 'value2'], \@set3) or print "ok\n" ;

	DBIx::Recordset::Undef ('set3') ;
    

	# ---------------------

	printlogf "Select with linked name hash access";
	print LOG "\n--------------------\n" ;

	*set3 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
					    '!Username'     =>  $User,
					    '!Password'     =>  $Password,
					    '!Table'        =>  "$Table[0]",
					    '!Links'        =>  {
								'subid' => {
								    '!Table' => $Table[1],
								    '!LinkedField' => 'id',
								    '!PrimKey' => 'id',
								    }
								},
                        '!PrimKey'      => 'id',
                        'id' => 3,
						})  or die "not ok ($DBI::errstr)" ;

                        if ($set3{subid}{id} != 3 || $set3{subid}{value2} != 3456)
                {
                printlog "ERROR in $lasttest\n" ;
                $errors++ ;
                }        
            else
                {
                print "ok\n" ;
                }



	DBIx::Recordset::Undef ('set3') ;
    

	# ---------------------
	printlogf "Select with linked names mode 1";
	print LOG "\n--------------------\n" ;

	*set3 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
					    '!Username'     =>  $User,
					    '!Password'     =>  $Password,
					    '!Table'        =>  "$Table[0]",
					    '!LinkName'     =>  1,
					    '!Links'        =>  {
								'subid' => {
								    '!Table' => $Table[1],
								    '!LinkedField' => 'id',
								    '!PrimKey' => 'id',
								    '!NameField' => ['name2', 'value2']
								    }
								},
					    'id'            =>  "2\t4\t7",
						})  or die "not ok ($DBI::errstr)" ;

	Check ([2, 4, 7], [@{$TestFields[0]}, 'name2', 'value2'], \@set3) or print "ok\n" ;

	DBIx::Recordset::Undef ('set3') ;

	# ---------------------

	printlogf "Select with linked name mode 2";
	print LOG "\n--------------------\n" ;

	*set3 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
					    '!Username'     =>  $User,
					    '!Password'     =>  $Password,
					    '!Table'        =>  "$Table[0]",
					    '!LinkName'     =>  2,
					    '!Links'        =>  {
								'subid' => {
								    '!Table' => $Table[1],
								    '!LinkedField' => 'id',
								    '!PrimKey' => 'id',
								    '!NameField' => 'value2'
								    }
								},
					    'id'            =>  "4",
						})  or die "not ok ($DBI::errstr)" ;

	Check ([4], [@{$TestFields[0]}], \@set3) or print "ok\n" ;

	printlogf "";
	if ($set3{ID} eq $TestCheck{4}{'value2'})
	    {
	    print "ok\n" ;
	    print LOG "ID = $set3{ID}\n" ;
	    }
	else
	    {
	    printlog "ERROR in $lasttest\n" ;
	    printlog "Field ID\n" ;
	    printlog "Is     =  $set3{ID}\n" ;
	    printlog "Should =  $TestCheck{4}{'value2'}\n" ;
	    $errors++ ;
	    }
    		
	DBIx::Recordset::Undef ('set3') ;
    

	# ---------------------

	printlogf "Select with linked names mode 2";
	print LOG "\n--------------------\n" ;

	*set3 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
					    '!Username'     =>  $User,
					    '!Password'     =>  $Password,
					    '!Table'        =>  "$Table[0]",
					    '!LinkName'     =>  2,
					    '!Links'        =>  {
								'subid' => {
								    '!Table' => $Table[1],
								    '!LinkedField' => 'id',
								    '!PrimKey' => 'id',
								    '!NameField' => ['name2', 'value2']
								    }
								},
					    'id'            =>  "6",
						})  or die "not ok ($DBI::errstr)" ;

	Check ([6], [@{$TestFields[0]}], \@set3) or print "ok\n" ;
	printlogf "";
	my $re = "$TestCheck{6}{'name2'}\\s+$TestCheck{6}{'value2'}" ;
	if ($set3{ID} =~ /$re/)
	    {
	    print "ok\n" ;
	    print LOG "ID = $set3{ID}\n" ;
	    }
	else
	    {
	    printlog "ERROR in $lasttest\n" ;
	    printlog "Field ID\n" ;
	    printlog "Is     =  $set3{ID}\n" ;
	    printlog "Should =  $TestCheck{6}{'name2'} $TestCheck{6}{'value2'}\n" ;
	    $errors++ ;
	    }
    		

	# ---------------------

	printlogf "Select with linked name mode 3";
	print LOG "\n--------------------\n" ;

	*set3 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
					    '!Username'     =>  $User,
					    '!Password'     =>  $Password,
					    '!Table'        =>  "$Table[0]",
					    '!LinkName'     =>  3,
					    '!Links'        =>  {
								'subid' => {
								    '!Table' => $Table[1],
								    '!LinkedField' => 'id',
								    '!PrimKey' => 'id',
								    '!NameField' => 'value2'
								    }
								},
					    'id'            =>  "4",
						})  or die "not ok ($DBI::errstr)" ;

	Check ([4], ['name', 'addon', 'value1'], \@set3) or print "ok\n" ;

	printlogf "";
	if ($set3{id} eq $TestCheck{4}{'value2'})
	    {
	    print "ok\n" ;
	    print LOG "id = $set3{ID}\n" ;
	    }
	else
	    {
	    printlog "ERROR in $lasttest\n" ;
	    printlog "Field id\n" ;
	    printlog "Is     =  $set3{id}\n" ;
	    printlog "Should =  $TestCheck{4}{'value2'}\n" ;
	    $errors++ ;
	    }
    		
	DBIx::Recordset::Undef ('set3') ;
    

	# ---------------------

	printlogf "Select with linked names mode 3";
	print LOG "\n--------------------\n" ;

	*set3 = DBIx::Recordset -> Search ({  '!DataSource'   =>  $dbh,
					    '!Username'     =>  $User,
					    '!Password'     =>  $Password,
					    '!Table'        =>  "$Table[0]",
					    '!LinkName'     =>  3,
					    '!Links'        =>  {
								'subid' => {
								    '!Table' => $Table[1],
								    '!LinkedField' => 'id',
								    '!PrimKey' => 'id',
								    '!NameField' => ['name2', 'value2']
								    }
								},
					    'id'            =>  "6",
						})  or die "not ok ($DBI::errstr)" ;

	Check ([6], ['name', 'addon', 'value1'], \@set3) or print "ok\n" ;
	printlogf "";
	$re = "$TestCheck{6}{'name2'}\\s+$TestCheck{6}{'value2'}" ; 
	if ($set3{id} =~ /$re/)
	    {
	    print "ok\n" ;
	    print LOG "id = $set3{id}\n" ;
	    }
	else
	    {
	    printlog "ERROR in $lasttest\n" ;
	    printlog "Field id\n" ;
	    printlog "Is     =  $set3{id}\n" ;
	    printlog "Should =  $TestCheck{6}{'name2'} $TestCheck{6}{'value2'}\n" ;
	    $errors++ ;
	    }
    		



	DBIx::Recordset::Undef ('set3') ;
	}
    else
	{
	printlogf "Select with linked names";
	print "skipped due to missing SQL-Join\n" ;
	}

    

    # ---------------------

    printlogf "Delete from hash";
    print LOG "\n--------------------\n" ;

    tie %set15h, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $dbh,
                                           '!Username'     =>  $User,
                                           '!Password'     =>  $Password,
                                           '!Table'        =>  "$Table[1]",
                                           '!PrimKey'      =>  'id'} or die "not ok ($DBI::errstr)" ;

    delete $set15h{5} ;

    untie %set15h ;

    DelTestRowAndId (1, 5) ;

    *set3 = DBIx::Recordset -> Search ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[1]"}) or die "not ok ($DBI::errstr)" ;

    Check ($TestIds[1], $TestFields[1], \@set3) or print "ok\n" ;
    
    DBIx::Recordset::Undef ('set3') ;


    # ---------------------

    printlogf "Clear hash disabled";
    print LOG "\n--------------------\n" ;

    tie %set15h, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $dbh,
                                           '!Username'     =>  $User,
                                           '!Password'     =>  $Password,
                                           '!Table'        =>  $Table[1],
                                           '!PrimKey'      =>  'id'} or die "not ok ($DBI::errstr)" ;

    eval
	{
	%set15h = () ;
	} ;


    if ($@)
	{
	print "ok\n" ;
	print LOG "disable CLEAR causes message = $@\n" ;
	}
    else
	{
	printlog "ERROR in $lasttest\n" ;
	printlog "Disable wmCLEAR does not work\n" ;
        $errors++ ;
	}

    untie %set15h ;

    printlogf "";

    *set3 = DBIx::Recordset -> Search ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[1]"}) or die "not ok ($DBI::errstr)" ;

    Check ($TestIds[1], $TestFields[1], \@set3) or print "ok\n" ;
    
    DBIx::Recordset::Undef ('set3') ;

    
    # ---------------------

    printlogf "Clear hash";
    print LOG "\n--------------------\n" ;

    tie %set15h, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $dbh,
                                           '!Username'     =>  $User,
                                           '!Password'     =>  $Password,
                                           '!Table'        =>  "$Table[1]",
					   '!WriteMode'    =>  (DBIx::Recordset::wmDELETE + DBIx::Recordset::wmCLEAR),
                                           '!PrimKey'      =>  'id'} or die "not ok ($DBI::errstr)" ;

    %set15h = () ;

    untie %set15h ;
    
    my @ids = @{$TestIds[1]} ;
    
    foreach my $id (@ids)
	{
	DelTestRowAndId (1, $id) ;
	}

    *set3 = DBIx::Recordset -> Search ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[1]"}) or die "not ok ($DBI::errstr)" ;

    Check ($TestIds[1], $TestFields[1], \@set3) or print "ok\n" ;
    
    DBIx::Recordset::Undef ('set3') ;

    # ---------------------

    printlogf "Assign hash";
    print LOG "\n--------------------\n" ;

    tie %set15h, 'DBIx::Recordset::Hash', {'!DataSource'   =>  $dbh,
                                           '!Username'     =>  $User,
                                           '!Password'     =>  $Password,
                                           '!Table'        =>  "$Table[0]",
					   '!WriteMode'    =>  (DBIx::Recordset::wmALL),
                                           '!PrimKey'      =>  'id'} or die "not ok ($DBI::errstr)" ;

    my %assign = (61 => {id => 61, name => 'n61', value1 => 961, addon => 'ao61'},
		  62 => {name => 'n62', value1 => 962, addon => 'ao62'}) ;  
    
    my %a2 = %assign ;

    %set15h = %a2 ;

    untie %set15h ;
    
    $assign {62} -> {id} = 62 ;
    
    @ids = @{$TestIds[0]} ;
    
    foreach my $id (@ids)
	{
	DelTestRowAndId (0, $id) ;
	}


    foreach my $id (keys %assign)
	{
	AddTestRowAndId (0, $assign{$id}) ;
	}
    

    *set3 = DBIx::Recordset -> Search ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[0]"}) or die "not ok ($DBI::errstr)" ;

    Check ($TestIds[0], $TestFields[0], \@set3) or print "ok\n" ;
    
    DBIx::Recordset::Undef ('set3') ;


    # ---------------------

    printlogf "Input Filter";
    print LOG "\n--------------------\n" ;

    *set3 = DBIx::Recordset -> Insert ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[1]",
					 'id'            =>  '4455',
					 'name2'         =>  '05.10.99',
					 '!Filter'   => 
					    {
					    'name2'     => [ sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"}, undef ]
					    }
					 }) or die "not ok ($DBI::errstr)" ;

    DBIx::Recordset::Undef ('set3') ;

    AddTestRowAndId (1, { id => '4455', name2 => '19991005'}) ;


    *set4 = DBIx::Recordset -> Search ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[1]",
					 'name2'         =>  '05.10.99',
					 '!Filter'   => 
					    {
					    'name2'     => 
						[ 
						    sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
					        ]
					    }
					 }) or die "not ok ($DBI::errstr)" ;


    Check ($TestIds[1], $TestFields[1], \@set4) or print "ok\n" ;
    
    DBIx::Recordset::Undef ('set4') ;
    
    # ---------------------

    printlogf "Output Filter";
    print LOG "\n--------------------\n" ;

    AddTestRowAndId (1, { id => '4455', name2 => '05.10.99'}) ;
    
    *set5 = DBIx::Recordset -> Search ({'!DataSource'   =>  $dbh,
                                        '!Username'     =>  $User,
                                        '!Password'     =>  $Password,
                                         '!Table'        =>  "$Table[1]",
					 'name2'         =>  '19991005',
					 '!Filter'   => 
					    {
					    'name2'     => 
						[ 
						    undef,
						    sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
					        ]
					    }
					 }) or die "not ok ($DBI::errstr)" ;


    Check ($TestIds[1], $TestFields[1], \@set5) or print "ok\n" ;
    

    # ---------------------

    printlogf "look for 4455";
    print LOG "\n--------------------\n" ;

    $set5 -> Search ({id => 4455
    					 }) or die "not ok ($DBI::errstr)" ;


    Check ($TestIds[1], $TestFields[1], \@set5) or print "ok\n" ;
    


    DBIx::Recordset::Undef ('set5') ;


    # ---------------------

    if ($Driver !~ /(?i:csv|sqlite)/)
	{
	printlogf "I/O Filter on type";
	print LOG "\n--------------------\n" ;

    
	*set6 = DBIx::Recordset -> Search ({'!DataSource'   =>  $dbh,
					    '!Username'     =>  $User,
					    '!Password'     =>  $Password,
					     '!Table'        =>  "$Table[1]",
					     'name2'         =>  '05.10.99',
					     '!Filter'   => 
						{
						&DBI::SQL_CHAR()     => 
						    [ 
							sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
							sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
						    ],
						&DBI::SQL_VARCHAR()     => 
						    [ 
							sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
							sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
						    ],
						1043   => 
						    [ 
							sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
							sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
						    ]
						}
					     }) or die "not ok ($DBI::errstr)" ;


	Check ($TestIds[1], $TestFields[1], \@set6) or print "ok\n" ;
    

	DBIx::Recordset::Undef ('set6') ;
        }
    
    # ---------------------

    if ($Driver ne 'CSV')
	{
        printlogf "DBIx::Database setup";
        print LOG "\n--------------------\n" ;



        my $db = DBIx::Database -> new ({'!DataSource'   =>  $dbh,
				        '!Username'     =>  $User,
				        '!Password'     =>  $Password,
                                        '!KeepOpen'     => 1}) ;


        my $tab ;
        my $k ;
        my $v ;
        my $e = $errors ;
        my $n ;

        my $tables = $db -> AllTables ;

        foreach (keys %$tables)
            {
            print LOG "Found table: $_\n" ;
            }


        foreach (@Table)
            {
            if (!$tables -> {lc($_)} && !$tables -> {uc($_)} )
                {
                printlog "ERROR in $lasttest: table $_ not found\n" ;
	        $errors++ ;
                }        
            my $l = $db -> TableLink ($_) ;
            if ($_ eq $Table[1] && (($n = keys (%$l)) != 1 || !$l -> {"-$Table[3]"}))
                {
                printlog "ERROR in $lasttest: table $_ does not contains the right link  (#$n)\n" ;
	        $errors++ ;
                }        
            elsif ($_ eq $Table[3] && (($n = keys (%$l)) != 1 || !$l -> {"*$Table[1]"}))
                {
                printlog "ERROR in $lasttest: table $_ does not contains the right link (#$n)\n" ;
	        $errors++ ;
                }        
            elsif ($_ eq $Table[7] && (($n = keys (%$l)) != 2 || !$l -> {"-$Table[7]"} || !$l -> {"*$Table[7]"}))
                {
                printlog "ERROR in $lasttest: table $_ does not contains the right link (#$n)\n" ;
	        $errors++ ;
                }        
            elsif ($_ ne $Table[1] && $_ ne $Table[3]  && $_ ne $Table[7] && keys (%$l) != 0)
                {
                printlog "ERROR in $lasttest: table $_ contains wrong link\n" ;
	        $errors++ ;
                }        
            }

        print "ok\n" if ($e == $errors) ;


        $db -> TableAttr ('*', '!PrimKey', 'id') ;

        # ---------------------


        if ($Driver !~ /(csv|sqlite)/i)
	    {
	    printlogf "DBIx::Database and I/O Filter";
	    print LOG "\n--------------------\n" ;
            }

            $db -> TableAttr ($Table[1], '!Filter', 
						    {
						    DBI::SQL_CHAR     => 
						        [ 
							    sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
							    sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
						        ],
						    DBI::SQL_VARCHAR     => 
						        [ 
							    sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
							    sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
						        ],
						    1043   => 
						        [ 
							    sub { shift =~ /(\d\d)\.(\d\d)\.(\d\d)/ ; "19$3$2$1"},
							    sub { shift =~ /\d\d(\d\d)(\d\d)(\d\d)/ ; "$3.$2.$1"}
						        ]
						    }) ;
                            


	    *set7 = DBIx::Recordset -> Search ({'!DataSource'   =>  $db,
					         '!Table'        =>  $Table[1],
					         'name2'         =>  '05.10.99',
						    
					         }) or die "not ok ($DBI::errstr)" ;


        if ($Driver !~ /(?i:csv|sqlite)/)
            {
	    Check ($TestIds[1], $TestFields[1], \@set7) or print "ok\n" ;
            }    

        # ---------------------

        printlogf "Attributes";
        print LOG "\n--------------------\n" ;

        if ($set7 -> PrimKey ne 'id')
            {
            printlog "ERROR in $lasttest: PrimKey not set\n" ;
	    $errors++ ;
            }        
        else
            {
            print "ok\n"  ;
            }

        printlogf "";

        if ($set7 -> TableName ne $Table[1])
            {
            printlog "ERROR in $lasttest: wrong TableName\n" ;
	    $errors++ ;
            }        
        else
            {
            print "ok\n"  ;
            }

        DBIx::Recordset::Undef ('set7') ;


        $db -> MetaData ($Table[4], undef, 1) ;
        $db -> MetaData ($Table[5], undef, 1) ;


        # ---------------------

        printlogf "DBIx::Database !TableFilter";
        print LOG "\n--------------------\n" ;



        my $db2 = DBIx::Database -> new ({'!DataSource'   =>  $dbh,
				        '!Username'     =>  $User,
				        '!Password'     =>  $Password,
                                        '!KeepOpen'     => 1,
                                        '!TableFilter'  => 'dbix_'}) ;


        $e = $errors ;

        $tables = $db2 -> AllTables ;

        if (($n = keys (%$tables)) != 2)
            {
            printlog "ERROR in $lasttest: wrong number of table (#$n)\n" ;
	    $errors++ ;
            }

        foreach (($Table[4], $Table[5]))
            {
            if (!$tables -> {$_})
                {
                printlog "ERROR in $lasttest: table $_ not found\n" ;
	        $errors++ ;
                }        

            my $l = $db -> TableLink ($_) ;
            if ($_ eq $Table[4] && (($n = keys (%$l)) != 4 || !$l -> {"-up__rs5"} || !$l -> {"*up__rs5"}  || !$l -> {"-a__rs6"} || !$l -> {"-b__rs6"}))
                {
                printlog "ERROR in $lasttest: table $_ does not contains the right link  (#$n)\n" ;
                foreach my $link (keys %$l)
                    {
                    print LOG "Found link $link\n" ;
                    }
	        $errors++ ;
                }        
            elsif ($_ eq $Table[5] && (($n = keys (%$l)) != 2 || !$l -> {"*a__rs5"}|| !$l -> {"*b__rs5"}))
                {
                printlog "ERROR in $lasttest: table $_ does not contains the right link (#$n)\n" ;
                foreach my $link (keys %$l)
                    {
                    print LOG "Found link $link\n" ;
                    }
	        $errors++ ;
                }        
            elsif ($_ ne $Table[4] && $_ ne $Table[5])
                {
                printlog "ERROR in $lasttest: table $_ contains wrong link\n" ;
	        $errors++ ;
                }        
            }

        print "ok\n" if ($e == $errors) ;

        if ($Driver eq 'mysql')
            {
            $e = $errors ;
                # ---------------------
    
            printlogf "DBIx::Recordset::DBseq";
            print LOG "\n--------------------\n" ;
    
            my $seq = DBIx::Recordset::DBSeq -> new ($db2 -> DBHdl, $Table[6]) ;
            
            if ($seq -> NextVal('foo') != 1)
                {
                printlog "ERROR in $lasttest: sequence value != 1\n" ;
                $errors++ ;
                }        
            elsif ($seq -> NextVal('foo') != 2)
                {
                printlog "ERROR in $lasttest: sequence value != 2\n" ;
                $errors++ ;
                }        
            elsif ($seq -> NextVal('foo') != 3)
                {
                printlog "ERROR in $lasttest: sequence value != 3\n" ;
                $errors++ ;
                }        
            if ($seq -> NextVal('bar') != 1)
                {
                printlog "ERROR in $lasttest: sequence value for bar != 1\n" ;
                $errors++ ;
                }        
            if ($seq -> NextVal('foo') != 4)
                {
                printlog "ERROR in $lasttest: sequence value != 4\n" ;
                $errors++ ;
                }        
            print "ok\n" if ($e == $errors) ;
            
            }
            
        $db = undef ;
        $db2 = undef ;
        }

        {
        my $e = $errors ;

        printlogf "DBIx::Recordset::FileSeq";
        print LOG "\n--------------------\n" ;

        unlink <test/seq.*> ;
    
        my $seq = DBIx::Recordset::FileSeq -> new (undef ,'test') ;
        
        if ($seq -> NextVal('foo') != 1)
            {
            printlog "ERROR in $lasttest: sequence value != 1\n" ;
            $errors++ ;
            }        
        elsif ($seq -> NextVal('foo') != 2)
            {
            printlog "ERROR in $lasttest: sequence value != 2\n" ;
            $errors++ ;
            }        
        elsif ($seq -> NextVal('foo') != 3)
            {
            printlog "ERROR in $lasttest: sequence value != 3\n" ;
            $errors++ ;
            }        
        if ($seq -> NextVal('bar') != 1)
            {
            printlog "ERROR in $lasttest: sequence value for bar != 1\n" ;
            $errors++ ;
            }        
        if ($seq -> NextVal('foo') != 4)
            {
            printlog "ERROR in $lasttest: sequence value != 4\n" ;
            $errors++ ;
            }        

        print "ok\n" if ($e == $errors) ;
        }
        
        {
        my $e = $errors ;

        printlogf "DBIx::Recordset::FileSeq 2";
        print LOG "\n--------------------\n" ;

        my $seq = DBIx::Recordset::FileSeq -> new (undef ,'test') ;
        
        if ($seq -> NextVal('foo') != 5)
            {
            printlog "ERROR in $lasttest: sequence value != 5\n" ;
            $errors++ ;
            }        
        elsif ($seq -> NextVal('foo') != 6)
            {
            printlog "ERROR in $lasttest: sequence value != 6\n" ;
            $errors++ ;
            }        
        if ($seq -> NextVal('bar') != 2)
            {
            printlog "ERROR in $lasttest: sequence value for bar != 2\n" ;
            $errors++ ;
            }        
        if ($seq -> NextVal('foo') != 7)
            {
            printlog "ERROR in $lasttest: sequence value != 7\n" ;
            $errors++ ;
            }        

        print "ok\n" if ($e == $errors) ;
        }



    #########################################################################################

     # cleanup
     if (!$nocleanup)
        {
        my  $dbh = DBIx::Recordset -> SetupObject ({'!DataSource' =>  $dbh,
                                                 '!Username' =>  $User, '!Password' =>  $Password
                                                });
        DropTestTables($dbh, @Table);
        $dbh->Disconnect;
        }

    #########################################################################################

    if ($errors)
        {
        print "\n$errors Errors detected for driver $Driver\n" ;
        }
    else
        {
        print "\nTests passed successfully for driver $Driver\n" ;
        }

    return $errors ;
    }

#########################################################################################


unlink "test.log" ;
unlink <test/seq.*> ;
chmod 0777, 'test' ; 
    
    open LOG, ">>test.log" or die "Cannot open test.log" ; 

    *DBIx::Recordset::LOG = \*LOG ; 
    $DBIx::Recordset::Debug = 5 ; 

    open (STDERR, ">&LOG") || die "Cannot redirect stderr" ;  
    #open (STDERR, ">dbi.log") || die "Cannot redirect stderr" ;  
    #DBI->trace(2) ;
    select (STDERR) ; $| = 1 ;
    select (LOG) ; $| = 1 ;
    select (STDOUT) ; $| = 1 ;



if ($#ARGV != -1)
    {
    eval { do $configfile ; } ;


    $Driver      = $ARGV[0] ;
    $DSN         = $ARGV[1] || $Drivers{$Driver}{dsn} ; 
    $User        = $ARGV[2] || $Drivers{$Driver}{user}  ;
    $Password    = $ARGV[3] || $Drivers{$Driver}{pass}  ;
    $nocleanup   = $ARGV[4] || 0 ;

    $> = $Drivers{$Driver}{uid} if (defined ($Drivers{$Driver}{uid})) ;
    $rc = DoTest ($Driver, $DSN, $User, $Password) ;
    $> = $< if ($Drivers{$Driver}{uid}) ;
    
    $fatal = 0 ;

    exit $rc ;
    }

do $configfile ;

@drivers = sort keys %Drivers ;


foreach $drv (@drivers)
    {
    $> = $Drivers{$drv}{uid} if (defined ($Drivers{$drv}{uid})) ;
    $errcnt {$drv} = DoTest ($drv, $Drivers{$drv}{dsn}, $Drivers{$drv}{user}, $Drivers{$drv}{pass}) ;
    $> = $< if ($Drivers{$drv}{uid}) ;
    }
     
$err = 0 ;
print "\nSummary:\n" ;

foreach $drv (@drivers)
    {
    if ($errcnt {$drv})
        {
        print "$errcnt{$drv} Errors detected for $drv\n" ;
        }
    else
        {
        print "Tests for $drv passed successfully\n" ;
        }
    $err += $errcnt {$drv} ;
    }

if ($err)
    {
    print "\n$err Errors detected at all\n" ;
    }
else
    {
    print "\nAll tests passed successfully\n" ;
    }

$fatal = 0 ;

__END__
