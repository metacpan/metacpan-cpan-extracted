#!/usr/bin/perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use utf8;

BEGIN {
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
    $ENV{PERL_UNICODE} = 'AS';
}
use open qw(:std :encoding(UTF-8));
binmode(DATA, ":encoding(UTF-8)");

use Test::More tests => 6;
use Test::Output;
use Test::NoWarnings;

use App::SpreadRevolutionaryDate;

@ARGV = ('--locale', 'fr');
my $data_start = tell DATA;
my $fr_spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $fr_spread_revolutionary_date->spread } qr/Diffusé sur Twitter : Nous sommes le/, 'Spread on Twitter in French';

@ARGV = ('--locale', 'en');
seek DATA, $data_start, 0;
my $en_spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $en_spread_revolutionary_date->spread } qr/Spread on Twitter: We are/, 'Spread on Twitter in English';

@ARGV = ('--locale', 'it');
seek DATA, $data_start, 0;
my $it_spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $it_spread_revolutionary_date->spread } qr/Diffondi su Twitter : È/, 'Spread on Twitter in Italian';

@ARGV = ('--locale', 'es');
seek DATA, $data_start, 0;
my $es_spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $es_spread_revolutionary_date->spread } qr/Difundido en Twitter: ¡Estamos el/, 'Spread on Twitter in French not Spanish';

@ARGV = ('--locale', 'tlh');
seek DATA, $data_start, 0;
my $klingon_spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $klingon_spread_revolutionary_date->spread } qr/Diffusé sur Twitter : Nous sommes le/, 'Spread on Twitter in Klingon';

__DATA__

test
twitter

[twitter]
# Get these values from https://apps.twitter.com/
consumer_key        = 'ConsumerKey'
consumer_secret     = 'ConsumerSecret'
access_token        = 'AccessToken'
access_token_secret = 'AccessTokenSecret'
