#!perl

use strict;
use warnings;

use Test::More tests => 2 + 2*7;

use lib 't';
require 'testdb.pl';
our $dbh;

use_ok('DBIx::Path');

{
    my($oldlock, $lock, $unlock)=qw(0 0 0);
    sub lock_hook { $lock++; }
    sub unlock_hook { $unlock++; }
    sub ck_lock {
        my($op, $locks)=@_;
        is($lock, $unlock, "$op: Locks and unlocks even");
        is($lock, $oldlock+$locks, "$op: Took $locks lock(s)");
        $oldlock=$lock;
    }
}

my $root=DBIx::Path->new(dbh => $dbh, table => 'dbix_path_test', hooks => { lock => \&lock_hook, unlock => \&unlock_hook });
isa_ok($root, 'DBIx::Path', 'Constructor return');

GOOD: {
    ck_lock("Initialization", 0);

    $root->get('usr');
    ck_lock("get", 1);

    $root->list();
    ck_lock("list", 1);

    #Note: nested locks
    $root->resolve(qw(usr bin perl));
    ck_lock("resolve", 1);

    $root->add('usr~', 2);
    ck_lock("add", 1);

    $root->del('usr~');
    ck_lock("del", 1);

    #Note: nested locks
    $root->set('var', 2);
    ck_lock("set", 1);
}

