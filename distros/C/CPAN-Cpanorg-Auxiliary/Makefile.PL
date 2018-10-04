use strict;
use warnings;
if ($^O =~ m/mswin32/i) {
    print STDERR "The application which will use this functionality does not run on Windows\n";
    exit 0;
}
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $mm_ver = ExtUtils::MakeMaker->VERSION;

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
        'File::Temp'    => 0,
        'JSON'          => 0,
        'LWP::Simple'   => 0,
        'Path::Tiny'    => 0.011,
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/CPAN-Cpanorg-Auxiliary/',
            repository => {
                url => 'https://github.com/jkeenan/CPAN-Cpanorg-Auxiliary.git',
                web => 'https://github.com/jkeenan/CPAN-Cpanorg-Auxiliary',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Cpanorg-Auxiliary',
            },
        },
    })),
);

