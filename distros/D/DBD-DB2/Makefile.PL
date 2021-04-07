
#   engn/perldb2/Makefile.PL, engn_perldb2, db2_v82fp9, 1.11 04/09/14 10:47:41
#
#   Copyright (c) 1995-2004 International Business Machines Corp.
#
#!/usr/local/bin/perl -sw

use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose );
use Getopt::Std;
use Config;
#require 'flush.pl';

use DBI;        # The DBI must be installed before we can build a DBD

my %opts = (
    'NAME'         => 'DBD::DB2',
    'VERSION_FROM' => 'DB2.pm',
    ($] ge '5.005')
       ? ( 'AUTHOR' => 'DB2 Perl (db2perl@ca.ibm.com)',
           'ABSTRACT' => 'Perl driver for IBM DB2 Universal Database', )
       : (),
    ( $Config{archname} =~ /-object\b/i )
       ? ( 'CAPI' => 'TRUE', )
       : (),
    'OBJECT'       => '$(O_FILES)',
);

# --- Introduction

print "\nConfiguring DBD::DB2...\n";
print "Remember to actually read the README and CAVEATS files!\n\n";

# --- Operating system

my $os = $^O;

# --- Where is DB2 installed...

my $envvar = 'DB2_HOME';
my $DB2 = $ENV{$envvar};
if( not $DB2 )
{
  $envvar = 'DB2PATH';
  $DB2 = $ENV{$envvar};
}
if( not $DB2 )
{
  my ($pathsep, $path, @pathlist);

  $pathsep = $Config{'path_sep'};
  $pathsep = ':' unless $pathsep;

  $path = $ENV{'PATH'};
  $path =~ s:\\:/:g if $pathsep eq ';';

  @pathlist = split /$pathsep/, $path;
  foreach $path (@pathlist)
  {
    if( lc( substr( $path, -4 ) ) eq '/bin' &&
        -f "$path/../include/sqlcli.h" )
    {
      $DB2 = substr( $path, 0, -4 );
      last;
    }
  }
}
$DB2 =~ s:\\:/:g if $os eq 'MSWin32' || $os eq 'MSWin64' || $os eq 'os2';
$DB2 =~ s/"//g;
die "DB2_HOME environment variable must be set to installed location of DB2.\n"
    unless $DB2;
die "$envvar environment variable ($DB2) not valid.\n" unless -d $DB2;

print qq(Using DB2 in "$DB2"\n);

# --- Setup include paths and libraries
$opts{INC} .= qq( -I"$DB2/include" -I"$Config{sitearchexp}/auto/DBI" );
$opts{INC} .= qq(-I"$Config{installarchlib}/auto/DBI" ) if $Config{installarchlib};
$opts{INC} .= qq(-I"$Config{installvendorarch}/auto/DBI" ) if $Config{installvendorarch};
$opts{INC} .= qq(-I"$Config{installsitearch}/auto/DBI" ) if $Config{installsitearch};
$opts{dynamic_lib} = { OTHERLDFLAGS => '$(COMPOBJS) '};

# libraries required to build DBD::DB2 driver
if( $os eq 'MSWin32' || $os eq 'MSWin64' || $os eq 'os2' )
{
  my $DB2LIB = $ENV{'DB2LIB'};
  if( not $DB2LIB )
  {
    if (-e "$DB2/lib64")
    {
      $DB2LIB = "$DB2/lib64";
    }
    else
    {
      if (-e "$DB2/lib32")
      {
         $DB2LIB = "$DB2/lib32";
      }
      else
      {
        $DB2LIB = "$DB2/lib";
      }
    }
  }
  $sysliblist = qq(-L"$DB2LIB" db2cli.lib db2api.lib);
  my @libpaths = split /;/, $ENV{'LIB'};
  my $libpath;
  while( @libpaths )
  {
    ( $libpath = shift(@libpaths) ) =~ s/"//g;  # Remove quotes
    $libpath =~ s:\\:/:g;

    if( $libpath && $sysliblist !~ /-L"$libpath"/i )
    {
      $sysliblist .= qq( -L"$libpath");
    }
  }
}
else
{
  my $DB2LIB = $ENV{'DB2LIB'};
  if( not $DB2LIB )
  {
    if (-e "$DB2/lib64")
    {
      $DB2LIB = "$DB2/lib64";
    }
    else
    {
      if (-e "$DB2/lib32")
      {
         $DB2LIB = "$DB2/lib32";
      }
      else
      {
        $DB2LIB = "$DB2/lib";
      }
    }
  }
      
  $sysliblist = "-L$DB2LIB -ldb2";

}

# --- Handle special cases ---
if ($os eq 'hpux')
{
  $sysliblist .= ' -lcl';
  $opts{DEFINE} .= ' +e';
}

#Defining a macro to fix the compile issue in DBD::DB2  
#which was due to change in definition of DBIc_CACHED_KIDS in DBIv1.55  
 
#if( $DBI::VERSION > 1.54 )
if( "$DBI::VERSION" ge "1.55" )
{
   $opts{DEFINE} .= ' -DDB2_CACHE_FIX ';
}

$opts{LIBS} = [ $sysliblist ];

# log key platform information to help me help you quickly
print "System: perl$] DBI$DBI::VERSION @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";
print "Includes: $opts{INC}\n";
print "Libraries: @{$opts{LIBS}}\n";
print "\n";

WriteMakefile(%opts);

exit 0;


sub MY::post_initialize{
'
default_target: all
';
}

__END__
