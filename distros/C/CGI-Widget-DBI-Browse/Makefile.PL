use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => "CGI::Widget::DBI::Browse",
  VERSION_FROM => "lib/CGI/Widget/DBI/Browse.pm",
  PREREQ_PM => { CGI => 0, DBI => 0, Test::Unit => 0, CGI::Widget::DBI::Search => 0.26 },
  'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" }
);
