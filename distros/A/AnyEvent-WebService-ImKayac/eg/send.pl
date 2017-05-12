#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::WebService::ImKayac;
use Config::Pit;

my %conf = (%{ pit_get('im.kayac.com') }, type => 'secret');

my $cv = AE::cv;

my $im = AnyEvent::WebService::ImKayac->new(%conf);

$im->send( message => 'Hello! test send', cb => sub {
        my ($hdr, $json, $reason) = @_;

        if ( $json ) {
            if ( $json->{result} eq "posted" ) {
                warn "success";
            }
            else {
                warn $json->{error};
            }
        }
        else {
            warn $reason;
        }

        $cv->send;
    });

$cv->recv;
