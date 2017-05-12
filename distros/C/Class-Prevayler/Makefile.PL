use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Class::Prevayler',
    VERSION_FROM => 'lib/Class/Prevayler.pm', # finds $VERSION
    AUTHOR       => 'Nathanael Obermayer (natom-pause@smi2le.net)',
    ABSTRACT     => 'Prevayler implementation - www.prevayler.org',
    PREREQ_PM	 => {
				'Class::MethodMaker' 	=> 0,
				'File::Sync'		=> 0,
				'File::Spec'		=> 0,
			}
);
