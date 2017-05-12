#!/usr/local/bin/perl -w
#
# $Id: base.t,v 1.1 1997/08/12 16:02:12 mpeppler Exp $

# Base DBD Driver Test

print "1..$tests\n";

require DBI;
print "ok 1\n";

import DBI;
print "ok 2\n";

$switch = DBI->internal;
(ref $switch eq 'DBI::dr') ? print "ok 3\n" : print "not ok 3\n";

$drh = DBI->install_driver('ASAny');
(ref $drh eq 'DBI::dr') ? print "ok 4\n" : print "not ok 4\n";

print "ok 5\n" if $drh->{Version};

BEGIN { $tests = 5 }
exit 0;
# end.
