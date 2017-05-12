#!/usr/bin/perl -w

use lib '/Users/dws/checkouts/github/AnyEvent-Chromi/lib';
use 5.014;

use AnyEvent;
use AnyEvent::Chromi;

sub main
{
    my $cv = AnyEvent->condvar;

    AnyEvent::Chromi->new(mode => 'client', on_connect => sub {
        my ($chromi) = @_;
        $chromi->call(
            'chrome.windows.getAll', [{ populate => Types::Serialiser::true }],
            sub {
                my ($status, $reply) = @_;
                $status eq 'done' or return;
                defined $reply and ref $reply eq 'ARRAY' or return;
                map { say "$_->{url}" } @{$reply->[0]{tabs}};
                $cv->send();
            }
        );
    });

    $cv->wait();
}

main;
