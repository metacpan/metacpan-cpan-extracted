use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME      => 'CGI::Application::Plugin::Nes',
  AUTHOR    => 'Skriptke',
  ABSTRACT  => 'Plugin for use Nes templates in CGI::Application',
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "CGI::Application" => '1.41',
    "Nes" => '1.03.4',
  },
);