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

use Test::More tests => 3;
use Test::NoWarnings;
use Test::Output;
use File::HomeDir;


use App::SpreadRevolutionaryDate;

@ARGV = ('--test', '--twitter');
my $data_start = tell DATA;
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);

# Default message
stdout_like { $spread_revolutionary_date->spread } qr/Spread to Twitter: Goodbye old world, hello revolutionary worlds$/, 'Spread default to Twitter';

# Set message
@ARGV = ('--test', '--twitter', '--promptuser_default', 'Thinking, attacking, building – such is our fabulous agenda.');
seek DATA, $data_start, 0;
$spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $spread_revolutionary_date->spread } qr/Spread to Twitter: Thinking, attacking, building – such is our fabulous agenda\.$/, 'Spread message to Twitter';


__DATA__

msgmaker = 'PromptUser'

[twitter]
# Get these values from https://apps.twitter.com/
consumer_key        = 'ConsumerKey'
consumer_secret     = 'ConsumerSecret'
access_token        = 'AccessToken'
access_token_secret = 'AccessTokenSecret'
