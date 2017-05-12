use strict;
use ExtUtils::MakeMaker;
 
WriteMakefile(
        NAME            => 'Date::Calc::Endpoints',
        VERSION_FROM    => 'lib/Date/Calc/Endpoints.pm',
        ABSTRACT_FROM   => 'lib/Date/Calc/Endpoints.pod',
        AUTHOR          => 'Terry Olenchuk <OLENCHUK@cpan.org>',
        PREREQ_PM       => {
                                'Date::Calc' => 6.0,
                                'Class::Accessor' => 0.34,
                                'Test::More' => 0.98
                           },
        test            => {TESTS => 't/*.t'},

        );
