use ExtUtils::MakeMaker;
use Config;
unless ($^O eq 'linux') { print "NA: requires Linux\n"; exit 0 }
if ($Config{ivsize} < 8) { print "NA: requires 64-bit\n"; exit 0 }
use Devel::PPPort; Devel::PPPort::WriteFile();

# Optional build-time dependency on PDL: if PDL::Core::Dev is available we compile
# the zero-copy as_pdl_alias against PDL's C API (a real PDL_DONTTOUCHDATA external-
# data ndarray, so in-place PDL ops write straight through to the shared mmap).
# Without PDL the module still builds; as_pdl_alias then croaks, and the copy
# methods (to_pdl/from_pdl/...) keep working via a runtime `require PDL`.
my ($DEFINE, $INC) = ('-D_GNU_SOURCE', '-I.');
if (eval { require PDL::Core::Dev; 1 }) {
    $DEFINE .= ' -DHAVE_PDL';
    $INC    .= ' ' . PDL::Core::Dev::PDL_INCLUDE();   # for <pdlcore.h>
    print "PDL found: building the zero-copy as_pdl_alias C path\n";
} else {
    print "PDL not found: as_pdl_alias will be unavailable (copy methods still work via runtime PDL)\n";
}

WriteMakefile(
    NAME               => 'Data::NDArray::Shared',
    VERSION_FROM       => 'lib/Data/NDArray/Shared.pm',
    PREREQ_PM          => {},
    TEST_REQUIRES      => { 'Test::More' => 0 },
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, 'Devel::PPPort' => 0 },
    ABSTRACT_FROM      => 'lib/Data/NDArray/Shared.pm',
    AUTHOR             => 'vividsnow',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => '5.022',
    LIBS               => [''],
    DEFINE             => $DEFINE,
    INC                => $INC,
    XS                 => { 'Shared.xs' => 'Shared.c' },
    OBJECT             => 'Shared$(OBJ_EXT)',
    depend             => { 'Shared$(OBJ_EXT)' => 'ndarray.h' },
    META_MERGE         => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        prereqs => {
            runtime => { recommends => { 'PDL' => 0 } },   # optional: enables to_pdl/from_pdl/as_pdl_alias
        },
        resources => {
            repository => { type => 'git',
                url => 'https://github.com/vividsnow/perl5-data-ndarray-shared.git',
                web => 'https://github.com/vividsnow/perl5-data-ndarray-shared' },
            bugtracker => { web => 'https://github.com/vividsnow/perl5-data-ndarray-shared/issues' },
        },
    },
    clean              => { FILES => "*.bs *.o ppport.h Shared.c" },
);
