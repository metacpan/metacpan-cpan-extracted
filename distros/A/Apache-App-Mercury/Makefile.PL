use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => "Apache::App::Mercury",
  VERSION_FROM => "Mercury.pm",
  'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" }
);
