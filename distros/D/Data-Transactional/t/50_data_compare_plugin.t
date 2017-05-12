#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
use Data::Compare;
use Test::More tests => 6;

use Data::Transactional;

my $tied1 = Data::Transactional->new();
my $tied2 = Data::Transactional->new();
my $not_tied = {
    fruit => [
        'apple',
        'pear',
        'cherry',
	{ nuts => [qw(brazil walnut)] }
    ],
    meat => {
        pets => [qw(cat dog gerbil)],
	notpets => [qw(cow sheep oyster)]
    }
};
%{$tied1} = (
    fruit => [
        'apple',
        'pear',
        'cherry',
	{ nuts => [qw(brazil walnut)] }
    ],
    meat => {
        pets => [qw(cat dog gerbil)],
	notpets => [qw(cow sheep oyster)]
    }
);
%{$tied2} = (
    fruit => [
        'apple',
        'pear',
        'cherry',
	{ nuts => [qw(brazil walnut)] }
    ],
    meat => {
        pets => [qw(cat dog gerbil)],
	notpets => [qw(cow sheep oyster)]
    }
);

$tied1->checkpoint();
ok(Compare($tied1, $tied2), 'successfully compare dt/dt correctly');
ok(Compare($tied1, $not_tied), 'successfully compare dt/not-dt correctly');

delete $tied1->{meat}->{pets}->[1];
ok(!Compare($tied1, $tied2), 'unsuccessfully compare dt/dt correctly');
ok(!Compare($tied1, $not_tied), 'unsuccessfully compare dt/not-dt correctly');

$tied1->rollback();
ok(Compare($tied1, $tied2), 'successfully compare dt/dt correctly after rolling back');
ok(Compare($tied1, $not_tied), 'successfully compare dt/not-dt correctly after rolling back');
