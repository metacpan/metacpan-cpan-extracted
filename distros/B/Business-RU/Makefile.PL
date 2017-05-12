use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Business::RU',
    VERSION_FROM => 'lib/Business/RU.pm',
    PREREQ_PM => { 
        Moose   => 0,    
});