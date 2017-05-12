#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul;

use AnyEvent;
use AnyEvent::Consul;

my $tc = eval { Test::Consul->start };

SKIP: {
    skip "consul test environment not available", 17 unless $tc;

    my $kv = AnyEvent::Consul->kv(port => $tc->port);
    ok $kv, "got KV API object";

    my $cv = AE::cv;

    $kv->put(foo => "bar", cb => sub {
        my ($r, $meta) = @_;
        ok $r, "key was updated";

        $kv->get("foo", cb => sub {
            my ($r, $meta) = @_;
            is $r->value, "bar", "returned KV has correct value";
            isa_ok $meta, 'Consul::Meta', "got server meta object";

            $kv->get("foo", index => $meta->index, cb => sub {
                my ($r, $meta) = @_;
                is $r->value, "baz", "watched KV has correct value";
                $cv->send;
            });

            $kv->put(foo => "baz", cb => sub {
                my ($r, $meta) = @_;
                ok $r, "key was updated";
            });
        });
    });

    $cv->recv;
}

done_testing;
