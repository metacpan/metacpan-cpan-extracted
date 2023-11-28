use 5.010;
use ExtUtils::MakeMaker 6.56;
# Require a version of EU:MM sufficient to have 'BUILD_REQUIRES'
# so that we get the modern File::Path::make_path() in our tests.

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME         => 'CPAN::Mini::Visit::Simple',
    VERSION_FROM => 'lib/CPAN/Mini/Visit/Simple.pm',
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Lightweight traversal of a minicpan repository',
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM    => {
                     'Archive::Extract' => 0.80,
                     'Archive::Zip' => 0,
                     'CPAN::Mini'   => 0,
                     'File::Find'   => 0,
                     'File::Path'   => 2.06,
                     'File::Spec'   => 0,
                     'File::Temp'   => 0.14,
                     'Path::Class'  => 0.15,
                     'Scalar::Util' => 0,
                    },
   ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
                     'Capture::Tiny' => 0,
                     'Test::Simple' => 0.44,
                    },
    LICENSE      => "perl",

    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/CPAN-Mini-Visit-Simple/',
            repository => {
                url => 'https://github.com/jkeenan/cpan-mini-visit-simple.git',
                web => 'https://github.com/jkeenan/cpan-mini-visit-simple',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Mini-Visit-Simple',
            },
        },
    })),
);
