use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AIX::LVM',
    VERSION_FROM      => 'lib/AIX/LVM.pm', # finds $VERSION
    PREREQ_PM         => {'IPC::Open3' => '1.0', 'IO::Handle' => '1.0', 'IO::Select' => '1.0'}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/AIX/LVM.pm', # retrieve abstract from module
	AUTHOR         =>  'Murugesan Kandasamy <murugesan.kandasamy@gmail.com>'
);

