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

# The 16-byte Int slot commits (value, sequence) with a lock-free 16-byte CAS
# where the target supports one. On x86-64 gcc/clang only emit cmpxchg16b
# inline with -mcx16; arm64 has it natively. Without it the Int variant falls
# back to serializing publish on the header mutex (still correct).
my $ccflags = $Config{ccflags};
if ($Config{archname} =~ /(?:x86_64|amd64)/i) {
    $ccflags .= ' -mcx16';
}
# Opt-in test-only XSUBs (e.g. _publish_at) for the deterministic concurrency
# regression tests. Off by default so they never ship in a normal build.
$ccflags .= ' -DPUBSUB_TEST_HOOKS' if $ENV{PUBSUB_TEST_HOOKS};
# Opt-in: force the Int header-mutex publish fallback (normally chosen only where
# a lock-free 16-byte CAS is unavailable) so tests can exercise it on any host.
$ccflags .= ' -DPUBSUB_INT_FORCE_MUTEX' if $ENV{PUBSUB_INT_FORCE_MUTEX};

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
    CCFLAGS           => $ccflags,
    DEFINE            => '-D_GNU_SOURCE',
    INC               => '-I. ' . join(' ', @xpk_flags),
    XS                => { 'Shared.xs' => 'Shared.c' },
    OBJECT            => 'Shared$(OBJ_EXT)',
    clean             => { FILES => "*.bs *.o ppport.h Shared.c" },
);
