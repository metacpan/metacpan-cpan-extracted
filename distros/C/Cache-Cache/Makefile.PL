use strict;
use ExtUtils::MakeMaker;

##
# Constants
##


my $NAME = 'Cache::Cache';
my $VERSION_FROM = 'lib/Cache/Cache.pm';
my $COMPRESS = 'gzip';
my $SUFFIX = '.gz';
my $DEFAULT_PREREQ_PM = {
                         'Digest::SHA1' => '2.02',
                         'File::Spec' => '0.82',
                         'Storable' => '1.014',
                         'IPC::ShareLite' => '0.09',
                         'Error' => '0.15'
                        };

my @NON_IPC_TESTS = ( 't/1_test_cache_interface.t',
                      't/2_test_memory_cache.t',
                      't/3_test_file_cache.t',
                      't/5_test_size_aware_file_cache.t',
                      't/6_test_size_aware_memory_cache.t' );

##
# Main
##


Main( );


##
# Subroutines
##


sub Main
{
  my %options;

  $options{NAME} = $NAME;
  $options{VERSION_FROM} = $VERSION_FROM;
  $options{dist} = { COMPRESS => $COMPRESS, SUFFIX => $SUFFIX };
  $options{PREREQ_PM} = $DEFAULT_PREREQ_PM;

  if ( not Has_Module( 'IPC::ShareLite' ) )
  {
    Print_ShareLite_Missing_Message( );
    $options{test} = { TESTS => join( ' ', @NON_IPC_TESTS ) };
    delete $options{PREREQ_PM}->{'IPC::ShareLite'};
  }

  WriteMakefile( %options );

  Print_Make_Test_Message( );
}


sub Has_Module
{
  my ( $module ) = @_;

  print "Checking for $module... ";

  my $has_module = ( eval "require $module"  && ! $@ );

  print ( $has_module ? "found\n" : "not found\n" );

  return $has_module;
}


sub Print_ShareLite_Missing_Message
{
  print <<END

  NOTE: Your system does not seem to have IPC::ShareLite installed.
  This module is a prerequisite for the SharedMemoryCache
  implementations.  However, since it is not available on all
  platforms, the Cache::Cache module does not list it as an explicit
  dependency.  If you are able to build IPC::ShareLite (available on
  CPAN), please install it now and re run this Makefile.PL.
  Automatically disabling the tests for the SharedMemoryCache.

END
}


sub Print_Make_Test_Message
{
  print <<END
------------------------------------------------------------------
Please be patient while running "make test" as the full test suite
takes roughly two minutes to complete.
------------------------------------------------------------------
END
}
