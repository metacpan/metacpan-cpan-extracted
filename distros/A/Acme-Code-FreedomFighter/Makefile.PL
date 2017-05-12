use ExtUtils::MakeMaker;
my $module = 'FreedomFighter.pm';
WriteMakefile(
              NAME         => 'Acme::Code::FreedomFighter',
              VERSION_FROM => $module,
              PREREQ_PM    => {
                               Test::More => 0,
                              },
              AUTHOR       => 'Greg McCarroll <greg@mccarroll.demon.co.uk>',
             );


