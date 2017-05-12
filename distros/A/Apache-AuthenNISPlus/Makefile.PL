use ExtUtils::MakeMaker;

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
  NAME => "Apache::AuthenNISPlus",
  VERSION_FROM => "AuthenNISPlus.pm",
);
