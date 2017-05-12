#!perl -w

use Data::Compare ();
print "1..1\n";

my $test = 0;

# in no-import mode there should be no plugins

print "not " unless(Data::Compare::Compare({}, Data::Compare::plugins()));
print 'ok '.(++$test)." plugins disabled in no-import mode\n";
