use strict;
use warnings;
use Test2::V0;
use Async::Redis;

subtest 'hostname connect + verify on: SSL_hostname + SSL_verifycn_name set' => sub {
    my $c = Async::Redis->new(host => 'redis.example.com', port => 6379, tls => 1);
    my %opts = $c->_build_tls_options;
    is $opts{SSL_verify_mode},     $c->_ssl_verify_peer,  'verify PEER';
    is $opts{SSL_hostname},        'redis.example.com',   'SNI set';
    is $opts{SSL_verifycn_name},   'redis.example.com',   'cn check';
    is $opts{SSL_verifycn_scheme}, 'default',             'scheme default';
};

subtest 'IP literal + verify on: IP used for SNI and SSL_verifycn_name' => sub {
    my $c = Async::Redis->new(host => '10.0.1.5', port => 6379, tls => 1);
    my %opts = $c->_build_tls_options;
    is $opts{SSL_hostname},        '10.0.1.5', 'SNI is IP (legal)';
    is $opts{SSL_verifycn_name},   '10.0.1.5', 'verify IP SAN';
    is $opts{SSL_verify_mode},     $c->_ssl_verify_peer, 'chain still verified';
};

subtest 'verify_hostname => 0: SNI set but identity skipped' => sub {
    my $c = Async::Redis->new(
        host => 'redis.example.com',
        port => 6379,
        tls  => { verify_hostname => 0 },
    );
    my %opts = $c->_build_tls_options;
    is $opts{SSL_verify_mode}, $c->_ssl_verify_peer, 'chain verification still on';
    is $opts{SSL_hostname},    'redis.example.com',  'SNI still set';
    ok !exists $opts{SSL_verifycn_name}, 'no hostname identity check';
};

subtest 'verify => 0 disables verification entirely' => sub {
    my $c = Async::Redis->new(
        host => 'redis.example.com',
        port => 6379,
        tls  => { verify => 0 },
    );
    my %opts = $c->_build_tls_options;
    is $opts{SSL_verify_mode}, $c->_ssl_verify_none, 'no verify';
};

subtest 'CA/cert/key files are forwarded' => sub {
    my $c = Async::Redis->new(
        host => 'redis.example.com',
        port => 6379,
        tls  => {
            ca_file   => '/path/to/ca.pem',
            cert_file => '/path/to/cert.pem',
            key_file  => '/path/to/key.pem',
        },
    );
    my %opts = $c->_build_tls_options;
    is $opts{SSL_ca_file},   '/path/to/ca.pem';
    is $opts{SSL_cert_file}, '/path/to/cert.pem';
    is $opts{SSL_key_file},  '/path/to/key.pem';
};

done_testing;
