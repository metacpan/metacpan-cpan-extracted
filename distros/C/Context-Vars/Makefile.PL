use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use File::Find ();

# Vars.xs sits at the top of the dist and the build is the plain
# single-extension one MakeMaker defaults to, for the reason HAMT's
# Makefile.PL gives: the import-library rule Strawberry adds for MinGW reads
# $(BASEEXT).def in the top directory.

sub inc_dirs { my @d; push @d, $1 while $_[0] =~ /-I(\S+)/g; return @d }

# ---- Context::Vars as an ABI CONSUMER ---------------------------------- *
# A context is a HAMT map, reached through HAMT's C ABI, so the header is
# hamt_abi.h and the table is resolved when the module loads. A sibling
# checkout comes first, ahead of an installed copy, as everywhere in this
# workspace: an installed header that is older than the sibling's would
# otherwise win and compile against a table the sibling no longer has.
#
# HAMT is REQUIRED. There is nothing to degrade to, so a build that finds
# the header in neither place stops here.
my $pkg = eval { ExtUtils::Depends->new('Context::Vars', 'HAMT') };
my $hamt_inc;
{
    my @sib  = grep { -d } ('../HAMT/include');
    my $inst = '';
    if ($pkg) {
        my %v = $pkg->get_makefile_vars;
        $inst = $v{INC} || '';
    }
    for my $d (@sib, inc_dirs($inst)) {
        next unless -f "$d/hamt_abi.h";
        $hamt_inc = $d;
        last;
    }
    die "Context::Vars needs HAMT 0.02 installed, or present as the sibling "
      . "../HAMT: its hamt_abi.h is what a context is built on.\n"
        unless $hamt_inc;
    print "hamt_abi.h: from $hamt_inc\n";
}

# ---- Context::Vars as an ABI PROVIDER ---------------------------------- *
# context_vars_abi.h is what lets an event loop written in C capture a
# context when a callback is registered and enter it when the callback runs,
# with no Perl call in between. ExtUtils::Depends installs the header and
# records the include path; Context::Vars::_abi_ptr hands over the table's
# address at runtime.
#
# NO set_inc, for the reason HAMT's Makefile.PL gives: what is recorded there
# is handed to every consumer, and this dist's build-tree paths mean nothing
# once it is installed.
$pkg ||= ExtUtils::Depends->new('Context::Vars');
$pkg->install('include/context_vars_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %dep = $pkg->get_makefile_vars;
# EU::Depends hands back an empty LIBS/LDFROM that would clobber MakeMaker's
# defaults, and an INC that names only an installed HAMT. INC is set below
# from whichever HAMT was found.
delete @dep{qw(LIBS LDFROM INC)};

# Its PM map REPLACES MakeMaker's auto-detected one, so everything under lib/
# has to be re-added by hand or it silently stops being installed.
File::Find::find(sub {
    return unless -f && /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# MakeMaker maps Vars.xs -> Vars.c and rescans neither the INCLUDEd xs/
# fragments nor the C headers, so name both. The globs run at CONFIGURE
# time - re-run Makefile.PL after adding a file.
my $xs_deps = join ' ', glob('xs/*.xs');
my $h_deps  = join ' ', 'include/context_vars_abi.h', glob('include/context_vars/*.h');

my %WriteMakefileArgs = (
    NAME             => 'Context::Vars',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Context/Vars.pm',
    ABSTRACT_FROM    => 'lib/Context/Vars.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    # HAMT at configure time as well as at runtime: its header is needed to
    # compile, and ExtUtils::Depends finds it through HAMT::Install::Files.
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'HAMT'                => '0.02',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'HAMT' => '0.03',
    },
    XS     => { 'Vars.xs' => 'Vars.c' },
    OBJECT => 'Vars$(OBJ_EXT)',
    INC    => "-I. -Iinclude -I$hamt_inc",
    depend => {
        'Vars.c'         => $xs_deps,
        'Vars$(OBJ_EXT)' => $h_deps,
    },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Context-Vars-* Install/Files.pm' },
    %dep,
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
