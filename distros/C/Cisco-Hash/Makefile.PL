use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Cisco::Hash',
              VERSION_FROM  => 'Hash.pm',
              PREREQ_PM     => { 
                                Carp => "1.04",
                               },             
              ABSTRACT_FROM => 'Hash.pm',
              AUTHOR        => 'Lord Infernale <infernale@cpan.org>',
             );
