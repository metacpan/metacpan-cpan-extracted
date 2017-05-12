use strict;
use warnings;
use Crypt::Dining;

my $message = undef;
if ($ARGV[0] !~ /^[0-9\/]$/) {
	$message = shift @ARGV;
}

my $dc = new Crypt::Dining(
	# LocalAddr	=> '192.168.3.16',
	Peers		=> \@ARGV,
);

$dc->round($message);
