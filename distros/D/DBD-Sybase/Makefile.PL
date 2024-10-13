# $Id: Makefile.PL,v 1.48 2012/10/26 19:11:54 mpeppler Exp $

use ExtUtils::MakeMaker;

require 5.004;

use strict;

# If either of these aren't available on your system then you need to
# get them!
use DBI;
use DBI::DBD;
use Config;
use Getopt::Long;

use vars qw($SYBASE $inc_string $lib_string $LINKTYPE $written_pwd_file
  $newlibnames $libdir);

$LINKTYPE         = 'dynamic';
$written_pwd_file = 'PWD';

# regexp to find libct/libsybct, and avoid picking up libct_cu which isn't anything we want at all...
# https://github.com/mpeppler/DBD-Sybase/issues/64
my $libct_re = qr/\blib(syb)?ct(64)?\./i;
# freetds can be installed in system lib directories. We can pick those out
# from Config{libsdir}
my @libsdir = split(' ', $Config{libsdirs});


my $file;
my $chained;
my $threaded_libs;
my $accept_test_defaults;
my $use_env;
GetOptions(
  '--file'                 => \$file,
  '--chained:s'            => \$chained,
  '--threaded_libs:s'      => \$threaded_libs,
  '--accept_test_defaults' => \$accept_test_defaults,
  '--use_env'              => \$use_env
);

if ($ENV{DBD_SYB_USE_ENV} and $ENV{DBD_SYB_USE_ENV} =~ /y/i) {
  $use_env = 1;
}

select(STDOUT);
$| = 1;

configure();

configPwd();

my $lddlflags = $Config{lddlflags};
# According to https://github.com/mpeppler/DBD-Sybase/issues/62 we don't need to set
# lddlflags or ldflags on Windows.
$lddlflags = "-L$SYBASE/$libdir $lddlflags" unless $^O eq 'VMS' || $^O eq 'MSWin32';
my $ldflags = $Config{ldflags};
$ldflags = "-L$SYBASE/$libdir $ldflags" unless $^O eq 'VMS' || $^O eq 'MSWin32';

WriteMakefile(
  'NAME'    => 'DBD::Sybase',
  PREREQ_PM => {
    'DBI' => '0'
  },
  LIBS           => [$lib_string],
  INC            => $inc_string,
  clean          => { FILES => "Sybase.xsi $written_pwd_file" },
  OBJECT         => '$(O_FILES)',
  'VERSION_FROM' => 'Sybase.pm',
  'LDDLFLAGS'    => $lddlflags,

  #	      'LDFLAGS'      => $ldflags,
  LINKTYPE => $LINKTYPE,
  (
    $^O eq 'VMS'
    ? ( MAN3PODS => { 'Sybase.pm' => 'blib/man3/DBD_Sybase.3' } )
    : ( MAN3PODS => { 'Sybase.pm' => 'blib/man3/DBD::Sybase.3' } )
  ),
  ABSTRACT => 'DBI driver for Sybase datasources',
  AUTHOR   => 'Michael Peppler (mpeppler@peppler.org)',
  (
         $] >= 5.005
      && $^O eq 'MSWin32'
      && $Config{archname} =~ /-object\b/i ? ( CAPI => 'TRUE' ) : ()
  ),
  'dist' => { 'TARFLAGS' => 'cvf', 'COMPRESS' => 'gzip' },
  ( $^O eq 'VMS' ? ( PM => 'Sybase.pm' ) : () ),
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources   => {
      bugtracker => {
        web => 'https://github.com/mpeppler/DBD-Sybase/issues',
      },
      repository => {
        url  => 'https://github.com/mpeppler/DBD-Sybase.git',
        web  => 'https://github.com/mpeppler/DBD-Sybase',
        type => 'git',
      }
    },
  }
);

sub MY::postamble {
  return dbd_postamble();
}

sub configure {
  my %attr;
  my ( $key, $val );

  my $sybase_dir = $ENV{SYBASE};

  if ( !$sybase_dir ) {

    # PR 517 - getpwnam() isn't portable.
    eval q{
	    $sybase_dir = (getpwnam('sybase'))[7];
	};
  }

  open( IN, "CONFIG" ) || die "Can't open CONFIG: $!";
  while (<IN>) {
    chomp;
    next if /^\s*\#/;
    next if /^\s*$/;

    ( $key, $val ) = split( /\s*=\s*/, $_ );
    $key =~ s/\s//g;
    $val =~ s/\s*$//;

    $attr{$key} = $val;
  }

  if ( -d $sybase_dir ) {
    $SYBASE = $sybase_dir;
  } else {
    if ( $attr{SYBASE} && -d $attr{SYBASE} ) {
      $SYBASE = $attr{SYBASE};
    }
  }

  if ( !$SYBASE || $SYBASE =~ /^\s*$/ ) {
    die "Please set SYBASE in CONFIG, or set the \$SYBASE environment variable";
  }

  $SYBASE = VMS::Filespec::unixify($SYBASE) if $^O eq 'VMS';
  if ( $^O eq 'darwin' ) {
    my $osxdir = 'Applications/Sybase/System';
    $SYBASE = $osxdir if -d $SYBASE && -d $osxdir;
  }

  # System 12.0 has a different directory structure...
  if ( defined( $ENV{SYBASE_OCS} ) ) {

    # if $SYBASE_OCS is an absolute path, then use that
    if ( $ENV{SYBASE_OCS} =~ m!^/! ) {
      $SYBASE = $ENV{SYBASE_OCS};
    } else {
      $SYBASE .= "/$ENV{SYBASE_OCS}";
    }
  }

  my @libdir = ( "$SYBASE/lib", "$SYBASE/lib64", @libsdir);
  if ( $^O eq 'MSWin32' ) {
    @libdir = ("$SYBASE/dll");
  }

  foreach my $l (@libdir) {
    if ( -d $l ) {
      if ( checkLib($l) ) {
        $libdir = $l;
        last;
      }
    }
  }

  die "Can't find any Sybase libraries in "
    . join( ' or ', @libdir )
    unless defined $libdir;

  my $inc_found = 0;
  if ( -d "$SYBASE/include" && -f "$SYBASE/include/cspublic.h" ) {
    ++$inc_found;
    $inc_string = "-I$SYBASE/include";
  }

  # In some freetds installations the include files have been moved
  # into /usr/include/freetds.
  if ( -d "$SYBASE/include/freetds" && "$SYBASE/include/freetds/cspublic.h" ) {
    ++$inc_found;
    $inc_string = "-I$SYBASE/include/freetds";
  }
  die "Can't find the Client Library include files under $SYBASE"
    unless ($inc_found);

  my $version = getLibVersion($libdir);

  #    if(!$version || $version lt '12') {
  #print "FreeTDS or older Client Library. Enabling CS-Lib Callbacks\n";
  #$inc_string .= " -DUSE_CSLIB_CB=1";
  #    }

  checkChainedAutoCommit();

  #    print "OS = $^O\n";
  my %libname = loadSybLibs( $libdir,
      $^O eq 'MSWin32' ? qr/lib/
    : $^O eq 'VMS'     ? qr/olb/
    :                    qr/(?:so|a|sl)/ );

  my $libtype = '';

  if ( $^O eq 'MSWin32' ) {
    if ( $version ge '15' ) {

      # $libsub is "dll" on Windows...
      $lib_string =
"-L$libdir -llibsybct.lib -llibsybcs.lib -llibsybtcl.lib -llibsybcomn.lib -llibsybintl.lib -llibsybblk.lib $attr{EXTRA_LIBS} -lm";
    } else {
      $lib_string =
"-L$libdir -llibct.lib -llibcs.lib -llibtcl.lib -llibcomn.lib -llibintl.lib -llibblk.lib $attr{EXTRA_LIBS} -lm";
    }
  } elsif ( $^O eq 'VMS' ) {
    $lib_string =
"-L$SYBASE/lib -llibct.olb -llibcs.olb -llibtcl.olb -llibcomn.olb -llibintl.olb -llibblk.olb $attr{EXTRA_LIBS}";
  } elsif ( $^O =~ /cygwin/ ) {
#    $lib_string = "-L$SYBASE/lib -lct -lcs -lblk";
#    $inc_string .= " -D_MSC_VER=800";
    $inc_string .= " -D_MSC_VER=800";
    my $bits64 = "";
   	if ($Config{ptrsize} == 8) {
  		$bits64 = 64;
      $inc_string .= " -DSYB_LP64";
  	}
    if ($version ge '15') {
      $lib_string = "-L$SYBASE/lib -lsybct$bits64 -lsybcs$bits64 -lsybblk$bits64";
    } else {
      $lib_string = "-L$SYBASE/lib -lct$bits64 -lcs$bits64 -lblk$bits64";
    }
  } else {
    # Supplied by Erick Calder. I'm not sure why libsybsrv is needed...
    $attr{EXTRA_LIBS} .= " -lsybsrv" if $^O eq 'darwin';

    my $extra = getExtraLibs( $attr{EXTRA_LIBS}, $version );
    if ($file) {
      $lib_string =
"-L$libdir -lct -lcs -ltcl -lcomn -lintl -lblk $attr{EXTRA_LIBS} -ldl -lm";
    } else {
      $lib_string =
        "-L$libdir -lct -lcs -ltcl -lcomn -lintl -lblk $extra -ldl -lm";
    }
    if ($newlibnames) {
      foreach (qw(ct cs tcl comn intl blk)) {
        $lib_string =~ s/-l$_/-lsyb$_/;
      }
    } elsif ( $^O =~ /linux|freebsd/i ) {
      $lib_string =~ s/-ltcl/-lsybtcl/;
    }

    # Logic to replace normal libs with _r (re-entrant) libs if
    # usethreads is defined provided by W. Phillip Moore (wpm@ms.com)
    # I have no idea if this works on Win32 systems (probably not!)
    if ( $Config{usethreads} ) {
      print "Running in threaded mode - looking for _r libraries...\n";

      if ( checkForThreadedLibs() ) {
        my $found = 0;
        foreach ( split( /\s+/, $lib_string ) ) {
          next unless /^-l(\S+)/;
          my $oldname = $1;
          my $newname = $1 . "_r";
          next unless exists $libname{$newname};
          print "Found -l$newname for -l$oldname\n";
          ++$found;
          $lib_string =~ s/-l$oldname\b/-l$newname/;
        }
        if ( !$found ) {
          print "No thread-safe Sybase libraries found\n";
          $inc_string .= ' -DNO_THREADS ';
        } else {
          $libtype .= '_r';
        }
      } else {
        print "OK - I'll use the normal libs\n\n";
      }
    }

    # If we are building for a 64 bit platform that also supports 32 bit
    # (i.e. Solaris 8, HP-UX11, etc) then we need to make some adjustments
    if ( $Config{use64bitall} ) {

      # Tru64/DEC OSF does NOT use the SYB_LP64 define
      # as it is ALWAYS in 64 bit mode.
      $inc_string .= ' -DSYB_LP64' unless $^O eq 'dec_osf';

      print "Running in 64bit mode - looking for '64' libraries...\n";

      my $found = 0;
      foreach ( split( /\s+/, $lib_string ) ) {
        next unless /^-l(\S+)/;
        my $oldname = $1;
        my $newname = $1 . '64';
        next unless exists $libname{$newname};
        print "Found -l$newname for -l$oldname\n";
        $lib_string =~ s/-l$oldname\b/-l$newname/;
        ++$found;
      }
      if ($found) {
        $libtype .= '64';
      }
    }
  }

  # Is the blk library available?
  #my @k = keys(%libname);
  #print "@k\n";
  #print "libtype = $libtype\n";
  if ( my @l = grep( /(syb)?blk$libtype/, keys(%libname) ) ) {
    print "BLK api available - found: @l\n";
  } else {
    print "BLK api NOT available.\n";
    $inc_string .= ' -DNO_BLK=1';
  }

  my $config_sitearch  = $Config{sitearchexp};
  my $attr_dbi_include = $attr{DBI_INCLUDE};
  if ( $^O eq 'VMS' ) {
    $config_sitearch  = VMS::Filespec::unixify($config_sitearch);
    $attr_dbi_include = VMS::Filespec::unixify($attr_dbi_include);
  }
  my @try = ( @INC, $Config{sitearchexp} );
  unshift @try, $attr{DBI_INCLUDE} if $attr{DBI_INCLUDE};
  my $dbidir;
  for my $trydir (@try) {
    if ( -e "$trydir/auto/DBI/DBIXS.h" ) {
      $dbidir = "$trydir/auto/DBI";
      last;
    }
  }
  die "Can't find the DBI include files. Please set DBI_INCLUDE in CONFIG"
    if !$dbidir;
  $inc_string .= " -I$dbidir";
  if ( $attr{LINKTYPE} ) {
    $LINKTYPE = $attr{LINKTYPE};
  }
}

sub loadSybLibs {
  my ( $dir, $extensionRegexp ) = @_;

  my %libname = ();

  opendir( SYBLIB, $dir )
    or die "Unable to opendir $dir: $!\n";
  foreach ( readdir(SYBLIB) ) {
    next unless -f "$dir/$_";
    next unless /^lib(\S+)\.$extensionRegexp/;
    $libname{$1} = 1;
  }

  closedir(SYBLIB);

  return %libname;
}

sub getLibVersion {
  my $lib = shift;

  opendir( DIR, $lib );

  # reverse to pick up libsybct before libct...
  my @files = reverse( grep( /$libct_re/, readdir(DIR) ) );
  closedir(DIR);
  my $file;
  foreach (@files) {
    $file = "$lib/$_";
    last if -e $file;
  }

  open( IN, $file ) || die "Can't open $file: $!";
  binmode(IN);
  my $version;
  while (<IN>) {
    if (/S(?:AP|ybase) Client-Library\/([^\/]+)\//) {
      $version = $1;
      last;
    }
  }
  close(IN);

  if ( !$version ) {
    print "Unknown Client Library version - assuming FreeTDS.\n";
  } else {
    print "Sybase OpenClient $version found.\n";
  }

  return $version;
}

sub getExtraLibs {
  my $cfg     = shift;
  my $version = shift;

  opendir( DIR, "$libdir" ) || die "Can't access $libdir: $!";
  my %files =
    map { $_ =~ s/lib([^\.]+)\..*/$1/; $_ => 1 }
    grep( /lib/ && -f "$libdir/$_", readdir(DIR) );
  closedir(DIR);

  my %x     = map { $_ => 1 } split( ' ', $cfg );
  my $dlext = $Config{dlext} || 'so';
  foreach my $f ( keys(%x) ) {
    my $file = $f;
    $file =~ s/-l//;
    next if ( $file =~ /^-/ );
    delete( $x{$f} ) unless exists( $files{$file} );
  }

  foreach my $f (qw(insck tli sdna dnet_stub tds skrb gss)) {
    $x{"-l$f"} = 1 if exists $files{$f} && -f "$libdir/lib$f.$dlext";
  }
  if ( $version gt '11' ) {
    delete( $x{-linsck} );
    delete( $x{-ltli} );
  }

  #    if($version ge '12.5.1') {
  #	delete($x{-lskrb});
  #    }

  join( ' ', keys(%x) );
}

sub checkLib {
  my $dir = shift;

  opendir( DIR, "$dir" ) || die "Can't access $dir: $!";
  my @files = grep( /$libct_re/i, readdir(DIR) );
  closedir(DIR);
  if ( grep( /libsybct/, @files ) ) {
    $newlibnames = 1;
  } else {
    $newlibnames = 0;
  }

  scalar(@files);
}

sub configPwd {
  open( IN, "PWD.factory" ) || die "Can't open PWD.factory: $!";
  my %pwd;
  while (<IN>) {
    chomp;
    next if (/^\s*\#/);
    next if (/^\s*$/);
    my ( $key, $val ) = split( /=/, $_ );
    $pwd{$key} = $val || "undef";
  }
  close(IN);

  if ($use_env) {
    $pwd{SRV} = $ENV{DBD_SYB_SRV} || "SYBASE";
    $pwd{UID} = $ENV{DBD_SYB_UID} || "sa";
    $pwd{PWD} = $ENV{DBD_SYB_PWD};
    $pwd{DB}  = $ENV{DBD_SYB_DB};
  } elsif ($accept_test_defaults) {
    $pwd{SRV} = $pwd{SRV};
    $pwd{UID} = $pwd{UID};
    $pwd{PWD} = $pwd{PWD};
    $pwd{DB}  = $pwd{DB};
  } else {
    print
"The DBD::Sybase module need access to a Sybase server to run the tests.\n";
    print "To clear an entry please enter 'undef'\n";
    print "Sybase server to use (default: $pwd{SRV}): ";
    $pwd{SRV} = getAns(0) || $pwd{SRV};
    print "User ID to log in to Sybase (default: $pwd{UID}): ";
    $pwd{UID} = getAns(0) || $pwd{UID};
    print "Password (default: $pwd{PWD}): ";
    $pwd{PWD} = getAns(1) || $pwd{PWD};
    print "Sybase database to use on $pwd{SRV} (default: $pwd{DB}): ";
    $pwd{DB} = getAns(0) || $pwd{DB};
  }

  warn
"\n* Writing login information, including password, to file $written_pwd_file.\n\n";

  # Create the file non-readable by anyone else.
  my $old_umask;
  unless ( $^O =~ /MSWin32/ ) {
    $old_umask = umask(077);
    warn "cannot umask(): $!" unless defined($old_umask);
  }
  open( OUT, ">$written_pwd_file" ) || die "Can't open $written_pwd_file: $!";
  unless ( $^O =~ /MSWin32/ ) {
    umask($old_umask) != 077 && warn "strange return from umask()";
  }
  print OUT <<EOF;
# This file contains optional login id, passwd and server info for the test
# programs:
# You probably don't want to have it lying around after you've made
# sure that everything works OK.

EOF
  foreach ( keys %pwd ) {
    $pwd{$_} = '' if $pwd{$_} eq 'undef';
    print OUT "$_=$pwd{$_}\n";
  }
  close(OUT);
}

sub checkChainedAutoCommit {
  print <<EOF;

By default DBD::Sybase 1.05 and later use the 'CHAINED' mode (where available)
when 'AutoCommit' is turned off. Versions 1.04 and older instead managed
the transactions explicitly with a 'BEGIN TRAN' before the first DML
statement. Using the 'CHAINED' mode is preferable as it is the way that
Sybase implements AutoCommit handling for both its ODBC and JDBC drivers.

EOF
  print "Use 'CHAINED' mode by default (Y/N) [Y]: ";
  my $ans;
  if ( $use_env ) {
    $ans = $ENV{DBD_SYB_CHAINED} || 'Y';
  } elsif ( defined($chained) ) {
    $ans = $chained;
  } else {
    $ans = getAns(0);
  }
  if ( $ans and $ans !~ /^y/i ) {
    $inc_string .= " -DNO_CHAINED_TRAN=1";
  }
  print "\n";
}

sub checkForThreadedLibs {
  my $ret = 1;
  if ( $] >= 5.008 ) {
    $ret = 0;

    print <<EOF;

***NOTE***
There is an incompatibility between perl (5.8.x or later) built in threaded 
mode and Sybase's threaded libraries, which means that signals delivered to 
the perl process result in a segment violation.

I suggest building DBD::Sybase with the normal libraries in this case to get
reasonable behavior for signal handling.

EOF
    print "Use the threaded (lib..._r) libraries [N]: ";
    my $ans;

    if ($use_env) {
      $ans = $ENV{DBD_SYB_THREADED_LIBS} || 'N';
    } elsif ( defined($threaded_libs) ) {
      $ans = $threaded_libs;
    } else {
      $ans = getAns(0);
    }
    if ( $ans and $ans =~ /^y/i ) {
      $ret = 1;
    }
    print "\n";
  }

  return $ret;
}

sub getAns {
  my $flag = shift;

  if ( $flag && -t ) {
    eval {
      require Term::ReadKey;
      Term::ReadKey::ReadMode('noecho');
    };
  }
  my $ans = <STDIN>;
  if ( $flag && -t ) {
    eval { Term::ReadKey::ReadMode('normal'); };
    print "\n";    # because newline from user wasn't echo'd
  }
  $ans =~ s/^\s+//;
  $ans =~ s/\s+$//;

  return $ans;
}