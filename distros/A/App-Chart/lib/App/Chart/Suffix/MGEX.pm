# Minneapolis Grain Exchange (MGEX) setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Suffix::MGEX;
use 5.010;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $timezone_minneapolis = App::Chart::TZ->new
  (name     => __('Minneapolis'),
   # no separate Minneapolis in Olson database
   choose   => [ 'America/Minneapolis', 'America/Chicago' ],
   fallback => 'CST+6');

my $pred = App::Chart::Sympred::Suffix->new ('.MGEX');
$timezone_minneapolis->setup_for_symbol ($pred);

# (source-help! mgex-symbol?
# 	      __p('manual-node','Minneapolis Grain Exchange'))


#------------------------------------------------------------------------------
# weblink - product info
#
# Believe these overview pages are more helpful than the contracts specs
# page.

App::Chart::Weblink->new
  (pred => $pred,
   name => __('MGEX _Product Information'),
   desc => __('Open web browser at the Minneapolis Grain Exchange product information page for this company'),
   proc => sub {
     my ($symbol) = @_;
     my $commodity = App::Chart::symbol_commodity ($symbol);
     if ($commodity eq 'MW' || $commodity eq 'MWE') {
       return 'http://www.mgex.com/spring_wheat.html';
     } else {
       return 'http://www.mgex.com/indexes_index.html';
     }
   });


#-----------------------------------------------------------------------------
# intraday
#
# Alternately to do it with the main App::Chart::Barchart
#     $App::Chart::Barchart::intraday_pred->add ($pred);
#

barchart_customer_intraday
  ($pred,
   'http://customer1.barchart.com/cgi-bin/mri/mgexchart.htx?page=chart&code=mfo&org=com&crea=Y');

#  (lambda (symbol)
#    (let ((date-time (mgex-quote-adate-time symbol)))
#      (set-first! date-time (adate->tdate (first date-time)))))

#------------------------------------------------------------------------------
# The charts at KCBT and MGEX come from barchart.com and are the same style
# as barchart itself, ie. download a page which contains a generated
# 4-digit numbered .gif file.  The links from www.kcbt.com and www.mgex.com
# are preferred though, since the pages to get that gif file are only
# 26kbytes instead of 50k from barchart.com's native links.
#
# Z10 MEDHI gives 7 days, Z05 MED gives 1.5 or 2, Z10 HIGH gives about 10 days

sub barchart_customer_intraday {
  my ($pred, $base_url, $tdate_time_proc) = @_;

  require App::Chart::IntradayHandler;
  App::Chart::IntradayHandler->new
      (pred => $pred,
       proc => \&barchart_customer_url,
       mode => '1.5d',
       name => __('_1 1/2 Days'),
       base_url => $base_url);
  App::Chart::IntradayHandler->new
      (pred => $pred,
       proc => \&barchart_customer_url,
       mode => '7d',
       name => __nx('_{n} Day',
                    '_{n} Days',
                    7,
                    n => 7),
       base_url => $base_url);
}

my %intraday_mode_to_data = ('1.5d' => '&data=Z05', # 5 minute, linear scale
                             '7d'   => '&data=Z10&den=MEDHI');

sub barchart_customer_url {
  my ($self, $symbol, $mode) = @_;

  # my $mdate = latest_symbol_mdate ($symbol, ($tdate_time_proc->())[0]);
  # mdate_to_MYY ($mdate);

  App::Chart::Download::status
      (__x('Intraday page {symbol} {mode}',
           symbol => $symbol,
           mode   => $mode));

  my $url = $self->{'base_url'}
    . '&sly=N&sym='
      . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol))
        . $intraday_mode_to_data{$mode};
  App::Chart::Download::verbose_message ("Intraday page", $url);

  my $resp = App::Chart::Download->get ($url);
  return barchart_customer_resp_to_url ($resp, $symbol);
}
# separate func for offline testing ...
sub barchart_customer_resp_to_url {
  my ($resp, $symbol) = @_;
  my $content = $resp->decoded_content (raise_error => 1);

  # This doesn't use java_document_write() and HTML::LinkExtor because the
  # width/height in the document.write() in the <img> bit is computed, which
  # java_document_write() can't handle.  The src="" part of it is constant
  # though.  There's only a single <img> to pick out.
  if ($content =~ /<img src="([^"]+)"/i) {
    return $1;  # url
  }
  if ($content =~ /no chart available/i) {
    die __x("No chart available for {symbol}\n",
            symbol => $symbol);
  }
  die 'Barchart Customer: Intraday page not matched';
}

1;
__END__
