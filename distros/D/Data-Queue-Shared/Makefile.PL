use ExtUtils::MakeMaker;
use Config;

unless ($^O eq 'linux') {
    print "NA: Data::Queue::Shared requires Linux\n";
    exit 0;
}
if ($Config{ivsize} < 8) {
    print "NA: Data::Queue::Shared requires 64-bit integers (ivsize >= 8)\n";
    exit 0;
}

use Devel::PPPort;
Devel::PPPort::WriteFile();

my (@xpk_flags, $xpk_define);
eval {
    require XS::Parse::Keyword::Builder;
    @xpk_flags = XS::Parse::Keyword::Builder->extra_compiler_flags;
    $xpk_define = '-DHAVE_XS_PARSE_KEYWORD';
};
if ($@) {
    warn "XS::Parse::Keyword not found; keyword API will not be available\n";
    $xpk_define = '';
}

WriteMakefile(
    NAME              => 'Data::Queue::Shared',
    VERSION_FROM      => 'lib/Data/Queue/Shared.pm',
    PREREQ_PM         => {},
    TEST_REQUIRES     => {
        'Test::More' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Devel::PPPort' => 0,
    },
    ABSTRACT_FROM     => 'lib/Data/Queue/Shared.pm',
    AUTHOR            => 'vividsnow',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.022',
    LIBS              => [''],
    DEFINE            => "-D_GNU_SOURCE $xpk_define",
    INC               => '-I. ' . join(' ', @xpk_flags),
    XS                => { 'Shared.xs' => 'Shared.c' },
    OBJECT            => 'Shared$(OBJ_EXT)',
    TYPEMAPS          => ['typemap'],
    clean             => { FILES => "*.bs *.o ppport.h Shared.c" },
);
