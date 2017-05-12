# $Id$

use strict;


use Test::More qw/no_plan/;

# Tests for expire(), which doesn't directly use driver-specific code. 

use CGI::Session;
my $s = CGI::Session->new();

is($s->expire, undef, "undef is returned if nothing has been set yet. ");

$s->expire(10);
is($s->expire, 10, "basic set/get check");

$s->expire(-10);
is($s->expire, -10, "negative set/get check");

$s->expire(0);
is($s->expire, undef, "zero cancels expiration");

$s->expire('pumpkin',10);

# reach into internals to test
is($s->{_DATA}{_SESSION_EXPIRE_LIST}{'pumpkin'}, 10 , "setting expiration for a single param works");


$s->expire('pumpkin', 0);
ok(!exists($s->{_DATA}->{_SESSION_EXPIRE_LIST}->{'pumpkin'}), "zero expires parameters");

#
# Let's cleanup after ourselves
$s->delete;

# more related tests are in t/str2second.t


