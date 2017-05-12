use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'CGI::Plus',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'CGI::Plus -- Extra utilities for CGI',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/CGI/Plus.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {
                                'CGI::Cookie' => 0,
                                'CGI::Safe' => 0,
                                'String::Util' => '1.24'
                              }
             };


WriteMakefile(%$make_args);
