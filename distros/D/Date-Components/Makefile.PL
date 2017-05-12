use 5.008008;
use ExtUtils::MakeMaker;

eval "use Test::Manifest";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Date::Components',
    VERSION_FROM      => 'lib/Date/Components.pm', # finds $VERSION
    PREREQ_PM         => {
                          warnings             => 1.05,
                          version              => 0.74,
                          Carp                 => 1.04,
                          Readonly             => 1.03,
                          Readonly::XS         => 1.04,
                          Test::More           => 0.74,
                          Test::Manifest       => 1.22,
                          Test::Pod            => 1.26,
                          Test::Pod::Coverage  => 1.08,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Date/Components.pm', # retrieve abstract from module
       AUTHOR         => 'David McAllister <perldave@gmail.com>') : ()),
);
