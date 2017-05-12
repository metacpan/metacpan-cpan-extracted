
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'CGI-Application-Plugin-CompressGzip',
  NAME      => 'CGI::Application::Plugin::CompressGzip',
  AUTHOR    => 'Rhesa\ Rozendaal\ \<rhesa\@cpan\.org\>',
  ABSTRACT  => 'Add gzip compression to CGI::Application',
  VERSION   => '1.02',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "CGI::Application" => '4.01',
    "CGI::Compress::Gzip" => '0.19',
  },
);
