#
#   engn/perldb2/Constants/Makefile.PL, engn_perldb2, db2_v82fp9, 1.6 01/10/03 11:26:28
#
#   Copyright (c) 1995,1996,1998,1999 International Business Machines Corp.
#
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%opts = (
        'NAME'          => 'DBD::DB2::Constants',
        'VERSION_FROM'  => 'Constants.pm',
        'LIBS'          => [''],   # e.g., '-lm'
        'DEFINE'        => '',     # e.g., '-DHAVE_SOMETHING'
);

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
  my ($pathsep, $path, @pathlist, $apath);

  $pathsep = $Config{'path_sep'};
  $pathsep = ':' unless $pathsep;

  $path = $ENV{'PATH'};
  $path =~ s:\\:/:g if $pathsep eq ';';

  @pathlist=();
  while ($path =~ /(.)/g)
  {
    if ("$1" eq "$pathsep")
    {
      push(@pathlist, $apath);
      $apath="";
    } else {
      $apath .= $1;
    }
  }
  push(@pathlist, $apath);

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

# --- Setup include path

$opts{INC} = qq(-I"$DB2/include");

# --- Handle special cases
if( $os eq "hpux" )
{
  $opts{DEFINE} .= ' +Onolimit +e';
}
elsif( $os eq "aix" )
{
  $opts{DEFINE} .= ' -qcpluscmt';
}
elsif( $os eq "solaris" )
{
  if( $Config{cc} eq 'cc' )
  {
    $opts{DEFINE} .= ' -xCC';
  }
}

WriteMakefile( %opts );
