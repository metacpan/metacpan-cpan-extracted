# cleanup (no test)

print "1..1\n";

if ( opendir TD, '.' ) {
    for ( grep { /^_test_\d\d/ } readdir TD ) {
	unlink $_ or warn "Unable to delete stale testfile";
    }
    closedir TD;
}

print "ok 1\n";
