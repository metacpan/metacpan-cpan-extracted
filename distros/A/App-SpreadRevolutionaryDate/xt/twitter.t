#!perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

use Test::More;
use Test::Output;
use File::HomeDir;

unless(   -f File::HomeDir->my_home . '/.config/spread-revolutionary-date/spread-revolutionary-date.conf'
       || -f File::HomeDir->my_home . '/.spread-revolutionary-date.conf') {
  plan skip_all => 'No user config file found';
} else {
  plan tests => 1;
}

use App::SpreadRevolutionaryDate;

@ARGV = ('--test', '--twitter');
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new;

stdout_like { $spread_revolutionary_date->spread } qr/Spread to Twitter:/, 'Spread to Twitter';
