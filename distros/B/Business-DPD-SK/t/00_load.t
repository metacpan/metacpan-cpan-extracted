use strict;
use warnings;

use Test::More;
use File::Spec;

use_ok('Business::DPD::SK');
use_ok('Business::DPD::SK::SPc');
use_ok('Business::DPD::SK::API');

like(Business::DPD::SK->VERSION, qr/^\d+\.\d+/, 'distribution has a version');

subtest 'checkout paths point into the distribution' => sub {
    my $ini = File::Spec->catfile(Business::DPD::SK::SPc->sysconfdir, 'dpd-sk', 'geordb.ini');
    ok(-f $ini, 'geordb.ini found via sysconfdir');
    is(Business::DPD::SK::API->new->base_url, 'https://capi.dpd.sk/shipment/json',
        'shipped api.ini found via sysconfdir and selects the test endpoint');
    my $state = File::Spec->catdir(Business::DPD::SK::SPc->sharedstatedir, 'dpd-sk');
    ok(-d $state, 'dpd-sk state directory found via sharedstatedir');
};

done_testing();
