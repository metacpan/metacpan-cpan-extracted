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
use Test::More tests => 21;

use lib qw(t/lib);
use Fake::Librarian;
use Fake::Loader;

#----------------------------------------------------------------------------
# Test Variables

my $config = 't/_DBDIR/test-config.ini';

my $loader = Fake::Loader->new();

#----------------------------------------------------------------------------
# Test Main

# TEST INTERNALS

SKIP: {
    skip "Test::Database required for DB testing", 21 unless($loader);

    # prep test directory
    my $directory = './test';
    rmtree($directory);
    mkpath($directory) or die "cannot create directory";

    is($loader->count_cpanstats(),5,'Internal Tests, cpanstats contains 5 reports');
    is($loader->count_metabase(),5,'Internal Tests, metabase contains 5 reports');

    my $t;
    eval {
        $t = CPAN::Testers::Data::Generator->new(
            config      => $config,
            logfile     => $directory . '/cpanstats.log',
            localonly   => 1
        );
    };

    isa_ok($t,'CPAN::Testers::Data::Generator');

    #diag(Dumper($@))    if($@);

    my $fact = $t->load_fact('0cbce1be-07f0-11e3-9db1-878205732d18');
    is($fact->{'CPAN::Testers::Fact::LegacyReport'}{metadata}{core}{guid},'0cbd57fc-07f0-11e3-9db1-878205732d18','.. got LegacyReport fact');
    is($fact->{'CPAN::Testers::Fact::TestSummary'}{metadata}{core}{guid},'0cbd723c-07f0-11e3-9db1-878205732d18','.. got TestSummary fact');

    $t->{librarian} = Fake::Librarian->new;

    $fact = $t->get_fact('4f976d00-08d2-11e3-bc0a-b75d6d822b3f');
    isa_ok($fact,'CPAN::Testers::Report');
    #diag(Dumper($fact));
    my @facts = $fact->facts;

    my $report = $t->dereference_report($fact);

    #diag("report=".Dumper($report));

    is($report->{'CPAN::Testers::Fact::LegacyReport'}{metadata}{core}{guid},'4f977e8a-08d2-11e3-bc0a-b75d6d822b3f','.. got LegacyReport fact');
    is($report->{'CPAN::Testers::Fact::TestSummary'}{metadata}{core}{guid},'4f9786b4-08d2-11e3-bc0a-b75d6d822b3f','.. got TestSummary fact');
    is($report->{'CPAN::Testers::Fact::TestSummary'}{content}{archname},'x86_64-linux-gnu-thread-multi','.. got TestSummary fact content');

    $t->{report}{guid} = '4f976d00-08d2-11e3-bc0a-b75d6d822b3f';

    my $res = $t->parse_report(report => $fact);
    is($res,0,'..parsed report');

    is($t->{report}{metabase}->{'CPAN::Testers::Fact::LegacyReport'}{metadata}{core}{guid},'4f977e8a-08d2-11e3-bc0a-b75d6d822b3f','.. got LegacyReport fact');
    is($t->{report}{metabase}->{'CPAN::Testers::Fact::TestSummary'}{metadata}{core}{guid},'4f9786b4-08d2-11e3-bc0a-b75d6d822b3f','.. got TestSummary fact');
    is($t->{report}{metabase}->{'CPAN::Testers::Fact::TestSummary'}{content}{archname},'x86_64-linux-gnu-thread-multi','.. got TestSummary fact content');


    $res = $t->store_report();
    is($res,1,'..stored cpanstats report');
    $res = $t->store_report();
    is($res,0,'..already stored cpanstats report');

    #diag(Dumper($t->{report}{metabase}{'CPAN::Testers::Fact::TestSummary'}{content}));

    $res = $t->cache_report();
    is($res,1,'..stored metabase report');

    $t->{CPANSTATS}->do_commit;
    $t->{METABASE}->do_commit;

    is($loader->count_cpanstats(),6,'Internal Tests, cpanstats contains 6 reports');
    is($loader->count_metabase(),6,'Internal Tests, metabase contains 6 reports');

    $fact = $t->load_fact('4f976d00-08d2-11e3-bc0a-b75d6d822b3f');
    is($fact->{'CPAN::Testers::Fact::LegacyReport'}{metadata}{core}{guid},'4f977e8a-08d2-11e3-bc0a-b75d6d822b3f','.. got LegacyReport fact');
    is($fact->{'CPAN::Testers::Fact::TestSummary'}{metadata}{core}{guid},'4f9786b4-08d2-11e3-bc0a-b75d6d822b3f','.. got TestSummary fact');
    is($fact->{'CPAN::Testers::Fact::TestSummary'}{content}{archname},'x86_64-linux-gnu-thread-multi','.. got TestSummary fact content');
}
