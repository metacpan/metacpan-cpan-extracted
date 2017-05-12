use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => 'Get Drunk, Acme Style',
               NAME          => 'Acme::Drunk',
               VERSION_FROM  => 'lib/Acme/Drunk.pm',
               PREREQ_PM     => {
                                 'Test::More' => '0.47',
                                },
              );
