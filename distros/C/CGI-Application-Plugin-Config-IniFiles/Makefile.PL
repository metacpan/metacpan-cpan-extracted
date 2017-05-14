#! perl

use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => "CGI::Application::Plugin::Config::IniFiles",
    VERSION   => "0.03",
    PREREQ_PM => { 'CGI::Application' => 4.06,
		   'Config::IniFiles' => 2.38 },
    ABSTRACT  => "CGI::Application plugin for Config::IniFiles",
    AUTHOR    => "Artur Penttinen <artur+perl\@niif.spb.su>",
    clean     => { 'FILES' => "*~ */*~ */*/*~ */*/*/*~ *.tar.gz" }
);

exit;

### That's all, folks!
