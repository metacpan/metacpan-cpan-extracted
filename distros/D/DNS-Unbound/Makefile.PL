use ExtUtils::MakeMaker 7.12; # for XSMULTI option

my $pkgconfig_name = 'libunbound';

# These can fail because older libunbound versions (e.g., 1.4.22)
# didn’t include a pkg-config file.
my $cflags = `pkg-config --cflags $pkgconfig_name`;
my $ldflags = `pkg-config --libs $pkgconfig_name`;

chomp for $cflags, $ldflags;

# In case pkg-config didn’t give us anything.
if ($?) {
    warn "You either don’t have libunbound installed, or your installed version didn’t include a pkg-config file. Will attempt build with default configuration.\n";
    $ldflags ||= '-lunbound';
}

WriteMakefile(
    NAME           => 'DNS::Unbound',
    VERSION_FROM   => 'lib/DNS/Unbound.pm',
    ABSTRACT_FROM  => 'lib/DNS/Unbound.pm',
    AUTHOR         => 'Felipe Gasper (FELIPE)',
    CCFLAGS        => "$cflags -Wall -std=c99",
    LIBS           => [ $ldflags ],
    LICENSE        => 'perl',
    XSMULTI        => 1,

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 7.12,
    },

    PREREQ_PM => {
        'X::Tiny' => 0,
        'XSLoader' => 0.24,
    },

    TEST_REQUIRES => {
        'Test::More'      => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => 'https://github.com/FGasper/p5-DNS-Unbound/issues',
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-DNS-Unbound.git',
                web  => 'https://github.com/FGasper/p5-DNS-Unbound',
            },
        },
    },
);
