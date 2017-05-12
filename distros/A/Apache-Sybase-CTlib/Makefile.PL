use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
$| = 1;
my $missing_modules = 0;
 
print "Checking for Sybase::CTlib...";
eval {
    require Sybase::CTlib;
    Sybase::CTlib->require_version('2.09');
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
SybPerl is required...
 
EOT
    sleep(2);  
} else {
    print " ok\n";
}

print "Checking for ModPerl...";
eval {
    use Apache2 ();
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
ModPerl2 is required...
 
EOT
    sleep(2);  
} else {
    print " ok\n";
}

WriteMakefile(
    'NAME'	=> 'Apache::Sybase::CTlib2',
    'VERSION_FROM' => 'CTlib2.pm', # finds $VERSION
);
