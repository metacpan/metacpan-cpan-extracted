use ExtUtils::MakeMaker;
require 5.6.0;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
   (
   'ABSTRACT'     => 'Handles "@_" for your own class methods',
   'AUTHOR'       => 'Tommy Butler <cpan@atrixnet.com>',
   'INSTALLDIRS'  => 'site',
   'NAME'         => 'Class::OOorNO',
   'VERSION_FROM' => 'OOorNO.pm',
   'linkext'      => { LINKTYPE => '' }, # no link needed
   'dist'         =>
      {
         'COMPRESS'  => 'gzip -9f',
         'SUFFIX'    => 'gz',
         'ZIP'       => '/usr/bin/zip',
         'ZIPFLAGS'  => '-rl',
      }
   );
