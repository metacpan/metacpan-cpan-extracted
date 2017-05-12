#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use AE;
use AnyEvent::Pg::Pool;

$Pg::PQ::debug = -1;
$AnyEvent::Pg::debug = -1;

my $cv = AE::cv();

my $db = AnyEvent::Pg::Pool->new("dbname=pgpqtest");
my $w = $db->listen('foo',
                    on_listener_started => sub { say "started!!!" },
                    on_notify           => sub { say "foo!" });

warn "waiting for notifications!\n";

$cv->recv();

