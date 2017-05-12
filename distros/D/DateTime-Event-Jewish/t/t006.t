
=head1 NAME

t005.pl	- Check for typos n Declination.pm

=head1 DESCRIPTION

check for typos in Declination.pm


=cut

use strict;
use warnings;
use Test::More tests => 366;
use FindBin qw($Bin);
use lib qq($Bin/../lib);

use DateTime::Event::Jewish::Declination qw(%Declination);

my $day	= 16;


foreach my $m (keys %Declination) {
    print "$m\n";
    my $day = 0;
    foreach my $d (@{$Declination{$m}}) {
	$day++;
        like($d , qr/^-?[0-9]?[0-9]:[0-9]?[0-9]$/,
	    sprintf("%d %s '%s'\n", $day, $m, $d));
    }

}
exit 0;

