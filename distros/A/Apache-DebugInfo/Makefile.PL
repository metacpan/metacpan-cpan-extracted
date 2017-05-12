use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "\nChecking mod_perl version dependencies...\n";
eval {
    require mod_perl;
    die if $mod_perl::VERSION < 1.2401;
};
if ($@) {
  print "\n\n\tWhoops!  Apache::DebugInfo requires mod_perl 1.2401,
\tbut you are only running mod_perl $mod_perl::VERSION.  An upgrade
\tis in order to avoid undesirable (and unsupported)
\tside-effects...\n
\tPlease upgrade.\n
\tPlease see the README for module and hook dependencies.\n\n";
} else {
  print "\nAcceptable mod_perl version found.  Good...
\tPlease see the README for module and hook dependencies.\n\n";
}

WriteMakefile(
    'NAME'	   => 'Apache::DebugInfo',
    'VERSION_FROM' => 'DebugInfo.pm', # finds $VERSION
    'PREREQ_PM'    => { mod_perl => 1.2401, },
);
