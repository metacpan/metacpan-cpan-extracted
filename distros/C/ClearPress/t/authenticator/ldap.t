# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More tests => 16;
use lib qw(t/lib);
use English qw(-no_match_vars);
use IO::Capture::Stderr;

our $PKG = q[ClearPress::authenticator::ldap];
use_ok($PKG);

{
  my $ldap = $PKG->new;
  is($ldap->server, 'ldaps://ldap.local:636', 'server default');
}

{
  my $ldap = $PKG->new({
			server => 'myserver.org'
		       });
  is($ldap->server, 'myserver.org', 'server from constructor');
}

{
  my $ldap = $PKG->new();
  is($ldap->server('myserver.org'), 'myserver.org', 'server from arg');
}

{
  my $ldap = $PKG->new;
  is($ldap->ad_domain, 'WORKGROUP', 'ad_domain default');
}

{
  my $ldap = $PKG->new({
			ad_domain => 'CLEARPRESS.NET'
		       });
  is($ldap->ad_domain, 'CLEARPRESS.NET', 'ad_domain from constructor');
}

{
  my $ldap = $PKG->new();
  is($ldap->ad_domain('CLEARPRESS.NET'), 'CLEARPRESS.NET', 'ad_domain from arg');
}

{
  my $ldap      = $PKG->new();
  my $connector = $ldap->_ldap();
  is_deeply($connector->{constructor_args}, [qw(ldaps://ldap.local:636)], 'connector construction');
  is_deeply($ldap->_ldap(), $connector, 'cached connector');
}

{
  my $ldap = $PKG->new;
  is($ldap->authen_credentials(), undef, 'auth no args');
  is($ldap->authen_credentials({username => 'bob'}), undef, 'auth no password');
  is($ldap->authen_credentials({password => 'passw0rd'}), undef, 'auth no username');
}

{
  no warnings qw(once);
  my $ldap = $PKG->new;
  eval {
    local $Net::LDAP::CONSTRUCTOR_FAIL = 1;
    $ldap->authen_credentials({username => 'bob', password => 'pass'});
  };
  like($EVAL_ERROR, qr/Failed[ ]to[ ]connect/smx, 'ldap connection failure');
}

{
  my $ref  = {
	      username => 'bob',
	      password => 'pass',
	     };
  my $ldap = $PKG->new;
  my $state;
  eval {
    local $Net::LDAP::BIND_CODE  = undef;
    local $Net::LDAP::BIND_ERROR = 'no bind error';

    $state = $ldap->authen_credentials($ref);
  };
  unlike($EVAL_ERROR, qr/Failed[ ]to[ ]connect/smx, 'no ldap connection failure');
  is_deeply($state, $ref, 'authentication pass');
}

{
  my $ref  = {
	      username => 'bob',
	      password => 'pass',
	     };
  my $ldap = $PKG->new;
  my $cap = IO::Capture::Stderr->new;
  $cap->start;
  my $state;
  eval {
    local $Net::LDAP::BIND_CODE  = 1;
    local $Net::LDAP::BIND_ERROR = 'bind error number 1';

    $state = $ldap->authen_credentials($ref);
  };
  $cap->stop;
  is($state, undef, 'authentication fail');
}
