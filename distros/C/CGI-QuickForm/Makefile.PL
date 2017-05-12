use ExtUtils::MakeMaker ;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'CGI::QuickForm',
    'VERSION_FROM' => 'QuickForm.pm', # finds $VERSION
    'DISTNAME'     => 'CGI-QuickForm',
    ($] >= 5.005 ?
        (
            ABSTRACT => 'Provides quick CGI forms for CGI and mod_perl',
            AUTHOR   => 'Mark Summerfield <summer@perlpress.com>',
        ) : () ),
    'LIBS'         => [''],   # e.g., '-lm'
    'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'          => '',     # e.g., '-I/usr/include/other'
    'dist'         => { COMPRESS => "gzip -9", SUFFIX => "gz" }
) ;
