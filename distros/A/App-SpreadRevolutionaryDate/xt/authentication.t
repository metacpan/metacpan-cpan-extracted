#!/usr/bin/perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2024 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

use Test::More;
use File::HomeDir;

unless(   -f File::HomeDir->my_home . '/.config/spread-revolutionary-date/spread-revolutionary-date.conf'
       || -f File::HomeDir->my_home . '/.spread-revolutionary-date.conf') {
  plan skip_all => 'No user config file found';
} else {
  plan tests => 3;
}

use App::SpreadRevolutionaryDate;

@ARGV = ('--test', '--twitter_api=1');
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new;

ok($spread_revolutionary_date->targets->{bluesky}->obj->{did}, 'Bluesky connection with actual credentials in user conf');

eval { $spread_revolutionary_date->targets->{twitter}->obj->verify_credentials };
ok(!$@, 'Twitter connection with actual credentials in user conf');

eval { $spread_revolutionary_date->targets->{mastodon}->obj->get_account };
ok(!$@, 'Mastodon connection with actual credentials in user conf');
