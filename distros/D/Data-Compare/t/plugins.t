#!perl -w

use strict;

use Data::Compare;

print "1..1\n";

my $test = 0;

# Scalar::Properties is the only plugin we know will be present.  The plugin
# will even be present if S::P itself isn't installed.
my $plugins = Data::Compare::plugins();
my %pairs = ();
foreach my $key (keys %{$plugins}) {
    foreach(@{$plugins->{$key}}) {
        $pairs{"$key <-> $_"} = 1;
	$pairs{"$_ <-> $key"} = 1 if($key ne $_);
    }
}

print 'not ' unless($pairs{'[scalar] <-> Scalar::Properties'} && $pairs{'Scalar::Properties <-> Scalar::Properties'} && $pairs{'Scalar::Properties <-> [scalar]'});
print 'ok '.(++$test)." plugins() function\n";
