#!perl

use CGI ;
use DBIx::Recordset ;


$DBIx::Recordset::Debug = 0 ;

$q = new CGI ;

print $q -> header ;
print $q -> start_html (title=>'Example for DBIx::Recordset') ;
print '<h1>DBIx::Recordset Example </h1>' ;


### convert form parameter to hash ###

%fdat = map { $_ => $q -> param($_) } $q -> param ;

$fdat{'!IgnoreEmpty'} = 2 ; # Just to make the condition dialog work

if (!defined ($fdat{'!DataSource'}) || !defined ($fdat{'!Table'})|| defined($fdat{'showdsn'}))
    {
    
    #### show entry form to select datasource ####
    
    
    delete $fdat{'showdsn'} ;
    
    @drvs = DBI-> available_drivers ; 


    print $q ->  startform (-method => GET) ;
    print "<table><tr><td>Available DBD drivers<br>\n" ;
    print $q -> scrolling_list (-name=>"driver",
                                -values=>\@drvs,
                                -size=>7) ;
    print "</td>\n" ;
    print "<td>First of all you have to specify which database and table you want to access and enter\n" ;
    print "the user and password (if required)<p>For the Datasource you have the following Options:<br>\n" ;
    print "1.) choose a DBD driver from the list on the left and hit the Show Datasources button,\n" ;
    print "then you can select a Datasource below (if your DBD driver supports the <em>data_sources</em>\n" ;
    print "method)<br>\n" ;
    print "2.) enter the Data Source directly in the text field below</td>\n" ;
    print "</tr>\n" ;
    print "</table>\n" ;
    
    @dsns = DBI->data_sources ($fdat{driver}) if ($fdat{driver}) ; 

    print "<table>\n" ;
    print "<tr>\n" ;
    print "  <td>Datasource:</td>\n" ;
    print "  <td>\n" ;

    # fixup for drivers which does not support the data_sources method
    @dsns = () if ($dsns[0] =~ /HASH/ ) ;

    # fixup for mSQL/mysql driver
    for ($i = 0; $i <= $#dsns; $i++)
        {
        $dsns[$i] =~ s/^DBI/dbi/ ;
        }
    
    if ($#dsns >= 0)
        {
        print $q -> popup_menu (-name=>"!DataSource",
                                -size=>"1",
                                -value=>\@dsns) ;
        }
    else
        {
        print $q -> textfield (-name=>"!DataSource", -size=>20) ;           
        print "Datasource list not available, enter DSN manual" ;
        }
    print "  </td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>Table:</td>\n" ;
    print "  <td>" , $q -> textfield (-name=>"!Table", -size=>"20"), "</td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>User:</td>\n" ;
    print "  <td>" , $q -> textfield (-name=>"!Username", -size=>"20"), "</td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>Password:</td>\n" ;
    print "  <td>" , $q -> password_field (-name=>"!Password", -size=>"20"), "</td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>Rows Per Page:</td>\n" ;
    $q -> param (-name=>'$max', -value=>5) if (!$fdat{'$max'}) ;
    print "  <td>" , $q -> textfield (-name=>'$max', -size=>5), "</td>\n" ;
    print "</tr>\n" ;
    print "</table>\n" ;
    print "<p>\n" ;
    print $q -> submit (-value=>"Show Datasources", -name=>"showdsn") ;
    print $q -> submit (-value=>"Show whole table", -name=>"show") ;
    print $q -> submit (-value=>"Specify condition", -name=>"cond") ;
    print $q -> reset  (-name=>"Reset") ;

    print $q -> endform ;
    }
elsif (defined ($fdat{'cond'}))
    {

    #### enter a search condition #####

    delete $fdat{'cond'};
    
    ### setup recordset ###
    $set = DBIx::Recordset -> SetupObject (\%fdat) ;
    ### get the names of all fields ###
    $names = $set -> AllNames ()  if ($set) ;


    print "<table>\n" ;
    print "<tr>\n" ;
    print "  <td>Datasource:</td>\n" ;
    print "  <td>\n" ;
    print $fdat{"!DataSource"} ;           
    print "  </td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>Table:</td>\n" ;
    print "  <td>$fdat{'!Table'}</td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>User:</td>\n" ;
    print "  <td>$fdat{'!Username'}</td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>Rows Per Page:</td>\n" ;
    print "  <td>$fdat{'$max'}</td>\n" ;
    print "</tr>\n" ;

    if ($DBI::errstr)
        {
        print "<tr>\n" ;
        print "  <td>ERROR:</td>\n" ;
        print "  <td>" , $DBI::errstr , "</td>\n" ;
        print "</tr>\n" ;
        }

    print "</table><p>\n" ;

    if ($set)
        {
        print $q ->  startform (-method => GET) ;
        print "  <table border=1>\n" ;
        print "    <tr>\n" ;
        print "      <th>Fieldname</th>\n" ;
        print "      <th>Operator</th>\n" ;
        print "      <th>Value</th>\n" ;
        print "    </tr>\n" ;
    
        foreach $n (@$names)
            {
            print "    <tr>\n" ;
            print "      <td>$n</td>\n" ;
            print "      <td>", $q -> textfield (-name=>"\*$n", -size=>5), "</td>\n" ;
            print "      <td>", $q -> textfield (-name=>$n, -size=>20), "</td>\n" ;
            print "    </tr>\n" ;
            }
        print "  </table>\n" ;
        print "<p>\n" ;
        print $q -> hidden (-name=>'!DataSource', -value=>$fdat{'!DataSource'}) ;
        print $q -> hidden (-name=>'!Table',      -value=>$fdat{'!Table'}) ;
        print $q -> hidden (-name=>'!Username',   -value=>$fdat{'!Username'}) ;
        print $q -> hidden (-name=>'!Password',   -value=>$fdat{'!Password'}) ;
        print $q -> hidden (-name=>'$max',        -value=>$fdat{'$max'}) ;
        print $q -> hidden (-name=>'driver',      -value=>$fdat{'driver'}) ;
    
        print $q -> submit (-value=>"Start search",      -name=>"search") ;
        print $q -> submit (-value=>"Change Datasource", -name=>"showdsn") ;
        print $q -> reset  (-name=>"Reset") ;

        print $q -> endform ;
        }
    }
else
    {

    #### show query result ####

    ### setup object and do the query ###
    *set = DBIx::Recordset -> Search (\%fdat) ;
    ### get fieldnames of query ###
    $names = $set -> Names if ($set) ;

    print "<table>\n" ;
    print "<tr>\n" ;
    print "  <td>Datasource:</td>\n" ;
    print "  <td>\n" ;
    print $fdat{"!DataSource"} ;           
    print "  </td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>Table:</td>\n" ;
    print "  <td>$fdat{'!Table'}</td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>User:</td>\n" ;
    print "  <td>$fdat{'!Username'}</td>\n" ;
    print "</tr>\n" ;
    print "<tr>\n" ;
    print "  <td>Rows Per Page:</td>\n" ;
    print "  <td>$fdat{'$max'}</td>\n" ;
    print "</tr>\n" ;

    if ($DBI::errstr)
        {
        print "<tr>\n" ;
        print "  <td>ERROR:</td>\n" ;
        print "  <td>" , $DBI::errstr , "</td>\n" ;
        print "</tr>\n" ;
        }


    if ($set)
        {
        print "<tr>\n" ;
        print "  <td>Current Start Row:</td>\n" ;
        print "  <td>" , $set -> StartRecordNo , "</td>\n" ;
        print "</tr>\n" ;

        print "<tr>\n" ;
        print "  <td>SQL Statement:</td>\n" ;
        print "  <td>" , $set -> LastSQLStatement , "</td>\n" ;
        print "</tr>\n" ;

        print "</table><p>\n" ;


        print "<table border=1>\n" ;
        print "  <tr>\n" ;
        foreach $n (@$names)
            {
            print "    <th>$n</th>\n" ;
            }
        print "  </tr>\n" ;
        $row = 0 ;
        while ($r = $set[$row++])
            {
            print "  <tr>\n" ;
            foreach $n (@$names)
                {
                print "    <td>$$r{lc($n)}</td>\n" ;
                }
            print "  </tr>\n" ;
            }
        print "</table>\n" ;

        print $set -> PrevNextForm ('<<Previous Records', 'Next Records>>', \%fdat) ;

        print $q ->  startform (-method => GET) ;
        while (($k, $v) = each (%fdat))
            {
            if ($k ne 'refresh' && $k ne 'search' && $k ne 'showdsn' && $k ne 'cond')
                {
                print $q -> hidden (-name=>$k, -value=>$v) ;
                }
            }
        print "<p>\n" ;
        print $q ->submit (-value=>"Refresh", -name=>"refresh") ;
        print $q -> submit (-value=>"Specify condition", -name=>"cond") ;
        print $q -> submit (-value=>"Change Datasource", -name=>"showdsn") ;
        print $q -> endform ;
        }
    }

### cleanup ###

DBIx::Recordset::Undef ('set') ;

print $q -> end_html ;

