use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Catalyst::Authentication::Store::Jifty::DBI',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Catalyst/Authentication/Store/Jifty/DBI.pm',
  ABSTRACT_FROM => 'lib/Catalyst/Authentication/Store/Jifty/DBI.pm',
  PREREQ_PM => {
    'Catalyst::Runtime'                => '5.70',
    'Catalyst::Model::Jifty::DBI'      => '0.06',
    'Catalyst::Plugin::Authentication' => '0.10005',
    'Scalar::Util'                     => '0',
    'Test::More'                       => '0.47',
    'Test::UseAllModules'              => '0.09',
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);
