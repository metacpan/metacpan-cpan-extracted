use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Acme::Apache::Werewolf',
    VERSION_FROM => 'lib/Acme/Apache/Werewolf.pm',
    AUTHOR       => 'Rich Bowen (rbow@cpan.org)',
    ABSTRACT     => 
         'Keep werewolves out of your website during the full moon',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Astro::MoonPhase' => 0,
                     'Apache::Constants' => 0,
                    },
);
