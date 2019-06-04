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
use 5.014;
use utf8;

BEGIN {
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
}
use open qw(:std :encoding(UTF-8));
binmode(DATA, ":encoding(UTF-8)");

use Test::More tests => 7;
use Test::NoWarnings;
use Test::Output;
use File::HomeDir;


use App::SpreadRevolutionaryDate;

@ARGV = ('--test', '--twitter', '--locale', 'en');
my $data_start = tell DATA;
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);

# Default message
stdout_like { $spread_revolutionary_date->spread } qr/Spread on Twitter: Goodbye old world, hello revolutionary worlds$/, 'Spread default on Twitter';

# Set message
@ARGV = ('--test', '--twitter', '--promptuser_default', 'Thinking, attacking, building – such is our fabulous agenda.');
seek DATA, $data_start, 0;
$spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $spread_revolutionary_date->spread } qr/Diffusé sur Twitter : Thinking, attacking, building – such is our fabulous agenda\.$/, 'Spread message on Twitter';

# Default message in Italian
@ARGV = ('--test', '--twitter', '--locale', 'it');
seek DATA, $data_start, 0;
$spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $spread_revolutionary_date->spread } qr/Diffondi su Twitter : Goodbye old world, hello revolutionary worlds$/, 'Spread in Italian';

# Default message in Spanish
@ARGV = ('--test', '--twitter', '--locale', 'es');
seek DATA, $data_start, 0;
$spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $spread_revolutionary_date->spread } qr/Difundido en Twitter: Goodbye old world, hello revolutionary worlds$/, 'Spread in Italian';

# Use locale oustide of languages allowed by RevolutionaryDate
@ARGV = ('--test', '--twitter', '--locale', 'de');
seek DATA, $data_start, 0;
$spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $spread_revolutionary_date->spread } qr/Überträgt auf Twitter: Goodbye old world, hello revolutionary worlds$/, 'Spread in German';

# Default message in French for untranslated locale
@ARGV = ('--test', '--twitter', '--locale', 'tlh');
seek DATA, $data_start, 0;
$spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $spread_revolutionary_date->spread } qr/Spread on Twitter: Goodbye old world, hello revolutionary worlds$/, 'Spread in Klingon';

__DATA__

msgmaker = 'PromptUser'

[twitter]
# Get these values from https://apps.twitter.com/
consumer_key        = 'ConsumerKey'
consumer_secret     = 'ConsumerSecret'
access_token        = 'AccessToken'
access_token_secret = 'AccessTokenSecret'
