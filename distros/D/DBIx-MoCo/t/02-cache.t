#!perl -T
use strict;
use warnings;
use File::Spec;

use lib File::Spec->catdir('t', 'lib');

ThisTest->runtests;

# ThisTest
package ThisTest;
use base qw/Test::Class/;
use Test::More;
use DBIx::MoCo::Cache;

sub use_test : Tests {
    use_ok 'DBIx::MoCo::Cache';
}

sub cache : Tests {
    my $c = 'DBIx::MoCo::Cache';
    my $a = 1;
    my $oid = 'test1';
    $c->set($oid, $a);
    my $a2 = $c->get($oid);
    ok $a2;
    is $a2, $a;
    my $b = [1,2,3];
    $oid = 'test2';
    $c->set($oid, $b);
    my $b2 = $c->get($oid);
    ok $b2;
    is $b2, $b;
}

sub remove : Tests {
    my $c = 'DBIx::MoCo::Cache';
    my $a = 1;
    my $oid = 'test1';
    $c->set($oid, $a);
    my $a2 = $c->get($oid);
    ok $a2;
    is $a2, $a;
    $c->remove($oid);
    ok !$c->get($oid);
}

1;
