use ExtUtils::MakeMaker;
use Config;

unless ($^O eq 'linux') {
    print "NA: Data::HashMap::Shared requires Linux\n";
    exit 0;
}
if ($Config{ivsize} < 8 || $Config{ptrsize} < 8) {
    print "NA: Data::HashMap::Shared requires a 64-bit perl (ivsize and ptrsize >= 8)\n";
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

# Compilers older than GCC 5 default to gnu89, where the C99 declarations in
# the templates are errors.  Only add -std when the default rejects them, so a
# toolchain that already accepts them keeps whatever perl was built with.
my $ccflags = $Config{ccflags};
{
    # The probe mirrors what the templates actually need: a C99 declaration in
    # a for-init, and the static assert exactly as SHM_STATIC_ASSERT writes it.
    # Before GCC 5 __atomic_always_lock_free is not a constant expression, so
    # -std=gnu11 turns one failure into another there; probing the real
    # constructs picks gnu99 on those compilers and gnu11 on newer ones.
    my $probe = "shm_std_probe_$$";
    open my $fh, '>', "$probe.c" or last;
    print $fh <<'PROBE';
#include <stdint.h>
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(__atomic_always_lock_free(sizeof(uint8_t), 0), "byte atomics");
#endif
int main(void){ for (int i = 0; i < 1; i++) {} return 0; }
PROBE
    close $fh;
    my ($cc_override) = map { /^CC=(.*)/ ? $1 : () } @ARGV;   # honour a smoker's CC=
    my $cc = ($cc_override || $Config{cc}) . " $ccflags";
    unless (system("$cc -c -o $probe.o $probe.c >/dev/null 2>&1") == 0) {
        for my $std (qw(gnu11 gnu99)) {
            next unless system("$cc -std=$std -c -o $probe.o $probe.c >/dev/null 2>&1") == 0;
            $ccflags .= " -std=$std";
            print "Compiler defaults to C89; adding -std=$std\n";
            last;
        }
    }
    unlink "$probe.c", "$probe.o";
}

my $define = '-D_GNU_SOURCE';
{
    my $probe = "shm_futex_probe_$$";
    if (open my $fh, '>', "$probe.c") {
        print $fh "#include <linux/futex.h>\nint main(void){return FUTEX_WAIT+FUTEX_WAKE;}\n";
        close $fh;
        my ($cc_override) = map { /^CC=(.*)/ ? $1 : () } @ARGV;
        my $cc = ($cc_override || $Config{cc}) . " $ccflags";
        $define .= ' -DSHM_HAVE_LINUX_FUTEX_H'
            if system("$cc -c -o $probe.o $probe.c >/dev/null 2>&1") == 0;
        unlink "$probe.c", "$probe.o";
    }
}

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
    # pthread_once is not in libc before glibc 2.34; the empty fallback keeps
    # working where it is (and where libpthread does not exist separately).
    LIBS              => ['-lpthread', ''],
    CCFLAGS           => $ccflags,
    DEFINE            => $define,
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
