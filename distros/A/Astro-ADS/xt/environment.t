use Test2::V0;

use lib qw|t/lib|;
use Test::Astro::ADS;

use Astro::ADS::Metrics;

my $metrics = Astro::ADS::Metrics->new();

# checks that the ADS_DEV_KEY is set by the test suite and
# not the author's environment
# local $ENV{HOME} = '/homeless';
is $metrics->token, 'A_very_long_string_to_use_as_a_dev_key',
    'Using ADS_DEV_KEY set in Test::Astro::ADS'
    or warn << 'FACEPALM';
####
Picking up ADS_DEV_KEY from own environment
Will FAIL in CPANTS
####
FACEPALM

todo "Shouldn't release with debugging turned on" => sub {
    use Astro::ADS;
    is $Astro::ADS::DEBUG, 0, 'DEBUG flag is turned off';
};

done_testing();
