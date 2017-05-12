#!perl -w

$| = 1;

print "1..$::tests\n";

# BEGIN { $Exporter::Verbose=1 }
use strict;
use DBD::Solid::Const qw(:sql_types);

print "not " unless (SQL_INTEGER > 0);
print "ok 1\n";

BEGIN { $::tests=1; }
