use ExtUtils::MakeMaker;
use Config;

unless ($^O eq 'linux') {
    print "NA: Data::PubSub::Shared requires Linux\n";
    exit 0;
}
if ($Config{ivsize} < 8) {
    print "NA: Data::PubSub::Shared requires 64-bit integers (ivsize >= 8)\n";
    exit 0;
}

use Devel::PPPort;
Devel::PPPort::WriteFile();

require XS::Parse::Keyword::Builder;
my @xpk_flags = XS::Parse::Keyword::Builder->extra_compiler_flags;

WriteMakefile(
    NAME              => 'Data::PubSub::Shared',
    VERSION_FROM      => 'lib/Data/PubSub/Shared.pm',
    TEST_REQUIRES     => {
        'Test::More' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Devel::PPPort' => 0,
        'XS::Parse::Keyword::Builder' => '0.40',
    },
    PREREQ_PM => {
        'XS::Parse::Keyword' => '0.40',
    },
    ABSTRACT_FROM     => 'lib/Data/PubSub/Shared.pm',
    AUTHOR            => 'vividsnow',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.022',
    LIBS              => [''],
    DEFINE            => '-D_GNU_SOURCE',
    INC               => '-I. ' . join(' ', @xpk_flags),
    XS                => { 'Shared.xs' => 'Shared.c' },
    OBJECT            => 'Shared$(OBJ_EXT)',
    clean             => { FILES => "*.bs *.o ppport.h Shared.c" },
);
