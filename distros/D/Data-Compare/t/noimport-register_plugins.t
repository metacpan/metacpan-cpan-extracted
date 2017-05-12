#!perl -w

use Data::Compare ();
Data::Compare->register_plugins();

print "1..1\n";

my $test = 0;

# and now there should be plugins

print "not " if(Data::Compare::Compare({}, Data::Compare::plugins()));
print 'ok '.(++$test)." plugins available in no-import mode if explicitly asked for\n";
