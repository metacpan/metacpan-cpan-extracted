use ExtUtils::MakeMaker;
use Config;

unless ($^O eq 'linux') {
    print "OS unsupported: Data::ReqRep::Shared requires Linux\n";
    exit 0;
}
if ($Config{ivsize} < 8) {
    print "OS unsupported: Data::ReqRep::Shared requires 64-bit integers (ivsize >= 8)\n";
    exit 0;
}
sub env_on {
    my $v = $ENV{$_[0]};
    return 0 unless defined $v && $v =~ /\S/;
    $v =~ s/^\s+|\s+$//g;
    return 0 if $v =~ /^(?:false|no|off)$/i;
    return 1 unless $v =~ /^[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?$/;
    return $v != 0;
}
unless (env_on('DATA_REQREP_SHARED_UNSAFE_PIDNS')
        || (stat '/proc/self/ns/pid' && -r '/proc/sys/kernel/random/boot_id')) {
    print "OS unsupported: Data::ReqRep::Shared requires /proc (/proc/self/ns/pid, boot_id)\n";
    exit 0;
}

my ($cc) = map { /^CC=(.*)/ ? $1 : () } @ARGV;   # honour a smoker's CC=
$cc ||= $Config{cc};
my $ccflags = $Config{ccflags};
sub compiles {
    my ($code, $flags) = @_;
    my $probe = "reqrep_probe_$$";
    open my $fh, '>', "$probe.c" or return 0;
    print $fh $code;
    close $fh;
    my $ok = system("$cc $flags -D_GNU_SOURCE -o $probe $probe.c >/dev/null 2>&1") == 0;
    unlink "$probe.c", $probe;
    return $ok;
}

compiles("int main(void) { return 0; }\n", $ccflags)
    or die "Cannot build a trivial C program with $cc\n";

# Compilers older than GCC 5 default to gnu89, where the C99 declarations are errors.
my $c99 = "int main(void) { for (int i = 0; i < 1; i++) {} return 0; }\n";
if (!compiles($c99, $ccflags) && compiles($c99, "$ccflags -std=gnu99")) {
    $ccflags .= ' -std=gnu99';
    print "Compiler defaults to C89; adding -std=gnu99\n";
}
unless (compiles(<<'C', $ccflags)) {
#include <sys/mman.h>
#include <fcntl.h>
#include <linux/futex.h>
int main(void) {
    int fd = memfd_create("probe", MFD_CLOEXEC | MFD_ALLOW_SEALING);
    return fcntl(fd, F_ADD_SEALS, F_SEAL_SHRINK | F_SEAL_GROW) + FUTEX_WAKE;
}
C
    print "OS unsupported: Data::ReqRep::Shared requires memfd_create, file sealing and the Linux headers\n";
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
    LIBS              => ['-lpthread'],
    CCFLAGS           => $ccflags,
    DEFINE            => '-D_GNU_SOURCE',
    INC               => '-I.',
    XS                => { 'Shared.xs' => 'Shared.c' },
    OBJECT            => 'Shared$(OBJ_EXT)',
    TYPEMAPS          => ['typemap'],
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => { type => 'git',
                url => 'https://github.com/vividsnow/perl5-data-reqrep-shared.git',
                web => 'https://github.com/vividsnow/perl5-data-reqrep-shared' },
            bugtracker => { web => 'https://github.com/vividsnow/perl5-data-reqrep-shared/issues' },
        },
    },
    clean             => { FILES => "*.bs *.o ppport.h Shared.c" },
);
