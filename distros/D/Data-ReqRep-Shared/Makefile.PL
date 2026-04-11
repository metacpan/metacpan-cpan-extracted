use ExtUtils::MakeMaker;
use Config;

unless ($^O eq 'linux') {
    print "NA: Data::ReqRep::Shared requires Linux\n";
    exit 0;
}
if ($Config{ivsize} < 8) {
    print "NA: Data::ReqRep::Shared requires 64-bit integers (ivsize >= 8)\n";
    exit 0;
}

use Devel::PPPort;
Devel::PPPort::WriteFile();

WriteMakefile(
    NAME              => 'Data::ReqRep::Shared',
    VERSION_FROM      => 'lib/Data/ReqRep/Shared.pm',
    PREREQ_PM         => {},
    TEST_REQUIRES     => {
        'Test::More' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Devel::PPPort' => 0,
    },
    ABSTRACT_FROM     => 'lib/Data/ReqRep/Shared.pm',
    AUTHOR            => 'vividsnow',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.022',
    LIBS              => [''],
    DEFINE            => '-D_GNU_SOURCE',
    INC               => '-I.',
    XS                => { 'Shared.xs' => 'Shared.c' },
    OBJECT            => 'Shared$(OBJ_EXT)',
    TYPEMAPS          => ['typemap'],
    clean             => { FILES => "*.bs *.o ppport.h Shared.c" },
);
