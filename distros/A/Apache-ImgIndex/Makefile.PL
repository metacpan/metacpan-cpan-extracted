use ExtUtils::MakeMaker;

##
# Constants
##


my $NAME = 'Apache::ImgIndex';
my $VERSION_FROM = 'ImgIndex.pm';
my $COMPRESS = 'gzip';
my $SUFFIX = '.gz';
#my $DEFAULT_PREREQ_PM = {
#                         Apache2 => '.02',
#                        };

#my @NON_IPC_TESTS = ( 't/1_test.t',
#                      't/2_test.t',
#                      't/3_test.t',
#                      't/5_test.t',
#                      't/6_test.t' );

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
#  $options{PREREQ_PM} = $DEFAULT_PREREQ_PM;

  WriteMakefile( %options );

#  Print_Make_Test_Message( );
}


sub Has_Module
{
  my ( $module ) = @_;

  print "Checking for $module... ";

  my $has_module = ( eval "require $module"  && ! $@ );

  print ( $has_module ? "found\n" : "not found\n" );

  return $has_module;
}


