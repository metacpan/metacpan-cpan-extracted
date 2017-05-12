use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
  'NAME'	=> 'Data::Filter',
  'VERSION_FROM' => 'lib/Data/Filter.pm', # finds $VERSION
  'PREREQ_PM' => {
    'Test::More'      => 0,
    'File::Basename'  => 0,
  },
);
