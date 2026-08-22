use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'ClamAV::Clamd',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/ClamAV/Clamd.pm',
    ABSTRACT_FROM    => 'lib/ClamAV/Clamd.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        # None. This speaks a protocol; it does not link libclamav.
    },
    INC   => '-I.  -Iinclude',
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'ClamAV-Clamd-* Install dev/fildes_probe '
                      . 'dev/fake_clamd dev/drain_clamd t/abi_consumer/blib '
                      . 't/abi_consumer/Makefile t/abi_consumer/pm_to_blib' },
);

# --- the C ABI ---------------------------------------------------------
#
# ExtUtils::Depends lets a consumer compile against include/clamav/
# clamd_abi.h without linking against this .so. It is a CONFIGURE-time
# dependency only - nothing is required at runtime, and a build without
# it still produces a fully working module. Only the consumer wiring is
# lost, so it degrades rather than failing.
if (eval { require ExtUtils::Depends; 1 }) {
    my $pkg = ExtUtils::Depends->new('ClamAV::Clamd');
    $pkg->install('include/clamav/clamd_abi.h');
    mkdir 'Install' unless -d 'Install';
    $pkg->save_config('Install/Files.pm');

    my %dep = $pkg->get_makefile_vars;

    # GOTCHA 1: EU::Depends hands back empty LIBS/LDFROM that clobber
    # MakeMaker's own defaults. This dist links nothing, so they go.
    delete $dep{LIBS};
    delete $dep{LDFROM};

    # GOTCHA 2: its PM map REPLACES MakeMaker's auto-detected one, so
    # everything under lib/ has to be put back by hand or the module
    # itself stops being installed.
    if ($dep{PM}) {
        require File::Find;
        File::Find::find(sub {
            return unless -f $_;
            my $from = $File::Find::name;
            (my $to = $from) =~ s{^lib/}{\$(INST_LIB)/};
            $dep{PM}{$from} = $to;
        }, 'lib');
    }

    # GOTCHA 3: merge its INC into ours rather than letting it win.
    $dep{INC} = join ' ', ($WriteMakefileArgs{INC} || ''), ($dep{INC} || '');

    %WriteMakefileArgs = (%WriteMakefileArgs, %dep);
    $WriteMakefileArgs{CONFIGURE_REQUIRES}{'ExtUtils::Depends'} = '0.302';
}
else {
    warn <<'NOTE';
ExtUtils::Depends is not installed. ClamAV::Clamd will build and work
normally; only the C ABI wiring for other XS distributions is skipped.
NOTE
}

# MakeMaker tracks neither include/*.h nor anything an XS file pulls in,
# so editing a header rebuilds nothing and the .so keeps the old code.
# Name them as dependencies or lose an afternoon to a stale object.
sub MY::postamble {
    return <<'MAKE_FRAG';
CLAMD_HEADERS = include/clamav/clamd_compat.h include/clamav/clamd_conn.h \
                include/clamav/clamd_stream.h include/clamav/clamd_scan.h \
                include/clamav/clamd_verdict.h include/clamav/clamd_async.h \
                include/clamav/clamd_abi.h include/clamav/clamd_abi_impl.h

Clamd.c : Clamd.xs $(CLAMD_HEADERS)

$(OBJECT) : $(CLAMD_HEADERS)
MAKE_FRAG
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

WriteMakefile(%WriteMakefileArgs);
