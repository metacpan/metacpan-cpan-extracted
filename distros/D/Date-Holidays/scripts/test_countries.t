# $Id: test_countries.t 1615 2005-12-18 15:18:34Z jonasbn $

use strict;
use Date::Holidays;
use Locale::Country;
use Test::More qw(no_plan);
use Env qw($TEST_VERBOSE);

my @countrycodes = all_country_codes();
my ( $ok, $nok ) = ( 0, 0 );
my ( $t, @ok_countries, @nok_countries );

foreach my $cc (@countrycodes) {

    print STDERR "\n[$t]: Testing country code: $cc\n" if $TEST_VERBOSE;
    my $dh = Date::Holidays->new( countrycode => $cc, );

    if ( $dh->{'_inner_object'} ) {
        $ok++;
        push @ok_countries, $cc;
    }
    else {
        $nok++;
        push @nok_countries, $cc;
    }
}

print STDERR "Countries represented: $ok\n";
print STDERR "Countries not represented: $nok\n";
print STDERR "Countries in total (from Locale::Country): "
    . scalar @countrycodes . "\n";

print STDERR "Countries missing:\n";
foreach my $cc ( sort @nok_countries ) {
    print STDERR code2country($cc) . "\n";
}
