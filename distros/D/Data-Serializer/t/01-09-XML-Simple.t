use lib "./t";             # to pick up a ExtUtils::TBone


require "./t/serializer-testlib";

use Data::Serializer; 

use ExtUtils::TBone;

my $T = typical ExtUtils::TBone;                 # standard log


	
my @serializers;

foreach my $serializer (qw(XML::Simple)) {
	if (eval "require $serializer") {
		$T->msg("Found serializer $serializer");  
		push(@serializers, $serializer);
	} else {
		$T->msg("Serializer $serializer not found") unless (@serializers);
	}
}

#
# XML::Simple has an internal dependency of either XML::SAX or XML::Parser, so we need to test for those
# too, and if we don't find them, act like XML::Simple is not installed
#
if (grep {/^XML::Simple$/} @serializers) {
	if (eval "require XML::SAX") {
		$T->msg("Found XML::SAX to support XML::Simple");  
	} elsif (eval "require XML::Parser") {
		$T->msg("Found XML::Parser to support XML::Simple");  
	} else {
		$T->msg("Could not find XML::Parser or XML::SAX, removing XML::Simple") unless (@serializers);
		@serializers = grep {!/^XML::Simple$/} @serializers;
	}
}

unless (@serializers) {
        $T->begin('0 # Skipped:  XML::Simple not installed');
        exit;
}



my @types = qw(basic);

find_features($T,@types);


my %tests;
my $testcount;


foreach my $serializer (@serializers) {
	while (my ($test,$value) = each %{$serializers{$serializer}}) {
		next unless $value;
		foreach my $type (@types) {
			next unless $found_type{$type}; 
 	  		$testcount += $value;
                }
        }
}
$T->begin($testcount);
$T->msg("Begin Testing for @types");  # message for the log

foreach my $serializer (@serializers) {
	while (my ($test,$value) = each %{$serializers{$serializer}}) {
		next unless $value;
		foreach my $type (@types) {
			next unless $found_type{$type}; 
                	run_test($T,$serializer,$test,$type);
                }
        }
}

