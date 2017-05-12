use ExtUtils::MakeMaker;

print "Checking for Authen::Smb...";
eval {
  require Authen::Smb;
};
if ($@) {
  print " failed\n";
  print <<EOT;
$@
The Authen::Smb module is required for this module to work properly.
EOT
  exit;
} else {print " ok\n"}
 
print "Checking for Net::NISPlus...";
eval {
  require Net::NISPlus;
};
if ($@) {
  print " failed\n";
  print <<EOT;
$@
The Net::NISPlus module is required for this module to work properly.
EOT
  exit;
} else {print " ok\n"}
 
WriteMakefile(
  NAME => "Apache::AuthenN2",
  VERSION_FROM => "AuthenN2.pm",
);
