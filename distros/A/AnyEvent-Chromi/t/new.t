#!/usr/bin/perl -w

use Test::Simple tests => 5;
use AnyEvent::Chromi;

{
    my $c = AnyEvent::Chromi->new();
    ok(defined $c);
}
{
    my $c = AnyEvent::Chromi->new(mode => 'client');
    ok(defined $c);
}

{
    my $c = AnyEvent::Chromi->new(mode => 'client', on_connect => sub { print "connected\n"; } );
    ok(defined $c);
}
{
    my $c = AnyEvent::Chromi->new(mode => 'server', port => 7000);
    ok(defined $c);
}
{
    my $c = AnyEvent::Chromi->new(mode => 'server', port => 7001, on_connect => sub { print "connected\n"; } );
    ok(defined $c);
}
