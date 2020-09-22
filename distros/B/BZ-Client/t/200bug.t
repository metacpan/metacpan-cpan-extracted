#!/usr/bin/env perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print qq{1..0 # SKIP these tests only run with AUTHOR_TESTING set\n};
        exit
    }
}

use strict;
use warnings 'all';

use lib 't/lib';

use BZ::Client::Test();
use BZ::Client::Bug();
use Test::More;

use Data::Dumper;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;

# these next three lines need more thought
use Test::RequiresInternet ( 'landfill.bugzilla.org' => 443 );
my @bugzillas = do 't/servers.cfg';

plan tests => ( scalar @bugzillas * 12 );

my $tester;

my @_priority = qw/ P1 P2 P3 P4 P5 /;

my @_severity = (
    'blocker', 'critical', 'major', 'normal',
    'minor',   'trivial',  'enhancement'
);

my @_op_sys = (
    'All',                       'Windows 3.1',
    'Windows 95',                'Windows 98',
    'Windows ME',                'Windows 2000',
    'Windows NT',                'Windows XP',
    'Windows Server 2003',       'Mac System 7',
    'Mac System 7.5',            'Mac System 7.6.1',
    'Mac System 8.0',            'Mac System 8.5',
    'Mac System 8.6',            'Mac System 9.x',
    'Mac OS X 10.0',             'Mac OS X 10.1',
    'Mac OS X 10.2',             'Linux',
    'BSD/OS',                    'FreeBSD',
    'NetBSD',                    'OpenBSD',
    'AIX',                       'BeOS',
    'HP-UX',                     'IRIX',
    'Neutrino',                  'OpenVMS',
    'OS/2',                      'OSF/1',
    'Solaris',                   'SunOS',
    "M\x{e1}\x{e7}\x{d8}\x{df}", 'Other'
);

my @_platform =
  ( 'All', 'DEC', 'HP', 'Macintosh', 'PC', 'SGI', 'Sun', 'Other' );

my @_resolution = (
    '',      'FIXED',  'INVALID',   'WONTFIX',
    'LATER', 'REMIND', 'DUPLICATE', 'WORKSFORME',
    'MOVED'
);

sub contains {
    my ( $value, $values ) = @_;
    for my $v (@$values) {
        return 1
          if ( $v eq $value );
    }
    return 0;
}

my %quirks = (

    '5.0' => {
        status =>
          [ 'UNCONFIRMED', 'CONFIRMED', 'IN_PROGRESS', 'RESOLVED', 'VERIFIED' ],
        priority   => \@_priority,
        severity   => \@_severity,
        op_sys     => \@_op_sys,
        platform   => \@_platform,
        resolution => [
            '',          'FIXED',      'INVALID', 'WONTFIX',
            'DUPLICATE', 'WORKSFORME', 'MOVED'
        ]
    },
    '4.4' => {
        status =>
          [qw/ UNCONFIRMED NEW ASSIGNED REOPENED RESOLVED VERIFIED CLOSED /],
        priority   => \@_priority,
        severity   => \@_severity,
        op_sys     => \@_op_sys,
        platform   => \@_platform,
        resolution => \@_resolution,
    },

);

sub TestLegalValues {
    my $field  = shift;
    my $client = $tester->client();
    my $values;
    eval {
        $values = BZ::Client::Bug->legal_values( $client, $field );
        $client->logout();
    };
    if ($@) {
        my $err = $@;
        my $msg;
        if ( ref($err) eq 'BZ::Client::Exception' ) {
            $msg = 'Error: '
              . ( defined( $err->http_code() ) ? $err->http_code()     : 'undef' ) . ', '
              . ( defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code() : 'undef' ) . ', '
              . ( defined( $err->message() ) ? $err->message()         : 'undef' );
        }
        else {
            $msg = "Error $err\n";
        }
        diag($msg);
        return;
    }
    if ( !$values or ref($values) ne 'ARRAY' or !@$values ) {
        diag "No values returned.\n";
        return;
    }
    return $values;
}

sub RunTest {
    my $test = shift;
    my $values = TestLegalValues($test);
    return is_deeply( $quirks{ $tester->{version} }{$test},
        $values, $test . ' values correct' )
}

###

sub TestSearchAll {
    my $bugs = TestSearch( {} );
    return $bugs && ref($bugs) eq 'ARRAY';
}

sub TestSearchOpen {
    my $all = TestSearch( {} );
    my $open = TestSearch(
        { 'status' => [ 'NEW', 'UNCONFIRMED', 'ASSIGNED', 'REOPENED' ] } );
    for my $bug (@$all) {
        my $found = 0;
        for my $b (@$open) {
            if ( $b->id() eq $bug->id() ) {
                $found = 1;
                last;
            }
        }
        if ( $bug->is_open() ) {
            if ( !$found ) {
                diag 'Bug '
                  . $bug->id()
                  . " is open, but not reported as open.\n";
                return 0;
            }
        }
        else {
            if ($found) {
                diag 'Bug '
                  . $bug->id()
                  . " isn't open, but reported as open.\n";
                return 0;
            }
        }
    }
    return 1;
}

sub TestSearch {
    my ( $params, $emptyOk ) = @_;
    my $client = $tester->client();
    my $bugs;
    eval {
        $bugs = BZ::Client::Bug->search( $client, $params );
        $client->logout();
    };
    if ($@) {
        my $err = $@;
        my $msg;
        if ( ref($err) eq 'BZ::Client::Exception' ) {
            $msg = 'Error: '
              . ( defined( $err->http_code() ) ? $err->http_code()     : 'undef' ) . ', '
              . ( defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code() : 'undef' ) . ', '
              . ( defined( $err->message() ) ? $err->message()         : 'undef' );
        }
        else {
            $msg = "Error: $err";
        }
        diag "$msg\n";
        return;
    }
    if ( !$bugs || ref($bugs) ne 'ARRAY' || ( !$emptyOk && !@$bugs ) ) {
        diag "No bugs returned.\n";
        return;
    }
    return $bugs;
}

sub TestSearchExistingProduct {
    my $all = TestSearch( {} );
    my $productName = $all->[0]->product();
    return TestSearchProduct( $all, $productName, 0 );
}

sub TestSearchInvalidProduct {
    my $all = TestSearch( {} );
    return TestSearchProduct( $all, 'asdflksdfsldkj  sdflkjsdlf', 1 );
}

sub TestSearchProduct {
    my ( $all, $productName, $emptyOk ) = @_;
    my $product_bugs = TestSearch( { 'product' => $productName }, $emptyOk );
    if ( $emptyOk && !$product_bugs ) {
        return 1;
    }
    if ( $emptyOk && !@$product_bugs ) {
        return 1;
    }
    for my $bug (@$all) {
        my $found = 0;
        for my $b (@$product_bugs) {
            if ( $b->id() eq $bug->id() ) {
                $found = 1;
                last;
            }
        }
        if ( $bug->product() eq $productName ) {
            if ( !$found ) {
                diag 'Bug ' . $bug->id()
                  . " has product $productName, but not reported to have it.\n";
                return 0;
            }
        }
        else {
            if ($found) {
                diag 'Bug ' . $bug->id() . ' has product ' . $bug->product()
                  . ", but reported to have $productName.\n";
                return 0;
            }
        }
    }
    return 1;
}

for my $server (@bugzillas) {

    diag sprintf 'Trying server: %s', $server->{testUrl} || '???';

    $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

  SKIP: {

        skip( 'No Bugzilla server configured, skipping', 6 )
          if $tester->isSkippingIntegrationTests();

        ok( &RunTest('status'),     'Status' );
        ok( &RunTest('priority'),   'Priority' );
        ok( &RunTest('severity'),   'Severity' );
        ok( &RunTest('op_sys'),     'OpSys' );
        ok( &RunTest('platform'),   'Platform' );
        ok( &RunTest('resolution'), 'Resolution' );

        #these will time out on a large install
        #    ok(&TestSearchAll, 'SearchAll');
        #    ok(&TestSearchOpen, 'SearchOpen');
        #    ok(&TestSearchExistingProduct, 'SearchExistingProduct');
        #    ok(&TestSearchInvalidProduct, 'SearchInvalidProduct');

    }

}
