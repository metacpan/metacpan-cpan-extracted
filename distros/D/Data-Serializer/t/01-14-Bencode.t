use lib "./t";             # to pick up a ExtUtils::TBone


require "./t/serializer-testlib";

use Data::Serializer; 

use ExtUtils::TBone;

my $T = typical ExtUtils::TBone;                 # standard log


	
my @serializers;

foreach my $serializer (qw(Bencode)) {
	if (eval "require $serializer") {
		$T->msg("Found serializer $serializer");  
		push(@serializers, $serializer);
	} else {
		$T->msg("Serializer $serializer not found") unless (@serializers);
	}
}
unless (@serializers) {
        $T->begin('0 # Skipped:  Bencode not installed');
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

