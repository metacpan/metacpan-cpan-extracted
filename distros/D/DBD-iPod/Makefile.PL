use lib 'lib';
use File::Spec::Functions;
use Package::Install;
my %sources = (); #put source.PL => 'description' pairs in here
my %mm_args = (
                  'NAME'      => 'DBD-iPod',
                  'VERSION'   => '0.01',
                  'PREREQ_PM' => {
                                   'DBI'               => 0.00,
                                   'Mac::iPod::GNUpod' => 1.00,
                                   'Package::Base'     => 0.01,
                                   'SQL::Statement'    => 1.09,
                                 },
                  'ABSTRACT'  => 'Connect to an iPod via DBI',
                  'AUTHOR'    => 'Allen Day <allenday@ucla.edu>',
               );

my $install = Package::Install->new(
  interactive => 1,
  sources     => %sources,
                                    );

$ENV{IPOD_ROOT} ||= '/mnt/ipod';
if(! -d catfile($ENV{IPOD_ROOT},'iPod_Control')){
  print "iPod not detected at $ENV{IPOD_ROOT}.  Please\n".
  "mount at /mnt/ipod, or set \$IPOD_ROOT to your mount\n".
  "location.  If you don't do this, all unit tests will be\n".
  "skipped.  Press <enter> to continue...\n\n";
  <>;
} else {
  print "iPod detected at $ENV{IPOD_ROOT}...\n";
}

$install->write_makefile(%mm_args);
