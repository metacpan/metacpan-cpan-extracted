use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'	   => 'Async::Group',
              'VERSION' => '0.3',
              ($] >= 5.005 ?
               (ABSTRACT   => 'Deal with simultaneous asynchronous calls',
                AUTHOR     => 'Dominique Dumont (domi@barrayar.grenoble.hp.com)') : ()),
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
             );
