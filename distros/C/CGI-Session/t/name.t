#/usr/bin/perl -w

use strict;

use File::Spec;

use Test::More tests => 14;
use CGI;

use CGI::Session;

my $dir_name = File::Spec->tmpdir();

my $session = CGI::Session->new('id:static','testname',{Directory=>$dir_name});
ok($session);

# as class method
ok(CGI::Session->name,'name used as class method');

ok(CGI::Session->name('fluffy'),'name as class method w/ param');
ok(CGI::Session->name eq 'fluffy','name as class method w/ param effective?');

# as instance method
ok($session->name,'name as instance method');
ok($session->name eq CGI::Session->name,'instance method falls through to class');

ok($session->name('spot'),'instance method w/ param');

ok($session->name eq 'spot','instance method w/ param effective?');

ok(CGI::Session->name eq 'fluffy','instance method did not affect class method');

## test interface for setting session/cookie key name CGISESSID.
my $s2 = CGI::Session->new(
    'id:static',
    'testname',
    { Directory => $dir_name },
    { name => 'itchy' }
);

is $s2->name, 'itchy', 'constructor new with name for session/cookie key';
is( CGI::Session->name, 'fluffy', 'constructor name not affecting class');
is $session->name, 'spot', 'constructor on new session not affecting old';

## test from query
$s2 = CGI::Session->new(
    'id:static',
    CGI->new( 'itchy=2001' ),
    { Directory => $dir_name },
    { name => 'itchy' }
);

is $s2->id, 2001, 'session from query with new name';

## should die since it won't find value from query
eval {
    $s2 = CGI::Session->new(
        'id:static',
        CGI->new( 'CGISESSID=2001' ),
        { Directory => $dir_name },
        { name => 'itchy' }
    );
};

ok $@, "session in query with default name";
