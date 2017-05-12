use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Class::XPath',
              VERSION_FROM  => 'XPath.pm',              
              PREREQ_PM     => { 
                                Test::More => "0.47",
                                Carp       => 0,
                               },
              ABSTRACT_FROM => 'XPath.pm',
              AUTHOR        => 'Sam Tregar <sam@tregar.com>',
             );
