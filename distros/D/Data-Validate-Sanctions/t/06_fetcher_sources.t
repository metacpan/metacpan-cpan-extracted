use strict;
use warnings;

use Data::Validate::Sanctions::Fetcher;
use Test::More;
use Test::Warnings;
use Test::Warn;

subtest 'Fetch and process all sources from default urls' => sub {
    # EU sanctions cannot be tested without a tooken; let's skip it
    my $data = Data::Validate::Sanctions::Fetcher::run(
        # EU sanctions need a token. Sample data should be used here to avoid failure.
        eu_url => "file://t/data/sample_eu.xml",
        # the default HMT url takes too long to download. Let's use sample data to speed it up
        hmt_url  => "file://t/data/sample_hmt.csv",
        unsc_url => "file://t/data/sample_unsc.xml",
        handler  => sub { },
    );

    is_deeply [sort keys %$data], [qw(EU-Sanctions HMT-Sanctions MOHA-Sanctions OFAC-Consolidated OFAC-SDN UNSC-Sanctions)],
        'sanction source list is correct';

    cmp_ok($data->{'EU-Sanctions'}{updated}, '>=', 1541376000, "Fetcher::run HMT-Sanctions sanctions.yml");

    cmp_ok($data->{'HMT-Sanctions'}{updated}, '>=', 1541376000, "Fetcher::run HMT-Sanctions sanctions.yml");

    cmp_ok($data->{'MOHA-Sanctions'}{updated}, '>=', 1725846735, "Fetcher::run MOHA-Sanctions sanctions.yml");

    cmp_ok($data->{'OFAC-SDN'}{updated}, '>=', 1541376000, "Fetcher::run OFAC-SDN sanctions.yml");

    cmp_ok($data->{'OFAC-Consolidated'}{updated}, '>=', 1541376000, "Fetcher::run OFAC-Consolidated sanctions.yml");

    cmp_ok($data->{'UNSC-Sanctions'}{updated}, '>=', 1541376000, "Fetcher::run HMT-Sanctions sanctions.yml");

    cmp_ok(scalar $data->{'HMT-Sanctions'}{'content'}->@*, '==', 23, "HMT-Sanctions namelist - sample file");
};

done_testing;
