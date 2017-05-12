use ExtUtils::MakeMaker;

my $succeeded = 0;
my $fatal = 0;

print "\nChecking for required modules:\n\n";

eval { require LWP::UserAgent };
if($@) {
  print "LWP::UserAgent is installed... no\n";
} else {
  print "LWP::UserAgent is installed... yes\n";
  $succeeded++;
}

eval { require XML::EasyOBJ };
if($@) {
  print "XML::EasyOBJ is installed... no\n";
} else {
  print "XML::EasyOBJ is installed... yes\n";
  $succeeded++;
}

unless($succeeded == 2) {
  print "\nYou must install both LWP::UserAgent and XML::EasyOBJ\n\n";
  exit;
}
print "\n";

WriteMakefile(
'NAME' => 'Apache::FilteringProxy',
'VERSION_FROM' => 'lib/Apache/FilteringProxy.pm',
'PREREQ_PM' => { LWP::UserAgent => 0,
                 XML::EasyOBJ => 0
			   },
'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
'ABSTRACT_FROM' => 'lib/Apache/FilteringProxy.pm',
'AUTHOR' => 'David Castro <dcastro@apu.edu>',
);

