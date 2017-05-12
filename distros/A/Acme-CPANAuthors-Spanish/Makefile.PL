use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile( NAME                => 'Acme::CPANAuthors::Spanish',
               AUTHOR              => 'Several',
               VERSION_FROM        => 'lib/Acme/CPANAuthors/Spanish.pm',
               ABSTRACT_FROM       => 'lib/Acme/CPANAuthors/Spanish.pm',
               PREREQ_PM           => { 'Test::More' => 0,
                                        'Acme::CPANAuthors::Register' => 0, },
               ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'public domain') : ()),
               ($ExtUtils::MakeMaker::VERSION < 6.46 ? () :
                 ( META_MERGE => {
                       resources => {
                           repository => 'https://github.com/salva/p5-Acme-CPANAuthors-Spanish',
                       },
                   },
                 ),
               ),
             );
