use ExtUtils::MakeMaker;
WriteMakefile
(
 'PL_FILES' => {},
 'INSTALLDIRS' => 'site',
 'NAME' => 'CGI::Application::Plugin::DBIC::Schema',
 'EXE_FILES' => [],
 'VERSION_FROM' => 'lib/CGI/Application/Plugin/DBIC/Schema.pm',
 'PREREQ_PM' => {
     'CGI::Application' => '3',
     'DBIx::Class' => '0',
 },
 'LICENSE' => 'perl',
);
