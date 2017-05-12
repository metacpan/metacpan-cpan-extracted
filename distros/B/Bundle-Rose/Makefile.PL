require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Bundle::Rose',
              PMLIBDIRS    => [ 'lib' ],
              VERSION_FROM => 'lib/Bundle/Rose.pm');
