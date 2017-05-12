use ExtUtils::MakeMaker;

use 5.006; # From http://wiki.cpantesters.org/wiki/CPANAuthorNotes
           # If this doesn't work its time to rm -rf CPAN Tester systems to stop them bugging me ;-)

my $module = 'ManekiNeko.pm';
WriteMakefile(
              NAME         => 'Acme::ManekiNeko',
              VERSION_FROM => $module,
              PREREQ_PM    => {
                               Test::More => 0,
                              },
              AUTHOR       => 'Greg McCarroll <greg@mccarroll.org.uk>',
             );


