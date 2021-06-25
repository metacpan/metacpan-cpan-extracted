use ExtUtils::MakeMaker;
( do './maint/Makefile.PL.include' or die $@ ) unless -f 'META.yml';
WriteMakefile(
    NAME             => "Dancer2::Plugin::PrometheusTiny",
    ABSTRACT         => "Prometheus metrics for Dancer2",
    AUTHOR           => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/PrometheusTiny.pm',
    MIN_PERL_VERSION => 5.010001,
    TEST_REQUIRES    => {
        'HTTP::Request::Common' => 0,
        'Plack'                 => '1.0029',
        'Scalar::Util'          => 0,
        'Test::Deep'            => 0,
        'Test::More'            => 0,
    },
    PREREQ_PM => {
        'Dancer2'                  => '0.200000',
        'Dancer2::Plugin'          => 0,
        'Carp'                     => 0,
        'Prometheus::Tiny'         => '0.006',
        'Prometheus::Tiny::Shared' => '0.021',
        'Time::HiRes'              => '0',
        'Types::Standard'          => '0',
    },
    META_MERGE => {
        resources => {
            repository =>
              'https://github.com/SysPete/Dancer2-Plugin-PrometheusTiny',
            bugtracker =>
              'https://github.com/SysPete/Dancer2-Plugin-PrometheusTiny/issues',
            IRC     => 'irc://irc.perl.org/#dancer',
            license => ['http://dev.perl.org/licenses/'],
        },
    },
);
