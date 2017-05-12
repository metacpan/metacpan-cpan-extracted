use strict;

print "1..1\n";
eval "use Crypt::SHAVS";
print "not " if $@;
print "ok 1\n";
