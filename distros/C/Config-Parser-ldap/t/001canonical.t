# -*- perl -*-
use lib qw(lib);
use strict;
use Test;
use Config::Parser::ldap;
use File::Basename;

plan(tests => 1);

my $cf = new Config::Parser::ldap(filename => basename($0),
				  fh => \*main::DATA);

ok($cf->canonical(delim => ' '),
   q{base="dc=example,dc=com" deref="never" tls_reqcert="allow" uri="ldap://ldap.example.com ldap://ldap-master.example.com:666"});


__DATA__
# Test config

BASE   dc=example,dc=com
URI    ldap://ldap.example.com ldap://ldap-master.example.com:666

  TLS_REQCERT allow
DEREF          never
    
