use ExtUtils::MakeMaker;
WriteMakefile(
    'AUTHOR'      => 'Philip Collins (pmc@cpan.org)',
    'NAME'		=> 'Apache2::FileManager',
    'VERSION_FROM'	=> 'FileManager.pm',
    'PREREQ_PM'		=> {
      'Apache2::Request'    => 0,
      'Apache2::Util'       => 0,
      'Apache2::RequestRec' => 0,
      'Apache2::RequestIO'  => 0,
      'Apache2::ServerUtil' => 0,
      'Apache2::Const'      => 0,
      'Apache2::Log'        => 0,
      'Apache2::Upload'     => 0,
      'File::NCopy'       => 0.32,
      'File::Copy'        => 2.03,
      'File::Remove'      => 0.20,
      'File::stat'        => 0,
      'Archive::Any'      => 0.03,
      'POSIX'             => 1.03,
      'CGI::Cookie'       => 1.20,
      'IO::File'          => 0
    }
);
