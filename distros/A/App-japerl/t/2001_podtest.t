######################################################################
#
# 2001_podtest.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

eval q{ use Test::Pod 1.48 tests => 2; };
if ($@) {
    print "1..2\n";
    print "ok 1 - SKIP\n";
    print "ok 2 - SKIP\n";
}
else {
    pod_file_ok('lib/App/japerl.pm');
    pod_file_ok('bin/japerl.bat');
}

__END__
