use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::Authentication::Simple',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Authentication/Simple.pm', # finds $VERSION
    PREREQ_PM         => { 
                            Catalyst => '2.99',
                            Catalyst::Plugin::Session::FastMmap => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Mark Ethan Trostler <mark@zzo.com>') : ()),
);
