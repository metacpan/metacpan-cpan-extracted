use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::Auth::Auto',
    VERSION_FROM      => 'lib/CGI/Auth/Auto.pm', # finds $VERSION
    PREREQ_PM         => { 
		'CGI::Auth' => 0,
		'Carp'		=> 0,
		'HTML::Template' => 0,
      'HTML::Template::Default' => 0,
      'LEOCHARRE::DEBUG' => '1.06',
      'Data::Dumper' => 0,
      'Cwd' => 0,
      'Cwd::Ext' => '1.03',
      'CGI::Scriptpaths' => '1.01',
      'Linux::usermod' => 0,      
      'LEOCHARRE::CLI' => '1.09',
      
	},

   EXE_FILES => ['bin/authman'],
);
