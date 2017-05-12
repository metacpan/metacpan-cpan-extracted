use 5.008008;
use ExtUtils::MakeMaker;

my @dirs = qw(
/usr/
/usr/local
/usr/local/tcc
);

my $tcc_dir;
my $tcc_cflags;
my $tcc_ldflags;
foreach (@dirs) {
    if (-f $_ . "/include/libtcc.h") {
        $tcc_dir = $_;
        last;
    }
}

if (!defined($tcc_dir)) {
    die "Cannot find tcc directory - see Makefile.PL";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'C::TCC',
    VERSION_FROM      => 'lib/C/TCC.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/C/TCC.pm', # retrieve abstract from module
       AUTHOR         => 'Tsukasa Hamano <hamano@cpan.org>') : ()),
    LIBS              => ["-L$tcc_dir/lib -ltcc"],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. -I$tcc_dir/include",
    LICENSE           => 'LGPL',
    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
