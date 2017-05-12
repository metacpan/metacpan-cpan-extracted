use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR' => 'Jean-Christophe Kermagoret <jck@BabelObjects.Org>',
    'NAME'	=> 'BabelObjects',
    'VERSION_FROM' => 'VERSION',
    'dist' => { 'COMPRESS' => 'gzip -9f',
                'SUFFIX' => 'gz'
              },
    'PREREQ_PM' => { XML::DOM => 0
#		     CGI::Fast => 0,
#                     URI::Bookmarks => 0
                   }
);
