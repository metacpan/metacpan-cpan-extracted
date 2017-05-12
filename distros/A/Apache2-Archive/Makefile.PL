use inc::Module::Install;
  
name           'Apache2-Archive';
all_from       'lib/Apache2/Archive.pm';
  
requires  'Archive::Tar'        => 0;
requires  'Apache2::Log'        => 0;
requires  'Apache2::Const'      => 0;
requires  'Apache2::Util'       => 0;
requires  'Apache2::Status'     => 0;
requires  'Apache2::SubRequest' => 0;

WriteAll;
