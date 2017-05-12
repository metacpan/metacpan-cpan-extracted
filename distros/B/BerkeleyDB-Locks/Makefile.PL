use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $apidir = '/usr/local' ;
my @versions = qw( 
		BerkeleyDB.4.2 -DV42
		BerkeleyDB.4.1 -DV41
		BerkeleyDB.4.0 -DPREV41
		BerkeleyDB.3.2 -DPREV41
		) ;
my %versions = @versions ;
my @version = grep exists $versions{$_}, @versions ;

my $usage = <<'eof' ;

  usage: perl Makefile.PL path-to-db_config.h

  BerkeleyDB::Locks uses application functions that are not part of
  Berkeley's published API.  In order to install this module, you must
  download the BerkeleyDB::Locks source code.  For more information,
  type:

    perl Makefile.PL --help

eof

my $noberkeleydb = <<'eof' ;

  Couldn't find installed BerkeleyDB.  Standard Unix implementation
  installs BerkeleyDB in /usr/local.  Modify the variable $apidir
  for a different implentation.

eof

my $help = <<'eof' ;

  BerkeleyDB::Locks has only been tested on Unix (Linux, SunOS) systems. 
  Let me know about porting to other systems.

  In order to proceed, you'll need the complete BerkeleyDB source code
  distribution.  This distribution is found at:

    http://www.sleepycat.com/update/snapshot/db-4.2.52.NC.tar.gz
    or http://www.sleepycat.com/download/db/index.shtml

  Then perform the following steps:

    tar -zxf db-4.2.52.NC.tar.gz
    cd db-4.2.52.NC/build_unix
    ../dist/configure
    echo `pwd`/db_config.h

  Whatever the last command prints out should be the argument passed
  to Makefile.PL.

eof

exit print $usage unless $ARGV[0] ;
exit print $help if $ARGV[0] eq '--help' ;
exit print $usage unless -f $ARGV[0] ;

my @path = split m|/|, $ARGV[0] ;

exit print $usage unless $path[-1] eq 'db_config.h' ;
pop @path ;
pop @path ;

my @found = grep -d "$apidir/$_", @version ;
exit print $noberkeleydb unless @found ;

print "building BerkeleyDB::Locks for $found[0]\n\n" ;
# start here

my $lib = join '/', $apidir, $found[0], 'lib' ;
my $build = join '/', @path ;
my $sys = 'build_unix' ;
my $ver = $versions{ $found[0] } ;

my @OLDINC = ( 
		"-I$build/dist",
		"-I$build/include",
		"-I$build/include_auto",
		) ;
@OLDINC = () unless $ver eq '-DV41' || $ver eq '-DPREV41' ;

WriteMakefile(
    'NAME'		=> 'BerkeleyDB::Locks',
    'VERSION_FROM'	=> 'Locks.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Locks.pm', # retrieve abstract from module
       AUTHOR     => 'Jim Schueler <jschueler@tqis.com>') : ()),
    'LIBS'		=> ["-L$lib -ldb"], # e.g., '-lm'
    'DEFINE'		=> $ver, # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> join ( ' ',
				"-I$build",
				"-I$build/$sys",
				@OLDINC ),
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
