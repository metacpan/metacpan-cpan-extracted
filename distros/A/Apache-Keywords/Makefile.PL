use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME' => 'Apache::Keywords',
  'VERSION_FROM' => 'lib/Apache/Keywords.pm',
  'dist' => {COMPRESS=>'gzip', SUFFIX => 'gz'},
)
