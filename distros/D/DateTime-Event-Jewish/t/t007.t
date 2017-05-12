
=head1 NAME

t005.pl	- Check for typos in Eqt.pm

=head1 DESCRIPTION

Check for typos in Eqt.pm


=cut

use strict;
use warnings;
use Test::More tests => 366;
use FindBin qw($Bin);
use lib qq($Bin/../lib);

use DateTime::Event::Jewish::Eqt qw(%eqt);


foreach my $m (keys %eqt) {
    print "$m\n";
    my $day = 0;
    foreach my $d (@{$eqt{$m}}) {
	$day++;
        like($d , qr/^-?[0-9]?[0-9]:[0-9]?[0-9]$/,
	    sprintf("%d %s '%s'\n", $day, $m, $d));
    }

}
exit 0;

