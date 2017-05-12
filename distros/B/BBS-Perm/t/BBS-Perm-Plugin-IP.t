#!/usr/bin/perl
use strict;
use warnings;
use Encode;

use Test::More tests => 10;

BEGIN { use_ok('BBS::Perm::Plugin::IP'); }
my $ip = BBS::Perm::Plugin::IP->new( qqwry => '/opt/QQWry.Dat' );

isa_ok( $ip, 'BBS::Perm::Plugin::IP', '$ip' );
isa_ok( $ip->widget, 'Gtk2::Statusbar', '$ip->widget' );

SKIP: {
    skip 'have no QQWry.Dat file', 7;
    $ip->remove('no exists');

    eq_hash( $ip->ip, {}, 'remove 0 size' );

    my $ip1 = '166.111.166.111';
    $ip->add('166.111.166.111');
    is( scalar keys %{ $ip->ip }, 1, 'add' );
    $ip->add('59.66.158.28');
    is( scalar keys %{ $ip->ip }, 2, 'add an extra' );

    $ip->remove('59.66.158.28');
    is( scalar keys %{ $ip->ip }, 1, 'remove' );

    $ip->remove('166.111.166.111');
    eq_hash( $ip->ip, {}, 'remove' );

    $ip->add('166.111.166.111');
    $ip->add('166.111.166.111');
    is( scalar keys %{ $ip->ip }, 1, 'add dumplicated ip' );
    $ip->add('59.66.158.28');
    $ip->clear;
    eq_hash( $ip->ip, {}, 'clear' );
}

