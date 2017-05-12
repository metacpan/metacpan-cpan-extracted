use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Code::Generator::Perl',
    VERSION_FROM      => 'lib/Code/Generator/Perl.pm', # finds $VERSION
    PREREQ_PM         => {
	'Data::Dumper' => 2.121,
	'File::Spec'   => 3.29,
	'File::Path'   => 2.07,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Code/Generator/Perl.pm', # retrieve abstract from module
       AUTHOR         => 'nazri <nazri@>') : ()),
    clean             => { FILES => 't/tmp' },
);
