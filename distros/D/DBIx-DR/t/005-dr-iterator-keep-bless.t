#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 10;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DBIx::DR::Iterator';
    use_ok 'Scalar::Util', 'blessed';
}


{
    package TstI;
    sub new {
        my ($self, $o) = @_;
        bless { %$o } => ref($self) || $self;
    }
}

package main;


subtest 'normal bless ARRAYREF' => sub {
    plan tests => 9;
    my $aref = [ { id => 1 }, { id => 2 }, { id => 3 } ];
    my $i = DBIx::DR::Iterator->new($aref, -item => 'tst_i');

    for (0 .. $#$aref) {
        ok !blessed($i->{fetch}[$_]), "item[$_] not blessed";
    }

    while (my $a = $i->next) {
        isa_ok $a => TstI::, 'item fetched';
    }
    for (0 .. $#$aref) {
        ok blessed($i->{fetch}[$_]), "item[$_] blessed";
    }
};

subtest 'normal constructor ARRAYREF' => sub {
    plan tests => 9;
    my $aref = [ { id => 1 }, { id => 2 }, { id => 3 } ];
    my $i = DBIx::DR::Iterator->new($aref, -item => 'tst_i#new');

    for (0 .. $#$aref) {
        ok !blessed($i->{fetch}[$_]), "item[$_] not blessed";
    }

    while (my $a = $i->next) {
        isa_ok $a => TstI::, 'item fetched';
    }
    for (0 .. $#$aref) {
        ok blessed($i->{fetch}[$_]), "item[$_] blessed";
    }
};

subtest 'normal bless HASHREF' => sub {
    plan tests => 9;
    my $href = { a => { id => 1 }, b => { id => 2 }, c => { id => 3 } };
    my $i = DBIx::DR::Iterator->new($href, -item => 'tst_i');

    for (keys %$href) {
        ok !blessed($i->{fetch}{$_}), "item{$_} not blessed";
    }

    while (my $a = $i->next) {
        isa_ok $a => TstI::, 'item fetched';
    }
    for (keys %$href) {
        ok blessed($i->{fetch}{$_}), "item{$_} blessed";
    }
};

subtest 'normal constructor HASHREF' => sub {
    plan tests => 9;
    my $href = { a => { id => 1 }, b => { id => 2 }, c => { id => 3 } };
    my $i = DBIx::DR::Iterator->new($href, -item => 'tst_i#new');

    for (keys %$href) {
        ok !blessed($i->{fetch}{$_}), "item{$_} not blessed";
    }

    while (my $a = $i->next) {
        isa_ok $a => TstI::, 'item fetched';
    }
    for (keys %$href) {
        ok blessed($i->{fetch}{$_}), "item{$_} blessed";
    }
};

subtest 'normal bless ARRAYREF no keep_blessed' => sub {
    plan tests => 9;
    my $aref = [ { id => 1 }, { id => 2 }, { id => 3 } ];
    my $i = DBIx::DR::Iterator->new($aref, -item => 'tst_i', -keep_blessed => 0);

    for (0 .. $#$aref) {
        ok !blessed($i->{fetch}[$_]), "item[$_] not blessed";
    }

    while (my $a = $i->next) {
        isa_ok $a => TstI::, 'item fetched';
    }
    for (0 .. $#$aref) {
        ok blessed($i->{fetch}[$_]), "item[$_] ALWAYS keep blessed";
    }
};

subtest 'normal constructor ARRAYREF no keep_blessed' => sub {
    plan tests => 9;
    my $aref = [ { id => 1 }, { id => 2 }, { id => 3 } ];
    my $i = DBIx::DR::Iterator->new($aref, -item => 'tst_i#new', -keep_blessed => 0);

    for (0 .. $#$aref) {
        ok !blessed($i->{fetch}[$_]), "item[$_] not blessed";
    }

    while (my $a = $i->next) {
        isa_ok $a => TstI::, 'item fetched';
    }
    for (0 .. $#$aref) {
        ok !blessed($i->{fetch}[$_]), "item[$_] NOT blessed";
    }
};

subtest 'normal bless HASHREF no keep_blessed' => sub {
    plan tests => 9;
    my $href = { a => { id => 1 }, b => { id => 2 }, c => { id => 3 } };
    my $i = DBIx::DR::Iterator->new($href, -item => 'tst_i', -keep_blessed => 0);

    for (keys %$href) {
        ok !blessed($i->{fetch}{$_}), "item{$_} not blessed";
    }

    while (my $a = $i->next) {
        isa_ok $a => TstI::, 'item fetched';
    }
    for (keys %$href) {
        ok blessed($i->{fetch}{$_}), "item{$_} ALWAYS keep blessed";
    }
};

subtest 'normal constructor HASHREF no keep_blessed' => sub {
    plan tests => 9;
    my $href = { a => { id => 1 }, b => { id => 2 }, c => { id => 3 } };
    my $i = DBIx::DR::Iterator->new($href, -item => 'tst_i#new', -keep_blessed => 0);

    for (keys %$href) {
        ok !blessed($i->{fetch}{$_}), "item{$_} not blessed";
    }

    while (my $a = $i->next) {
        isa_ok $a => TstI::, 'item fetched';
    }
    for (keys %$href) {
        ok !blessed($i->{fetch}{$_}), "item{$_} NOT blessed";
    }
};
