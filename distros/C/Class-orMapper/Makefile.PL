use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::orMapper',
    VERSION_FROM      => 'lib/Class/orMapper.pm', # finds $VERSION
    PREREQ_PM         => {
	'DBI' => '1.627',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/orMapper.pm', # retrieve abstract from module
       AUTHOR         => 'Kazunori Minoda <kazunori@cpan.org>') : ()),
);
