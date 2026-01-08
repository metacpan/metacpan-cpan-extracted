#!/usr/bin/perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2026 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;

BEGIN {
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
}
use open qw(:std :encoding(UTF-8));
binmode(DATA, ":encoding(UTF-8)");

use Test::More tests => 2;
use Test::NoWarnings;
use Test::Output;
use File::HomeDir;


use App::SpreadRevolutionaryDate;

@ARGV = ('--test', '--mastodon', '--locale', 'en');
my $data_start = tell DATA;
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);

# Default message
stdout_like { $spread_revolutionary_date->spread } qr/^(?:Message 1: )?Diffusé sur Mastodon : Chalut ! Aujourd'hui, (?:Lourdi|Pardi|Morquidi|Jourdi|Dendrevi|Sordi|Mitanche) \d+, c'est la Sainte?-[^.]+\..+Bonne.+fête.+à.+tou(?:te)?s.+les.+ !.+with.+image.+path:.+groucha\.png.+,.+alt:.+Grouchat.+de.+Téléchat.+:.+«[^«]+»$/s, 'Spread default on Mastodon';

__DATA__

msgmaker = 'Telechat'

[mastodon]
# Get these values from https://<your mastodon instance>/settings/applications
instance        = 'Instance'
client_id       = 'ClientId'
client_secret   = 'ClientSecret'
access_token    = 'AccessToken'
