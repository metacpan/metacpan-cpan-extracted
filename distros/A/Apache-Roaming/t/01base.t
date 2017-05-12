# -*- perl -*-

print "1..2\n";

my $num = 0;
foreach my $package (qw(Apache::Roaming Apache::Roaming::LiPrefs)) {
    ++$num;
    if (eval "require $package") {
	print "ok $num\n";
    } else {
	print "not ok $num\n";
	print STDERR $@;
    }
}
