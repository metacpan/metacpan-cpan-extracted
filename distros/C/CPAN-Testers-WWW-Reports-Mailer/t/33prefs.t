#!/usr/bin/perl -w
use strict;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use Test::More tests => 9;

use CPAN::Testers::WWW::Reports::Mailer;

use TestObject;

# -------------------------------------------------------------------
# Variables

my $CONFIG = 't/_DBDIR/preferences.ini';

my %prefs = (
    LBROCARD => {
        'version'   => 'LATEST',
        'ignored'   => 0,
        'perl'      => 'ALL',
        'report'    => '1',
        'tuple'     => 'FIRST',
        'platform'  => 'ALL',
        'patches'   => 0,
        'grades'    => {
            'FAIL'      => 1
        }
    },
    NOONE => {
        'active'    => 0,
        'version'   => 'LATEST',
        'ignored'   => 0,
        'perl'      => 'ALL',
        'report'    => '1',
        'tuple'     => 'FIRST',
        'platform'  => 'ALL',
        'patches'   => 0,
        'grades'    => {
            'FAIL'      => 1
        }
    },
    BARBIE => {
        'active'    => 3,
        'version'   => 'LATEST',
        'ignored'   => 0,
        'perl'      => 'ALL',
        'report'    => '3',
        'tuple'     => 'FIRST',
        'platform'  => 'ALL',
        'patches'   => 0,
        'grades'    => {
            'ALL'       => 1
        }
    },
    SAPER => {
        'version'   => 'LATEST',
        'active'    => '3',
        'ignored'   => 0,
        'perl'      => 'ALL',
        'report'    => '1',
        'tuple'     => 'FIRST',
        'platform'  => 'ALL',
        'patches'   => 0,
        'grades'    => {
            'FAIL'      => 1
        }
    },
);

# -------------------------------------------------------------------
# Tests

SKIP: {
    skip "No supported databases available", 9  unless(-f $CONFIG);

    ok( my $obj = TestObject->load(), "got object" );


    is_deeply($obj->_get_prefs('LBROCARD','-'),                     $prefs{LBROCARD},   'found author prefs - LBROCARD');
    is_deeply($obj->_get_prefs('SAPER','Acme-CPANAuthors-French'),  $prefs{SAPER},      'found author prefs - SAPER');

#use Data::Dumper;
#print STDERR Dumper($obj->_get_prefs('LBROCARD','-'));
#print STDERR Dumper($obj->_get_prefs('SAPER','Acme-CPANAuthors-French','-'));

    my $row  = {};
    my $hash = {
        'version'   => 'LATEST',
        'ignored'   => 0,
        'perl'      => 'ALL',
        'report'    => 1,
        'tuple'     => 'FIRST',
        'platform'  => 'ALL',
        'patches'   => 0,
        'grades'    => {
            'FAIL'      => 1
        }
    };

    is_deeply($obj->_parse_prefs($row), $hash, 'default prefs parse');
#print STDERR Dumper($obj->_parse_prefs($row));

    $row = {
        grade       => 'PASS,FAIL,UNKNOWN,NA',
        ignored     => 1,
        report      => 0,
        tuple       => 'ALL',
        version     => 'ALL',
        patches     => 1,
        perl        => '5.8.8',
        platform    => 'Linux'
    };
    $hash = {
        'version'   => 'ALL',
        'ignored'   => 1,
        'perl'      => '5.8.8',
        'report'    => 0,
        'tuple'     => 'ALL',
        'platform'  => 'Linux',
        'patches'   => 1,
        'grades'    => {
            'PASS'      => 1,
            'FAIL'      => 1,
            'UNKNOWN'   => 1,
            'NA'        => 1
        }
    };

    is_deeply($obj->_parse_prefs($row), $hash, 'default prefs parse');
#print STDERR Dumper($obj->_parse_prefs($row));

    is_deeply($obj->_get_prefs('NOONE'),               $prefs{NOONE},  'author not found - NOONE');
    is_deeply($obj->_get_prefs('BARBIE'),              $prefs{BARBIE}, 'found author prefs - BARBIE');
    is_deeply($obj->_get_prefs('SAPER'),               $prefs{SAPER},  'found author prefs - SAPER');
    is_deeply($obj->_get_prefs('SAPER','Fake-Distro'), $prefs{SAPER},  'found author prefs - SAPER - for unset Distro');
}
