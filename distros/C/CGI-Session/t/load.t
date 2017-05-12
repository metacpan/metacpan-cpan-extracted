# $Id$

use strict;


use Test::More 'no_plan';

# Some driver independent tests for load();

use CGI::Session;

{
    my $s = CGI::Session->load('Driver:file;serial:FreezeThaw',undef, Directory=> 'wrong' );
    is($s,undef, "undefined session is created with wrong number of args to load");
    like(CGI::Session->errstr, qr/Too many/, "expected error is returned for too many args");
    unlike(CGI::Session->errstr, qr/new/, "don't mention new() in error when load() fails directly.");
}
{
    my $s = CGI::Session->new();
    is(CGI::Session->errstr, '', "reality check: no error when calling new()");
    $s->load();
    like($s->errstr, qr/instance method/, "expected error when load() called as instance method.");
    $s->delete();
}

