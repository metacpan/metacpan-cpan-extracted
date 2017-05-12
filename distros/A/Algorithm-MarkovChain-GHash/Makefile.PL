use ExtUtils::MakeMaker;

`glib-config --libs`;
die "Can't find glib-config in your path, so bailing now" if $?;

WriteMakefile(
              NAME         => 'Algorithm::MarkovChain::GHash',
              VERSION_FROM => 'GHash.pm',
              AUTHOR       => 'Richard Clamp <richardc@unixbeard.net>',
              ABSTRACT     => 'Markov Chain implementation',
              LIBS         => `glib-config --libs`,
              INC          => `glib-config --cflags`,
              PREREQ_PM    => { 'Algorithm::MarkovChain' => 0.05,
                                'Test::More' => 0 },
             );

