# Basic accessor/mutator tests

use File::Basename;
use Test::More tests => 32;
BEGIN { use_ok( Apache::AuthTkt ) }
use strict;

my $at;
my $dir = dirname($0);
my %arg = (
    secret => 'squirrel',
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
);
my %arg2 = (
    timeout => '1d',
    timeout_refresh => 0.66,
    guest_login => 1,
    ignore_ip => 0,
    require_ssl => 0,
    cookie_secure => 0,
);
# Uppercase any missing arg2 args
for (keys %arg) {
  next if exists $arg2{$_};
  $arg2{$_} = uc $arg{$_};
}

ok($at = Apache::AuthTkt->new(%arg), 'non-conf constructor with args ok');
is($at->$_(), $arg{$_}, "$_ accessor value ok") for keys %arg;

# Mutator tests
for (keys %arg2) {
  $at->$_($arg2{$_});
  is($at->$_(), $arg2{$_}, "post-mutator $_ accessor value ok");
}


# vim:ft=perl
