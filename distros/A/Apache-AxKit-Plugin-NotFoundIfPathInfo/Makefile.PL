use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::AxKit::Plugin::NotFoundIfPathInfo',
    VERSION_FROM      => 'lib/Apache/AxKit/Plugin/NotFoundIfPathInfo.pm', # finds $VERSION
    PREREQ_PM         => {'AxKit' => '1.60'}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Apache/AxKit/Plugin/NotFoundIfPathInfo.pm', # retrieve abstract from module
    AUTHOR            => 'Hansjoerg Pehofer <hansjoerg.pehofer@uibk.ac.at>',
);
