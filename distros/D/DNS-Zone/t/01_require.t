#!/usr/local/bin/perl -w

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

print "1..5\n";

require DNS::Zone;
print "ok 1\n";

require DNS::Zone::Label;
print "ok 2\n";

require DNS::Zone::Record;
print "ok 3\n";

require DNS::Zone::File;
print "ok 4\n";

require DNS::Zone::File::Default;
print "ok 5\n";
