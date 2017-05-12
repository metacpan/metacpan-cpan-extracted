require 5.004;
use strict;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "Checking for LWP...........";
eval { require LWP; };
if ($@) {
  die "missing!  See http://www.cpan.org/modules/by-module/LWP/\n" ;
}

print "ok\n";

WriteMakefile(
    'NAME'	=> 'Apache::ReverseProxy',
    'VERSION_FROM' => 'lib/Apache/ReverseProxy.pm', # finds $VERSION
);

