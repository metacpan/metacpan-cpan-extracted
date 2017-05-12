use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => "CGI::Widget::DBI::Search",
  VERSION_FROM => "lib/CGI/Widget/DBI/Search.pm",
  PREREQ_PM => { CGI => 0, DBI => 0, DBD::mysql => 0, Encode::Detect => 0, Test::Unit => 0 },
  'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" }
);
