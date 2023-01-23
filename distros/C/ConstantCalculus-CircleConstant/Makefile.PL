use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ConstantCalculus::CircleConstant',
    VERSION_FROM      => 'lib/ConstantCalculus/CircleConstant.pm', # Finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'bignum' => '0.51'}, # e.g. 'Module::Name' => '1.1'
    ABSTRACT          => 'Perl extension for calculating the circle constant in high accurccy.', # Abstract of module
    AUTHOR            => 'Dr. Peter Netz <ztenretep@cpan.org>',
    LICENSE           => 'mit',
    #LICENSE           => 'perl',
    #ABSTRACT_FROM     => 'lib/ConstantCalculus/CircleConstant.pm', # Retrieve abstract from module
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
