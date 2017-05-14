use strict;
use ExtUtils::MakeMaker;

eval { require 5.6.0 } or die <<EOD;
################
### This module requires lvaluable subroutines, which are not available
### in versions of Perl earlier than 5.6.  Please upgrade!
############
EOD

WriteMakefile(
    'NAME'      => 'AutoSQL',
#    'VERSION_FROM' => 'AutoSQL/Root.pm'
);

