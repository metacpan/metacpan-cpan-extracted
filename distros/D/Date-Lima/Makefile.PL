use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		    => 'Date::Lima',
    'VERSION_FROM'	=> 'Lima.pm',
    'PREREQ_PM'		=> {},

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006,
            META_MERGE => {
                keywords => [qw(date time interval)],
                resources=> {
                    repository => 'http://github.com/jettero/date--lima',
                },
            },

        LICENSE	=> 'LGPL',

    ) : ()),
);
