use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
                    NAME          => 'Algorithm::Evolve',
                    VERSION_FROM  => 'lib/Algorithm/Evolve.pm',
                    PREREQ_PM     => { List::Util => 0.1 },
    ($] >= 5.005 ? (ABSTRACT_FROM => 'lib/Algorithm/Evolve.pm',
                    AUTHOR        => 'Mike Rosulek <mike@mikero.com>')
                 : ()),
);
