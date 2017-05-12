# Copyright 2008, 2009, 2011 Kevin Ryde

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

package App::Chart::FinanceQuote;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 'App-Chart';
use App::Chart::Download;
use App::Chart::LatestHandler;

use constant DEBUG => 0;

sub setup {
  my ($class, %options) = @_;
  my $modules = delete $options{'modules'} or croak;
  my $method = delete $options{'method'} or croak;
  my $suffix = delete $options{'suffix'} or croak;
  my $pred = delete $options{'pred'}
    || App::Chart::Sympred::Suffix->new ($suffix);
  App::Chart::LatestHandler->new
      (pred => $pred,
       proc => sub { latest_download ($modules, $method, $suffix, @_) },
       %options);
}

sub latest_download {
  my ($modules, $method, $suffix, $symbol_list) = @_;

  if (DEBUG) { require Data::Dumper;
               print Data::Dumper::Dumper($modules); }

  # lose .FQ
  $symbol_list = [ map {App::Chart::symbol_sans_suffix($_)} @$symbol_list ];

  App::Chart::Download::status
      (__x('FinanceQuote {method} {symbol_range}',
           method => $method,
           symbol_range =>
           App::Chart::Download::symbol_range_string ($symbol_list)));
  require Finance::Quote;
  my $q = Finance::Quote->new (@$modules);
  my $quotes = $q->fetch ($method, @$symbol_list);

  require App::Chart::Suffix::FQ;
  my $h = App::Chart::Suffix::FQ::quotes_to_group
    ($suffix, $symbol_list, $quotes);
  App::Chart::Download::write_latest_group ($h);
}

1;
__END__
