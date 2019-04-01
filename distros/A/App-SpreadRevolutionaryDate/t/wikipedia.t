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

use Test::More tests => 3;
use Test::NoWarnings;
use Test::Output;
use File::HomeDir;

use App::SpreadRevolutionaryDate;

@ARGV = ('--test', '--twitter');
my $data_start = tell DATA;
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);

stdout_like { $spread_revolutionary_date->spread } qr/Spread to Twitter: Nous sommes le.+! https:\/\/fr.wikipedia.org\/wiki\//, 'Spread to Twitter with wikipedia link';

@ARGV = ('--test', '--twitter', '--revolutionarydate_wikipedia_link', 0);
seek DATA, $data_start, 0;
my $spread_no_wikipedia_link = App::SpreadRevolutionaryDate->new(\*DATA);
stdout_like { $spread_no_wikipedia_link->spread } qr/Spread to Twitter: Nous sommes le.+!/, 'Spread to Twitterwitout wikipedia link';

__DATA__

[twitter]
# Get these values from https://apps.twitter.com/
consumer_key        = 'ConsumerKey'
consumer_secret     = 'ConsumerSecret'
access_token        = 'AccessToken'
access_token_secret = 'AccessTokenSecret'
