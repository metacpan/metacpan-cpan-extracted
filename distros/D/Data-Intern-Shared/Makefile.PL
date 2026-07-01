use ExtUtils::MakeMaker;
use Config;
unless ($^O eq 'linux') { print "NA: requires Linux\n"; exit 0 }
if ($Config{ivsize} < 8) { print "NA: requires 64-bit\n"; exit 0 }
use Devel::PPPort; Devel::PPPort::WriteFile();
WriteMakefile(
    NAME               => 'Data::Intern::Shared',
    VERSION_FROM       => 'lib/Data/Intern/Shared.pm',
    PREREQ_PM          => {},
    TEST_REQUIRES      => { 'Test::More' => 0 },
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, 'Devel::PPPort' => 0 },
    ABSTRACT_FROM      => 'lib/Data/Intern/Shared.pm',
    AUTHOR             => 'vividsnow',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => '5.022',
    LIBS               => [''],
    DEFINE             => '-D_GNU_SOURCE',
    INC                => '-I.',
    XS                 => { 'Shared.xs' => 'Shared.c' },
    OBJECT             => 'Shared$(OBJ_EXT)',
    depend             => { 'Shared$(OBJ_EXT)' => 'intern.h xxhash.h' },
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            repository => { type => 'git',
                url => 'https://github.com/vividsnow/perl5-data-intern-shared.git',
                web => 'https://github.com/vividsnow/perl5-data-intern-shared' },
            bugtracker => { web => 'https://github.com/vividsnow/perl5-data-intern-shared/issues' },
        },
    },
    clean              => { FILES => "*.bs *.o ppport.h Shared.c" },
);
