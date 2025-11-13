package Test::Astro::ADS;

my $mocked_dev_key = 'A_very_long_string_to_use_as_a_dev_key';

# can't mock the _build_token method, so set the env variable
# for playback only (needs a valid key for ADS access)
$ENV{ADS_DEV_KEY} = $mocked_dev_key
    unless $ENV{LWP_UA_MOCK} eq 'record'
        || $ENV{LWP_UA_MOCK} eq 'passthrough';

1;
