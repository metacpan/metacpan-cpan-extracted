use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# IF_OPT sets the -O value used to compile the XS backend (default -O3).
# IF_ARCH optionally sets the target arch, e.g. IF_ARCH=native for
# -march=native. Both accept a bare value or a full compiler flag.
my $optimize = defined $ENV{IF_OPT} && length $ENV{IF_OPT} ? $ENV{IF_OPT} : '3';
$optimize = "-O$optimize" unless $optimize =~ /^-/;

my $arch_flags = '';
if ( defined $ENV{IF_ARCH} && length $ENV{IF_ARCH} ) {
    $arch_flags = $ENV{IF_ARCH};
    $arch_flags = "-march=$arch_flags" unless $arch_flags =~ /^-/;
}

# The XS backend is optional: without a working compiler (or with
# PUREPERL_ONLY=1) the module installs as pure Perl and
# Algorithm::EventsPerSecond falls back automatically.
my $pureperl_only = grep { /^PUREPERL_ONLY=(\S+)$/ && $1 } @ARGV;

my $can_xs = !$pureperl_only
    && eval { ExtUtils::MakeMaker->VERSION('7.12'); 1 }    # XSMULTI
    && _have_compiler();

sub _have_compiler {
    # if the probe itself is unavailable, assume a compiler and let
    # make fail loudly rather than silently degrading
    return 1 unless eval { require ExtUtils::CBuilder; 1 };
    my $ok = eval { ExtUtils::CBuilder->new( quiet => 1 )->have_compiler };
    return $ok ? 1 : 0;
}

my %WriteMakefileArgs = (
    NAME             => 'Algorithm::EventsPerSecond',
    AUTHOR           => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
    VERSION_FROM     => 'lib/Algorithm/EventsPerSecond.pm',
    ABSTRACT_FROM    => 'lib/Algorithm/EventsPerSecond.pm',
    EXE_FILES        => ['src_bin/iqbi-damiq'],
    LICENSE          => 'lgpl_2_1',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => {
        FILES => join ' ', 'Algorithm-EventsPerSecond-*',
            map { "lib/Algorithm/EventsPerSecond/XS.$_" } qw(c o bs),
    },
    (
        $can_xs
        ? (
            XSMULTI  => 1,
            OPTIMIZE => $optimize,
            ( $arch_flags ? ( CCFLAGS => "$Config{ccflags} $arch_flags" ) : () ),
          )
        : ()
    ),
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

# XSMULTI compiles XS.c/XS.o/XS.bs next to XS.xs inside lib/; keep the
# intermediates out of blib (and so out of make install) if a previous
# build left them behind. The .xs must pass through, or XSMULTI cannot
# find it.
sub MY::libscan {
    my ( $self, $path ) = @_;
    return '' if $path =~ /\.(?:c|o|bs)$/;
    return $path;
}
