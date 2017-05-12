#
#

BEGIN { require 5.004 }				# 5.004 is required for Win32
use Config;
use ExtUtils::MakeMaker 5.16, qw(&WriteMakefile $Verbose);
use DBI 0.89;					# must be installed first
use DBI::DBD;
use File::Find;
use strict;

my $VER = '3.5';				# DBMaker version
my $VERNO = $VER;
$VERNO =~ s/\.//;
my $search_dirs;
if (!$ENV{'DBMAKER_HOME'}) {
  if ($^O eq 'MSWin32') {			# Win32
    $ENV{'DBMAKER_HOME'} = "c:/dbmaker/$VER";	# Guess DBMaker install in here.
  }
  else {					# UNIX
    if(my $d=(getpwnam('dbmaker'))[7]) {	# If not defined DBMAKER_HOME
      $ENV{'DBMAKER_HOME'} = $d . "/$VER";	# we search ~dbmaker user
    }
    else {					# Maybe just install client
      $ENV{'DBMAKER_HOME'} = "/usr/local";	# Guess install in /usr/local.
    }
  }
}
$search_dirs = $ENV{'DBMAKER_HOME'};

my %opts = 
(
    'NAME'	  => 'DBD::DBMaker',
    'VERSION_FROM'=> 'DBMaker.pm',
    'LIBS'        => [''],
    'DEFINE'      => '',
    'INC'         => "-I\$(INSTALLSITEARCH)/auto/DBI",
    clean	  => { FILES=> 'DBMaker.xsi' },
    dist	  => {
		     #DIST_DEFAULT=> 'clean distcheck disttest ci tardist',
		     DIST_DEFAULT => 'clean distcheck ci tardist',
		     PREOP        => '$(MAKE) -f Makefile.old distdir',
		     COMPRESS     => 'gzip', SUFFIX => 'gz'
	             },
    OBJECT	  => '$(O_FILES)',
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
	$opts{ABSTRACT} = "DBMaker $VER driver for Perl DBI";
	$opts{AUTHOR} = 'DBMaker team(dbmaker@lion.syscom.com.tw)';
	$opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
}

print "\nConfiguring DBD::DBMaker ...\n
>>>\tRemember to actually *READ* the README file!
   \tAnd re-read it if you have any problems.\n
";

my ($incdir) = find_inc($search_dirs);
my ($libname, $libdir) = find_lib($search_dirs);
unless (defined($incdir) && defined($libname) && defined($libdir)) {
  print "Cannot found DBMaker include files or lib\n".
  Usage();
}

print "Configuring for DBMaker ...\n";
if ($^O eq 'MSWin32') {
    $opts{DEFINE}  = "-DMSWin32";
    $opts{LIBS} = ["$libdir/DMAPI$VERNO.LIB"];
    $opts{INC}  = "-I$incdir $opts{INC}";
    $opts{INC}  = "$opts{INC} $Config{incpath}\\mfc" if ($Config{cc} eq 'bcc32');
}
else {
    $opts{INC} = "-I. -I$incdir $opts{INC}";
    $libname =~ s/^lib//;
    $libname =~ s/\.a|\.so&//;
    $opts{LIBS} = " -L$libdir -l$libname -lm";
    # Because unable to resolve stat()
    if ($^O eq "linux") {
      $opts{LIBS} = $opts{LIBS}." -lc";
    }
}

WriteMakefile(%opts);

local($^W)=0;
print qq{
The DBD::DBMaker tests will use these values for the database connection:
    DBI_DSN=$ENV{DBI_DSN}		e.g. dbi:DBMaker:demo
    DBI_USER=$ENV{DBI_USER}
    DBI_PASS=$ENV{DBI_PASS}
};
print "Warning: not all required environment variables are set.\n"
	unless ($ENV{DBI_DSN} && $ENV{DBI_USER} && $ENV{DBI_PASS});
print "Warning: DBI_DSN ($ENV{DBI_DSN}) doesn't start with 'dbi:DBMaker:'\n"
	if ($ENV{DBI_DSN} && $ENV{DBI_DSN} !~ m/^[dD][bB][iI]:DBMaker:/);

sub find_lib {				# Search DBMaker include file directory
  my $dirs = $_[0];
  my $wanted = sub {
      my $f = $::wanted_lib;
      if ($_ =~ /$f/i && -f $_ && -r $_) {
      	push(@::dbmaker_libname, $_);
      	push(@::dbmaker_libdir, $File::Find::dir);
      }
    };
  @::dbmaker_libname = ();
  @::dbmaker_libdir = ();
  my @lib_name;
  @lib_name = ($^O eq 'MSWin32') ? ( "DMAPI$VERNO.LIB" ) : ( "libdmapic.a" );
  foreach (@lib_name) {
    $::wanted_lib = $_;
    find($wanted, $dirs);
  }
  ($::dbmaker_libname[0], $::dbmaker_libdir[0]);
}

sub find_inc {				# Search DBMaker include file directory
  my $dirs = $_[0];
  my $wanted = sub {
      my $f = $::wanted_inc; 
      push(@::dbmaker_inc, $File::Find::dir)
          if($_ =~ /$f/i && -f $_ && -r $_);
    };
  @::dbmaker_inc = ();
  my @inc_name = ( "sqlopt.h" );
  foreach (@inc_name) {
    $::wanted_inc = $_;
    find($wanted, $dirs);
  }
  ($::dbmaker_inc[0]);
}

sub Usage {
  print "You must set the 'DBMAKER_HOME' environment variable before running me.\n";
  exit(0);
}
__END__
