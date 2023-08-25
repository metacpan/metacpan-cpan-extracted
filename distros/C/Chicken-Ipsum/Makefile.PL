use 5.012;
use warnings;
require ExtUtils::MakeMaker;

my $sc = 'https://codeberg.org/h3xx/perl-Chicken-Ipsum';
my $bt = "$sc/issues";

my %writemakefileargs = (
    NAME             => 'Chicken::Ipsum',
    AUTHOR           => 'Dan Church <h3xx@gmx.com>',
    VERSION_FROM     => 'lib/Chicken/Ipsum.pm',
    ABSTRACT_FROM    => 'lib/Chicken/Ipsum.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012',
    CONFIGURE_REQUIRES => {qw(
        ExtUtils::MakeMaker 0
    )},
    TEST_REQUIRES => {qw(
        FindBin 0
        IPC::Open3 0
        Math::BigInt 0
        Symbol 0
        Test::More 0
    )},
    PREREQ_PM => {qw(
        Carp 0
        List::Util 1.54
    )},
    EXE_FILES => [
        'chicken-ipsum',
    ],
    PL_FILES => {
        'chicken-ipsum.PL' => 'chicken-ipsum',
    },
    clean => { FILES => [
        'chicken-ipsum',
    ]},
    MAN1PODS => {
        'doc/chicken-ipsum.pod' => 'blib/man1/chicken-ipsum.1',
    },
    META_ADD => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => { web => $bt },
            license    => [ 'https://dev.perl.org/licenses/' ],
            repository => { type => 'git', url => "$sc.git", web => $sc },
        },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (_mm_ver_atleast('6.64')) {
    my $test_requires = delete $writemakefileargs{TEST_REQUIRES} || {};
    @{$writemakefileargs{PREREQ_PM}}{keys %{$test_requires}} = values %{$test_requires};
}

unless (_mm_ver_atleast('6.55_03')) {
    my $build_requires = delete $writemakefileargs{BUILD_REQUIRES} || {};
    @{$writemakefileargs{PREREQ_PM}}{keys %{$build_requires}} = values %{$build_requires};
}

unless (_mm_ver_atleast('6.52')) {
    delete $writemakefileargs{CONFIGURE_REQUIRES};
}
unless (_mm_ver_atleast('6.48')) {
    delete $writemakefileargs{MIN_PERL_VERSION};
}
unless (_mm_ver_atleast('6.31')) {
    delete $writemakefileargs{LICENSE};
}

ExtUtils::MakeMaker::WriteMakefile(%writemakefileargs);

sub _mm_ver_atleast {
    my $ver = shift;
    return eval { ExtUtils::MakeMaker->VERSION($ver); 1 };
}
