#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Addresses;
use Data::Dumper;
use File::Slurp;
use Test::More tests => 12;

my $config = 't/_DBDIR/test-config.ini';
my $output = 't/_DBDIR/output.txt';

# Test Data

my %results = (
    parsed_map => {
        'srezic@cpan.org' => {
            'testerid' => '2',
            'pause' => 'SREZIC',
            'match' => '# MAPPED ADDRESS',
            'name' => 'Slaven Rezi&#x0107;',
            'addressid' => '2'
        },
        'newtester@example.com' => {
            'testerid' => '6',
            'pause' => 'NEWTESTER',
            'match' => '# MAPPED ADDRESS',
            'name' => 'New Tester',
            'addressid' => '21'
        },
        'barbie@example.com' => {
            'testerid' => '5',
            'pause' => 'BARBIE',
            'match' => '# MAPPED ADDRESS',
            'name' => 'Barbie',
            'addressid' => '20'
        },
        'bingos@cpan.org' => {
            'testerid' => '4',
            'pause' => 'BINGOS',
            'match' => '# MAPPED ADDRESS',
            'name' => 'Chris Williams',
            'addressid' => '4'
        },
        'jj@jonallen.info ("JJ")' => {
            'testerid' => '3',
            'pause' => 'JONALLEN',
            'match' => '# MAPPED ADDRESS',
            'name' => 'Jon Allen',
            'addressid' => '3'
        },
        'kriegjcb@mi.ruhr-uni-bochum.de ((Jost Krieger))' => {
            'testerid' => '1',
            'pause' => 'JOST',
            'match' => '# MAPPED ADDRESS',
            'name' => 'Jost Krieger',
            'addressid' => '1'
        },
        'barbie@missbarbell.co.uk' => {
            'testerid' => '5',
            'pause' => 'BARBIE',
            'match' => '# MAPPED ADDRESS',
            'name' => 'Barbie',
            'addressid' => '5'
        }
    },
    stored_map => {
        'andreas.koenig.gmwojprw@franz.ak.mind.de' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '13'
        },
        'imacat@mail.imacat.idv.tw' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '11'
        },
        'stro@cpan.org' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '9'
        },
        'CPAN.DCOLLINS@comcast.net' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '14'
        },
        'Ulrich Habel <rhaen@cpan.org>' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '10'
        },
        '"Josts Smokehouse" <JOST@cpan.org>' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '8'
        },
        'kriegjcb@mi.ruhr-uni-bochum.de (Jost Krieger)' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '6'
        },
        '"Oliver Paukstadt" <cpan@sourcentral.org>' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '12'
        },
        'barbie@cpan.org' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '19'
        },
        '"JJ" <jj@jonallen.info>' => {
            'testerid' => 0,
            'pause' => '',
            'match' => '# STORED ADDRESS',
            'name' => '',
            'addressid' => '7'
        }
    },
    pause_map => {
        'jost' => {
            'testerid' => 0,
            'pause' => 'JOST',
            'match' => '# PAUSE ID',
            'name' => 'Jost Krieger',
            'addressid' => 0
        },
        'barbie' => {
            'testerid' => '5',
            'pause' => 'BARBIE',
            'match' => '# PAUSE ID',
            'name' => 'Barbie',
            'addressid' => '5'
        },
        'srezic' => {
            'testerid' => 0,
            'pause' => 'SREZIC',
            'match' => '# PAUSE ID',
            'name' => 'Slaven Rezic',
            'addressid' => 0
        },
        'jonallen' => {
            'testerid' => '3',
            'pause' => 'JONALLEN',
            'match' => '# PAUSE ID',
            'name' => 'Jon Allen',
            'addressid' => '3'
        },
        'bingos' => {
            'testerid' => 0,
            'pause' => 'BINGOS',
            'match' => '# PAUSE ID',
            'name' => 'Chris Williams',
            'addressid' => 0
        }
    },
    cpan_map => {
        'jost.krieger+pppause@ruhr-uni-bochum.de' => {
            'testerid' => 0,
            'pause' => 'JOST',
            'match' => '# CPAN EMAIL',
            'name' => 'Jost Krieger',
            'addressid' => 0
        },
        'chris@bingosnet.co.uk' => {
            'testerid' => 0,
            'pause' => 'BINGOS',
            'match' => '# CPAN EMAIL',
            'name' => 'Chris Williams',
            'addressid' => 0
        },
        'slaven@rezic.de' => {
            'testerid' => 0,
            'pause' => 'SREZIC',
            'match' => '# CPAN EMAIL',
            'name' => 'Slaven Rezic',
            'addressid' => 0
        },
        'jj@jonallen.info' => {
            'testerid' => '3',
            'pause' => 'JONALLEN',
            'match' => '# CPAN EMAIL',
            'name' => 'Jon Allen',
            'addressid' => '3'
        },
        'barbie@missbarbell.co.uk' => {
            'testerid' => '5',
            'pause' => 'BARBIE',
            'match' => '# CPAN EMAIL',
            'name' => 'Barbie',
            'addressid' => '5'
        }
    },
    address_map => {
        'srezic@cpan.org' => {
            'testerid' => '2',
            'pause' => 'SREZIC',
            'match' => '# MAPPED EMAIL',
            'name' => 'Slaven Rezi&#x0107;',
            'addressid' => '2'
        },
        'kriegjcb@mi.ruhr-uni-bochum.de' => {
            'testerid' => '1',
            'pause' => 'JOST',
            'match' => '# MAPPED EMAIL',
            'name' => 'Jost Krieger',
            'addressid' => '1'
        },
        'newtester@example.com' => {
            'testerid' => '6',
            'pause' => 'NEWTESTER',
            'match' => '# MAPPED EMAIL',
            'name' => 'New Tester',
            'addressid' => '21'
        },
        'barbie@example.com' => {
            'testerid' => '5',
            'pause' => 'BARBIE',
            'match' => '# MAPPED EMAIL',
            'name' => 'Barbie',
            'addressid' => '20'
        },
        'bingos@cpan.org' => {
            'testerid' => '4',
            'pause' => 'BINGOS',
            'match' => '# MAPPED EMAIL',
            'name' => 'Chris Williams',
            'addressid' => '4'
        },
        'jj@jonallen.info' => {
            'testerid' => '3',
            'pause' => 'JONALLEN',
            'match' => '# MAPPED EMAIL',
            'name' => 'Jon Allen',
            'addressid' => '3'
        },
        'barbie@missbarbell.co.uk' => {
            'testerid' => '5',
            'pause' => 'BARBIE',
            'match' => '# MAPPED EMAIL',
            'name' => 'Barbie',
            'addressid' => '5'
        }
    },
    unparsed_map => {
        'root@gmail.com' => {
            'email' => 'root@gmail.com',
            'testerid' => 0,
            'sort' => '',
            'fulldate' => '200901021220',
            'guid' => '02975983-b19f-3f77-b713-d32bba55d77f',
            'reportid' => '2975983',
            'addressid' => 0
        },
        'barbie@example.test' => {
            'email' => 'barbie@example.test',
            'testerid' => 0,
            'sort' => '',
            'fulldate' => '200901021220',
            'guid' => '02975981-b19f-3f77-b713-d32bba55d77f',
            'reportid' => '2975981',
            'addressid' => 0
        },
        'test@example.test' => {
            'email' => 'test@example.test',
            'testerid' => 0,
            'sort' => '',
            'fulldate' => '200901021220',
            'guid' => '02975984-b19f-3f77-b713-d32bba55d77f',
            'reportid' => '2975984',
            'addressid' => 0
        },
        'admin@example.com' => {
            'email' => 'admin@example.com',
            'testerid' => 0,
            'sort' => '',
            'fulldate' => '200901021220',
            'guid' => '02975982-b19f-3f77-b713-d32bba55d77f',
            'reportid' => '2975982',
            'addressid' => 0
        }
    },
    unparsed_map_result => {
        'root@gmail.com' => {
            'email' => 'root@gmail.com',
            'testerid' => 0,
            'sort' => '',
            'fulldate' => '200901021220',
            'guid' => '02975983-b19f-3f77-b713-d32bba55d77f',
            'reportid' => '2975983',
            'addressid' => 0
        },
        'barbie@example.test' => {
            'email' => 'barbie@example.test',
            'testerid' => 0,
            'sort' => '',
            'fulldate' => '200901021220',
            'guid' => '02975981-b19f-3f77-b713-d32bba55d77f',
            'reportid' => '2975981',
            'addressid' => 0
        },
        'test@example.test' => {
            'email' => 'test@example.test',
            'testerid' => 0,
            'sort' => '',
            'fulldate' => '200901021220',
            'guid' => '02975984-b19f-3f77-b713-d32bba55d77f',
            'reportid' => '2975984',
            'addressid' => 0
        },
        'admin@example.com' => {
            'email' => 'admin@example.com',
            'sort' => '',
            'fulldate' => '200901021220',
            'guid' => '02975982-b19f-3f77-b713-d32bba55d77f',
            'reportid' => '2975982',
            'addressid' => 0,
            'testerid' => 6,
            'match' => '# MAPPED DOMAIN - example.com',
            'name' => 'New Tester',
            'pause' => 'NEWTESTER'
        }
    }
);

my @data = (
    '2975981,02975981-b19f-3f77-b713-d32bba55d77f,200901021220,200901,pass,barbie@example.test',
    '2975982,02975982-b19f-3f77-b713-d32bba55d77f,200901021220,200901,pass,admin@example.com',
    '2975983,02975983-b19f-3f77-b713-d32bba55d77f,200901021220,200901,pass,root@gmail.com',
    '2975984,02975984-b19f-3f77-b713-d32bba55d77f,200901021220,200901,pass,test@example.test',
);

SKIP: {
    skip "Unable to locate config file [$config]", 12   unless(-f $config);

    ### Prepare object
    my $obj;
    unlink($output)  if(-f $output);
    ok( $obj = CPAN::Testers::Data::Addresses->new(config => $config, output => $output), "got object" );

    # Load test data

    my $dbh = $obj->dbh;
    for my $data (@data) {
        my @items = split(',',$data);
        $dbh->do_query('insert into cpanstats (id,guid,fulldate,postdate,state,type,tester) VALUES (?,?,?,?,?,2,?)',@items);
    }

    ### Test Underlying Process Methods

    $obj->load_addresses;
    is_deeply( $obj->{$_}, $results{$_}, ".. load - $_") for(qw(parsed_map stored_map pause_map cpan_map address_map unparsed_map));
    #diag("$_:" . Dumper($obj->{$_}))    for(qw(parsed_map stored_map pause_map cpan_map address_map unparsed_map));
    #diag("$_:" . Dumper($obj->{$_}))    for(qw(unparsed_map));

    $obj->match_addresses;
    is_deeply( $obj->{result}{NOEMAIL}, undef, '.. load - NOEMAIL');

    #diag("$_:" . Dumper($obj->{$_}))    for(qw(unparsed_map));
    is_deeply( $obj->{unparsed_map}, $results{unparsed_map_result}, ".. unparsed matches");

    $obj->print_addresses;
    $obj = undef;

    my $text = read_file($output);
    unlike($text, qr/ERRORS:/, '.. found no errors');
    like($text, qr/MATCH:/,    '.. found matches');
    like($text, qr/PATTERNS:/, '.. found patterns');
}
