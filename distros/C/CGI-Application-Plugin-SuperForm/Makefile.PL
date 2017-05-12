use ExtUtils::MakeMaker;
WriteMakefile
(
 'PL_FILES' => {},
 'INSTALLDIRS' => 'site',
 'NAME' => 'CGI::Application::Plugin::SuperForm',
 'EXE_FILES' => [],
 'VERSION_FROM' => 'lib/CGI/Application/Plugin/SuperForm.pm',
 'PREREQ_PM' => {
     'CGI::Application' => '3',
     'HTML::SuperForm' => '1.06',
 },
 'LICENSE'=> 'perl'
);
