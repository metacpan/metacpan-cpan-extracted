#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Addresses;
use Test::More tests => 56;

my $config = 't/_DBDIR/test-config.ini';


### Email Extraction Tests

my @addresses = (
#[ '', '' ],
[ 'kriegjcb@mi.ruhr-uni-bochum.de ((Jost Krieger))', 'kriegjcb@mi.ruhr-uni-bochum.de' ],
[ 'srezic@cpan.org', 'srezic@cpan.org' ],
[ 'jj@jonallen.info ("JJ")', 'jj@jonallen.info' ],
[ 'bingos@cpan.org', 'bingos@cpan.org' ],
);

for(@addresses) {
    is( CPAN::Testers::Data::Addresses::_extract_email($_->[0]), $_->[1], "... checking $_->[0]" );
}


SKIP: {
    skip "Unable to locate config file [$config]", 52   unless(-f $config);

    ### Prepare object

    ok( my $obj = CPAN::Testers::Data::Addresses->new(config => $config), "got object" );
    $obj->{filters} = [
        'us.ibm.com',
        'shaw.ca',
        'ath.cx',
        '(rambler|mail)\.de',
        '(nasa|nih)\.gov',
        '(net|org|com)\.(br|au|tw)',
        '(co|org)\.uk',
        '\w+\.edu',
        '(ac|edu)\.(uk|jp|at|tw)',
        'cpan\.org'
    ];


    ### Tester Mapping Tests

    my %results = (
        'barbie@missbarbell.co.uk (Barbie)' => {
            'result'    => 1,
            'testerid'  => 4,
            'addressid' => 4,
            'match'     => '# MAPPED EMAIL'
        },
        'barbie@missbarbell.co.uk' => {
            'result'    => 1,
            'testerid'  => 2,
            'addressid' => 2,
            'match'     => '# CPAN EMAIL'
        },
        'barbie@cpan.org' => {
            'result'    => 1,
            'testerid'  => 1,
            'addressid' => 1,
            'match'     => '# PAUSE ID'
        },
        'barbie@barbie.missbarbell.co.uk (Barbie)' => {
            'result'    => 0,
            'testerid'  => 0,
            'addressid' => 0,
            'match'     => undef
        }
    );

    $obj->{unparsed_map} = {
        'barbie@missbarbell.co.uk (Barbie)' => {
            'email'     => 'barbie@missbarbell.co.uk',
            'testerid'  => 0,
            'sort'      => '',
            'addressid' => 0
        },
        'barbie@missbarbell.co.uk' => {
            'email'     => 'barbie@missbarbell.co.uk',
            'testerid'  => 0,
            'sort'      => '',
            'addressid' => 0
        },
        'barbie@cpan.org' => {
            'email'     => 'barbie@cpan.org',
            'testerid'  => 0,
            'sort'      => '',
            'addressid' => 0
        },
        'barbie@barbie.missbarbell.co.uk (Barbie)' => {
            'email'     => 'barbie@barbie.missbarbell.co.uk',
            'testerid'  => 0,
            'sort'      => '',
            'addressid' => 0
        },
    };

    $obj->{pause_map}   = {
        'barbie' => {
            'testerid'  => 1,
            'pause'     => 'BARBIE',
            'match'     => '# PAUSE ID',
            'name'      => 'Barbie',
            'addressid' => 1
        },
    };
    $obj->{cpan_map}    = {
        'barbie@missbarbell.co.uk' => {
            'testerid'  => 2,
            'pause'     => 'BARBIE',
            'match'     => '# CPAN EMAIL',
            'name'      => 'Barbie',
            'addressid' => 2
        },
    };

    $obj->{stored_map}  = {
        'barbie@missbarbell.co.uk (Barbie)' => {
            'testerid'  => 3,
            'pause'     => 'BARBIE',
            'match'     => '# MAPPED ADDRESS',
            'name'      => 'Barbie',
            'addressid' => 3
        },
    };
    $obj->{address_map} = {
        'barbie@missbarbell.co.uk (Barbie)' => {
            'testerid'  => 4,
            'pause'     => 'BARBIE',
            'match'     => '# MAPPED EMAIL',
            'name'      => 'Barbie',
            'addressid' => 4
        },
    };
    $obj->{parsed_map}  = {
        'barbie@missbarbell.co.uk (Barbie)' => {
            'testerid'  => 5,
            'pause'     => 'BARBIE',
            'match'     => '# MAPPED ADDRESS',
            'name'      => 'Barbie',
            'addressid' => 5
        },
    };
    $obj->{paused_map}  = {
        'BARBIE' => {
            'testerid'  => 6,
            'pause'     => 'BARBIE',
            'match'     => '# MAPPED PAUSE',
            'name'      => 'Barbie',
            'addressid' => 6
        },
    };

    for my $key (keys %{ $obj->{unparsed_map} }) {
        my $email = lc CPAN::Testers::Data::Addresses::_extract_email($key);
        my ($local,$domain) = split(/\@/,$email);
        is( $obj->map_address($key,$local,$domain,$email),
            $results{$key}{result}, "Address checks for $key");

        is( $obj->{unparsed_map}{$key}{$_}, $results{$key}{$_},
            ".. checking $_")    for(qw(testerid addressid match));
    }


    ### Domain Mapping Tests

    %results = (
        'barbie@missbarbell.co.uk (Barbie)' => {
            'result'    => 1,
            'name'      => 'Barbie',
            'testerid'  => 6,
            'addressid' => 0,
            'match'     => '# MAPPED DOMAIN - missbarbell.co.uk'
        },
        'barbie@missbarbell.co.uk' => {
            'result'    => 1,
            'name'      => 'Barbie',
            'testerid'  => 6,
            'addressid' => 0,
            'match'     => '# MAPPED DOMAIN - missbarbell.co.uk'
        },
        'barbie@cpan.org' => {
            'result'    => 0,
            'name'      => undef,
            'testerid'  => 0,
            'addressid' => 0,
            'match'     => undef
        },
        'barbie@barbie.missbarbell.co.uk (Barbie)' => {
            'result'    => 1,
            'name'      => 'Barbie',
            'testerid'  => 6,
            'addressid' => 0,
            'match'     => '# MAPPED DOMAIN - barbie.missbarbell.co.uk - missbarbell.co.uk'
        }
    );

    $obj->{unparsed_map} = {
        'barbie@missbarbell.co.uk (Barbie)' => {
            'email'     => 'barbie@missbarbell.co.uk',
            'testerid'  => 0,
            'sort'      => '',
            'addressid' => 0
        },
        'barbie@missbarbell.co.uk' => {
            'email'     => 'barbie@missbarbell.co.uk',
            'testerid'  => 0,
            'sort'      => '',
            'addressid' => 0
        },
        'barbie@cpan.org' => {
            'email'     => 'barbie@cpan.org',
            'testerid'  => 0,
            'sort'      => '',
            'addressid' => 0
        },
        'barbie@barbie.missbarbell.co.uk (Barbie)' => {
            'email'     => 'barbie@barbie.missbarbell.co.uk',
            'testerid'  => 0,
            'sort'      => '',
            'addressid' => 0
        },
    };

    $obj->{domain_map} = {
        'missbarbell.co.uk' => {
            'testerid' => 6,
            'pause' => 'BARBIE',
            'match' => '# MAPPED DOMAIN',
            'name' => 'Barbie',
            'addressid' => 6
        },
        'cpan.org' => {
            'testerid' => 7,
            'pause' => 'BARBIE',
            'match' => '# MAPPED DOMAIN',
            'name' => 'Barbie',
            'addressid' => 7
        },
    };

    for my $key (keys %{ $obj->{unparsed_map} }) {
        my $email = lc CPAN::Testers::Data::Addresses::_extract_email($key);
        my ($local,$domain) = split(/\@/,$email);
        is( $obj->map_domain($key,$local,$domain,$email),
            $results{$key}{result}, "Domain checks for $key");

        is( $obj->{unparsed_map}{$key}{$_}, $results{$key}{$_},
            ".. checking $_ for '$key'")    for(qw(testerid addressid name match));
    }


    # ensure domains can be rejected

    my @domains = (
        'us.ibm.com',
        'shaw.ca',
        'ath.cx',
        'rambler.de',
        'mail.de',
        'nasa.gov',
        'nih.gov',
        'net.br',
        'org.au',
        'com.tw',
        'co.uk',
        'org.uk',
        'example.edu',
        'ac.uk',
        'edu.at'
    );

    for my $domain (@domains) {
        my $local = 'example';
        my $email = $local .'@'. $domain;
        is( $obj->map_domain($email,$local,$domain,$email), 0, "Domain checks filter out $domain");
    }
}
