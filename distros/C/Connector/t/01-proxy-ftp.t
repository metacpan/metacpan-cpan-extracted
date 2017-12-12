# Test for Connector::Proxy::Net::FTP

use strict;
use warnings;
use English;
use Data::Dumper;
use Log::Log4perl qw(:easy);

use Test::More;

BEGIN {
    use_ok('Connector::Proxy::Net::FTP');
}

SKIP: {
    skip "Proxy FTP server not set" unless $ENV{CONN_PROXY_FTP_LOCATION};

    Log::Log4perl->easy_init($ERROR);

    my $conn = Connector::Proxy::Net::FTP->new(
        {
            LOCATION => $ENV{CONN_PROXY_FTP_LOCATION},
            username => $ENV{CONN_PROXY_FTP_USERNAME} // 'connector',
            password => $ENV{CONN_PROXY_FTP_PASSWORD} // 'test',
            path     => 'tmp/[% ARGS.0 %]',
            debug    => 0,
        }
    );

    ok( $conn->set( ['issuing.crl'], 'Test Message' ) );

    is( $conn->get( ['issuing.crl'] ), 'Test Message' );

    $conn->path('issuing.crl');
    $conn->basedir('tmp');
    is( $conn->get(), 'Test Message' );
    ok( $conn->set( '', 'Test Message 2' ) );

    $conn->path('');
    $conn->basedir('tmp');
    is( $conn->get( ['issuing.crl'] ), 'Test Message 2' );
    ok( $conn->set( ['issuing.crl'], 'Test Message 3' ) );

    $conn->path('');
    $conn->basedir('');
    is( $conn->get( [ 'tmp', 'issuing.crl' ] ), 'Test Message 3' );

    eval { $conn->get( ['tmp/issuing.crl'] ); };
    like( $EVAL_ERROR, '/args contains invalid characters/' );

    my @files = $conn->get_keys('tmp');
    ok( grep /issuing.crl/, @files );
}

done_testing();
