use ExtUtils::MakeMaker;
my $module = 'Mutator.pm';
WriteMakefile(
              NAME         => 'Class::Mutator',
              VERSION_FROM => $module,
              PREREQ_PM    => {
                               Test::More => 0,
                              },
              AUTHOR       => 'Greg McCarroll <greg@mccarroll.demon.co.uk>',
             );





