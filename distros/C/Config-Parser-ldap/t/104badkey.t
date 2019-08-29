# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestLDAP;

plan(tests => 1);

my $cf = new TestLDAP(expect => [
    q(keyword "tls_cert" is unknown)
]);
ok(!$cf->status);

__DATA__
BASE   dc=example,dc=com
tls_cert crt
URI    ldap://ldap.example.com
