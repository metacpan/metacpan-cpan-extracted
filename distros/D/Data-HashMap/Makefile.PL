use ExtUtils::MakeMaker;
use Config;

die "Data::HashMap requires 64-bit integers (ivsize >= 8), got ivsize=$Config{ivsize}\n"
    if $Config{ivsize} < 8;

# Generate ppport.h
use Devel::PPPort;
Devel::PPPort::WriteFile();

# Get XS::Parse::Keyword compiler flags
my @xpk_flags;
eval {
    require XS::Parse::Keyword::Builder;
    @xpk_flags = XS::Parse::Keyword::Builder->extra_compiler_flags;
};
warn "XS::Parse::Keyword::Builder not found; build will likely fail\n" if $@;

WriteMakefile(
    NAME              => 'Data::HashMap',
    VERSION_FROM      => 'lib/Data/HashMap.pm',
    PREREQ_PM         => {
        'XS::Parse::Keyword' => '0.40',
    },
    TEST_REQUIRES     => {
        'Test::More' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Devel::PPPort' => 0,
        'XS::Parse::Keyword::Builder' => '0.40',
    },
    ABSTRACT_FROM     => 'lib/Data/HashMap.pm',
    AUTHOR            => 'vividsnow',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.022',
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I. ' . join(' ', @xpk_flags),
    XS                => { 'HashMap.xs' => 'HashMap.c' },
    OBJECT            => 'HashMap$(OBJ_EXT)',
    TYPEMAPS         => ['typemap'],
    clean            => { FILES => "*.bs *.o ppport.h HashMap.c" }
);
