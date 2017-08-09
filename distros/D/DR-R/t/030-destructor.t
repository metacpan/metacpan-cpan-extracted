#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use Test::More tests    => 13;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::R';
}



package Guard;

sub new {
    my ($self, $cb) = @_;
    bless \$cb => ref($self) || $self;
}

sub DESTROY {
    my ($self) = @_;
    ${$self}->($self);
}

package main;

{
    my $count = 0;

    my $r = DR::R->new;

    ok $r => 'index created';

    {
        ok $r->insert([1,2], Guard->new(sub { $count++ })), 'guard inserted';
    }
    is $count, 0, 'destructor was not touched';
    undef $r;
    is $count, 1, 'destructor was called';
}
{
    my $count = 0;

    my $r = DR::R->new;

    ok $r => 'index created';

    {
        my $item;
        $item =  Guard->new(sub { $count++ });
        ok $r->insert([1,2], $item), 'guard inserted';
        $item = undef;
    }
    is $count, 0, 'destructor was not touched';
    undef $r;
    is $count, 1, 'destructor was called';
}
{
    my $count = 0;

    my $r = DR::R->new;

    ok $r => 'index created';

    {
        my $item =  Guard->new(sub { $count++ });
        ok $r->insert([1,2], $item), 'guard inserted';
        undef $item;
    }
    is $count, 0, 'destructor was not touched';
    undef $r;
    is $count, 1, 'destructor was called';
}
