# parse_conf testing

use File::Basename;
use Test::More tests => 36;
BEGIN { use_ok( Apache::AuthTkt ) }
use strict;

my $dir = dirname($0);

my ($at, %attr);

# auth_tkt.conf - most attributes use defaults
ok($at = Apache::AuthTkt->new(conf => "$dir/t04/auth_tkt.conf"),
    'conf constructor ok');
%attr = (
    secret => '0e1d79e1-c18b-43c5-bfd6-a396e13bf39c',
    secret_old => "8be1b398-d84f-497c-9c73-9660ecee2b97",
    cookie_name => 'auth_tkt',
    back_cookie_name => undef,
    back_arg_name => 'back',
    domain => undef,
    cookie_expires => undef,
    login_url => => 'https://www.example.com/pub/login.cgi',
    timeout_url => undef,
    unauth_url => undef,
    timeout => 2 * 60 * 60,
    timeout_refresh => 0.5,
    token => undef,
    guest_login => 0,
    ignore_ip => 1,
    require_ssl => 0,
);
for (sort keys %attr) {
  is(eval "\$at->$_", $attr{$_}, "$_() ok");
}
ok(! defined eval { $at->foo }, "die on invalid method ok");

# auth_tkt2.conf - most attributes defined
ok($at = Apache::AuthTkt->new(conf => "$dir/t04/auth_tkt2.conf"),
    'conf constructor ok');
%attr = (
    secret => '0e1d79e1-c18b-43c5-bfd6-a396e13bf39c',
    cookie_name => 'session_id',
    back_cookie_name => undef,
    back_arg_name => 'whence',
    domain => 'www.example.com',
    cookie_expires => 86400,
    login_url => => 'https://www.example.com/pub/login.cgi',
    timeout_url => undef,
    unauth_url => undef,
    timeout => 60 * 60,
    timeout_refresh => 0.33,
    token => undef,
    guest_login => 1,
    ignore_ip => 1,
    require_ssl => 1,
);
for (sort keys %attr) {
  is(eval "\$at->$_", $attr{$_}, "$_() ok");
}
ok(! defined eval { $at->foo }, "die on invalid method ok");


# vim:ft=perl
