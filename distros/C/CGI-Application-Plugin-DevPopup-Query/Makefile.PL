# $Id: Makefile.PL 14 2009-12-04 12:47:11Z stro $

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'DISTNAME'      => 'CGI-Application-Plugin-DevPopup-Query',
  'NAME'          => 'CGI::Application::Plugin::DevPopup::Query',
  'ABSTRACT'      => 'Show CGI query in DevPopup window',
  'AUTHOR'        => 'Serguei Trouchelle <stro@cpan.org>',
  'VERSION_FROM'  => 'Query.pm',
  'LICENSE'       => 'perl',
  'PREREQ_PM'     => {
                         'CGI::Application::Plugin::DevPopup' => 1.03,
                     },
);
