use strict;
use warnings;


use Perl::Critic;
use Carp;

my ($file, $profile) = @ARGV;
die "Usage: $0 FILE  INI_FILE" if not $file;

my %args;
if ($profile) {
	$args{'-profile'} = $profile;
} else {
	$args{'-severity'} = 4;
}
my $pc = Perl::Critic->new( %args );
my @violations = $pc->critique( $file );
foreach my $v (@violations) {
	print "=============================\n";
	foreach my $f (qw(policy description explanation
			line_number logical_line_number 
			column_number visual_column_number 
			diagnostics)) {
		print "$f: " . $v->$f . "\n";
	}
	
	print "-------------------------\n";
	# Perl::Critic::Policy::ErrorHandling::RequireUseOfExceptions
	my $policy = substr($v->policy, 22);
	print "Policy: $policy\n";
}

print "DONE\n";