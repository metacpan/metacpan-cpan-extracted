use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'AnyEvent::Radius',
    AUTHOR       => [
        'Sergey Leschenko <sergle.ua at gmail.com>',
        'PortaOne <perl-radius at portaone.com>',
    ],
    LICENSE      => "artistic_2",
    VERSION_FROM => 'lib/AnyEvent/Radius.pm',
    MIN_PERL_VERSION => "v5.10.0",
    PREREQ_PM    => {
        'Data::Radius' => '1.2.8',
        'AnyEvent' => 0,
        'AnyEvent::Handle::UDP' => 0,
        'Class::Accessor::Fast' => 0,
    },
    # TEST_REQUIRES => {
    # },
);
