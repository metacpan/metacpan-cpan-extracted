#!/usr/bin/perl
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

local $SIG{__WARN__} = sub {1};

print "1..3\n";

print "not " unless eval { require Acme::Hello };
print "ok 1 # require Acme::Hello\n";

Acme::Hello->import;
print "not " unless eval { hello() };
print "ok 2 # procedural interface\n";

print "not " unless eval { Acme::Hello->new->hello };
print "ok 3 # object-oriented interface\n";
