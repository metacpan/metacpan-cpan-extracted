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
use Test::More tests => 9;

use lib qw(t/lib);
use Fake::Loader;

#----------------------------------------------------------------------------
# Test Variables

my $config = 't/_DBDIR/test-config.ini';

my $loader = Fake::Loader->new();

#----------------------------------------------------------------------------
# Test Main

# TEST INTERNALS

SKIP: {
    skip "Test::Database required for DB testing", 9 unless($loader);

    # prep test directory
    my $directory = './test';
    rmtree($directory);
    mkpath($directory) or die "cannot create directory";

    is($loader->count_cpanstats(),6,'Internal Tests, cpanstats contains 6 reports');
    is($loader->count_metabase(),6,'Internal Tests, metabase contains 6 reports');

    my $t;
    eval {
        $t = CPAN::Testers::Data::Generator->new(
            config      => $config,
            logfile     => $directory . '/cpanstats.log'
        );
    };

    SKIP: {
        skip "AWS profile required for live testing", 7 unless($t);

        isa_ok($t,'CPAN::Testers::Data::Generator');

        #diag(Dumper($@))    if($@);

        my $res = $t->parse({guid => '040b46fe-ab70-11e3-add5-ed1d4a243164'});
        is($res,1,'..parsed report');

        $t->{CPANSTATS}->do_commit;
        $t->{METABASE}->do_commit;

        is($loader->count_cpanstats(),7,'Internal Tests, cpanstats contains 7 reports');
        is($loader->count_metabase(),7,'Internal Tests, metabase contains 7 reports');

        my $fact = $t->load_fact('040b46fe-ab70-11e3-add5-ed1d4a243164');
        #diag(Dumper($fact));
        is($fact->{'CPAN::Testers::Fact::LegacyReport'}{metadata}{core}{guid},'040b5e32-ab70-11e3-add5-ed1d4a243164','.. got LegacyReport fact');
        is($fact->{'CPAN::Testers::Fact::TestSummary'}{metadata}{core}{guid},'040b72f0-ab70-11e3-add5-ed1d4a243164','.. got TestSummary fact');
        is($fact->{'CPAN::Testers::Fact::TestSummary'}{content}{archname},'amd64-netbsd-thread-multi','.. got TestSummary fact content');
    }
}
