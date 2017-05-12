# $Id: Makefile.PL 13 2009-12-04 11:16:01Z stro $

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'DISTNAME'      => 'CGI-Application-Plugin-DevPopup-Params',
  'NAME'          => 'CGI::Application::Plugin::DevPopup::Params',
  'ABSTRACT'      => 'Show CGI::Application parameters in DevPopup window',
  'AUTHOR'        => 'Serguei Trouchelle <stro@cpan.org>',
  'VERSION_FROM'  => 'Params.pm',
  'LICENSE'       => 'perl',
  'PREREQ_PM'     => {
                         'CGI::Application::Plugin::DevPopup' => 1.03,
                     },
);
