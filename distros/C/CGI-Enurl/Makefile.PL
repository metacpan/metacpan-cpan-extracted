use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CGI::Enurl',
    'VERSION_FROM' => 'Enurl.pm', # finds $VERSION
   ($] ge '5.005')
    ? (
     'AUTHOR' => 'Jan Krynicky (Jenda@Krynicky.cz)',
     'ABSTRACT' => 'Encode strings, arrays and hashes so that they may be appended to URLs as queries',
    )
    : ()
);
