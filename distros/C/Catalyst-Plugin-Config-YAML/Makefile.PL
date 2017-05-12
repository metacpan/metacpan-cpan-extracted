use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::Config::YAML',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Config/YAML.pm', # finds $VERSION
    PREREQ_PM         => {
    	'Catalyst' => 0, 
    	'YAML' => 0, 
    	'Path::Class' => 0, 
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Plugin/Config/YAML.pm', # retrieve abstract from module
       AUTHOR         => 'Bernhard Bauer <bauerb@in.tum.de>') : ()),
);
