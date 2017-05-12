#!perl -T
use strict;
use warnings;
use lib qw(t);
use Test::More;
use CD;

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 5);
}

Music::CD->CONSTRUCT;
my $row = Music::CD->retrieve_all->first;
ok $row->can('param');
ok $row->param('artist') eq 'foo';

$row->param('artist' => 'baz');

ok $row->param('artist') eq 'baz';
ok $row->is_changed;

$row->discard_changes; # stop warning

ok not $row->is_changed;

