#
# Building Makefile for DBIx::Recordset
#
# (C) 1997-1998 G.Richter (richter@dev.ecos.de) / ECOS
#
#


use ExtUtils::MakeMaker;

# Ignore the following DBD Drivers

%ignore = ('ExampleP' => 1,
           'NullP'    => 1,
           'Sponge'   => 1,
           'Proxy'   => 1,
	   'File'     => 1) ;

%datasource = (
	       'Pg'       => 'dbi:Pg:dbname=test',
	       'SQLite'   => 'dbi:SQLite:test.db',
               'Solid'    => 'dbi:Solid:'
	      ) ;

$configfile = 'test/Config.pl' ;

mkdir 'test', 0755 ;

if (-e $configfile)
    {
    do $configfile ;
    }

## ----------------------------------------------------------------------------

sub MY::test_via_script 
	{
	my ($txt) = shift -> MM::test_via_script (@_) ;

	$txt =~ s/\$\(TEST_FILE\)/\$(TEST_FILE) \$(TESTARGS)/g ;

	return $txt ;
	}
	

## ----------------------------------------------------------------------------

sub GetString
	{
	my ($prompt, $default) = @_ ;

	printf ("%s [%s]", $prompt, $default) ;
	chop ($_ = <STDIN>) ;
	if (!/^\s*$/)
	    {return $_ ;}
	else
    	{
        if ($_ eq "")
	        {return $default ;}
	    else
            { return "" ; }
    
        }
    }

## ----------------------------------------------------------------------------

sub GetYesNo
	{
	my ($prompt, $default) = @_ ;
	my ($value) ;

	do
	    {
	    $value = lc (GetString ($prompt . "(y/n)", ($default?"y":"n"))) ;
	    }
	until (($value cmp "j") == 0 || ($value cmp "y") == 0 || ($value cmp "n" ) == 0) ;

	return ($value cmp "n") != 0 ;
	}

## ----------------------------------------------------------------------------

print "\n" ;

eval 'use DBI' ;

if ($@ ne '')
    {
    print "\nPlease install DBI before installing DBIx::Recordset\n" ;
    exit (1) ;
    }

print "Found DBI version $DBI::VERSION\n" ;

$skip = 0 ;
if (-e $configfile)
    {
    $skip = GetYesNo ("Use previous configuration for tests", 1) ;
    }
	
if (!$skip)
    {
@drvs = DBI::available_drivers () ;

$driversinstalled = 0 ;
foreach $drv (@drvs)
    {
    next if (exists ($ignore{$drv})) ;
    
    if (exists $Drivers{$drv})
        { $drivers{$drv} = $Drivers{$drv} ; }
    else
        { $drivers{$drv}{dsn} = $datasource{$drv} || "dbi:$drv:test" ; }

    $driversinstalled = 1 ;
    }

if ($driversinstalled == 0)
    {
    print "\nAt least one DBD driver must be installed before installing DBIx::Recordset\n" ;
    exit (1) ;
    }

print "Found the following DBD drivers:\n" ;

@drivers = sort keys %drivers ;
$i = 1 ;

foreach $drv (@drivers)
    {
    print "$i.) $drv\n" ;
    $i++ ;
    }
print "\n" ;
print "For running tests it's necessary to have an existing datasource for each\n" ;
print "DBD driver against which DBIx::Recordset should be tested.\n" ;
print '
For most drivers, 

   DROP DATABASE TEST; CREATE DATABASE TEST 

is adequate. For SQLite, it is recommended to do the following:

   cd $DIST; cat > test.db <control-d>

to create an empty database. $DIST is the root directory of the Recordset
distribution.
';

print "Please enter a valid datasource (or accept the default) for each DBD driver\n" ;
print "or enter a '.' if you do not want to test DBIx::Recordset against this driver\n" ;
print "\n" ;

$i = 1 ;
foreach $drv (@drivers)
    {
    $dsn = GetString ("$i.) $drv",  $drivers{$drv}{dsn}) ;
    if ($dsn eq '.')
        { delete $drivers{$drv} ; }
    else
        {
        $drivers{$drv}{dsn} = $dsn ;
        $user = GetString ("\tUsername", defined ($drivers{$drv}{user})?$drivers{$drv}{user}:"undef") ;
        if ($user ne 'undef') 
            {
            $drivers{$drv}{user} = $user ;        
            $pass = GetString ("\tPassword", defined ($drivers{$drv}{pass})?$drivers{$drv}{pass}:"undef") ;
            $drivers{$drv}{pass} = $pass if ($pass ne 'undef') ;        
            }
        }
    $i++ ;
    }

print "\n" ;
print "The tests will performed with the following parameters\n" ;

@drivers = sort keys %drivers ;
foreach $drv (@drivers)
    {
    print "$drv \t-> $drivers{$drv}{dsn}\t" ;
    print "user: $drivers{$drv}{user}\t" if (defined ($drivers{$drv}{user})) ;
    print "password: $drivers{$drv}{pass}"  if (defined ($drivers{$drv}{pass})) ;
    print "\n" ;
    }

print "\n" ;
print "In every of the above datasources the tables\n" ;
print "\n" ;
print "   dbixrs1, dbixrs2, dbixrs3, dbixrs4\n" ;
print "\n" ;
print "will be created and dropped afterwards. 
Please make sure the datasources
exist *before* you run make test.


" ;



open FH, ">$configfile" or die "Cannot open $configfile for writing ($!)" ;

print FH "%Drivers = (\n" ;

foreach $drv (@drivers)
    {
    print FH "\t$drv => {\n" ;
    print FH "\t\tdsn  => \"$drivers{$drv}{dsn}\",\n" ;
    print FH "\t\tuser => \"$drivers{$drv}{user}\",\n" if (defined ($drivers{$drv}{user})) ;
    print FH "\t\tpass => \"$drivers{$drv}{pass}\",\n" if (defined ($drivers{$drv}{pass}));
    print FH "\t},\n" ;
    }

print FH ");\n" ;

close FH ;
    } 


WriteMakefile
    (
    'NAME'	=> 'DBIx::Recordset',
    'VERSION_FROM' => 'Recordset.pm', # finds $VERSION
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz'},
    'clean'        => { FILES => 'test.log' },
    'realclean'    => { FILES => './test test.log' },

    );
