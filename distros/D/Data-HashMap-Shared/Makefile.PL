use ExtUtils::MakeMaker;
use Config;

unless ($^O eq 'linux') {
    print "NA: Data::HashMap::Shared requires Linux\n";
    exit 0;
}
if ($Config{ivsize} < 8) {
    print "NA: Data::HashMap::Shared requires 64-bit integers (ivsize >= 8)\n";
    exit 0;
}
if ($Config{byteorder} !~ /^1234/) {
    print "NA: Data::HashMap::Shared requires a little-endian architecture\n";
    exit 0;
}

require Devel::PPPort;   # not use: it would load before the NA checks above
Devel::PPPort::WriteFile();

my @xpk_flags;
eval {
    require XS::Parse::Keyword::Builder;
    @xpk_flags = XS::Parse::Keyword::Builder->extra_compiler_flags;
};
warn "XS::Parse::Keyword::Builder not found; build will likely fail\n" if $@;

my %provides;
for my $file ('lib/Data/HashMap/Shared.pm', sort glob 'lib/Data/HashMap/Shared/*.pm') {
    (my $module = $file) =~ s{^lib/|\.pm$}{}g;
    $module =~ s{/}{::}g;
    $provides{$module} = { file => $file, version => MM->parse_version($file) };
}

WriteMakefile(
    NAME              => 'Data::HashMap::Shared',
    VERSION_FROM      => 'lib/Data/HashMap/Shared.pm',
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
    ABSTRACT_FROM     => 'lib/Data/HashMap/Shared.pm',
    AUTHOR            => 'vividsnow',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.022',
    LIBS              => [''],
    DEFINE            => '-D_GNU_SOURCE',
    INC               => '-I. ' . join(' ', @xpk_flags),
    XS                => { 'Shared.xs' => 'Shared.c' },
    OBJECT            => 'Shared$(OBJ_EXT)',
    TYPEMAPS         => ['typemap'],
    # Track the INCLUDE:d xs/*.xs and the #included C templates, or `make`
    # silently reuses a stale Shared.c after editing one.
    depend            => {
        'Shared.c'         => join(' ', sort glob 'xs/*.xs'),
        'Shared$(OBJ_EXT)' => join(' ', 'xxhash.h', sort glob 'shm_*.h'),
    },
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        provides    => \%provides,
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-data-hashmap-shared.git',
                web  => 'https://github.com/vividsnow/perl5-data-hashmap-shared',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-data-hashmap-shared/issues',
            },
        },
    },
    clean            => { FILES => "*.bs *.o ppport.h Shared.c" },
);
