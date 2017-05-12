
use ExtUtils::MakeMaker;
use ExtUtils::Liblist;

use File::Basename;
use File::Spec::Functions qw/ catfile /;


# where the heck are things?  allow the user to lead us
# by the nose
my $libs = $ENV{CXCPARAM_LIBS};
my $incs = $ENV{CXCPARAM_INCS};
my $defs = $ENV{CXCPARAM_DEFS};

# default directories to search.  pay attention to env!
our $SEARCH_DIRS = $ENV{CXCPARAM_DIRS} || '/usr /usr/local';

# grab this as well
our $ld_library_path = $ENV{$^O eq 'darwin' ? 'DYLD_LIBRARY_PATH' :
			     'LD_LIBRARY_PATH' } || '';


# library info we determine from find_libs, if necessary
our $info;

# if that didn't work, we need to search for them.
if ( ! defined($libs) &&
     ($info = find_libs( 'cxcparam', 'cxcparam', 'parameter.h' )) )
{
  $libs = $info->{libs};
  $incs = $info->{incs};
  $defs = $info->{defs} if defined $info->{defs};
}

# bail if not found
die( "unable to find cxcparam library anywhere\n" )
  unless defined $libs;

# special treatment if we're pulling the library from CIAO
if ( $libs =~ /ciao/ )
{
  $libs .= ' -lvarmm';
  $defs .= ' -DCIAO';
}


# Platform specific magic
if ( 'solaris' eq $^O )
{
  # solaris ld ignores LD_RUN_PATH if there are -R options.  The Perl
  # config may have some in lddlflags and some might be lurking in the
  # libs we've gotten so far.  If so, if so, add -R's for all of the -L's
  require Config;
  Config->import();
  if ( $Config{lddlflags} =~ /-R/ || $libs =~ /-R/ )
  {
    $libs = join(' ', 
		 ( map { s/-L/-R/; $_ } grep { /^-L/ } split(' ', $libs ) ),
		 $libs);
  }
}

if ( 'linux' eq $^O )
{
  # on some linux platforms with readline 4.x, explicit linking against
  # ncurses is necessary. this is oh so hokey!
  $libs .= ' -lncurses'
    if -e '/usr/lib/libncurses.so';
}

my @Extras;

# this is a Red Hat (bless 'em) proprietary flag. they changed the default
# behavior of ExtUtils::MakeMaker, and now we have to revert it.  at least
# they provide a switch to do so.
push @Extras, (USE_MM_LD_RUN_PATH => 1 )
  if -f '/etc/redhat-release';


WriteMakefile
(
 NAME              => 'CIAO::Lib::Param',
 VERSION_FROM      => 'lib/CIAO/Lib/Param.pm', # finds $VERSION
 PREREQ_PM         => {},	# e.g., Module::Name => 1.1
 ($] >= 5.005 ?			## Add these new keywords supported since 5.005
  (ABSTRACT_FROM  => 'lib/CIAO/Lib/Param.pm', # retrieve abstract from module
   AUTHOR         => 'Diab Jerius <dj@cfa.harvard.edu>') : ()),
 LIBS              => [$libs],	# e.g., '-lm'
 DEFINE            => $defs || '', # e.g., '-DHAVE_SOMETHING'
 INC               => "-I. $incs", # e.g., '-I. -I/usr/include/other'
 clean		  => { FILES => "tmp" },
 @Extras
);




# check if we can find the library somewhere
sub find_libs
{
  my ( $pkg, $lib, $inc ) = @_;
  my ( $libs, $incs );

  find_libs_in_dirs( $pkg, $lib, $inc ) || find_lib_in_pkgconfig( $pkg );
}

sub find_libs_in_dirs
{
  my ( $pkg, $lib, $inc ) = @_;

  my @dirs;

  push @dirs, split( ':', $ld_library_path );
  push @dirs, split( /(:?:|,|\s+)/, $SEARCH_DIRS);

  my ( $libs, $incs );

  my $info;
  for my $dir ( @dirs )
  {
    last if
      $info = find_lib_in_dir( $pkg, $lib, $inc, $dir );
  }
  $info;
}


# try pkg-config
sub find_lib_in_pkgconfig
{
  my ( $pkg ) = @_;

  my $info;

  unless ( system("pkg-config $pkg 2>&1 > /dev/null") )
  {
    print "Found $pkg via pkg-config\n";
    $info = { 
	     libs => `pkg-config --libs $pkg`,
	     incs => `pkg-config --cflags $pkg`,
	     };
  }

  return $info;
}



sub find_lib_in_dir
{
  my ( $pkg, $lib, $inc, $libdir ) = @_;
  my $err;

  my $libl = defined $libdir ? "-L$libdir -l$lib" : "-l$lib";


  my %info;
  my $libs;
  my $incs;
  my $defs;
  my @libs;
  my %libs;

  {
    local $SIG{__WARN__} = sub { $err = shift } ;
    @libs = ExtUtils::Liblist->ext( $libl, 0, 1 );
    @libs{qw/ EXTRALIBS BSLOADLIBS LDLOADLIBS LD_RUN_PATH /} = @libs;
  }

  unless ( $err )
  {
    print ("Found $pkg library in $libdir\n" );

    # look for header file. keep ascending $libdir path
    # in case there's an extra level in the lib that isn't in the include
    # path

    for ( my $incroot = dirname($libdir);
	  $incroot ne '/';
	  $incroot = dirname($incroot)
	)
    {
      my $t_incdir = catfile( $incroot , 'include' );

      if ( -r "$t_incdir/$pkg/$inc" )
      {
	print ("Found $pkg headers in $t_incdir/$pkg\n" );
	$info{incs} = "-I$t_incdir";
	last;
      }

      elsif ( -r "$t_incdir/$inc" )
      {
	print ("Found $pkg headers in $t_incdir\n" );
	$info{incs} = "-I$t_incdir";
	$info{defs} = "-DFLAT_INCLUDES";
	last;
      }

    }

    if ( keys %info )
    {
      $info{libs} = $libl;
      $info{liblist} = \%libs;
    }
    else
    {
      print( "Strange! Unable to locate $pkg headers based on pkg-config dirs\n" );
      %info = ();
    }
  }

  return keys %info ? \%info : undef;
}
