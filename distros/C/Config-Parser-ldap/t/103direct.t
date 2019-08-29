# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestLDAP;

plan(tests => 3);

my $cf = new TestLDAP;

ok($cf->base,q{dc=example,dc=com});
ok($cf->TLS_REQCERT,q{allow});
ok(!$cf->sizelimit);

__DATA__
BASE   dc=example,dc=com
URI    ldap://ldap.example.com ldap://ldap-master.example.com:666
TLS_REQCERT allow
DEREF          never
    
