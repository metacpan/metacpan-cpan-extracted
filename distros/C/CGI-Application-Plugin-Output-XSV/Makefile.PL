use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'CGI::Application::Plugin::Output::XSV',
    'INSTALLDIRS'       => 'site',
    'VERSION_FROM'	=> 'XSV.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      'Test::More'       => 0,
      'CGI::Application' => 0,
      'Text::CSV_XS'     => 0,
    },
    'PL_FILES'          => {}, # empty to ignore Build.PL
    'clean'             => { FILES => "Makefile.old CGI-Application-*.gz" },
);
