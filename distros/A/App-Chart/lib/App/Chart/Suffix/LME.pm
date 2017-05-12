# London Metal Exchange (LME) setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2013, 2016 Kevin Ryde

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

package App::Chart::Suffix::LME;
use 5.010;
use strict;
use warnings;
use Carp;
use Date::Calc;
use Date::Parse;
use File::Temp;
use File::Basename;
use HTML::Form;
use List::Util;
use File::Slurp;
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::Sympred;
use App::Chart::Timebase::Months;
use App::Chart::TZ;
use App::Chart::Weblink;

use constant DEBUG => 0;


# As of July 2007, in https requests to secure.lme.com for the daily metals
# prices it seems essential to use http/1.1 persistent connections.  If
# "Connection: close" is requested by the client something fishy happens and
# the connection hangs at about byte 48887 out of about 62110 (waiting for
# the last 16kbyte tls packet).  This is with either gnutls or openssl and a
# trace with gnutls shows it just stops sending, though the TCP connection
# remains up.  Either the default http/1.1 persistence (no Connection header
# at all) or the compatibility "Connection: keep-alive" style seems to make
# it better.  Presumably it's something buggy in the server (Microsoft-IIS
# 6.0).

my $pred = App::Chart::Sympred::Suffix->new ('.LME');
App::Chart::TZ->london->setup_for_symbol ($pred);

# App::Chart::setup_source_help
#   ($pred, __p('manual-node','London Metal Exchange'));


my %polypropylene_hash = ('PP'=>1,'PA'=>1,'PE'=>1,'PN'=>1);
my %linearlow_hash     = ('LP'=>1,'LA'=>1,'LE'=>1,'LN'=>1);
my %steel_hash         = ('FM'=>1,'FF'=>1);

sub type {
  my ($symbol) = @_;
  my $commodity = App::Chart::symbol_commodity ($symbol);
  if ($polypropylene_hash{$commodity} || $linearlow_hash{$commodity}) {
    return 'plastics';
  }
  if ($steel_hash{$commodity}) {
    return 'steels';
  }
  return 'metals';
}

#-----------------------------------------------------------------------------
# weblink - commodity pages

App::Chart::Weblink->new
  (pred => $pred,
   name => __('LME _Commodity Page'),
   desc => __('Open web browser at the London Metal Exchange page for this commodity'),
   proc => sub {
     my ($symbol) = @_;

     if ($symbol =~ /^AA/) { return 'http://www.lme.co.uk/aluminiumalloy.asp' }
     if ($symbol =~ /^AH/) { return 'http://www.lme.co.uk/aluminium.asp' }
     if ($symbol =~ /^CA/) { return 'http://www.lme.co.uk/copper.asp' }
     if ($symbol =~ /^NA/) { return 'http://www.lme.co.uk/nasaac.asp' }
     if ($symbol =~ /^NI/) { return 'http://www.lme.co.uk/nickel.asp' }
     if ($symbol =~ /^PB/) { return 'http://www.lme.co.uk/lead.asp' }
     if ($symbol =~ /^SN/) { return 'http://www.lme.co.uk/tin.asp' }
     if ($symbol =~ /^ZS/) { return 'http://www.lme.co.uk/zinc.asp' }
     if ($symbol =~ /^F/)  { return 'http://www.lme.co.uk/steel.asp' }
     if ($symbol =~ /^P/)  { return 'http://www.lme.co.uk/plastics.asp' }
     if ($symbol =~ /^L/)  { return 'http://www.lme.co.uk/plastics.asp' }
     return undef;
   });


#-----------------------------------------------------------------------------
# HTTP::Cookies extras

# $jar is a HTTP::Cookies object, read $str into it with $jar->load (which
# would normally read from a file)
#
sub http_cookies_set_string {
  my ($jar, $str) = @_;
  my $fh = File::Temp->new (TEMPLATE => 'chart-cookie-jar-XXXXXX',
                            TMPDIR => 1);
  if (DEBUG) { print "cookie set tempfile ",$fh->filename,"\n"; }
  print $fh $str;
  close $fh or die;
  $jar->load ($fh->filename);
}

# $jar is a HTTP::Cookies object, return a string which is $jar->save output
# (which would normally go to a file)
#
sub http_cookies_get_string {
  my ($jar) = @_;
  my $fh = File::Temp->new (TEMPLATE => 'chart-cookie-jar-XXXXXX',
                            TMPDIR => 1);
  if (DEBUG) { print "cookie get $fh tempfile ",$fh->filename,"\n"; }
  $jar->save ($fh->filename);
  close $fh or die;
  # not certain if File::Temp 0.21 blessed handle is ok, use the filename
  return File::Slurp::slurp ($fh->filename);
}


#-----------------------------------------------------------------------------
# secure login
#
# This logs in at the data service page,
#
use constant LOGIN_URL =>
  'https://secure.lme.com/Data/Community/Login.aspx?ReturnUrl=%2fData%2fcommunity%2findex.aspx';
#
# The result is a cookie ".ASPXAUTH" recorded under "lme-cookie-jar" in the
# database ready for subsequent use.  An extra cookie with a dummy domain,
#
use constant LOGIN_DOMAIN  => 'chart-lme-logged-in.local';
#
# is used to note success.  Not sure how long a login is supposed to last
# (the server doesn't put an expiry on the cookie), but for now consider it
# expired after an hour,
#
use constant LOGIN_EXPIRY_SECONDS => 3600;
#

# create and return a new HTTP::Cookies which is the jar in the database
sub login_read_jar {
  require HTTP::Cookies;
  my $jar = HTTP::Cookies->new;
  my $str = App::Chart::Database->read_extra ('', 'lme-cookie-jar');
  if ($str) { http_cookies_set_string ($jar, $str); }
  return $jar;
}

# $jar is a HTTP::Cookies object, save it to the database
sub login_write_jar {
  my ($jar) = @_;
  App::Chart::Database->write_extra ('', 'lme-cookie-jar',
                                    http_cookies_get_string ($jar));
}

# return true if we're still logged in
sub login_is_logged_in {
  my $jar = login_read_jar();
  my $login_timestamp = jar_get_login_timestamp ($jar);
  return App::Chart::Download::timestamp_within ($login_timestamp,
                                                LOGIN_EXPIRY_SECONDS);
}

sub login_ensure {
  if (login_is_logged_in()) { return; }

  App::Chart::Download::status (__('LME login'));
  App::Chart::Database->write_extra ('', 'lme-cookie-jar', undef);

  my $username = App::Chart::Database->preference_get ('lme-username', undef);
  my $password = App::Chart::Database->preference_get ('lme-password', '');
  if (! defined $username || $username eq '') {
    die 'No LME username set in preferences';
  }

  require App::Chart::UserAgent;
  require HTTP::Cookies;
  my $ua = App::Chart::UserAgent->instance->clone;
  my $jar = HTTP::Cookies->new;
  $ua->cookie_jar ($jar);

  my $login_url = LOGIN_URL;
  $login_url = 'http://localhost/Login.aspx';
  my $resp = App::Chart::Download->get ($login_url, ua => $ua);

  my $content = $resp->decoded_content(raise_error=>1);
  my $form = HTML::Form->parse($content, $login_url)
    or die "LME login page not a form";

  # these are literal "$" in the field name
  $form->value ("_logIn\$_userID",   $username);
  $form->value ("_logIn\$_password", $password);

  my $req = $form->click();
  $ua->requests_redirectable ([]);
  $resp = $ua->request ($req);
  # The POST is to the Login.aspx page and success is a redirect to the main
  # data page /Data/community/index.aspx.  So failure is anything other than
  # 302, or no Location, or a Location but containing "Login".
  if ($resp->code != 302
      || ! $resp->header ('Location')
      || $resp->header ('Location') =~ /Login/) {
    die "LME: login failed";
  }

  jar_set_login_timestamp ($jar);
  login_write_jar ($jar);
}


sub jar_get_login_timestamp {
  my ($jar) = @_;
  my $login_timestamp;
  $jar->scan(sub {
               my ($version, $key, $val, $path, $domain, $port, $path_spec,
                   $secure, $expires, $discard, $hash) = @_;
               if ($domain eq LOGIN_DOMAIN && $key eq 'timestamp') {
                 $login_timestamp = $val;
               }
             });
  return $login_timestamp;
}
sub jar_set_login_timestamp {
  my ($jar) = @_;
  $jar->set_cookie (0,                    # version
                    'timestamp',          # key
                    App::Chart::Download::timestamp_now(), # value
                    '/',                  # path
                    LOGIN_DOMAIN,         # domain
                    0,                    # port
                    0,                    # path_spec
                    0,                    # secure
                    LOGIN_EXPIRY_SECONDS, # maxage
                    0);                   # discard
}


#-----------------------------------------------------------------------------
# Daily data

# return tdate for available daily report
# 
sub daily_available_date {
  my ($symbol) = @_;
  my $type = type($symbol);
  if ($type eq 'metals') {
    # http://www.lme.co.uk/who_how_ringtimes.asp
    #     Prices after second ring session each trading day, which would be
    #     16:15 maybe, try at 16:30.
    return App::Chart::Download::weekday_date_after_time
      (16,30, App::Chart::TZ->london, -1);
  }
  if ($type eq 'plastics') {
    # https://secure.lme.com/Data/community/Dataprices_daily_prices_plastics.aspx
    # per prices page, available at 2am the following day
    return App::Chart::Download::weekday_date_after_time
      (2,0, App::Chart::TZ->london, -1);
  }
  if ($type eq 'steels') {
    # per prices page, available at 2am the following day
    return App::Chart::Download::weekday_date_after_time
      (2,0, App::Chart::TZ->london, -1);
  }
  die;
}



#-----------------------------------------------------------------------------
# Daily price page parsing

sub daily_parse {
  my ($resp, $want_tdate) = @_;
  my @data = ();
  my $h = { source => __PACKAGE__,
            currency => 'USD',
            data => \@data };

  my $content = $resp->decoded_content (raise_error => 1);
  $content = mung_1x1_tables ($content);

  # Eg. "Official Prices, US$ per tonne for\n\t\t19 September 2008"
  # Eg. "LME Official Prices, US$ per tonne for 18 September 2008"
  #
  $content =~ /Prices.*?for\s*\n?\s*([0-9]{1,2}\s+[A-Za-z]+\s+[0-9][0-9][0-9][0-9])/i
    or die "LME daily: date not found";
  my $date = App::Chart::Download::Decode_Date_EU_to_iso ($1);
  if (defined $want_tdate) {
    my $want_date = App::Chart::tdate_to_iso($want_tdate);
    if ($date ne $want_tdate) {
      die "LME daily: didn't get expected date, got $date want $want_tdate";
    }
  }

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new (headers => [qr/PP.*Global/is],
                                    keep_headers => 1,
                                    slice_columns => 0);
  $te->parse($content);
  my $ts = $te->first_table_found();
  if (! $ts) {
    $te = HTML::TableExtract->new (headers => [qr/COPPER|STEEL/i],
                                   keep_headers => 1,
                                   slice_columns => 0);
    $te->parse($content);
    $ts = $te->first_table_found()
      || die "LME daily: prices table not found";
  }

  my $rows = $ts->rows();
  my $lastrow = $#$rows;
  my $lastcol = $#{$rows->[0]};

  my @column;
  my @column_commodity;
  my @column_name;
  foreach my $c (2 .. $lastcol) {
    my $commodity = $rows->[0]->[$c] || next;
    my $name;
    if    ($commodity =~ /ALUMINIUM ALLOY/i)       { $commodity = 'AA'; }
    elsif ($commodity =~ /ALUMINIUM/i)             { $commodity = 'AH'; }
    elsif ($commodity =~ /COPPER/i)                { $commodity = 'CA'; }
    elsif ($commodity =~ /LEAD/i)                  { $commodity = 'PB'; }
    elsif ($commodity =~ /NICKEL/i)                { $commodity = 'NI'; }
    elsif ($commodity =~ /TIN/i)                   { $commodity = 'SN'; }
    elsif ($commodity =~ /ZINC/i)                  { $commodity = 'ZS'; }
    elsif ($commodity =~ /NASAAC/i)                { $commodity = 'NI'; }
    elsif ($commodity =~ /STEEL.*MEDITERRANEAN/s)  { $commodity = 'FM'; }
    elsif ($commodity =~ /STEEL.*FAR EAST/s)       { $commodity = 'FF'; }
    elsif ($commodity =~ /^([A-Z][A-Z])\s+(.*)/is) { $commodity = $1; $name = $2; }
    else { next; }

    push @column,           $c;
    push @column_commodity, $commodity;
    push @column_name,      $name;
  }
  if (DEBUG) { require Data::Dumper;
               print "columns ", Data::Dumper::Dumper(\@column);
               print "columns ", Data::Dumper::Dumper(\@column_commodity);
               print "columns ", Data::Dumper::Dumper(\@column_name); }

  my %bid;
  foreach my $r (1 .. $lastrow) {
    my $row = $rows->[$r];
    if (DEBUG) { require Data::Dumper;
                 print Data::Dumper::Dumper($row); }
    my $type = $row->[1];
    if (! $type) { next; }

    my $side;
    if ($type =~ /^\s*$/is) {
      next; # empty
    } elsif ($type =~ /buyer/i) {
      $side = 'bid';
    } elsif ($type =~ /seller/i) {
      $side = 'offer';
    } else {
      die "LME daily: unrecognised row type '$type'\n";
    }

    my $month;
    my $post;
    if (DEBUG) { print "type $type\n"; }
    if ($type =~ /cash/i) {
      $post = '';
    } elsif ($type =~ /([0-9]+)[- \t]*month/s) {
      $post = $1;
    } elsif ($type =~ /^(.*?)\s+(buyer|seller)/i) {
      $month = month_str_to_nearest_iso ($1);
      $post = " " . App::Chart::Download::iso_to_MMM_YY($month);
    } else {
      die "LME daily: unrecognised row type '$type'\n";
    }

    foreach my $i (0 .. $#column) {
      my $c = $column[$i];
      my $commodity = $column_commodity[$i];
      my $price = $row->[$c];

      if ($side eq 'bid') {
        $bid{$commodity} = $price;
        next;
      }
      push @data, { symbol    => "$commodity$post.LME",
                    month     => $month,
                    name      => $column_name[$i],
                    date      => $date,
                    bid       => delete $bid{$commodity},
                    offer     => $price,
                    close     => $price,
                  };
    }
  }

  return $h;
}

# $str is some html (in wide chars)
# flatten out any little 1x1 tables to their contents
# such tables are found in the rows of the daily plastics page
#
sub mung_1x1_tables {
  my ($str) = @_;
  require HTML::TreeBuilder;
  my $top = HTML::TreeBuilder->new_from_content ($str);
  my $changed = 0;
  $top->traverse
    ([sub {
        my ($elem) = @_;
        if ($elem->tag ne 'table') { return 1; }
        my $table = $elem;

        # possible tbody within
        my $tbody = List::Util::first {ref $_ && $_->tag eq 'tbody'}
          $table->content_list;
        if (! $tbody) { $tbody = $table; }

        my @rows = grep {ref $_ && $_->tag eq 'tr'} $tbody->content_list;
        if (@rows != 1) { return 1; }
        my $row = $rows[0];

        my @cols = grep {ref $_ && $_->tag eq 'td'
                           && ! html_element_contains_only_img($_) }
          $row->content_list;
        if (@cols != 1) { return 1; }
        my $col = $cols[0];

        $table->replace_with ($col->content_list);
        $changed = 1;
        return 0; # prune
      }
     ],
     1); # pre-order, no text
  if (DEBUG) { print "mung_1x1 changed $changed\n"; }
  if ($changed) {
    return $top->as_HTML;
  } else {
    return $str;
  }
}

sub html_element_contains_only_img {
  my ($elem) = @_;
  my @list = $elem->content_list;
  return (@list == 1
          && ref $list[0]
          && $list[0]->tag eq 'img');
}

sub month_str_to_nearest_iso {
  my ($str) = @_;
  my $month = Date::Calc::Decode_Month ($str)
    || die "LME parse: unrecognised month: '$str'";
  my $year = App::Chart::Download::month_to_nearest_year ($month);
  return App::Chart::ymd_to_iso ($year, $month, 1);
}


#-----------------------------------------------------------------------------
# historical download page
#
# This uses the historical data at
#
use constant HISTORICAL_XLS_URL =>
  'http://www.lme.co.uk/dataprices_historical.asp';
#
# That page is downloaded to get urls of XLS files for prices and volumes
# for each calendar month.  A price file is like
#
#     http://www.lme.co.uk/downloads/January_2007.xls
#
# and a volumes file
#
#     http://www.lme.co.uk/downloads/volumes_September_2007.xls
#
# Sometimes there's a rev num like
#
#     http://www.lme.co.uk/downloads/historic_data/May_2008(1).xls
#     http://www.lme.co.uk/downloads/historic_data/December_2008_3.xls

sub historical_xls_files {
  require App::Chart::Pagebits;
  my $h = App::Chart::Pagebits::get
    (name      => __('LME historical downloads page'),
     url       => HISTORICAL_XLS_URL,
     method    => 'POST',
     data      => 'disclaimer=agreed',
     key       => 'lme-historical-xls',
     freq_days => 2,
     timezone  => App::Chart::TZ->london,
     parse     => \&historical_xls_parse);
  my $aref = $h->{'files'} || [];
  return @$aref;
}

# $content is the "dataprices_historical.asp" page.
# Return a hashref like { 'files' => [ {elem}, {elem}, ...] }
#
# At the start of the year there can be nothing available (the previous year
# files being made chargable items) so it's possible for 'urls' to be empty.
#
# There's a size in the text following each link, but since there's no
# overlapping files to choose between there's no need to pick that out.
#
sub historical_xls_parse {
  my ($content) = @_;

  my %urls;
  require HTML::LinkExtor;
  my $p = HTML::LinkExtor->new
    (sub {
       my($tag, %links) = @_;
       $tag eq 'a' or return;
       my $link = $links{'href'} or return;

       # only the .xls files
       $link =~ /\.xls$/i or return;

       # exclude warehouse stocks
       if ($link =~ /stocks/i) { return; }

       $urls{$link} = 1;
     }, HISTORICAL_XLS_URL);
  $p->parse($content);

  my @files;
  foreach my $url (keys %urls) {
    if (DEBUG) { print "url $url\n"; }

    $url =~ m{([^/]+)$} or die; # only a plain file
    my $basename = $1;

    # rev num in parens like "May_2008(1).xls"
    $basename =~ s/%28.*%29//;
    $basename =~ s/\(.*\)//;

    # rev num with underscore like "December_2008_3.xls"
    $basename =~ s/(\d\d\d\d)_\d+(\.)/$1$2/;

    $basename =~ s/volumes//i;
    my $month = App::Chart::Download::Decode_Date_EU_to_iso ("1 $basename");
    push @files, { url => $url,
                   month_iso => $month };
  }

  @files = sort {$a->{'month_iso'} cmp $b->{'month_iso'}
                   || $a->{'url'} cmp $b->{'url'}
                 } @files;
  return { 'files' => \@files };
}

# return mdate for STR like "January_2007" or "Jan_07", or #f if not that
# format
# sub Mmm_yyy_str_to_mdate {
#   my ($str) = @_;
#   # drop "(1)" part of "http://www.lme.co.uk/downloads/March_2008(1).xls"
#   $str =~ s/\(.*\)//;
#   $str = '1_' . $str;
#   my ($year, $month, $day) = Date::Calc::Decode_Date_EU ($str);
#   if (! $year || ! $month) { die "LME: unrecognised filename month: $str"; }
#   return App::Chart::Timebase::Months::ymd_to_mdate ($year, $month, 1);
# }


#-----------------------------------------------------------------------------
# download - month price xls files
#
# This crunches files like
#     http://www.lme.co.uk/downloads/April_2008.xls
#

App::Chart::DownloadHandler->new
  (name   => __('LME month xls'),
   pred   => $pred,
   proc   => \&monthxls_download,
   # backto => \&monthxls_backto,
   available_tdate => \&monthxls_available_tdate);

# Return tdate of anticipated available montly .xls download, that being
# the end of the previous month.
#
# Don't know exactly when a new month full of data becomes available,
# assume here midnight at the start of the second trading day of the new
# month.
#
sub monthxls_available_tdate {
  my $tdate = App::Chart::Download::tdate_today
    (App::Chart::TZ->london);
  $tdate--; # not until second business day into this month
  $tdate = tdate_start_of_month ($tdate);
  return $tdate - 1; # last day of previous month
}

sub monthxls_download {
  my ($symbol_list) = @_;
  if (DEBUG) { print "LME ",@$symbol_list,"\n"; }

  my $lo_tdate = App::Chart::Download::start_tdate_for_update (@$symbol_list);
  my $hi_tdate = monthxls_available_tdate();

  my @files = grep {$_->{'url'} !~ /volume/i} historical_xls_files();
  my $files = App::Chart::Download::choose_files (\@files, $lo_tdate, $hi_tdate);

  foreach my $f (@$files) {
    my $url = $f->{'url'};
    require File::Basename;
    my $filename = File::Basename::basename($url);
    App::Chart::Download::status (__x('LME data {filename}',
                                     filename => $filename));
    my $resp = App::Chart::Download->get ($url);
    my $h = monthxls_parse ($resp);
    App::Chart::Download::write_daily_group ($h);
  }
}

sub tdate_start_of_month {
  my ($tdate) = @_;
  my ($year,$month,$day) = App::Chart::tdate_to_ymd ($tdate);
  return App::Chart::ymd_to_tdate_ceil ($year, $month, 1);
}

my %monthxls_sheet_to_commodity =
  ('Copper'        => 'CA',
   'Al. Alloy'     => 'AA',
   'NASAAC'        => 'NA',
   'Zinc'          => 'ZS',
   'Lead'          => 'PB',
   'Pr. Aluminium' => 'AH',
   'Tin'           => 'SN',
   'Nickel'        => 'NI',
   'Far East'      => 'FF',  # steel
   'Med'           => 'FM',  # steel
   'Averages'              => undef,
   'Plastic Avg'           => undef,
   'Averages inc. Euro Eq' => undef);

sub monthxls_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content (charset => 'none', raise_error => 1);

  require Spreadsheet::ParseExcel;
  require Spreadsheet::ParseExcel::Utility;

  my @data = ();
  my $h = { source     => __PACKAGE__,
            cover_pred => $pred,
            data       => \@data };

  my $excel = Spreadsheet::ParseExcel::Workbook->Parse (\$content);
  foreach my $sheet (@{$excel->{Worksheet}}) {
    my $sheet_name = $sheet->{'Name'};
    if (DEBUG) { print "Sheet: $sheet_name\n"; }
    my $commodity;
    if ($sheet_name =~ /^[A-Z][A-Z]$/) {
      # plastics symbol
      $commodity = $sheet_name;
    } elsif (exists $monthxls_sheet_to_commodity{$sheet_name}) {
      $commodity = $monthxls_sheet_to_commodity{$sheet_name}
        // next;  # undef for ignored sheets
    } else {
      warn "LME: unrecognised month data sheet: $sheet_name\n";
      next;
    }

    my ($minrow, $maxrow) = $sheet->RowRange;
    my ($mincol, $maxcol) = $sheet->ColRange;

    my $heading_row = $minrow;
    my $date_col;
    my $seller_col;
  HEADING: for (;; $heading_row++) {
      if ($heading_row > $maxrow) { die "LME: headings row not found\n"; }
      for ($seller_col = $mincol; $seller_col <= $maxcol; $seller_col++) {
        my $cell = $sheet->Cell($heading_row,$seller_col) // next;
        my $str = $cell->Value;
        if (DEBUG >= 2) { print "  cell $heading_row,$seller_col $str\n"; }
        if ($str =~ /SELLER/i) { last HEADING; }
      }
    }
    $date_col = $seller_col - 2;
    if (DEBUG) { print "  heading row $heading_row seller col $seller_col\n"; }

    my @column_num = ();
    my @column_symbol = ();
    for (my $col = $seller_col; $col+2 <= $maxcol; $col += 3) {
      my $cell = $sheet->Cell($heading_row,$col) || last;
      $cell->Value =~ /SELLER/i or next;

      my $period = $sheet->Cell($heading_row-1,$col)->Value;
      if (DEBUG >= 2) { print "  col=$col period=$period\n"; }
      if ($period =~ /cash/i) {
        $period = '';
      } elsif ($period =~ /([0-9]+).*(months|mths)/i) {
        $period = $1;
      } elsif ($period eq '') {
        last;
      } else {
        die "LME: month sheet '$sheet_name' heading row=$heading_row col=$col period unrecognised: '$period'\n";
      }
      push @column_num, $col;
      push @column_symbol, "$commodity$period.LME";
    }
    if (! @column_num) {
      die "LME: oops, sheet '$sheet_name' month data columns not matched\n";
    }

    my $seen_date = 0;
    foreach my $row ($heading_row+1 .. $maxrow) {
      my $datecell = $sheet->Cell($row,$date_col) or next;
      # skip blanks at end, avoid "Total"
      $datecell->{'Type'} eq 'Date' or next;
      # default format is like 31-Jan-08, go straight to ISO to be unambiguous
      my $date = Spreadsheet::ParseExcel::Utility::ExcelFmt
        ('yyyy-mm-dd', $datecell->{'Val'}, $excel->{'Flg1904'});
      $seen_date = 1;

      foreach my $i (0 .. $#column_num) {
        my $col = $column_num[$i];
        my $symbol = $column_symbol[$i];

        # unformatted value gets '1490.00' instead of '$1,490.00'
        my $seller = $sheet->Cell($row,$col)->{'Val'};
        push @data, { symbol => $symbol,
                      date   => $date,
                      close  => $seller,
                    };
      }
    }
    if (! $seen_date) {
      die "LME month data: no dates found in sheet '$sheet_name'";
    }
  }
  my $date = $data[0]->{'date'};
  my ($year, $month, $day) = App::Chart::iso_to_ymd ($date);
  $h->{'cover_lo_date'} = App::Chart::ymd_to_iso ($year, $month, 1);
  ($year, $month, $day) = Date::Calc::Add_Delta_YMD ($year, $month, $day,
                                                     0, 1, -1);
  $h->{'cover_hi_date'} = App::Chart::ymd_to_iso ($year, $month, $day);
  return $h;
}

#-----------------------------------------------------------------------------
# download - volume xls files
#
# This crunches files like
#     http://www.lme.co.uk/downloads/volumes_Jan_08.xls
#

# App::Chart::DownloadHandler->new
#   (name   => __('LME month volumes'),
#    pred   => $pred,
#    proc   => \&volume_download,
#    # backto => \&volume_backto,
#    available_tdate => \&monthxls_available_tdate);

sub volume_download {
  my ($symbol_list) = @_;

  my $lo_tdate = App::Chart::Download::start_tdate_for_update (@$symbol_list);
  my $hi_tdate = monthxls_available_tdate();

  my @files = grep {$_->{'url'} =~ /volume/i} historical_xls_files();
  my $files = App::Chart::Download::choose_files (\@files, $lo_tdate, $hi_tdate);

  foreach my $f (@$files) {
    my $url = $f->{'url'};
    require File::Basename;
    my $filename = File::Basename::basename($url);
    App::Chart::Download::status (__x('LME volumes {filename}',
                                     filename => $filename));
    my $resp = App::Chart::Download->get ($url);
    my $h = volume_parse ($resp);
    App::Chart::Download::write_daily_group ($h);
  }
}

sub volume_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content (charset => 'none', raise_error => 1);

  require Spreadsheet::ParseExcel;
  require Spreadsheet::ParseExcel::Utility;

  my @data = ();
  my $h = { source => __PACKAGE__,
            data   => \@data };

  my $excel = Spreadsheet::ParseExcel::Workbook->Parse (\$content);
  my $sheet = $excel->Worksheet (0);
  if (DEBUG) { print "Sheet: ",$sheet->{'Name'},"\n"; }

  my ($minrow, $maxrow) = $sheet->RowRange;
  my ($mincol, $maxcol) = $sheet->ColRange;

  # headings are like "AAFUT" for Aluminium Alloy, find that row
  my $heading_row;
 HEADINGROW: foreach my $row ($minrow .. $maxrow) {
    foreach my $col ($mincol .. $maxcol) {
      my $cell = $sheet->Cell($row,$col) or next;
      if ($cell->Value =~ /FUT$/) {
        $heading_row = $row;
        last HEADINGROW;
      }
    }
  }
  if (! $heading_row) { die 'LME Volumes: unrecognised headings'; }
  if (DEBUG) { print "  heading row $heading_row\n"; }

  # look for each "AAFUT" etc column in the heading row
  my @column_num = ();
  my @column_symbol = ();
  foreach my $col ($mincol .. $maxcol) {
    my $cell = $sheet->Cell($heading_row,$col) // next; # skip empties
    $cell->{'Type'} eq 'Text' or next;  # skip dates in heading
    my $str = $cell->Value;
    $str =~ /(.*)FUT$/ or next;
    my $commodity = $1;
    push @column_num, $col;
    push @column_symbol, $commodity . '.LME';
  }

  my $seen_date = 0;
  foreach my $row ($heading_row+1 .. $maxrow) {
    my $date;
    # Jan 2008 has 'Date' type in column 1
    # May 2008 onwards has text d-Mmm-yy in column 0
    my $datecell = $sheet->Cell($row,0);
    if ($datecell->{'Type'} eq 'Text') {
      $date = App::Chart::Download::Decode_Date_EU_to_iso($datecell->{'Val'},1);
      # skip blanks at end, avoid "Total"
      if (! defined $date) { next; }
    } else {
      $datecell = $sheet->Cell($row,1);
      # skip blanks at end, avoid "Total"
      $datecell->{'Type'} eq 'Date' or next;
      # default format is like 31-Jan-08, go straight to ISO to be unambiguous
      $date = Spreadsheet::ParseExcel::Utility::ExcelFmt
        ('yyyy-mm-dd', $datecell->{'Val'}, $excel->{'Flg1904'});
    }
    $seen_date = 1;

    foreach my $i (0 .. $#column_num) {
      my $col = $column_num[$i];
      my $symbol = $column_symbol[$i];
      my $volume = $sheet->Cell($row,$col)->Value;
      push @data, { symbol    => $symbol,
                    date      => $date,
                    volume    => $volume,
                  };
    }
  }
  if (! $seen_date) {
    die 'LME volumes: no dates found';
  }

  return $h;
}

#-----------------------------------------------------------------------------
# download - daily
#
# This uses the metals and plastics settlement pages (login required) at
#
# https://secure.lme.com/Data/community/Dataprices_daily_metals.aspx
# https://secure.lme.com/Data/community/Dataprices_daily_prices_plastics.aspx
# https://secure.lme.com/Data/community/Dataprices_Steels_OfficialPrices.aspx
#

my $daily_pred = App::Chart::Sympred::Proc->new (\&is_daily_symbol);
sub is_daily_symbol {
  my ($symbol) = @_;
  return ($pred->match ($symbol) && is_enabled());
}
sub is_enabled {
  my $username = App::Chart::Database->preference_get ('lme-username', undef);
  return (defined $username && $username ne '');
}

# App::Chart::DownloadHandler->new
#   (name   => __('LME daily'),
#    pred   => $daily_pred,
#    proc   => \&daily_download,
#    available_tdate_by_symbol => \&daily_available_tdate);
# 
# sub daily_available_tdate {
#   my ($symbol) = @_;
#   return
#     App::Chart::Download::iso_to_tdate_floor (daily_available_date ($symbol));
# }

sub daily_download {
  my ($symbol_list) = @_;

  my $sm = partition_by_key ($symbol_list, \&type);
  while (my ($type, $symbol_list) = each %$sm) {
    App::Chart::Download::verbose_message ('LME', $type, @$symbol_list);

    login_ensure();
    my $l = daily_latest ($type);

    my $lo_tdate = App::Chart::Download::start_tdate_for_update (@$symbol_list);
    my $hi_tdate = $l->{'tdate'} - 1;

    foreach my $tdate ($lo_tdate .. $hi_tdate) {
      my $resp = daily_download_one ($type, $tdate, $l);
      my $h = daily_parse ($resp, $tdate);
      App::Chart::Download::write_daily_group ($h);
    }
    App::Chart::Download::write_daily_group ($l->{'h'});
  }
}

sub partition_by_key {
  my ($list, $func) = @_;
  require Tie::IxHash;
  my %sm;
  tie %sm, 'Tie::IxHash';
  foreach my $elem (@$list) {
    my $key = $func->($elem);
    push @{$sm{$key}}, $elem;
  }
  return \%sm;
}

sub daily_download_one {
  my ($type, $tdate, $l) = @_;

  require HTML::Form;
  my $content  = $l->{'content'};
  my $url  = $l->{'url'};
  my $form = HTML::Form->parse($content, $url)
    or die "LME metals page not a form";

  my ($year, $month, $day) = App::Chart::tdate_to_ymd ($tdate);
  # these are literal "$" in the field name
  $form->value ("_searchForm\$_lstdate",  $day);
  $form->value ("_searchForm\$_lstmonth", $month);
  $form->value ("_searchForm\$_lstyear",  $year);

  App::Chart::Download::status
      (__x('LME daily {type} {date}',
           type => $type,
           date => App::Chart::Download::tdate_range_string ($tdate)));

  require App::Chart::UserAgent;
  require HTTP::Cookies;
  my $ua = App::Chart::UserAgent->instance->clone;
  $ua->requests_redirectable ([]);
  my $jar = HTTP::Cookies->new;
  $ua->cookie_jar ($jar);

  my $req = $form->click();
  my $resp = $ua->request ($req);

  if (! $resp->is_success) {
    die "Cannot download $url\n",$resp->headers->as_string,"\n";
  }
  return $resp;
}

my %type_to_daily_url
  = (metals   => 'https://secure.lme.com/Data/community/Dataprices_daily_metals.aspx',
     plastics => 'https://secure.lme.com/Data/community/Dataprices_daily_prices_plastics.aspx',
     steels   => 'https://secure.lme.com/Data/community/Dataprices_Steels_OfficialPrices.aspx');

sub daily_latest {
  my ($type) = @_;
  require App::Chart::Pagebits;
  return App::Chart::Pagebits::get
    (name      => __x('LME daily latest {type}',
                      type => $type),
     url       => $type_to_daily_url{$type},
     key       => "lme-daily-latest-$type",
     freq_days => 0,
     timezone  => App::Chart::TZ->london,
     parse     => \&daily_latest_parse);
}

sub daily_latest_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content (raise_error => 1);
  my $h = daily_parse ($resp);
  return { h       => $h,
           date    => $h->{'data'}->[0]->{'date'},
           url     => $resp->uri->as_string,
           content => $content };
}


1;
__END__


#-----------------------------------------------------------------------------
# download - daily
#
#

# LST has elements (SYMBOL NAME TDATE BUY-STR SELL-STR MDATE) per
# `daily-html-parse'
#
# The sell price is used.  The report for cash prices has the seller marked
# as the settlement and for the forwards the historical files can be seen
# with the seller price.
#
(define (daily-process symbol-list lst)
  (download-process
   #:module      (_ "LME")
   #:symbol-list symbol-list
   #:currency    "USD"
   #:row-list
   (map (lambda (row)
	  (receive-list (symbol name tdate buy sell mdate)
	      row
	    (list #:tdate     tdate
		  #:mdate     mdate
		  #:commodity (chart-symbol-commodity symbol)
		  #:close     sell)))
	lst)))

(define (lme-daily-download symbol-list type)
  (define selector (case type
		     ((metals)   lme-metal-symbol?)
		     ((plastics) lme-plastics-symbol?)))

  (set! symbol-list (filter selector symbol-list))
  (if (not (null? symbol-list))

      (let* ((end-data  (assq-ref (daily-latest-info type) 'data))
	     (end-tdate (if end-data
			    (data-tdate end-data)
			    (daily-available-tdate type))))

	(set! symbol-list
	      (download-also symbol-list #:selector selector))

	# only go back 25 days for LMEX or others without yearly data,
	# since at 70kbytes per day it quickly becomes slow
	#
	(do ((t (apply min (map (lambda (symbol)
				  (download-start-tdate symbol #:initial 25))
				symbol-list))
		(1+ t)))
	    ((>= t end-tdate))
	  (and-let* ((data (lme-daily-download-tdate type t)))
	    (daily-process symbol-list data)))

	(if end-data
	    (daily-process symbol-list end-data)))))


(define (lme-historical-download symbol-list)

  (let* ((avail-tdate (monthxls-available-tdate)))

    # whether can update prices for SYMBOL using xls
    (define (want-monthxls? symbol)
      (>= avail-tdate (download-start-tdate symbol)))

    # whether can update volume for SYMBOL
    (define (want-volume? symbol)
      # no volumes for forward symbols like "ZINC 3.LME" or futures
      # specific symbols like "PP MAY 06.LME"
      (and (not (string-any char-numeric? symbol))
	   (let ((last-tdate (database-last-volume symbol)))
	     (or (not last-tdate)
		 (< last-tdate avail-tdate)))))

    # whether can update anything for SYMBOL
    (define (want-update? symbol)
      (or (want-monthxls? symbol)
	  (want-volume? symbol)))

    (if (any want-update? symbol-list)
	(begin
	  (if (any want-monthxls? symbol-list)
	      (monthxls-download symbol-list))
	  (if (any want-volume? symbol-list)
	      (volume-download symbol-list))))))



(let ((vol-tdate (database-last-volume symbol)))



  # date is: "26 Jan 2005 (Data >1 day old)   </b></td>"
  # or:      "3 Feb 2005   </b></td>"
  (let* ((m        (must-match (string-match " Prices[ ,][^\n]*for +([0-9]+) ([A-Za-z]+) ([0-9][0-9][0-9][0-9])" body)))
	 (tdate    (ymd->tdate (string->number (match:substring m 3))
			       (Mmm-str->month (match:substring m 2))
			       (string->number (match:substring m 1))))
	 (row-list (html-table-rows body (match:end m))))

    # blank separator lines
    (set! row-list (remove! (lambda (row)
			      (every string-null? row))
			    row-list))

    (let ((commodity-list (map daily-heading->commodity+name
			       (first row-list))))
      (set! row-list (cdr row-list))

      (for-each-two
       (lambda (buyer-row seller-row)
	 # row like ("" "September Buyer" "" "932" "" "931" "")
	 #          ("" "Cash buyer" "" "1,555.00" "" "1,737.00" "" ...)
	 (for-each
	  (lambda (commodity+name buy sell)
	    (if commodity+name
		(receive-list (commodity name)
		    commodity+name

		  (define symbol (commodity+label->symbol
				  commodity (second buyer-row)))
		  (define (lat sym)
		    (set! ret (cons (list sym name tdate buy sell
					  (chart-symbol-mdate symbol))
				    ret)))

		  (set! buy  (crunch-price buy))
		  (set! sell (crunch-price sell))

		  # first row as front month
		  (if (and (eq? buyer-row (first row-list))
			   (chart-symbol-mdate symbol))
		      (lat (string-append commodity ".LME")))

		  # all rows with month in symbol
		  (lat symbol))))

	  commodity-list buyer-row seller-row))
       row-list)))

  (and-let* ((m (string-match "LMEX Index value [^0-9\n]*([0-9]+ [A-Za-z]+ [0-9][0-9][0-9][0-9])[^0-9.\n]+([0-9.]+)" body)))
    (set! ret (cons (list "LMEX.LME"
			  #f
			  (d/m/y-str->tdate (match:substring m 1))
			  #f # no separate buy price
			  (match:substring m 2)
			  #f)
		    ret)))

  ret)



(define (daily-latest-parse body)
  (list
   (cons 'form   (html-form-parse body))
   (cons 'prices (daily-html-parse body))))

(define (daily-latest-info type)
  (lme-ensure-login)

  (pagebits-read #:filename  (case type
			       ((metals)   "lme-latest-metals")
			       ((plastics) "lme-latest-plastics"))
		 #:status    (list (_ "LME")
				   (case type
				     ((metals)   (_ "metals latest"))
				     ((plastics) (_ "plastics latest"))))
		 #:url       (list (case type
				     ((metals)   
				     ((plastics) "https://secure.lme.com/Data/community/Dataprices_daily_prices_plastics.aspx"))
				   #:cookiejar lme-cookiejar-filename
				   #:follow    #f)
		 #:timezone  (timezone-london)
		 #:parse     daily-latest-parse))


#-----------------------------------------------------------------------------
# latest
#
# This uses the daily prices in the login "free data service", login
# required, at
#
#     https://secure.lme.com/Data/community/Dataprices_daily_metals.aspx
#
# This plain url gives the most recent prices, which we take as a quote for
# the indicated day then work back with form-data fetching previous days to
# find price change amounts.  Or the database is used if it covers the
# desired symbol(s).
#
# Unfortunately there's no Last-Modified or ETag to save refetching if the
# latest GET contents have not yet updated.  (???)


(define (lme-latest-update-database type newest-data prev-data)
  (let* ((end-tdate   (data-tdate newest-data))
	 (start-tdate (if prev-data
			  (data-tdate prev-data)
			  end-tdate))
	 (db-list     (download-also '() #:selector (lme-type->selector type)
				     #:start-tdate start-tdate
				     #:end-tdate end-tdate)))
    (if prev-data
	(daily-process db-list prev-data))
    (daily-process db-list newest-data)))

(define (lme-latest-process newest-data prev-data proc)
  (define lst '())

  (for-each
   (lambda (elem)
     (receive-list (symbol name tdate buy sell mdate)
	 elem

       (and-let* ((prev-elem (assoc symbol prev-data))) # match car
	 (let ((prev-sell (fifth prev-elem)))

	   (receive-list (decimals buy sell prev-sell)
	       (strings->numbers+decimals buy sell prev-sell)

	     # need both buy and sell to show as quote
	     (define bid         buy)
	     (define offer       (and buy sell))
	     (define quote-tdate (and buy sell tdate))

	     # sell is normally always present, but have seen entire page
	     # blank (empty fields "" which become #f) 31aug05 after
	     # 29aug05 bank holiday

	     (set! lst
		   (cons (latest-new #:symbol         symbol
				     #:name           name
				     #:quote-tdate    quote-tdate
				     #:bid            bid
				     #:offer          offer
				     #:last-tdate     tdate
				     #:last           sell
				     #:prev           prev-sell
				     #:decimals       decimals
				     #:contract-mdate mdate
				     #:source         'lme)
			 lst)))))))
   newest-data)

  (proc lst))

(define (lme-latest-type symbol-list type proc)

  (and-let* ((newest-data  (assq-ref (daily-latest-info type) 'prices)))

    # COVERED-TDATE is the data we already have for all of SYMBOL-LIST (or
    # rather for the worst among that list), default to a dummy 100 days
    # ago
    (let* ((newest-tdate  (data-tdate newest-data))
	   (covered-data  (daily-from-database symbol-list))
	   (covered-tdate (if covered-data
			      (data-tdate covered-data)
			      (- (daily-available-tdate type) 100))))
      (let more ((attempt 1))
	(if (> attempt 5)
	    (error "LME: can't find previous daily data"))

	(let ((prev-tdate (- newest-tdate attempt)))
	  (if (>= covered-tdate prev-tdate)
	      (begin
		(lme-latest-update-database type newest-data #f)
		(lme-latest-process newest-data covered-data proc))

	      (let ((prev-data (lme-daily-download-tdate type prev-tdate)))
		(if prev-data
		    (begin
		      (lme-latest-update-database type newest-data prev-data)
		      (lme-latest-process newest-data prev-data proc))

		    (more (1+ attempt))))))))))

(define (lme-symbol->type symbol)
  (if (lme-metal-symbol? symbol) 'metals 'plastics))

(define (lme-latest-get symbol-list extra-list proc)

  (if (string-null? (preference-get 'lme-username ""))
      (proc (map (lambda (symbol)
		   (latest-new #:symbol symbol
			       #:note   (_ "must register")
			       #:source 'lme))
		 (append symbol-list extra-list)))

      # look for one or both metal and plastics in symbol-list, do the two in
      # the order they appear in SYMBOL-LIST
      (for-each (lambda (type)
		  (lme-latest-type symbol-list type proc))
		(delete-duplicates (map lme-symbol->type symbol-list)))))

(define (lme-quote-adate-time symbol)
  (list (tdate->adate (daily-available-tdate (lme-symbol->type symbol))) #f))

(latest-handler! #:selector   lme-symbol?
		 #:handler    lme-latest-get
		 #:adate-time lme-quote-adate-time)


#-----------------------------------------------------------------------------
# download - historical prices and/or volumes

# return tdate of last volume value recorded for SYMBOL, or #f if none ever
(define (database-last-volume symbol)
  (and-let* ((series (database-read-series symbol)))
    (series-array series   # initial request past month to look at
		  (- (series-hi series) 25)
		  (series-hi series))
    (let more ((i (series-hi series)))
      (and (>= i (series-lo series))
	   (if (array-ref (series-array series i i) i 4)
	       i
	       (more (1- i)))))))


#-----------------------------------------------------------------------------
# download

(define (lme-download-available-tdate)
 (daily-available-tdate 'metals)
      (monthxls-available-tdate))

(download-now-handler! (lambda (symbol-list)
			 (and (any lme-symbol? symbol-list)
			      (download-now-all-commodities-and-months))))
