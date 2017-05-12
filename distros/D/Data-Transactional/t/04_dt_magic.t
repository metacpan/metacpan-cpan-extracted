#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use Data::Compare;
use Scalar::Util qw(blessed);
use Test::More tests => 17;

use Data::Transactional;

my $tied = Data::Transactional->new(type => 'array');

ok(ref($tied) eq 'Data::Transactional', "array object has right type");
foreach my $method (qw(rollback commit checkpoint commit_all rollback_all)) {
    ok($tied->can($method), "got a $method method");
}
ok(Compare($tied, []), "newly created transactional array is empty");

$tied = Data::Transactional->new(); # hash
ok(ref($tied) eq 'Data::Transactional', "hash object has right type");
ok(Compare($tied, {}), "newly created transactional hash is empty");

eval { $tied->rollback(); };
ok($@, "can't rollback past beginning");
eval { $tied->commit(); };
ok($@, "can't commit with no checkpoints");

$tied->checkpoint();

%{$tied} = (
    animals => [qw(ant bear cat dog)],
    plants  => [qw(daisy grass rose tree)]
);

$tied->rollback();
ok(Compare($tied, {}), "rollback() appears to go back one step (so checkpoint() works too!)");

%{$tied} = (
    animals => [qw(ant bear cat dog)],
    plants  => [qw(daisy grass rose tree)]
);
$tied->checkpoint();
push @{$tied->{plants}}, "another tree";
$tied->commit();
ok(Compare($tied, {
    animals => [qw(ant bear cat dog)],
    plants  => [qw(daisy grass rose tree), 'another tree']
}), "commit() doesn't break anything ...");
eval { $tied->rollback(); };
ok($@, "and does remove a checkpoint");

$tied->checkpoint();
pop @{$tied->{plants}}; # remove "another tree"
$tied->rollback();
ok(Compare($tied, {
    animals => [qw(ant bear cat dog)],
    plants  => [qw(daisy grass rose tree), 'another tree']
}), "rollbacks remove changes in sub-structures");

$tied->checkpoint();
$tied->checkpoint();
$tied->commit_all();
eval { $tied->rollback(); };
ok($@, "commit_all() splats all checkpoints");

$tied->checkpoint();
delete $tied->{animals};
$tied->checkpoint();
$tied->{plants}->[0] = 'elderberry';
$tied->checkpoint();
$tied->{fish} = "i'm going to eat you little fishy";
$tied->rollback_all();
ok(Compare($tied, {
    animals => [qw(ant bear cat dog)],
    plants  => [qw(daisy grass rose tree), 'another tree']
}), "rollback_all does what it says on the tin");
