#!/usr/bin/perl -w
use strict;

#----------------------------------------------------------------------------
# TODO List

# 1. add other fact related tests

#----------------------------------------------------------------------------
# Libraries

use lib qw(lib);

use CPAN::Testers::Data::Generator;
use Data::Dumper;
use File::Path;
use IO::File;
use Metabase::Resource;
use Metabase::Resource::cpan::distfile;
use Metabase::Resource::metabase::user;
use Test::More tests => 22;

use lib qw(t/lib);
use Fake::Loader;

#----------------------------------------------------------------------------
# Test Variables

my $config = 't/_DBDIR/test-config.ini';

my $loader = Fake::Loader->new();

my @guids = (
    '045384d2-ab70-11e3-ae04-8631d666d1b8',
    '0505ba3a-ab70-11e3-ae04-8631d666d1b8',
    '0de43550-ab70-11e3-ae04-8631d666d1b8',
    '1012fdc0-ab70-11e3-ae04-8631d666d1b8',
    '102d0864-ab70-11e3-ae04-8631d666d1b8',
    '123e7a20-ab70-11e3-ae04-8631d666d1b8',
    '12ab2a3a-ab70-11e3-ae04-8631d666d1b8',
    '157be678-ab70-11e3-add5-ed1d4a243164',
    '1902898c-ab70-11e3-ae04-8631d666d1b8'
);

#----------------------------------------------------------------------------
# Test Main

# TEST INTERNALS

SKIP: {
    skip "Test::Database required for DB testing", 22 unless($loader);

    # prep test directory
    my $directory = './test';
    rmtree($directory);
    mkpath($directory) or die "cannot create directory";

    my $t;
    eval {
        $t = CPAN::Testers::Data::Generator->new(
            config      => $config,
            logfile     => $directory . '/cpanstats.log',
            poll_limit  => 10
        );
    };

    SKIP: {
        skip "AWS profile required for live testing", 22 unless($t);

        isa_ok($t,'CPAN::Testers::Data::Generator');

        # load 10 know guids
        for my $guid (@guids) {
            my $res = $t->parse({guid => $guid});
            is($res,1,'..parsed report');
        }

        is($loader->count_cpanstats(),16,'Internal Tests, cpanstats contains 16 reports');
        is($loader->count_metabase(),7,'Internal Tests, metabase contains 7 reports');

        #diag(Dumper($@))    if($@);

        $t->generate(1,'2014-03-14T12:00:00Z'); # run non-stop

        $t->{CPANSTATS}->do_commit;
        $t->{METABASE}->do_commit;

        is($loader->count_cpanstats(),18,'Internal Tests, cpanstats contains 18 reports');
        is($loader->count_metabase(),18,'Internal Tests, metabase contains 18 reports');

        $t->regenerate({
            dstart      => '2014-03-14T11:58:54Z',
            dend        => '2014-03-14T11:59:54Z'
        });

        $t->{CPANSTATS}->do_commit;
        $t->{METABASE}->do_commit;

        is($loader->count_cpanstats(),18,'Internal Tests, cpanstats contains 18 reports');
        is($loader->count_metabase(),18,'Internal Tests, metabase contains 18 reports');

        $t->rebuild({
            localonly   => 1,
            dstart      => '2014-03-14T11:58:54Z',
            dend        => '2014-03-14T11:59:54Z'
        });

        $t->{CPANSTATS}->do_commit;
        $t->{METABASE}->do_commit;

        is($loader->count_cpanstats(),18,'Internal Tests, cpanstats contains 18 reports');
        is($loader->count_metabase(),18,'Internal Tests, metabase contains 18 reports');

        $t->regenerate({
            file        => 't/data/regenerate.txt'
        });

        $t->{CPANSTATS}->do_commit;
        $t->{METABASE}->do_commit;

        is($loader->count_cpanstats(),18,'Internal Tests, cpanstats contains 18 reports');
        is($loader->count_metabase(),18,'Internal Tests, metabase contains 18 reports');

        $t->regenerate({
            file        => 't/data/regenerate2.txt'
        });

        $t->{CPANSTATS}->do_commit;
        $t->{METABASE}->do_commit;

        is($loader->count_cpanstats(),18,'Internal Tests, cpanstats contains 18 reports');
        is($loader->count_metabase(),18,'Internal Tests, metabase contains 18 reports');
    }
}
