use ExtUtils::MakeMaker;
use ExtUtils::Liblist;
use File::Basename;
use File::Spec::Functions qw/ catfile /;

# place to stick WriteMakefile arguments.
our @WM_Extras;

# check if we can find the CIAO libstk library

my $ld_library_path = $ENV{$^O eq 'darwin' ? 'DYLD_LIBRARY_PATH' :
			                       'LD_LIBRARY_PATH' } || '';

my $lib = '-lstk';
my $incs;

foreach my $libdir ( '', split( ':', $ld_library_path ) )
{

  my $libl = "-L$libdir $lib";

  my $err;

  {
    local $SIG{__WARN__} = sub { $err = shift } ;
    my @libs = ExtUtils::Liblist->ext( $libl, 0, 0 );
  }

  unless ( $err )
  {
    print ("Found local CIAO stackio library in $libdir\n" );

    # look for header file
    my $incdir = catfile( dirname( $libdir ), 'include' );
    if ( -r "$incdir/dmstack.h" )
    {
      print ("Found local CIAO stackio headers in $incdir\n" );
      $incs = "-I$incdir";
      $define = "-DCIAO";
    }
    else
    {
      print( "Unable to locate local CIAO stackio headers in $incdir\n" );
      next;
    }
    push @WM_Extras, ( NORECURS	      => 1 );
    $libs = $libl;
    last;
  }

};

unless ( defined $libs )
{
  warn ( "WARNING: Couldn't find libstk in environment; using included library\n" );
  push @WM_Extras, ( MYEXTLIB	      => 'stklib/libstk$(LIB_EXT)' );
}


WriteMakefile(
	      NAME              => 'CIAO::Lib::StackIO',
	      VERSION_FROM      => 'lib/CIAO/Lib/StackIO.pm', # finds $VERSION
	      PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?	## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM  => 'lib/CIAO/Lib/StackIO.pm', # retrieve abstract from module
		AUTHOR         => 'Diab Jerius <djerius@cpan.org>') : ()),
	      XSPROTOARG	      => '-noprototypes',
	      DEFINE            => "$define", # e.g., '-DHAVE_SOMETHING'
	      LIBS		=> [ $libs ],
	      INC               => "-I. $incs", # e.g., '-I. -I/usr/include/other',
	      OBJECT            => 'StackIO.o', # link all the C files too,
	      @WM_Extras,
	     );

sub MY::postamble {
'$(MYEXTLIB): stklib/Makefile
	cd stklib && $(MAKE) all
';
}
