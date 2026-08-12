use ExtUtils::MakeMaker;
use Config;

unless ($^O eq 'linux') {
    print "NA: Data::Buffer::Shared requires Linux\n";
    exit 0;
}
if ($Config{ivsize} < 8) {
    print "NA: Data::Buffer::Shared requires 64-bit integers (ivsize >= 8)\n";
    exit 0;
}

use Devel::PPPort;
Devel::PPPort::WriteFile();

my @xpk_flags;
eval {
    require XS::Parse::Keyword::Builder;
    @xpk_flags = XS::Parse::Keyword::Builder->extra_compiler_flags;
};
warn "XS::Parse::Keyword::Builder not found; build will likely fail\n" if $@;

WriteMakefile(
    NAME              => 'Data::Buffer::Shared',
    VERSION_FROM      => 'lib/Data/Buffer/Shared.pm',
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
    ABSTRACT_FROM     => 'lib/Data/Buffer/Shared.pm',
    AUTHOR            => 'vividsnow',
    LICENSE           => 'perl_5',
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            repository => { type => 'git',
                url => 'https://github.com/vividsnow/perl5-data-buffer-shared.git',
                web => 'https://github.com/vividsnow/perl5-data-buffer-shared' },
            bugtracker => { web => 'https://github.com/vividsnow/perl5-data-buffer-shared/issues' },
        },
    },
    MIN_PERL_VERSION  => '5.022',
    LIBS              => [''],
    DEFINE            => '-D_GNU_SOURCE',
    INC               => '-I. ' . join(' ', @xpk_flags),
    XS                => { 'Shared.xs' => 'Shared.c' },
    OBJECT            => 'Shared$(OBJ_EXT)',
    clean            => { FILES => "*.bs *.o ppport.h Shared.c" },
    # Shared.xs pulls the per-variant XSUBs in with INCLUDE:, which xsubpp
    # resolves but make does not see. Without this, editing xs/*.xs or a
    # buf_*.h leaves Shared.c stale and the rebuild silently keeps the old
    # code.
    depend            => {
        'Shared.c' => join ' ', sort( glob('xs/*.xs'), glob('buf_*.h') ),
    },
);
