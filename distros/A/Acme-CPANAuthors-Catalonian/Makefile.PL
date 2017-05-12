use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile( NAME                => 'Acme::CPANAuthors::Catalonian',
               AUTHOR              => 'Several',
               VERSION_FROM        => 'lib/Acme/CPANAuthors/Catalonian.pm',
               ABSTRACT_FROM       => 'lib/Acme/CPANAuthors/Catalonian.pm',
               PREREQ_PM           => { 'Test::More' => 0,
                                        'Acme::CPANAuthors::Register' => 0, },
               ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'public domain') : ()),
             );
