# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-WebMoney.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('Business::WebMoney::Exchanger') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $wmex = Business::WebMoney::Exchanger->new;

ok($wmex, 'constructor');

my $rates = $wmex->best_rates(
	debug_response => '<response><row Direct="WMZ - WMR" BaseRate="+27.5199" Plus01="0" Plus02="0" Plus03="0" Plus04="0" Plus05="0" Plus06="0" Plus07="0" Plus08="0" Plus09="0" Plus1="0" Plus2="78484.08" Plus3="109620.34" Plus5="157975.9" Plus10="378769.89" exchtype="1"/><row Direct="WMR - WMZ" BaseRate="-27.5199" Plus01="15320328.11" Plus02="15321328.11" Plus03="15322911.95" Plus04="15322911.95" Plus05="15323522.96" Plus06="15324482.52" Plus07="15324482.52" Plus08="15327212.52" Plus09="15327212.52" Plus1="15327212.52" Plus2="15420329.3" Plus3="15421603.85" Plus5="15462175.05" Plus10="15493296.32" exchtype="2"/></response>',
) or die $wmex->errstr;

ok($rates->{WMZ});
ok($rates->{WMZ}->{WMR});
cmp_ok($rates->{WMZ}->{WMR}->{rate}, '==', 27.5199);
cmp_ok($rates->{WMZ}->{WMR}->{0.5}, '==', 0);
cmp_ok($rates->{WMZ}->{WMR}->{3}, '==', 109620.34);

ok($rates->{WMR});
ok($rates->{WMR}->{WMZ});
cmp_ok($rates->{WMR}->{WMZ}->{rate}, '==', 1/27.5199);
cmp_ok($rates->{WMR}->{WMZ}->{0.5}, '==', 15323522.96);
cmp_ok($rates->{WMR}->{WMZ}->{3}, '==', 15421603.85);

