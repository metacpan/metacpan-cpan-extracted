# $Id: test_countries.t 1615 2005-12-18 15:18:34Z jonasbn $

use strict;
use Date::Holidays;
use Locale::Country;
use Test::More qw(no_plan);

my @countrycodes = all_country_codes();
my ($ok, $nok, $t, $verbose, @ok_countries, @nok_countries);

foreach my $cc (@countrycodes) {

	print STDERR "\n[$t]: Testing country code: $cc\n" if $verbose;
	my $dh = Date::Holidays->new(
		countrycode => $cc,
	);
	
	if ($dh->{'_inner_object'}) {
		$ok++;
		push @ok_countries, $cc;
	} else {
		$nok++;
		push @nok_countries, $cc;
	}
}

print "Countries represented: $ok\n";
print "Countries not represented: $nok\n";
print "Countries in total (from Locale::Country): ".scalar @countrycodes."\n";

print "Countries missing:\n";
foreach my $cc (@nok_countries) {
	print code2country($cc)."\n";
}