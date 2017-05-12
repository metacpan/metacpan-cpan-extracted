use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME' => 'CGI::Portal',
  'AUTHOR' => 'Alexander David P',
  'VERSION_FROM' => 'Portal.pm',
  'PREREQ_PM' => {'Digest::MD5' => '1','DBI' => '1','CGI' => '1','HTML::Template' => '1'}
);