use ExtUtils::MakeMaker;

my $succeeded = 0;
my $fatal = 0;

print "\nChecking for required modules:\n\n";

eval { require Net::SSLeay };
if($@) {
  print "Net::SSLeay is installed... no\n";
} else {
  print "Net::SSLeay is installed... yes\n";
  $succeeded++;
}

eval { require DBI };
if($@) {
  print "DBI is installed... no\n";
} else {
  print "DBI is installed... yes\n";
  $succeeded++;
}

unless($succeeded == 2) {
  print "\nYou must install both Net::SSLeay and DBI\n\n";
  exit;
}
print "\n";

WriteMakefile(
'NAME' => 'Apache::AuthCAS',
'VERSION' => '0.5',
'PREREQ_PM' => { "Net::SSLeay" => 1,
                 "MIME::Base64" => 0,
                 "DBI" => 1
               },
'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
'ABSTRACT_FROM' => 'lib/Apache/AuthCAS.pm',
'AUTHOR' => 'David Castro <dcastro@apu.edu>',
);

