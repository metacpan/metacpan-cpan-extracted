# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestLDAP;

plan(tests => 1);

my $cf = new TestLDAP;

ok($cf->canonical(delim => ' '),
   q{base="dc=example,dc=com" deref="never" tls_reqcert="allow" uri="ldap://ldap.example.com ldap://ldap-master.example.com:666"});


__DATA__
# Test config

BASE   dc=example,dc=com
URI    ldap://ldap.example.com ldap://ldap-master.example.com:666

  TLS_REQCERT allow
DEREF          never
    
