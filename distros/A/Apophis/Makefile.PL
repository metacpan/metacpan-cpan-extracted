use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

my $has_xsmulti = eval { ExtUtils::MakeMaker->VERSION('7.12'); 1 };

# Resolve Horus include directory:
#   1. Try installed Horus module (CPAN / system)
#   2. Fall back to sibling directory (development)
my $horus_inc;
eval {
    no warnings 'redefine';
    local *XSLoader::load = sub {};  # skip XS bootstrap
    require Horus;
    my $dir = Horus->include_dir();
    $horus_inc = $dir if $dir && -d $dir;
};
if (!$horus_inc && -d '../Horus/include') {
    $horus_inc = '../Horus/include';
}
die "Cannot find Horus include directory. Install Horus or place it as a sibling directory.\n"
    unless $horus_inc;

my %WriteMakefileArgs = (
    NAME             => 'Apophis',
    AUTHOR           => 'LNATION <email@lnation.org>',
    VERSION_FROM     => 'lib/Apophis.pm',
    ABSTRACT_FROM    => 'lib/Apophis.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'Horus'               => '0.04',
    },
    BUILD_REQUIRES => {
        'Devel::PPPort' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        'File::Temp' => '0',
    },
    PREREQ_PM => {
        'Horus' => '0.04',
    },

    # Horus UUID library headers (resolved above), plus our own include/ for
    # ap_abi.h and ap_abi_impl.h
    INC      => "-Iinclude -I$horus_inc",

    # MakeMaker does not scan XS #includes, so an edit to include/*.h would
    # otherwise rebuild nothing and the change would silently not happen.
    depend   => { 'lib/Apophis$(OBJ_EXT)' =>
                  'include/ap_abi.h include/ap_abi_impl.h' },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Apophis-* lib/*.o lib/*.c lib/*.bs Install' },
);

if ($has_xsmulti) {
    $WriteMakefileArgs{XSMULTI} = 1;
    $WriteMakefileArgs{XS}      = { 'lib/Apophis.xs' => 'lib/Apophis.c' };
    $WriteMakefileArgs{OBJECT}  = 'lib/Apophis$(OBJ_EXT)';
} else {
    $WriteMakefileArgs{XS}     = { 'lib/Apophis.xs' => 'lib/Apophis.c' };
    $WriteMakefileArgs{OBJECT} = 'lib/Apophis$(OBJ_EXT)';
}

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

# ---- Apophis as an ABI PROVIDER ------------------------------------------ *
# ap_abi.h publishes the content-addressing primitives so a consumer's XS can
# identify, shard and write a blob without a Perl frame. ExtUtils::Depends
# installs the header and records the include path; Apophis::_abi_ptr hands
# over the table's address at runtime.
my $pkg = ExtUtils::Depends->new('Apophis');
$pkg->install('include/ap_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep = $pkg->get_makefile_vars;

# EU::Depends returns an empty LIBS/LDFROM that would otherwise clobber
# MakeMaker's defaults; Apophis links nothing extra, so drop them.
delete $dep{LIBS};
delete $dep{LDFROM};
delete $dep{INC};              # ours is already correct, and more specific

# Its PM map REPLACES MakeMaker's auto-detected one, so lib/Apophis.pm has to
# be re-added by hand or it silently stops being installed.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

%WriteMakefileArgs = (%WriteMakefileArgs, %dep);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    return '' if $has_xsmulti;
    return <<'MAKE';
lib/Apophis$(OBJ_EXT): lib/Apophis.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $< -o $@
MAKE
}
