# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More tests => 10;
#########
# override getpwnam
#
BEGIN {
  *{ClearPress::authenticator::passwd::getpwnam} = sub {
    my $name = shift;
    if($name eq 'dummyuser') {
      return qw(dummyuser du2M/eJoAA/Ak 1809244410 1139001599 0  Roger Pettett /Users/rpettett /bin/bash 0);
    }

    return ();
  };
}

our $PKG = 'ClearPress::authenticator::passwd';
use_ok($PKG);
can_ok($PKG, qw(new authen_credentials));

{
  my $auth = $PKG->new();
  isa_ok($auth, $PKG);
  isa_ok($auth, 'ClearPress::authenticator');
}

{
  my $auth = $PKG->new();
  is($auth->authen_credentials(), undef, 'no creds');
}

{
  my $auth = $PKG->new();
  is($auth->authen_credentials({username => 'dummy'}), undef, 'no password');
}

{
  my $auth = $PKG->new();
  is($auth->authen_credentials({password => 'dummy'}), undef, 'no username');
}


{
  my $auth = $PKG->new();
  is($auth->authen_credentials({
				username => 'missing',
				password => 'something',
			       }), undef, 'unknown user');
}

{
  my $auth = $PKG->new();
  my $ref  = {
	      username => 'dummyuser',
	      password => 'dummypass',
	     };
  my $result = $auth->authen_credentials($ref);
  is_deeply($result, undef, 'valid user, bad password');
}

{
  my $auth = $PKG->new();
  my $ref  = {
	      username => 'dummyuser',
	      password => 'dummy',
	     };
  my $result = $auth->authen_credentials($ref);
  is_deeply($result, $ref, 'valid user');
}
