# Regression test from old suite: not sure what it's trying to do...
# looks like regression test ensuring that refetch gets original object

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

use autodb_119;

my $autodb=new Class::AutoDB(-database=>testdb);
# retrieve and check
my $cursor=$autodb->find(-collection=>'Person',-name=>'Joe');
my $joe=$cursor->get->[0];
is(ref $joe,'Person','before put: Joe is a Person');
is(scalar @{$joe->friends},2,'before put: Joe has 2 friends');
my $mary=$joe->friends->[0];
ok(ref $mary,'before put: Mary via Joe is an object');
is($mary->name,'Mary','before put: Mary has correct name');
my $bill=$joe->friends->[1];
ok(ref $bill,'before put: Bill via Joe is an object');
is($bill->name,'Bill','before put: Bill has correct name');

# change Joe's name, put object, and retest
$joe->name('Joey');
$joe->put;
my $bill=$joe->friends->[1];
ok(ref $bill,"after changing Joe's name: Bill via Joe is an object");
is($bill->name,'Bill',"after changing Joe's name: Bill has correct name");

# fetch again and retest
my $cursor=$autodb->find(-collection=>'Person',-name=>'Joey');
my $joey=$cursor->get->[0];
is($joey,$joe,'after refetch: Joey and Joe are same object');
is(ref $joey,'Person','after refetch: Joey is a Person');
is(scalar @{$joey->friends},2,'after refetch: Joey has 2 friends');
my $mary=$joey->friends->[0];
ok(ref $mary,'after refetch: Mary via Joe is an object');
is($mary->name,'Mary','after refetch: Mary has correct name');
my $bill=$joey->friends->[1];
ok(ref $bill,'after refetch: Bill via Joey is an object');
is($bill->name,'Bill','after refetch: Bill has correct name');

# change Joey's friends, put object, and retest
$joey->friends->[0]=$joey;
$joey->friends->[1]=$mary;
$joey->friends->[2]=$bill;
$joey->put;
my $bill=$joey->friends->[2];
ok(ref $bill,"after changing Joey's friends: Bill via Joe is an object");
is($bill->name,'Bill',"after changing Joey's friends: Bill has correct name");

# fetch again and retest
my $cursor=$autodb->find(-collection=>'Person',-name=>'Joey');
my $joey=$cursor->get->[0];
is(ref $joey,'Person','after refetch: Joey is a Person');
is(scalar @{$joey->friends},3,'after refetch: Joey has 3 friends');
my $new_joey=$joey->friends->[0];
ok(ref $new_joey,'after refetch: Joey via Joey is an object');
is($new_joey->name,'Joey','after refetch: Joey has correct name');
my $mary=$joey->friends->[1];
ok(ref $mary,'after refetch: Mary via Joe is an object');
is($mary->name,'Mary','after refetch: Mary has correct name');
my $bill=$joey->friends->[2];
ok(ref $bill,'after refetch: Bill via Joey is an object');
is($bill->name,'Bill','after refetch: Bill has correct name');

# change Joey but don't put. then refetch
$joey->name('Joseph');
is($joey->name,'Joseph',"before put: Joey's name changed");
my $cursor=$autodb->find(-collection=>'Person',-name=>'Joey');
my $joey=$cursor->get->[0];
is($joey->name,'Joseph',"after refetch: Joey's name still changed");

done_testing();
