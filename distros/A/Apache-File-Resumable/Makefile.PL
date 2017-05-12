use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::File::Resumable',
    'VERSION_FROM'	=> 'Resumable.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      Apache::Constants => 1
    }, # e.g., Module::Name => 1.1
);
