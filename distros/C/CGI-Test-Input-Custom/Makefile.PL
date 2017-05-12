
require 5.008;

use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'CGI::Test::Input::Custom',
               VERSION_FROM => 'lib/CGI/Test/Input/Custom.pm',
               PREREQ_PM => { 'CGI::Test' => 0 },
               AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',
             );
