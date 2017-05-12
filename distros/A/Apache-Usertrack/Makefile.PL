use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# 'Check for modules' code borrowed from Apache::ASP

@mods = (
         'Apache',
         'Time::HiRes'
         );
 
print "Checking for the prerequisite modules.\n";
my($errors);
for(@mods) {
    eval 'require ' . $_ ;
    if($@) {
        $errors++;
        print " !!! you need the module: $_\n";
    } else {
        print " - found $_\n";
    }
}

#if($errors) {
#    print "\n";
#    print "If you need a module, please download and install it from CPAN.\n";
#    print "Exiting now because of errors!\n";
#    print "\n";
#    exit;
#} else {
#    print "Looks good!\n";
#}
  
WriteMakefile(
    'NAME'	=> 'Apache::Usertrack',
    'VERSION_FROM' => 'Usertrack.pm',
    'PREREQ_PM'    => { 'Time::HiRes'    => 0,
                      },
);
