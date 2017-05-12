#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use LWP;
use Data::Dumper;
use File::Slurp 'slurp';
use App::Chart::Suffix::LME;
use HTML::TreeBuilder;
use List::Util;

{
  my $content = slurp (<~/chart/samples/lme/dataprices_historical.asp-2.html>);
  utf8::downgrade ($content);
  my $f = App::Chart::Suffix::LME::historical_xls_parse($content);
  #   @{$f->{'files'}} = sort { $a->{'month_iso'} cmp $b->{'month_iso'} } @{$f->{'files'}};
  print Dumper($f);
  exit 0;
}
{
  my @files = App::Chart::Suffix::LME::historical_xls_files();
  print Dumper(\@files);
  exit 0;
}
{
  my $resp = HTTP::Response->new(200,'OK');
  my $content = slurp (<~/chart/samples/lme/August_2008.xls>);
  $resp->content($content);
  my $h = App::Chart::Suffix::LME::monthxls_parse($resp);
  print "h= ",Dumper($h);
  # App::Chart::Download::write_daily_group ($h);
  exit 0;
}



{
  App::Chart::Database->write_extra ('', 'lme-historical-xls', undef);
  exit 0;
}


{
  my $resp = HTTP::Response->new(200,'OK');
  # my $content = slurp (<~/chart/samples/lme/Dataprices_daily_metals-18sep08.aspx.html>);
  # my $content = slurp (<~/chart/samples/lme/Dataprices_Steels_OfficialPrices.aspx-20sep08.html>);
  my $content = slurp (<~/chart/samples/lme/Dataprices_daily_prices_plastics.aspx-20sep08.html>);
  $resp->content($content);
  $resp->content_type('text/html; charset=iso-8859-1');
  my $h = App::Chart::Suffix::LME::daily_metals_parse($resp);
  print Dumper($h);
#  App::Chart::Download::write_latest_group ($h);
  exit 0;
}
{
  my $resp = HTTP::Response->new(200,'OK');
  my $content = slurp (<~/chart/samples/lme/Dataprices_daily_prices_plastics.aspx-20sep08.html>);
  $resp->content($content);
  $resp->content_type('text/html');
  my $h = App::Chart::Suffix::LME::daily_plastics_parse($resp);
  print "h= ",Dumper($h);
  # App::Chart::Download::write_latest_group ($h);
  exit 0;
}

{
  my $resp = HTTP::Response->new(200,'OK');
  my $content = slurp (<~/chart/samples/lme/volumes_May_08.xls>);
  $resp->content($content);
  my $h = App::Chart::Suffix::LME::volume_parse ($resp);
  print Dumper($h);
  exit 0;
}

{
  require HTTP::Cookies;
  my $jar = HTTP::Cookies->new;
  my $ts = App::Chart::Suffix::LME::jar_get_login_timestamp($jar);
  print Dumper($ts);

  App::Chart::Suffix::LME::jar_set_login_timestamp($jar);
  print "Jar as_string:\n",$jar->as_string;

  require URI;
  require HTTP::Request;
  my $uri = URI->new;
  $uri->scheme ('http');
  $uri->host (App::Chart::Suffix::LME::LOGIN_DOMAIN());
  $uri->path ('/');
  my $req = HTTP::Request->new ('GET', $uri);
  #  $req->header ('Host', $uri->host);
  my $ua = LWP::UserAgent->new;
  $ua->prepare_request ($req);
  $jar->add_cookie_header ($req);
  print $req->as_string,"\n";

  $jar->set_cookie (1,                    # version
                    'another',            # key
                    'foo bar',            # value
                    '/',                  # path
                    App::Chart::Suffix::LME::LOGIN_DOMAIN(), # domain
                    0,                    # port
                    0,                    # path_spec
                    0,                    # secure
                    120,                  # maxage
                    0,                    # discard
                    { Comment => 'hi',
                      Version => 1 });
  print "Jar as_string:\n",$jar->as_string;
  $jar->add_cookie_header ($req);
  print $req->as_string,"\n";

  $ts = App::Chart::Suffix::LME::jar_get_login_timestamp($jar);
  print Dumper($ts);
  exit 0;
}

{
  my $h = App::Chart::Suffix::LME::historical_xls_list();
  print Dumper($h);
  exit 0;
}
{
  my $tdate = App::Chart::Suffix::LME::monthxls_available_tdate();
  print "$tdate ",App::Chart::tdate_to_iso($tdate),"\n";
  exit 0;
}








sub table_num_rows {
  my ($elem) = @_;
  $elem = List::Util::first {ref $_ && $_->tag eq 'tbody'} $elem->content_list
    or return 0;
  my $count = 0;
  foreach my $subelem ($elem->content_list) {
    if (ref $subelem && $subelem->tag eq 'tr') {
      $count++;
    }
  }
  return $count;
}

sub table_first_row {
  my ($elem) = @_;
  $elem = List::Util::first {ref $_ && $_->tag eq 'tbody'} $elem->content_list
    or return undef;
  $elem = List::Util::first {ref $_ && $_->tag eq 'tr'} $elem->content_list
    or return undef;
  return $elem;
}

sub table_row_num_columns {
  my ($elem) = @_;
  my $count = 0;
  foreach my $subelem ($elem->content_list) {
    if (ref $subelem && $subelem->tag eq 'td') {
      $count++;
    }
  }
  return $count;
}

sub traverse {
  my ($elem) = @_;

#  $elem->traverse(sub { mung($_[0]); return 1; });

#   print $elem->tag,"\n";
#   if ($elem->tag eq 'table') { mung ($elem); }
#   foreach my $subelem ($elem->content_list) {
#     if (ref $subelem) {
#       traverse ($subelem);
#     }
#   }
}

{
  my $tree = HTML::TreeBuilder->new; # empty tree
  $tree->parse_file($ENV{'HOME'}.'/chart/samples/lme/Dataprices_daily_prices_plastics.aspx-30jul07.html');
#   print "And here it is, bizarrely rerendered as HTML:\n",
#     $tree->as_HTML, "\n";
traverse ($tree);

#   print "Hey, here's a dump of the parse tree of $file_name:\n";
   $tree->dump; # a method we inherit from HTML::Element
  exit 0;
}









{
  print App::Chart::Suffix::LME::login_is_logged_in() ? 1 : 0,"\n";
  App::Chart::Suffix::LME::login_ensure();
  exit 0;
}



{
  my $resp = HTTP::Response->new();
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/lme/exchange_rates.html');
  $resp->content($content);
  print Dumper (App::Chart::Suffix::LME::fiveday_parse($resp));
  exit 0;
}
