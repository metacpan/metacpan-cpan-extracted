# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Long-Filenames.t'

use File::Spec;

BEGIN { $| = 1; print "1..1\n"; }

$test=1;
if (! open FILETEST, "looOoo_oooooo-123ngfiletESt" ) { bail() }
elsif (File::Spec->case_tolerant())
{
    warn "Your system does not differentiate between upper and lowercase\n";
    warn "filenames.  This severely limits the number of unique 27 character\n";
    warn "filenames from 2^162 to 2^141.\n";
    print "ok $test\n";
}
else { close FILETEST; print "ok $test\n"; }


sub bail {
    print "Bail out! Long filename support (27 chars or greater) is required for CGI::SecureState.\n";
}
