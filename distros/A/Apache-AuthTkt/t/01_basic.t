# Basic constructor

use File::Basename;
use Test::More tests => 27;
BEGIN { use_ok( Apache::AuthTkt ) }
use strict;

my $dir = dirname($0);
my $secret = 'foobar';

# Simple constructor
my $at = Apache::AuthTkt->new(secret => $secret);
ok($at, 'secret constructor ok');
is($at->secret, $secret, 'secret() ok');

# Invalid constructor
ok(! defined eval { Apache::AuthTkt->new }, 'die on bare constructor');

# Invalid config file
ok(! defined eval { Apache::AuthTkt->new(conf => '/foo/bar') },
    'die on invalid config file');

# Config file missing TKTAuthSecret
ok(! defined eval { Apache::AuthTkt->new(conf => '/etc/passwd') },
    'die on config file without TKTAuthSecret');

# Constructor with 'conf'
ok($at = Apache::AuthTkt->new(conf => "$dir/t01/mod_auth_tkt.conf"),
    'conf constructor ok');
is($at->secret, '0e1d79e1-c18b-43c5-bfd6-a396e13bf39c', 'secret() ok');
is($at->digest_type, 'MD5', 'digest_type() ok');

# Constructor with args
my %arg = (
    secret => $secret,
    digest_type => 'MD5',
    cookie_name => 'auth_cookie',
    back_arg_name => 'bacchus',
    domain => '.openfusion.com.au',
    login_url => 'http://www.openfusion.com.au/auth/login.cgi',
    timeout_url => 'http://www.openfusion.com.au/auth/login.cgi?timeout=1',
    post_timeout_url => 'http://www.openfusion.com.au/auth/login.cgi?post_timeout=1',
    unauth_url => 'http://www.openfusion.com.au/auth/login.cgi?unauth=1',
    timeout => '2d',
    timeout_refresh => 0.33,
    guest_login => 0,
    guest_user => 'visitor',
    ignore_ip => 1,
    require_ssl => 1,
    cookie_secure => 1,
    debug => 1,
);
ok($at = Apache::AuthTkt->new(%arg), 'non-conf constructor with args ok');
is($at->$_(), $arg{$_}, "$_ accessor value ok") for keys %arg;


# vim:ft=perl
