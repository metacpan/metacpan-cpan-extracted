use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'CPAN::Cpanorg::Auxiliary',
    VERSION_FROM => 'lib/CPAN/Cpanorg/Auxiliary.pm',
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT_FROM   =>  'lib/CPAN/Cpanorg/Auxiliary.pm',
    PREREQ_PM    => {
        'Test::Simple'  => 0.44,
        Carp            => 0,
        Cwd             => 0,
        'File::Copy::Recursive::Reduced'    => 0,
        'File::Spec'    => 0,
        'File::Path'    => 2.15,
        'File::Slurp'   => 9999.19,
        'File::Temp'    => 0,
        'JSON'          => 0,
        'LWP::Simple'   => 0,
        'Path::Tiny'    => 0.011,
    },
);

