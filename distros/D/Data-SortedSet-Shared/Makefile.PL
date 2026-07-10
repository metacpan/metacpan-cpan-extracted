use ExtUtils::MakeMaker;
use Config;
unless ($^O eq 'linux') { print "NA: requires Linux\n"; exit 0 }
if ($Config{ivsize} < 8) { print "NA: requires 64-bit\n"; exit 0 }
use Devel::PPPort; Devel::PPPort::WriteFile();
WriteMakefile(
    NAME               => 'Data::SortedSet::Shared',
    VERSION_FROM       => 'lib/Data/SortedSet/Shared.pm',
    PREREQ_PM          => { 'Data::Intern::Shared' => '0.02' },   # for new_strings / Data::SortedSet::Shared::Strings
    TEST_REQUIRES      => { 'Test::More' => 0 },
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, 'Devel::PPPort' => 0 },
    ABSTRACT_FROM      => 'lib/Data/SortedSet/Shared.pm',
    AUTHOR             => 'vividsnow',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => '5.022',
    LIBS               => [''],
    DEFINE             => '-D_GNU_SOURCE',
    INC                => '-I.',
    XS                 => { 'Shared.xs' => 'Shared.c' },
    OBJECT             => 'Shared$(OBJ_EXT)',
    depend             => { 'Shared$(OBJ_EXT)' => 'sortedset.h' },
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            repository => { type => 'git',
                url => 'https://github.com/vividsnow/perl5-data-sortedset-shared.git',
                web => 'https://github.com/vividsnow/perl5-data-sortedset-shared' },
            bugtracker => { web => 'https://github.com/vividsnow/perl5-data-sortedset-shared/issues' },
        },
    },
    clean              => { FILES => "*.bs *.o ppport.h Shared.c" },
);
