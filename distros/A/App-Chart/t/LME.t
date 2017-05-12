#!/usr/bin/perl -w

# App::Chart::Suffix::LME tests.

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More 0.82 tests => 8;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Suffix::LME;

{
  my @weblink = App::Chart::Weblink->links_for_symbol ('CA.LME');
  is ($weblink[0]->url('CA.LME'),
      'http://www.lme.co.uk/copper.asp');
}
{
  my @weblink = App::Chart::Weblink->links_for_symbol ('XX.LME');
  is ($weblink[0]->url('XX.LME'),
      undef);
}

is (App::Chart::TZ->for_symbol ('COPPER.LME'),
    App::Chart::TZ->london,
    'COPPER.LME timezone london');

# not yet
# is (App::Chart::symbol_source_help ('COPPER.LME'),
#     __p('manual-node','London Metal Exchange'));


# is (App::Chart::Suffix::LME::Mmm_yyy_str_to_mdate ('January_1970'), 0);
# is (App::Chart::Suffix::LME::Mmm_yyy_str_to_mdate ('Mar_1970'), 2);
# is (App::Chart::Suffix::LME::Mmm_yyy_str_to_mdate ('Jan_1971'), 12);

{
  require HTTP::Cookies;
  my $jar = HTTP::Cookies->new;
  App::Chart::Suffix::LME::jar_set_login_timestamp($jar);
  my $ts = App::Chart::Suffix::LME::jar_get_login_timestamp($jar);
  ok (App::Chart::Download::timestamp_within ($ts, 3600),
      'current timestamp within 1 hour of now');
}

sub jar_count_cookies {
  my ($jar) = @_;
  my $count = 0;
  $jar->scan(sub { $count++ });
  return $count;
}

{
  require HTTP::Cookies;
  my $jar = HTTP::Cookies->new;
  my $str = App::Chart::Suffix::LME::http_cookies_get_string ($jar);
  diag explain $str;
  ok (1, 'jar empty -> string');

  App::Chart::Suffix::LME::http_cookies_set_string ($jar, $str);
  ok (1, 'empty string -> jar');

  App::Chart::Suffix::LME::jar_set_login_timestamp($jar);

  $str = App::Chart::Suffix::LME::http_cookies_get_string ($jar);
  diag explain $str;
  ok (1, 'one cookie -> string');

  App::Chart::Suffix::LME::http_cookies_set_string ($jar, $str);
  is (jar_count_cookies($jar), 1,
      'string -> one cookie');
}

exit 0;
