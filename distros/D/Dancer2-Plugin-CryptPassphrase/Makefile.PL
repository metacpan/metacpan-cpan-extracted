use ExtUtils::MakeMaker;
( do './maint/Makefile.PL.include' or die $@ ) unless -f 'META.yml';
WriteMakefile(
    BRANCH           => 'main',
    NAME             => "Dancer2::Plugin::CryptPassphrase",
    ABSTRACT         => "Crupt::Passphrase plugin for Dancer2",
    AUTHOR           => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/CryptPassphrase.pm',
    MIN_PERL_VERSION => 5.010001,
    TEST_REQUIRES    => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Dancer2'                   => '0.200000',
        'Dancer2::Plugin'           => 0,
        'Crypt::Passphrase'         => '0.004',
        'Crypt::Passphrase::Argon2' => '0.003',
        'Types::Standard'           => '0',
    },
    META_MERGE => {
        resources => {
            repository =>
              'https://github.com/SysPete/Dancer2-Plugin-CryptPassphrase',
            bugtracker =>
              'https://github.com/SysPete/Dancer2-Plugin-CryptPassphrase/issues',
            IRC     => 'irc://irc.perl.org/#dancer',
            license => ['http://dev.perl.org/licenses/'],
        },
    },
);
