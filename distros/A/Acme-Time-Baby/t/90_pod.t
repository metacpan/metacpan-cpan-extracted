# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN {
    if ($] eq '5.009005') {
        print "1..1\n";
        print "# This is for silly CPAN testers running 5.9.5.\n";
        print "ok 1\n";
        exit;
    }
}

use strict;
use warnings;
no  warnings 'syntax';

use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok ();

__END__
