use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CGI::Deurl',
    'VERSION_FROM' => 'Deurl.pm', # finds $VERSION
   ($] ge '5.005')
    ? (
     'AUTHOR' => 'Jan Krynicky (Jenda@Krynicky.cz)',
     'ABSTRACT' => 'Decode the parameters passed to a CGI',
    )
    : ()
);
