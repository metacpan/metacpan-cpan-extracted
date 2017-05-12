#$Id$

#
# Re: [cpan #14414] method remote_addr() was removed in version 4.01
#

use strict;
use Test::More ( tests=>5 );
use_ok("CGI::Session");

$ENV{REMOTE_ADDR} = '127.0.0.1';
ok(my $session = CGI::Session->new);

ok($session->can("remote_addr"), "remote_addr() exists");
ok(eval{$session->remote_addr}, "remote_addr() passes eval");
ok($session->remote_addr eq $ENV{REMOTE_ADDR}, "remote_addr() is " . $session->remote_addr);

$session->delete;
