use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> 'CAM::Session',
              'VERSION_FROM'	=> 'lib/CAM/Session.pm',
              'PREREQ_PM'		=> {
                 'CGI'                      => '2.0',
                 'CGI::Cookie'              => '1.0',
                 'DBI'                      => '1.0',
                 'Digest::MD5'              => '2.0',
                 # Build depends:
                 'Test::More'               => '0.01',
                 'DBD::mysql'               => '0.01',
              },
              'PL_FILES' => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/Session.pm',
                AUTHOR        => 'Clotho Advanced Media Inc. <cpan@clotho.com>') : ()),
              );
