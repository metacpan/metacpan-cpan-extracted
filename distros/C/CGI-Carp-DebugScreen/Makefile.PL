use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'CGI::Carp::DebugScreen',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/CGI/Carp/DebugScreen.pm',
  ABSTRACT_FROM => 'lib/CGI/Carp/DebugScreen.pm',
  PREREQ_PM => {
    'CGI::Carp'  => 0,
    'Test::More' => '0.47',
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);
