use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Catalyst::Plugin::Session::Store::Jifty::DBI',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Catalyst/Plugin/Session/Store/Jifty/DBI.pm',
  ABSTRACT_FROM => 'lib/Catalyst/Plugin/Session/Store/Jifty/DBI.pm',
  PREREQ_PM => {
    'Catalyst::Model::Jifty::DBI' => '0.06',
    'Catalyst::Plugin::Session'   => '0.27',
    'Catalyst::Runtime'           => '5.70',
    'MIME::Base64'                => 0,
    'DBD::SQLite'                 => '1.25',
    'Storable'                    => 0,
    'Test::More'                  => '0.47',
    'Test::UseAllModules'         => '0.09',
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);
