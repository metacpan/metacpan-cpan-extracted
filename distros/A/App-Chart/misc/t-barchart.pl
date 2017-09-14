#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2015, 2016, 2017 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use LWP;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Slurp 'slurp';
use App::Chart;
use App::Chart::Barchart;


{
  my $symbol = 'GCZ17.CMX';
  my $mode = '1d';
  require App::Chart::IntradayHandler;
  $App::Chart::option{'verbose'} = 2;
  my $handler = App::Chart::IntradayHandler->handler_for_symbol_and_mode
    ($symbol, $mode)
      // die "not found";
  $handler->download ($symbol);
  exit 0;
}
{
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = slurp("$ENV{HOME}/chart/samples/barchart/CLZ16.html");
  $resp->content($content);
  $resp->content_type('text/html');
  my $h = App::Chart::Barchart::fiveday_parse ('CLZ16.NYM', $resp);
  print Dumper ($h);
  # App::Chart::Download::write_latest_group ($h);
  exit 0;
}


{
  my $req_url = 'http://www.barchart.com/chart.php?sym=CLZ10&style=technical&p=I&d=O&im=&sd=&ed=&size=M&log=0&t=BAR&v=2&g=1&evnt=1&late=1&o1=&o2=&o3=&x=41&y=11&indicators=&addindicator=&submitted=1&fpage=&txtDate=#jump';

  require HTTP::Request;
  my $req = HTTP::Request->new ('GET', $req_url);

  my $resp = HTTP::Response->new(200, 'OK');
  $resp->request ($req);
  my $content = slurp(<~/chart/samples/barchart/chart.php-daily.html>);
  $resp->content($content);
  $resp->content_type('application/x-javascript');

  my $img_url = App::Chart::Barchart::intraday_resp_to_url ($resp, 'XYZ');
  say $img_url;
  exit 0;
}




{
  my $url = 'http://www.barchart.com/detailedquote/futures/CLZ10';
  require URI;
  my $uri = URI->new($url);

  require HTTP::Request;
  my @headers = (Referer => $url);
  my $req = HTTP::Request->new ('GET', $url, \@headers, undef);
  print $req->uri,"\n";

  require HTTP::Response;
  my $resp = HTTP::Response->new
    (200, 'OK',
     [ 'Set-Cookie', 'bcad_int=1; path=/; domain=barchart.com;' ]);
  $resp->request ($req);
  print $resp->as_string,"\n";

  require HTTP::Cookies;
  my $jar = HTTP::Cookies->new;
  #   $jar->set_cookie(1,               # version
  #                    'bcad_int',      # key
  #                    '1',             # value
  #                    '/',             # path
  #                    'barchart.com'); # domain
  $jar->extract_cookies ($resp);
  print $jar->as_string, "\n";

  require App::Chart::UserAgent;
  my $ua = App::Chart::UserAgent->instance;

  print HTTP::Cookies::_host($req,$uri),"\n";


  #  $ua->prepare_request ($req);
  $jar->add_cookie_header($req);

  print "req now\n", $req->as_string, "\n";

  exit 0;
}






{
  exit 0;
}

{
  my $resp = HTTP::Response->new(200, 'OK');
  #  my $content = slurp(<~/chart/samples/barchart/chart.asp.html>);
  my $content = slurp(<~/chart/samples/barchart/chart-no-chart.html>);
  $resp->content($content);
  $resp->content_type('application/x-javascript');

  my $url = App::Chart::Barchart::intraday_resp_to_url ($resp, 'XYZ');
  say $url;
  exit 0;
}
{
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = slurp(<~/chart/samples/barchart/ifutpage-NX.asp.html>);
  $resp->content($content);
  $resp->content_type('text/html');
  my $h = App::Chart::Barchart::ifutpage_parse ('NX', '.SIMEX', $resp);
  $h->{'resp'} = '...';
  print Dumper ($h);
  App::Chart::Download::crunch_h ($h);
  print Dumper ($h);
  # App::Chart::Download::write_latest_group ($h);
  exit 0;
}

{
  my $symbol = 'FOO';
  App::Chart::symbol_setups ($symbol);
  my $date = '1970-01-01';
  my $time = '00:00:00';
  ($date, $time) = App::Chart::Barchart::datetime_chicago_to_symbol
    ($symbol, $date, $time);
  print "$date, $time\n";
  exit 0;
}


exit 0;
