#!/usr/bin/perl -w
use strict;

#----------------------------------------------------------------------------
# TODO List

# 1. add regenrate tests
# 2. mock AWS connection and return pre-prepared report data

#----------------------------------------------------------------------------
# Libraries

use lib qw(lib);

use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use CPAN::Testers::Data::Generator;
use CPAN::Testers::Metabase::AWS;
#use Data::Dumper;
use File::Path;
use IO::File;
use JSON;
use Test::More tests => 27;

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
    skip "Test::Database required for DB testing", 23 unless($loader);

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

    is($t->_get_lastid(),33579060,'.. last id');

    #diag(Dumper($@))    if($@);

    my @test_dates = (
        [ undef, '', '' ],
        [ undef, 'xxx', '' ],
        [ undef, '', 'xxx' ],
        [ '2000-01-01T00:00:00Z', '', '2000-01-01T00:00:00Z' ],
        [ '2010-09-13T03:20:00Z', undef, '2010-09-13T03:20:00Z' ],
        [ '2013-08-18T10:22:13Z', '0cbce1be-07f0-11e3-9db1-878205732d18', '' ],
    );

    for my $test (@test_dates) {
        is($t->_get_createdate($test->[1],$test->[2]),$test->[0], ".. test date [".($test->[0]||'undef')."]"); 
    }

    is($t->already_saved('5ad79194-6cdc-1014-b4e3-38f2223f278c'),0,'.. missing metabase guid');
    is($t->already_saved('5ad79194-6cdc-1014-b4e3-38f2223f278b'),'2013-08-18T10:34:33Z','.. found metabase guid');

    is($t->retrieve_report('a58945f7-3510-11df-89c9-1bb9c3681c0d'),undef,'.. missing cpanstats guid');
    my $r = $t->retrieve_report('5ad79194-6cdc-1014-b4e3-38f2223f278b');
    is($r->{guid},'5ad79194-6cdc-1014-b4e3-38f2223f278b','.. found cpanstats guid');

    my @rows = $loader->{CPANSTATS}{dbh}->get_query('array','SELECT count(id) FROM osname');
    is($rows[0]->[0],25,'.. all OS names');

    is($t->_platform_to_osname('linux'),'linux',        '.. known OS');
    is($t->_platform_to_osname('linuxThis'),'linux',    '.. known mispelling');
    is($t->_platform_to_osname('unknown'),'',           '.. unknown OS');

    is($t->_osname('LINUX'),'Linux',                    '.. known OS fixed case');
    is($t->_osname('Unknown'),'UNKNOWN',                '.. save unknown OS');
    is($t->_platform_to_osname('unknown'),'unknown',    '.. unknown is now known OS');

    my $json;
    my $fh = IO::File->new("t/data/ad3189d0-3510-11df-89c9-1bb9c3681c0d.json") or die diag("$!");
    while(<$fh>) { $json .= $_ }
    $fh->close;

    my $text = decode_json($json);
    $t->{report}{metabase} = $text;
    $t->_check_arch_os();
    is($t->{report}{osname},'linux','.. set OS');
    is($t->{report}{platform},'i686-linux-thread-multi-64int','.. set platform');
}

my @dates = (
    [ '2014-03-22T00:00:00Z', '2014-03-22T00:00:01Z', 1     ], # regular time
    [ '2014-03-30T00:59:59Z', '2014-03-30T02:00:01Z', 3602  ], # spring forward, but still an hour and 2 seconds
    [ '2014-03-22T00:00:00Z', '2014-03-23T00:00:00Z', 86400 ], # 1 day
    [ '2014-03-22T00:00:00Z', '', -1                        ], # bad date
);

for my $dates (@dates) {
    is(CPAN::Testers::Data::Generator::_date_diff($dates->[0],$dates->[1]),$dates->[2],'returns correct time');
}