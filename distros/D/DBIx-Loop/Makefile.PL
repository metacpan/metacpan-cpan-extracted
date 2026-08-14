use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# DBIx::Loop publishes a runtime C ABI (include/dbil_abi.h) that consumers
# resolve through DBIx::Loop::_abi_ptr. ExtUtils::Depends installs the interface
# header and records the include path, so a consumer only has to name us in its
# own ExtUtils::Depends->new to get the -I. Only dbil_abi.h is installed; the
# implementation headers stay private to this build.
my $pkg = ExtUtils::Depends->new('DBIx::Loop');
$pkg->set_inc('-I. -Iinclude');
$pkg->install('include/dbil_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %DEP = $pkg->get_makefile_vars;
# get_makefile_vars hands back an empty LIBS/LDFROM that would clobber the real
# ones, and an INC and OBJECT we set ourselves below.
delete @DEP{qw(LIBS LDFROM INC OBJECT)};
# It also sets PM explicitly, which makes init_PM return early without running
# MakeMaker's own scan, so re-add what that scan would have found.
for my $pm (glob('lib/DBIx/Loop.pm'), glob('lib/DBIx/Loop/*.pm'),
            glob('lib/DBIx/Loop/Loop/*.pm')) {
    (my $dest = $pm) =~ s{^lib/}{};
    $DEP{PM}{$pm} = "\$(INST_LIB)/$dest";
}

my %WriteMakefileArgs = (
    NAME             => 'DBIx::Loop',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/DBIx/Loop.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Loop.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    INC              => '-I. -Iinclude',
    OBJECT           => 'Loop$(OBJ_EXT)',   # xs/*.xs are INCLUDE:d into Loop.xs
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More'   => '0',
        'DBD::SQLite'  => '0',
        'IO::Async'    => '0',   # baseline adapter: at least one loop in tests
    },
    PREREQ_PM => {
        'DBI' => '1.600',
    },
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Loop-* Install/Files.pm' },
    # MakeMaker maps Loop.xs -> Loop.c and does not rescan the INCLUDE:
    # fragments or the C headers, so an edit to xs/ or include/ left a stale
    # Loop.c behind and the build silently kept the previous XSUBs. Force the
    # regenerate on an xs/ change and the recompile on a header change.
    depend => {
        'Loop.c'         => join(' ', glob('xs/*.xs')),
        'Loop$(OBJ_EXT)' => join(' ', glob('include/*.h'), glob('xs/*.xs')),
    },
    %DEP,   # ExtUtils::Depends: PM map (installs dbil_abi.h + Files.pm + .pm)
);

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

WriteMakefile(%WriteMakefileArgs);
