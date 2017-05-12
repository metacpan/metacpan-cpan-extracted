use ExtUtils::MakeMaker;
WriteMakefile(
    'AUTHOR'      => 'Philip Collins (pmc@cpan.org)',
    'NAME'		=> 'Apache::FileManager',
    'VERSION_FROM'	=> 'FileManager.pm',
    'PREREQ_PM'		=> { 
      'Apache::Request'   => 0,
      'Apache::Util'      => 0,
      'Apache::File'      => 1.01,
      'File::NCopy'       => 0.32,
      'File::Copy'        => 2.03,
      'File::Remove'      => 0.20,
      'File::stat'        => 0,
      'Archive::Any'      => 0.03,
      'POSIX'             => 1.03,
      'CGI::Cookie'       => 1.20,
      'Apache::Constants' => 1.09,
      'IO::File'          => 0
    }
);

