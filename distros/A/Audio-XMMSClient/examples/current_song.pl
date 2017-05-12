#!/usr/bin/perl

use strict;
use warnings;
use Audio::XMMSClient;

my $c = Audio::XMMSClient->new('perl-xmmsclient');
$c->connect or die;

my $r = $c->playback_current_id;
$r->wait;

exit unless $r->value;

$r = $c->medialib_get_info($r->value);
$r->wait;

print $r->value->{artist}, ' - ', $r->value->{album}, "\n";
