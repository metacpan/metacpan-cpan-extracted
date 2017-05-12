use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Model::Tarantool',
    VERSION_FROM      => 'lib/Catalyst/Model/Tarantool.pm', # finds $VERSION
    PREREQ_PM         => {
        'Catalyst::Runtime' => 0,
        'DR::Tarantool' => '0.37'
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Model/Tarantool.pm', # retrieve abstract from module
       AUTHOR         => 'Alexey Orlov <aorlov@cpan.org>'
        ) : ()),
);
