use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::RuledValidator',
    VERSION_FROM      => 'lib/Data/RuledValidator.pm', # finds $VERSION
    PREREQ_PM         => {
	                   'Email::Valid'        => 0.15,
			   'Email::Valid::Loose' => 0.04,
			   'File::Slurp'         => 0.01,
			   'UNIVERSAL::require'  => 0,
			   'Class::Inspector'    => 0,
			   'Test::Base'          => 0,
			   'List::MoreUtils'     => 0,
			   'Module::Pluggable'   => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
     (ABSTRACT_FROM  => 'lib/Data/RuledValidator.pm', # retrieve abstract from module
      AUTHOR         => 'Ktat <ktat@cpan.org>') : (),
     ),
);
