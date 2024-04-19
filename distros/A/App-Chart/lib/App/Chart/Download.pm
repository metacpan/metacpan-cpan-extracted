# Download functions.

# Copyright 2007, 2008, 2009, 2010, 2011, 2013, 2015, 2016, 2017, 2018, 2020, 2023, 2024 Kevin Ryde

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

package App::Chart::Download;
use 5.010;
use strict;
use warnings;
use Carp 'carp','croak';
use Date::Calc;
use List::Util qw(min max);
use List::MoreUtils;
use Regexp::Common 'whitespace';
use Locale::TextDomain ('App-Chart');

use PerlIO::via::EscStatus;
use Tie::TZ;

use App::Chart;
use App::Chart::Database;
use App::Chart::DBI;
use App::Chart::TZ;

# uncomment this to run the ### lines
# use Smart::Comments;

use constant DEBUG => 0;

#------------------------------------------------------------------------------

sub get {
  my ($class, $url, %options) = @_;
  ### Download get(): $url

  # URI object becomes string
  $url = "$url";

  my $ua = $options{'ua'} || do { require App::Chart::UserAgent;
                                  App::Chart::UserAgent->instance };
  $ua->cookie_jar ($options{'cookie_jar'});  # undef for none

  require HTTP::Request;
  my $method = $options{'method'} || 'GET';
  my @headers = (Referer => $options{'referer'});
  my $data = $options{'data'};
  if (defined $data) {
    push @headers, 'Content-Type' => 'application/x-www-form-urlencoded';
  }
  my $req = HTTP::Request->new ($method, $url, \@headers, $data);

  # possible override
  if (my $user_agent = $options{'user_agent'}) {
    $req->user_agent($user_agent);
  }

  my $etag = $options{'etag'};
  my $lastmod = $options{'last_modified'};

  if (my $key = $options{'url_tags_key'}) {
    my $symbol = $options{'symbol'};
    my $prev_url = App::Chart::Database->read_extra($symbol,"$key-URL");
    if (defined $prev_url && $url eq $prev_url) {
      $etag    = App::Chart::Database->read_extra($symbol,"$key-ETag");
      $lastmod = App::Chart::Database->read_extra($symbol,"$key-Last-Modified");
    }
  }

  if ($etag)    { $req->header ('If-None-Match' => $etag); }
  if ($lastmod) { $req->header ('If-Modified-Since' => $lastmod); }

  $ua->prepare_request ($req);
  if (DEBUG) { print $req->as_string; }

  if ($App::Chart::option{'verbose'} || DEBUG) {
    if ($App::Chart::option{'verbose'} >= 2 || DEBUG >= 2) {
      print $req->as_string;
    } else {
      print "$method $url\n";
    }
    if (defined $data) {
      print "$data\n";
    }
  }

  my $resp = $ua->request ($req);
  if (DEBUG) { print $resp->status_line,"\n";
               print $resp->headers->as_string,"\n"; }

  # internal message from LWP when a keep-alive has missed the boat
  if ($resp->status_line =~ /500 Server closed connection/i) {
    substatus (__('retry'));
    $resp = $ua->request ($req);
    if (DEBUG) { print $resp->status_line,"\n";
                 print $resp->headers->as_string,"\n"; }
  }

  if ($resp->is_success
      || ($options{'allow_401'} && $resp->code == 401)
      || ($options{'allow_404'} && $resp->code == 404)
      || (($etag || $lastmod) && $resp->code == 304)) {
    substatus (__('processing'));
    return $resp;
  } else {
    croak "Cannot download $url\n",$resp->status_line,"\n";
  }
}

#------------------------------------------------------------------------------

my $last_status = '';     # without substatus addition

sub download_message {
  print join (' ',@_),"\n";
}
sub verbose_message {
  if ($App::Chart::option{'verbose'}) {
    print join (' ',@_),"\n";
  }
}

sub status {
  my $str = join (' ', @_);
  $last_status = $str;
  PerlIO::via::EscStatus::print_status ($str);
}
sub substatus {
  my ($str) = @_;
  if ($str) {
    PerlIO::via::EscStatus::print_status ($last_status, ' [', $str, ']');
  }
}

#------------------------------------------------------------------------------

sub split_lines {
  my ($str) = @_;
  my @lines = split (/[\r\n]+/, $str);     # LF or CRLF
  foreach (@lines) { $_ =~ s/[ \t]+$// }   # trailing whitespace
  return grep {$_ ne ''} @lines;           # no blanks
}

#------------------------------------------------------------------------------

sub trim_decimals {
  my ($str, $want_decimals) = @_;
  if ($str && $str =~ /(.*\.[0-9]{$want_decimals}[0-9]*?)0+$/) {
    return $1;
  } else {
    return $str;
  }
}

#------------------------------------------------------------------------------

sub str_is_zero {
  my ($str) = @_;
  return ($str =~ /^0+(\.0*)?$|^0*(\.0+)$/ ? 1 : 0);
}


#------------------------------------------------------------------------------

sub cents_to_dollars {
  my ($str) = @_;
  $str =~ /^([^.]*)(\.(.*))?$/
    or croak "cents_to_dollars(): bad string: \"$str\"";
  my $int = $1;
  my $frac = (defined $3 ? $3 : '');
  if (length ($int) < 3) {
    $int = sprintf ('%03s', $int);
  }
  return substr ($int, 0, length($int)-2) . '.' .
         substr ($int, length($int)-2) . $frac;
}


#------------------------------------------------------------------------------

sub month_to_nearest_year {
  my ($target_month) = @_;
  my ($year, $month, $day) = Date::Calc::Today();
  $month --;        # 0=January
  $target_month --;

  my $diff = $target_month - $month;
  $diff += 5;
  $diff %= 12;
  $diff -= 5;  # now range -5 to +6

  # applying $diff makes $month == $target_month modulo 12,
  # but $month<0 is last year, 0 to 11 this year, >= 12 next year
  $month += $diff;
  return $year + ($month < 0 ? -1 : $month < 12 ? 0 : 1);
}


#------------------------------------------------------------------------------

sub Decode_Date_EU_to_iso {
  my ($str, $noerror) = @_;
  my ($year, $month, $day) = Date::Calc::Decode_Date_EU ($str);
  unless (defined $year && defined $month && defined $day) {
    if ($noerror) {
      return undef;
    } else {
      croak "Decode_Date_EU_to_iso: unrecognised date \"$str\"\n";
    }
  }
  return App::Chart::ymd_to_iso ($year, $month, $day);
}

sub Decode_Date_US_to_iso {
  my ($str) = @_;
  my ($year, $month, $day) = Date::Calc::Decode_Date_US ($str);
  unless (defined $year && defined $month && defined $day) {
    croak "Decode_Date_US_to_iso: unrecognised date \"$str\"\n";
  }
  return App::Chart::ymd_to_iso ($year, $month, $day);
}

#------------------------------------------------------------------------------

sub Decode_Date_YMD {
  my ($str) = @_;
  ($str =~ m{^  # 6 or 8 digits are yyyymmdd or yymmdd
             ["'[:space:]]*
             (\d{2,4})              # $1 year
             ((\d{2})|([A-Za-z]+))  # $3 numeric month, $4 alpha month
             (\d{2})                # $5 day
             ["'[:space:]]*
             $}x)
    or
      ($str =~ m{^
                 ["'[:space:]]*
                 (\d{2,4})                # $1 year
                 [-_/:.[:space:]]*
                 ((\d{1,2})|([A-Za-z]+))  # $3 numeric month, $4 alpha month
                 [-_/:.[:space:]]*
                 (\d{1,2})                # $5 day
                 ["'[:space:]]*
                 $}x)
        or return;

  my $year = $1;
  my $num_month = $3;
  my $alpha_month = $4,
    my $day = $5;
  my $month = $num_month || Date::Calc::Decode_Month ($alpha_month);
  $year = Date::Calc::Moving_Window ($year);
  return ($year, $month, $day);
}

sub Decode_Date_YMD_to_iso {
  my ($str) = @_;
  my ($year, $month, $day) = Decode_Date_YMD ($str);
  if (! defined $year || ! defined $month || ! defined $day
      || ! Date::Calc::check_date ($year, $month, $day)) {
    croak "Decode_Date_YMD_to_iso: invalid date \"$str\"\n";
  }
  return App::Chart::ymd_to_iso ($year, $month, $day);
}


#------------------------------------------------------------------------------

sub date_parse_to_iso {
  my ($str) = @_;
  require Date::Parse;
  my ($ss,$mm,$hh,$day,$month,$year,$zone) = Date::Parse::strptime ($str);
  if (! defined ($day) || ! defined ($month) || ! defined ($year)) {
    croak "date_parse_to_iso: unrecognised date \"$str\"\n";
  }
  return App::Chart::ymd_to_iso ($year + 1900, $month + 1, $day);
}

#------------------------------------------------------------------------------

# $h is a hash of share prices
#   data => [ { symbol=>$str, 
#               date    => $str,
#               open    => $price,
#               high    => $price,
#               low     => $price,
#               close   => $price,
#               volume  => $number,
#               openint => $number,
#             },
#             ...
#           ]
#   dividends => [ { symbol      => $str, 
#                    ex_date     => $date,
#                    record_date => $date,
#                    pay_date    => $date,
#                    type        => $str,
#                    amount      => $price,
#                    imputation  => $price,
#                    qualifier   => $str,
#                    note        => $str,
#                  },
#                  ...
#                ],
# write it as daily data in the database
sub write_daily_group {
  my ($h) = @_;

  crunch_h ($h);

  my $prefer_decimals = $h->{'prefer_decimals'};
  my $database_symbols_hash = App::Chart::Database::database_symbols_hash();

  my %decimals;
  my %data_changed;

  substatus (__('writing database'));
  my $dbh = App::Chart::DBI->instance;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         if ($h->{'cost_key'}) {
           require App::Chart::DownloadCost;
           App::Chart::DownloadCost::cost_store_h ($h);
         }

         my %symbol_hash;
         {
           my $sth = $dbh->prepare_cached
             ('INSERT OR REPLACE INTO daily
             (symbol, date, open, high, low, close, volume, openint)
             VALUES (?,?,?,?,?,?,?,?)');

           foreach my $data (@{$h->{'data'}}) {
             my $symbol = $data->{'symbol'};
             next unless exists $database_symbols_hash->{$symbol};

             if (defined $prefer_decimals) {
               $decimals{$symbol} = $prefer_decimals;
             }
             $data_changed{$symbol} = 1;

             $sth->execute($symbol,
                           $data->{'date'},
                           $data->{'open'},
                           $data->{'high'},
                           $data->{'low'},
                           $data->{'close'},
                           $data->{'volume'},
                           $data->{'openint'});
             $sth->finish;
           }
         }

         foreach my $dividend (@{$h->{'dividends'}}) {
           my $symbol = $dividend->{'symbol'}
             or croak "write_daily_group: missing symbol in dividend record";
           next unless exists $database_symbols_hash->{$symbol};

           my $ex_date     = $dividend->{'ex_date'};
           my $record_date = $dividend->{'record_date'};
           my $pay_date    = $dividend->{'pay_date'};

           my $type       = $dividend->{'type'} || '';
           my $amount     = $dividend->{'amount'};
           my $imputation = $dividend->{'imputation'};
           my $qualifier  = crunch_empty_undef ($dividend->{'qualifier'});
           my $note       = crunch_empty_undef ($dividend->{'note'});

           my $old_qualifier = App::Chart::DBI->read_single
             ('SELECT qualifier FROM dividend WHERE symbol=? AND ex_date=? AND type=?', $symbol, $ex_date, $type);

           my $sth = $dbh->prepare_cached
             ('INSERT OR REPLACE INTO dividend
                (symbol, ex_date, record_date, pay_date,
                 type, amount, imputation, qualifier, note)
               VALUES (?,?,?,?, ?,?,?,?,?)');

           $sth->execute ($symbol, $ex_date, $record_date, $pay_date,
                          $type, $amount, $imputation, $qualifier, $note);
           $sth->finish;
           $data_changed{$symbol} = 1;
         }

         foreach my $split (@{$h->{'splits'}}) {
           my $symbol = $split->{'symbol'}
             or croak "write_daily_group: missing symbol in split record";
           next unless exists $database_symbols_hash->{$symbol};

           my $date = $split->{'date'};
           my $new  = crunch_number ($split->{'new'});
           my $old  = crunch_number ($split->{'old'});
           my $note = crunch_empty_undef ($split->{'note'});

           my $sth = $dbh->prepare_cached
             ('INSERT OR REPLACE INTO split (symbol, date, new, old, note)
               VALUES (?,?,?,?,?)');
           $sth->execute ($symbol, $date, $new, $old, $note);
           $sth->finish;
           $data_changed{$symbol} = 1;
         }

         if (my $names = $h->{'names'}) {
           while (my ($symbol, $name) = each %$names) {
             if (defined $name) {
               $data_changed{$symbol} |= set_symbol_name ($symbol, $name);
             }
           }
         }
         if (my $currencies = $h->{'currencies'}) {
           while (my ($symbol, $currency) = each %$currencies) {
             if (defined $currency) {
               $data_changed{$symbol} |= set_currency ($symbol, $currency);
             }
           }
         }
         if (my $isins = $h->{'isins'}) {
           while (my ($symbol, $isin) = each %$isins) {
             if (defined $isin) {
               $data_changed{$symbol} |= set_isin ($symbol, $isin);
             }
           }
         }
         if (my $exchanges = $h->{'exchanges'}) {
           while (my ($symbol, $exchange) = each %$exchanges) {
             if (defined $exchange) {
               $data_changed{$symbol} |= set_exchange ($symbol, $exchange);
             }
           }
         }
         while (my ($symbol, $decimals) = each %decimals) {
           if (defined $decimals) {
             $data_changed{$symbol} |= set_decimals ($symbol, $decimals);
           }
         }

         my $symbol_list = [ keys %data_changed ];

         if (my $key = $h->{'url_tags_key'}) {
           my $resp = $h->{'resp'};
           foreach my $symbol (@$symbol_list) {
             my $url  = (defined $resp ? $resp->request->uri : undef);
             my $etag = (defined $resp ? scalar $resp->header('ETag') : undef);
             my $last_modified =(defined $resp ? $resp->last_modified : undef);

             App::Chart::Database->write_extra
                 ($symbol, "$key-URL", "$url"); # stringize URI object
             App::Chart::Database->write_extra
                 ($symbol, "$key-ETag", $etag);
             App::Chart::Database->write_extra
                 ($symbol, "$key-Last-Modified", $last_modified);
           }
         }

         if (my $key = $h->{'copyright_key'}) {
           foreach my $symbol (@$symbol_list) {
             App::Chart::Database->write_extra
                 ($symbol, $key, $h->{'copyright'});
           }
         }

         my $timestamp = timestamp_now();

         if (my $key = $h->{'recheck_key'}) {
           my @recheck_list;
           if (my $l = $h->{'recheck_list'}) {
             @recheck_list = @$l;
           }
           if (my $pred = $h->{'recheck_pred'}) {
             push @recheck_list,
               grep { $pred->match($_) } keys %$database_symbols_hash;
           }
           if (DEBUG) { print "Recheck write ",join(' ',@recheck_list),"\n"; }
           foreach my $symbol (@recheck_list) {
             App::Chart::Database->write_extra ($symbol, $key, $timestamp);
           }
         }

         if ($h->{'last_download'}) {
           foreach my $symbol (keys %data_changed) {
             App::Chart::Database->write_extra ($symbol, 'last-download',
                                                $timestamp);
           }
           consider_historical ($symbol_list);
         }
         consider_latest_from_daily ($h, $database_symbols_hash);
       });

  ### data_changed: %data_changed
  App::Chart::chart_dirbroadcast()->send ('data-changed', \%data_changed);
}

sub consider_historical {
  my ($symbol_list) = @_;

  my $all_list;
  my $historical_list;

  foreach my $symbol (@$symbol_list) {
    if (App::Chart::Database->symbol_is_historical ($symbol)) {
      next; # already marked
    }
    my $reason = want_historical($symbol) // next;
    download_message ($reason);

    my $dbh = App::Chart::DBI->instance;
    $dbh->do ('UPDATE info SET historical=1 WHERE symbol=?',
              {}, $symbol);

    require App::Chart::Gtk2::Symlist;
    $all_list ||= App::Chart::Gtk2::Symlist::All->instance;
    $historical_list ||= App::Chart::Gtk2::Symlist::Historical->instance;

    $all_list->delete_symbol ($symbol);
    $historical_list->insert_symbol ($symbol);
  }
}

# return true if $symbol should be marked historical, meaning it has had no
# new daily data for a long time
# 
sub want_historical {
  my ($symbol) = @_;
  my $last_download_timestamp
    = App::Chart::Database->read_extra ($symbol, 'last-download')
    // return undef;  # no download attempted, not historical

  my $date = App::Chart::DBI->read_single
    ('SELECT date FROM daily WHERE (symbol=?) AND (close NOTNULL)
        ORDER BY date DESC LIMIT 1',
     $symbol);
  if (! defined $date) {
    return __x('{symbol} no data at all, marked historical',
               symbol => $symbol);
  }
  my $days = iso_timestamp_days_ago ($date, $last_download_timestamp);
  if ($days > 21) {
    return __x('{symbol} no data for {days} days, marked historical',
               days => $days,
               symbol => $symbol);
  }
  return undef;
}

sub iso_timestamp_days_ago {
  my ($iso, $prev_timestamp) = @_;
  my ($prev_year,$prev_month,$prev_day) = timestamp_to_ymdhms($prev_timestamp);
  return Date::Calc::Delta_Days (App::Chart::iso_to_ymd($iso),
                                 $prev_year, $prev_month, $prev_day);
}

sub consider_latest_from_daily {
  my ($h) = @_;
  my $dbh = App::Chart::DBI->instance;
  my %latest_changed;
  my $timestamp;

  my $database_symbols_hash = App::Chart::Database::database_symbols_hash();

  # find the newest and second newest data record of each symbol
  my %data_newest;
  my %data_second;
  foreach my $data (@{$h->{'data'}}) {
    my $symbol = $data->{'symbol'};
    if ($data->{'date'} ge ($data_newest{$symbol}->{'date'} // '')) {
      $data_second{$symbol} = $data_newest{$symbol};
      $data_newest{$symbol} = $data;
    } elsif ($data->{'date'} ge ($data_second{$symbol}->{'date'} // '')) {
      $data_second{$symbol} = $data;
    }
  }

  foreach my $symbol (keys %data_newest) {
    my $newest = $data_newest{$symbol};
    my $date = $newest->{'date'};

    # For symbols in the database, if newest daily is >= latest quote then
    # delete that quote in order to prefer the daily data in the database.
    if (exists $database_symbols_hash->{$symbol}) {
      my $latest_delete_sth = $dbh->prepare_cached
        ('DELETE FROM latest WHERE symbol=? AND quote_date < ?');
      if ($latest_delete_sth->execute ($symbol, $date)) {
        $latest_changed{$symbol} = 1;
      }
      next;
    }

    # For symbols not in the database, if the newest daily is >= latest quote
    # then replace that quote with the daily.
    #
    # Times in the latest record are not considered, so it's possible a
    # quote taken after close of trading will be deleted or overwritten.
    # Would want something in the latest to say it's after the close ...

    my $latest_get_sth = $dbh->prepare_cached
      ('SELECT last_date, name FROM latest WHERE symbol=?');
    my ($last_date, $name, $dividend)
      = $dbh->selectrow_array ($latest_get_sth, undef, $symbol);
    if (defined $last_date && $last_date gt $date) { next; }

    # "name" from the daily, or retain name from existing latest record.
    $name = $h->{'names'}->{$symbol} // $name;

    # "dividend" from existing latest record retained, but only if same date.
    unless (defined $last_date && $last_date eq $date) {
      undef $dividend;
    }

    # change by difference from second newest daily, if have one
    my $change = undef;
    if (defined(my $second_close = $data_second{$symbol}->{'close'})) {
      $change = App::Chart::decimal_sub ($newest->{'close'}, $second_close);
    }

    $timestamp ||= timestamp_now();

    my $latest_set_sth = $dbh->prepare_cached
      ('INSERT OR REPLACE INTO latest
        (symbol, name, currency, exchange, dividend,
         last_date, open, high, low, last, change, volume,
         source, fetch_timestamp)
        VALUES (?,?,?,?,?, ?,?,?,?,?,?,?, ?,?)');
    $latest_set_sth->execute
      ($symbol,
       $name,
       $h->{'currencies'}->{$symbol},
       $h->{'exchanges'}->{$symbol},
       $dividend,
       #
       $newest->{'date'},
       $newest->{'open'},
       $newest->{'high'},
       $newest->{'low'},
       $newest->{'close'},
       $change,
       $newest->{'volume'},
       #
       $h->{'source'},
       $timestamp);
    $latest_changed{$symbol} = 1;
  }

  foreach my $dividend (@{$h->{'dividends'}}) {
    my $latest_dividend_sth = $dbh->prepare_cached
      ('UPDATE latest SET dividend=? WHERE symbol=? AND last_date=?');
    my $symbol = $dividend->{'symbol'};
    if ($latest_dividend_sth->execute ($dividend->{'amount'},
                                       $symbol,
                                       $dividend->{'ex_date'})) {
      $latest_changed{$symbol} = 1;
    }
  }

  App::Chart::chart_dirbroadcast()->send ('latest-changed', \%latest_changed);

  require App::Chart::Annotation;
  foreach my $symbol (keys %latest_changed) {
    App::Chart::Annotation::Alert::update_alert ($symbol);
  }
}


#------------------------------------------------------------------------------

sub write_latest_group {
  my ($h) = @_;
  ### write_latest_group(): $h

  crunch_h ($h);
  ### crunched: $h

  my $fetch_timestamp = timestamp_now();
  my $prefer_decimals = $h->{'prefer_decimals'};
  my $source = $h->{'source'}
    or croak 'missing "source" for latest records';
  my %latest;

  my $dbh = App::Chart::DBI->instance;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {

         my $sth = $dbh->prepare_cached
           ('INSERT OR REPLACE INTO latest
            (symbol, name, month, exchange, currency,
             quote_date, quote_time, bid, offer,
             last_date, last_time, open, high, low, last, change, volume,
             note, error, dividend, copyright, source,
             fetch_timestamp, url, etag, last_modified)
            VALUES (?,?,?,?,?, ?,?,?,?, ?,?,?,?,?,?,?,?, ?,?,?,?,?, ?,?,?,?)');

         my $resp = $h->{'resp'};
         my $etag = (defined $resp ? scalar $resp->header('ETag') : undef);
         my $last_modified = (defined $resp ? $resp->last_modified : undef);

         foreach my $data (@{$h->{'data'}}) {
           my $symbol = $data->{'symbol'};
           my $this_date = $data->{'date'};
           if ($latest{$symbol}) {
             my $got_date = $latest{$symbol}->{'date'};
             if (! defined $got_date || ! defined $this_date) {
               carp "write_latest_group: $source: two records for '$symbol', but no 'date' field";
               if (DEBUG || 1) {
                 require Data::Dumper;
                 print Data::Dumper->Dump([$data,$latest{$symbol}],
                                          ['data','latest-so-far']);
               }
               next;
             }
             if ($got_date ge $this_date) { next; }
           }
           $latest{$symbol} = $data;
         }

         my $error = $h->{'error'};
         if (! defined $error && defined $resp && ! $resp->is_success) {
           $error = $resp->status_line;
         }

         foreach my $data (values %latest) {
           my $symbol = $data->{'symbol'};

           my $bid     = $data->{'bid'};
           my $offer   = $data->{'offer'};

           # disallow 0 for prices
           if ($bid    && $bid   == 0)   { $bid   = undef; }
           if ($offer  && $offer == 0)   { $offer = undef; }

           my $quote_date = crunch_date ($data->{'quote_date'});
           my $quote_time = crunch_time ($data->{'quote_time'});
           if ($quote_time && ! $quote_date) {
             croak "quote_time without quote_date for $symbol";
           }
           # default quote date/time to now
           if (($bid || $offer) && ! $quote_date) {
             my $symbol_timezone = App::Chart::TZ->for_symbol ($symbol);
             ($quote_date, $quote_time)
               = $symbol_timezone->iso_date_time
                 (time() - 60 * ($data->{'quote_delay_minutes'} || 0));
           }

           my $last_date = crunch_date ($data->{'last_date'} || $data->{'date'});
           my $last_time = crunch_time ($data->{'last_time'});

           my $open    = $data->{'open'};
           my $high    = $data->{'high'};
           my $low     = $data->{'low'};
           my $last    = $data->{'last'} || $data->{'close'};
           my $change  = $data->{'change'};
           my $prev    = crunch_price ($data->{'prev'}, $prefer_decimals);
           my $volume  = $data->{'volume'};

           if (! defined $last) {
             # if there's no last price then try to use the prev
             $open = $high = $low = undef;
             $last = $prev;
             $prev = undef;
             $change = undef;
             $last_date = undef;
             $last_time = undef;

           } elsif (! defined $change) {
             # if no change given then try to calculate it from last and prev

             if (! defined $prev) {
               # if no prev then look for one among other $data records, as for
               # when the group is a few consecutive daily data
               my $prev_date;
               foreach my $data (@{$h->{'data'}}) {
                 if ($data->{'symbol'} eq $symbol
                     && exists $data->{'date'}
                     && $data->{'date'} lt $last_date
                     && (! $prev_date
                         || $data->{'date'} gt $prev_date)) {
                   $prev_date = $data->{'date'};
                   $prev = $data->{'close'};
                 }
               }
             }
             if ($prev) {
               $change = App::Chart::decimal_sub ($last, $prev);
             }
           }

           $sth->execute ($symbol,
                          $h->{'names'}->{$symbol},
                          $data->{'month'},
                          $h->{'exchanges'}->{$symbol},
                          $h->{'currencies'}->{$symbol},

                          $quote_date, $quote_time,
                          $bid, $offer,

                          $last_date, $last_time,
                          $open, $high, $low, $last, $change, $volume,

                          $data->{'note'},
                          $data->{'error'} || $error,
                          $data->{'dividend'},
                          $h->{'copyright'},
                          $source,

                          $fetch_timestamp,
                          $h->{'url'},
                          $etag,
                          $last_modified);
           $sth->finish;
         }
       });

  App::Chart::chart_dirbroadcast()->send ('latest-changed', \%latest);

  require App::Chart::Annotation;
  foreach my $symbol (keys %latest) {
    App::Chart::Annotation::Alert::update_alert ($symbol);
  }
}

sub iso_to_MMM_YY {
  my ($iso) = @_;
  my ($year, $month, $day) = App::Chart::iso_to_ymd ($iso);
  return sprintf ("%.3s %02d",
                  uc(Date::Calc::Month_to_Text ($month)),
                  $year % 100);
}

#------------------------------------------------------------------------------

my $iso_date_re = qr/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/;

my %date_format_to_func
  = ('ymd' => \&App::Chart::Download::Decode_Date_YMD_to_iso,
     'dmy' => \&App::Chart::Download::Decode_Date_EU_to_iso,
     'mdy' => \&App::Chart::Download::Decode_Date_US_to_iso);
sub noop {
  return $_[0];
}

my %date_format_to_month_func
  = ('ymd' => \&crunch_month_ymd);

sub crunch_month_ymd {
  my ($str) = @_;
  my ($year, $month, $day) = Date::Calc::Decode_Date_EU ($str);
  if (! defined $year) {
    croak "unrecognised month string: $str";
  }
  if (defined $day) {
    if ($day != 1) { croak "month with day!=1: '$str' got $day"; }
  } else {
    $day = 1;
  }
  return App::Chart::ymd_to_iso ($year, $month, $day);
}

sub crunch_h {
  my ($h) = @_;
  my $database_symbols_hash = App::Chart::Database::database_symbols_hash();

  # ignore undef where expecting  hashrefs in 'data' and 'dividends' arefs
  foreach my $elem ('data',
                    'dividends') {
    my $aref = $h->{$elem} // next;
    @$aref = grep {
      defined $_
        # && App::Chart::Database->symbol_exists($_->{'symbol'})
    } @$aref;
  }

  my $suffix = $h->{'suffix'};
  my $month_format = $h->{'month_format'};
  my $prefer_decimals = $h->{'prefer_decimals'};

  my $date_format = delete $h->{'date_format'};
  my $date_func = ($date_format ? $date_format_to_func{$date_format} : \&noop)
    || croak "Unrecognised date_format '$date_format'";
  # my $month_func = $date_format ? $date_format_to_month_func{$date_format} : \&noop;

  my %currencies; $h->{'currencies'} = \%currencies;
  my %isins;      $h->{'isins'} = \%isins;
  my %names;      $h->{'names'} = \%names;
  my %exchanges;  $h->{'exchanges'} = \%exchanges;

  foreach my $info (@{$h->{'info'}}) {
    my $symbol = $info->{'symbol'}
      or croak "write_daily_group: missing symbol in info record";
    if (! exists $database_symbols_hash->{$symbol}) { next; }

    $names{$symbol}      ||= delete $info->{'name'};
    $currencies{$symbol} ||= delete $info->{'currency'};
    $exchanges{$symbol}  ||= delete $info->{'exchange'};
    $isins{$symbol}      ||= delete $info->{'isin'};
  }

  foreach my $data (@{$h->{'data'}}) {
    my $month = $data->{'month'};
    if (defined $month) {
      # $month = $data->{'month'} = $month_func->($month);
      $month =~ $iso_date_re or croak "Bad month value '$month'";
    }

    my $symbol = $data->{'symbol'};
    if (! defined $symbol) {
      # symbols built from commodity + month
      my $commodity = $data->{'commodity'}
        // croak "neither symbol nor commodity in 'data' element";
      $month // croak "Group data: no 'month' to go with 'commodity' in data element";
      $symbol = $data->{'symbol'}
        = $commodity . ' ' . iso_to_MMM_YY($month) . $suffix;
    }
    #       if ($month_format eq 'MMM_YY') {
    #         $month = iso_to_MMM_YY ($month);
    #       } else {
    #         croak "unrecognised month format: $month_format";
    #       }
  }

  if ($h->{'front_month'}) {
    my %front;
    foreach my $data (@{$h->{'data'}}) {
      my $symbol = $data->{'symbol'};
      my $front_symbol
        = App::Chart::symbol_commodity($symbol)
        . App::Chart::symbol_suffix($symbol);
      if (! $front{$front_symbol}
          || $data->{'month'} gt $front{$front_symbol}->{'month'}) {
        $front{$front_symbol} = $data;
      }
    }

    while (my ($symbol, $data) = each %front) {
      $data = { %$data };
      $data->{'symbol'} = $symbol;
      push @{$h->{'data'}}, $data;
    }
  }

  foreach my $data (@{$h->{'data'}}) {

    foreach my $field ('date', 'quote_date', 'last_date') {
      if (defined $data->{$field}) {
        $data->{$field} = crunch_date ($data->{$field}, $date_format);
      }
    }

    # empty volume or openint taken to be no data (as opposed to '0' for
    # zero volume or int)
    foreach my $field ('volume', 'openint') {
      if (defined $data->{$field} && $data->{$field} eq '') {
        $data->{$field} = undef;
      }
    }

    if (my $sessions = delete $data->{'sessions'}) {
      my @sessions = grep {defined} map {crunch_price($_)} @$sessions;
      $data->{'open'} = $sessions[0];
      ($data->{'low'}, $data->{'high'}) = List::MoreUtils::minmax (@sessions);
      $data->{'close'} = $sessions[-1];
    }

    if (exists $data->{'change'}) {
      $data->{'change'} = crunch_change ($data->{'change'}, $prefer_decimals);
    }
    foreach my $field (qw(bid offer open high low close last)) {
      if (exists $data->{$field}) {
        $data->{$field} = crunch_price ($data->{$field}, $prefer_decimals);
      }
    }
    foreach my $field (qw(volume openint)) {
      if (exists $data->{$field}) {
        $data->{$field} = crunch_number ($data->{$field});
      }
    }

    my $symbol = $data->{'symbol'};
    $currencies{$symbol} ||= delete $data->{'currency'} || $h->{'currency'};
    $names{$symbol}      ||= delete $data->{'name'}     || $h->{'name'};
    $exchanges{$symbol}  ||= delete $data->{'exchange'};
    $isins{$symbol}      ||= delete $data->{'isin'};
  }

  foreach my $dividend (@{$h->{'dividends'}}) {
    foreach my $field ('ex_date', 'record_date', 'pay_date') {
      if (defined $dividend->{$field}) {
        $dividend->{$field} = crunch_date ($dividend->{$field}, $date_format);
      }
    }
    $dividend->{'ex_date'}
      or croak 'Group data: missing ex_date in dividend record';

    foreach my $field (qw(amount imputation)) {
      if (exists $dividend->{$field}) {
        $dividend->{$field} = crunch_price ($dividend->{$field}, $prefer_decimals);
      }
    }
  }

  foreach my $split (@{$h->{'splits'}}) {
    if (defined $split->{'date'}) {
      $split->{'date'} = crunch_date ($split->{'date'}, $date_format);
    }
    $split->{'date'}
      or croak "Group data: missing 'date' in split record";
  }

  # whitespace in names, and possible leading/trailing in isins
  foreach my $href (\%names, \%currencies, \%exchanges, \%isins) {
    hash_delete_undefs ($href);
  }
  foreach (values %names, values %isins) {
    $_ = App::Chart::collapse_whitespace ($_);
  }

  if (eval { require Business::ISIN; 1 }) {
    my $bi = Business::ISIN->new;
    while (my ($symbol, $isin) = each %isins) {
      $bi->set ($isin);
      if ($bi->is_valid) { next; }
      warn "$symbol ISIN '$isin' is invalid, ignoring: ", $bi->error;
      delete $isins{$symbol};
    }
  }
}

sub hash_delete_undefs {
  my ($href) = @_;
  while (my ($key, $value) = each %$href) {
    if (! defined $value) {
      delete $href->{$key};
    }
  }
}

sub crunch_date {
  my ($str, $format) = @_;
  $str = crunch_empty_undef ($str);
  if (! defined $str) { return $str; }

  if (defined $format) {
    my $func = $date_format_to_func{$format};
    defined $func or croak "Unrecognised date_format spec: $format";
    $str = &$func ($str);
  }
  $str =~ $iso_date_re or croak "Bad date '$str'";
  return $str;
}

sub crunch_price {
  my ($str, $prefer_decimals) = @_;
  $str = crunch_change ($str, $prefer_decimals) // return undef;

  if (str_is_zero ($str)) { return undef; }
  return $str;
}
sub crunch_change {
  my ($str, $prefer_decimals) = @_;
  $str = crunch_number ($str) // return undef;

  if ($str eq '')     { return undef; }       # empty
  if (uc($str) eq 'CLOSED') { return undef; } # RBA 2003-2006.xls
  if ($str eq 'unch') { return '0'; }         # unchanged
  if (defined $prefer_decimals) {
    return App::Chart::Download::trim_decimals ($str, $prefer_decimals);
  } else {
    return $str;
  }
}

sub crunch_number {
  my ($str) = @_;
  if (! defined $str) { return undef; }

  $str =~ s/$RE{ws}{crop}//go;      # leading and trailing whitespace
  $str =~ s/^\+//;                  # leading + sign
  $str =~ s/^0+([1-9]|0\.|0$)/$1/;  # leading extra zeros

  if ($str eq ''
      || $str eq '-'
      || $str eq 'N/A'
      || $str eq 'n/a') {
    return undef;
  }
  $str =~ s/,//g;     # commas for thousands
  return $str;
}

sub crunch_time {
  my ($str) = @_;
  $str = crunch_empty_undef ($str);
  if (! defined $str) { return undef; }

  $str =~ /^([0-9]?[0-9])(:[0-9][0-9])(:[0-9][0-9])?([ap]m)?$/i
    or croak "bad time '$str'";
  my $hour = $1;
  my $minute = $2;
  my $second = $3;
  my $am_pm = $4;
  $second //= ':00';
  if (defined $am_pm && lc $am_pm eq 'pm') { $hour += 12; }
  $hour = sprintf '%02d', $hour;
  return "$hour$minute$second";
}

sub crunch_empty_undef {
  my ($str) = @_;
  if (! defined $str) { return $str; }
  $str =~ s/$RE{ws}{crop}//go;  # leading and trailing whitespace

  # eg. string "N/A" in dates and times from Yahoo
  if ($str eq '' || $str eq 'N/A') { return undef; }
  return $str;
}


#------------------------------------------------------------------------------

sub set_symbol_name {
  my ($symbol, $name) = @_;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached('UPDATE info SET name=? WHERE symbol=?');
  my $changed = $sth->execute($name, $symbol);
  $sth->finish();
  return $changed;
}
sub set_currency {
  my ($symbol, $currency) = @_;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached('UPDATE info SET currency=? WHERE symbol=?');
  my $changed = $sth->execute($currency, $symbol);
  $sth->finish();
  return $changed;
}
sub set_exchange {
  my ($symbol, $exchange) = @_;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached('UPDATE info SET exchange=? WHERE symbol=?');
  my $changed = $sth->execute($exchange, $symbol);
  $sth->finish();
  return $changed;
}
sub set_decimals {
  my ($symbol, $decimals) = @_;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached('UPDATE info SET decimals=? WHERE symbol=?');
  my $changed = $sth->execute($decimals, $symbol);
  $sth->finish();
  return $changed;
}
sub set_isin {
  my ($symbol, $isin) = @_;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached('UPDATE info SET isin=? WHERE symbol=?');
  my $changed = $sth->execute($isin, $symbol);
  $sth->finish();
  return $changed;
}


#------------------------------------------------------------------------------

# return true if $timestamp string is within the past $seconds from now
# also return true if $timestamp is some strange future value
sub timestamp_within {
  my ($timestamp, $seconds) = @_;
  if (! defined $timestamp) { return 0; }  # undef stamp always out of range
  my ($lo, $hi) = timestamp_range ($seconds);
  return (($timestamp ge $lo) && ($timestamp le $hi));
}
sub timestamp_range {
  my ($seconds) = @_;
  my $t = time();
  my $lo = $t - $seconds;
  my $hi = $t + 6*3600; # 2 hours future
  return (timet_to_timestamp($lo),
          timet_to_timestamp($hi));
}
sub timestamp_now {
  return timet_to_timestamp(time());
}
sub timet_to_timestamp {
  my ($t) = @_;
  return POSIX::strftime ('%Y-%m-%d %H:%M:%S+00:00', gmtime($t));
}
sub timestamp_to_ymdhms {
  my ($timestamp) = @_;
  return split /[- :+]/, $timestamp;
}
sub timestamp_to_timet {
  my ($timestamp) = @_;
  my ($year, $month, $day, $hour, $minute, $second) 
    = timestamp_to_ymdhms($timestamp);
  require Time::Local;
  return Time::Local::timegm_modern
    ($second, $minute, $hour, $day, $month-1, $year);
}


#------------------------------------------------------------------------------

sub tdate_strftime {
  my ($format, $tdate) = @_;
  my ($year, $month, $day) = App::Chart::tdate_to_ymd ($tdate);
  require App::Chart::Timebase;
  return App::Chart::Timebase::strftime_ymd ($format, $year, $month, $day);
}

sub tdate_range_string {
  my ($lo, $hi) = @_;
  if (@_ < 2) { $hi = $lo; }
  my $d_fmt = $App::Chart::option{'d_fmt'};
  if ($lo == $hi) {
    return tdate_strftime ($d_fmt, $lo);
  } else {
    return __x('{lodate} to {hidate}',
               lodate => tdate_strftime ($d_fmt, $lo),
               hidate => tdate_strftime ($d_fmt, $hi));
  }
}

sub symbol_range_string {
  my ($symbol_list) = @_;
  if (@$symbol_list == 0) {
    return '';
  } elsif (@$symbol_list == 1) {
    return $symbol_list->[0];
  } else {
    return __x('{start_symbol} to {end_symbol}',
               start_symbol => $symbol_list->[0],
               end_symbol   => $symbol_list->[-1]);
  }
}

#------------------------------------------------------------------------------

sub weekday_date_after_time {
  return App::Chart::tdate_to_iso (weekday_tdate_after_time (@_));
}
sub weekday_tdate_after_time {
  my ($after_hour,$after_min, $timezone, $offset) = @_;

  local $Tie::TZ::TZ = $timezone->tz;
  my ($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst)
    = Date::Calc::Localtime();

  my $tdate = App::Chart::ymd_to_tdate_floor ($year,$month,$day)
    + ($offset // 0);

  if ($dow >= 6   # Saturday or Sunday
      || ($hour*60+$min < $after_hour*60+$after_min)) {
    $tdate--;
  }
  return $tdate;
}

#------------------------------------------------------------------------------

sub download {
  my (%options) = @_;

  my @symbol_list = ();
  {
    my $symbol_list = $options{'symbol_list'}
      || croak "download() missing symbol_list\n";
    @symbol_list = @$symbol_list;
  }

  @symbol_list = List::MoreUtils::uniq (@symbol_list);
  verbose_message (__('Download:'), @symbol_list);

  foreach my $symbol (@symbol_list) {
    App::Chart::symbol_setups ($symbol);
  }
  App::Chart::Database->add_symbol (@symbol_list);

  require App::Chart::DownloadHandler;
  my $all_ok = 1;
  foreach my $handler (@App::Chart::DownloadHandler::handler_list) {
    my @this_list = grep {$handler->match($_)} @symbol_list;
    my $ok = $handler->download (\@this_list);
    if (! $ok) { $all_ok = 0; }
  }

  #   my %handler_result = ();
  #   foreach my $symbol (@symbol_list) {
  #
  #     my @handlers = App::Chart::DownloadHandler->handlers_for_symbol ($symbol);
  #     foreach my $handler (@handlers) {
  #       if (exists $handler_result{$handler}) {
  #         if (! $handler_result{$handler}) { $all_ok = 0; }
  #         next;
  #       }
  #
  #       my @this_list = grep { my $symbol = $_;
  #                              List::MoreUtils::all
  #                                  {$_->match($symbol)} @handlers
  #                            } @symbol_list;
  #       my $ok = $handler->download (\@this_list);
  #       $handler_result{$handler} = $ok;
  #     }
  #
  #   }
  status (__('Checking historical'));
  if ($all_ok) {
    consider_historical (\@symbol_list);
  }
}

# return a list of symbols, either just ($symbol), or if $symbol has
# wildcards then the result of matching that in the "all" list
sub symbol_glob {
  my ($symbol) = @_;

  if ($symbol =~ /[*?]/) {
    require Text::Glob;
    require App::Chart::Gtk2::Symlist::All;
    my $symlist = App::Chart::Gtk2::Symlist::All->instance;
    my $regexp = Text::Glob::glob_to_regex ($symbol);
    my @list = grep {$_ =~ $regexp} $symlist->symbols;
    if (! @list) {
      print __x("Warning, pattern \"{pattern}\" doesn't match anything in the database, ignoring\n",
                pattern => $symbol);
    }
    return @list;
  } else {
    return ($symbol);
  }
}

sub command_line_download {
  my ($class, $output, $args) = @_;
  my $hash;

  if ($output eq 'tty') {
    if (-t STDOUT) {
      binmode (STDOUT, ':via(EscStatus)')
        or die 'Cannot push EscStatus';
    } else {
      require PerlIO::via::EscStatus::ShowNone;
      binmode (STDOUT, ':via(EscStatus::ShowNone)')
        or die 'Cannot push EscStatus::ShowNone';
    }
  } elsif ($output eq  'all-status') {
    require PerlIO::via::EscStatus::ShowAll;
    binmode (STDOUT, ':via(EscStatus::ShowAll)')
      or die 'Cannot push EscStatus::ShowAll';
  }

  if (! @$args) {
    print __"No symbols specified to download\n";
    return;
  }

  my @symbol_list = ();
  foreach my $arg (@$args) {
    if (ref $arg) {
      # only what's already in the database
      $hash ||= App::Chart::Database::database_symbols_hash();
      my @list = grep {exists $hash->{$_}} $arg->symbols;
      push @symbol_list, @list;
      if (! @list) {
        print __x("Warning, no symbols in \"{symlist}\" are currently in the database\n(only symbols already in the database are downloaded from lists)\n",
                  symlist => $arg->name);
      }
    } else {
      push @symbol_list, symbol_glob ($arg);
    }
  }

  App::Chart::Download::download (symbol_list => \@symbol_list);

  require App::Chart::LatestHandler;
  App::Chart::LatestHandler->download (\@symbol_list);

  status ('');
}

#------------------------------------------------------------------------------

sub iso_to_tdate_floor {
  my ($str) = @_;
  my ($year, $month, $day) = App::Chart::iso_to_ymd ($str);
  return App::Chart::ymd_to_tdate_floor ($year, $month, $day);
}

sub iso_to_tdate_ceil {
  my ($str) = @_;
  my ($year, $month, $day) = App::Chart::iso_to_ymd ($str);
  return App::Chart::ymd_to_tdate_ceil ($year, $month, $day);
}

sub tdate_today {
  my ($timezone) = @_;
  $timezone //= App::Chart::TZ->loco;
  my ($year, $month, $day) = $timezone->ymd;
  return App::Chart::ymd_to_tdate_floor ($year, $month, $day);
}

my $default_download_tdates = 5 * 265;  # 5 years

sub start_tdate_for_update {
  my (@symbol_list) = @_;
  if (! @symbol_list) { croak "start_tdate_for_update(): no symbols"; }
  my $ret;
  foreach my $symbol (@symbol_list) {
    my $iso = App::Chart::DBI->read_single
      ('SELECT date FROM daily WHERE symbol=? ORDER BY date DESC LIMIT 1',
       $symbol);
    if (! defined $iso) {
      return (tdate_today() - $default_download_tdates);
    }
    my $tdate = iso_to_tdate_floor ($iso) + 1;
    $ret = App::Chart::min_maybe ($ret, $tdate);
  }
  return $ret;
}

sub tdate_today_after {
  my ($after_hour, $after_minute, $timezone) = @_;

  { local $Tie::TZ::TZ = $timezone->tz;
    my ($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst) =
      Date::Calc::System_Clock();

    my $tdate = App::Chart::ymd_to_tdate_floor ($year, $month, $day);
    if ($dow <= 5  # is a weekday
        && (App::Chart::hms_to_seconds ($hour, $min, 0)
            < App::Chart::hms_to_seconds ($after_hour, $after_minute, 0))) {
      $tdate--;
    }
    return $tdate;
  }
}


#-----------------------------------------------------------------------------
# selecting among possibly overlapping files

# $files is an arrayref containing hash records with keys
#
#     lo_tdate,hi_tdate   inclusive coverage of the record
#     lo_year,hi_year     alterative form for date range
#     cost                size of the file in bytes
#
sub choose_files {
  my ($files, $lo_tdate, $hi_tdate) = @_;
  if ($lo_tdate > $hi_tdate) { return []; }

  if (DEBUG) { print "choose_files $lo_tdate to $hi_tdate\n"; }

  foreach my $f (@$files) {
    if (! defined $f->{'lo_tdate'}) {
      if (my $m = $f->{'month_iso'}) {
        $f->{'lo_tdate'} = App::Chart::Download::iso_to_tdate_ceil ($m);
      } elsif ($f->{'lo_year'}) {
        $f->{'lo_tdate'}
          = App::Chart::ymd_to_tdate_ceil ($f->{'lo_year'}, 1, 1);
      } else {
        croak 'choose_files: missing lo date';
      }
    }

    if (! defined $f->{'hi_tdate'}) {
      if (my $m = $f->{'month_iso'}) {
        $f->{'hi_tdate'}
          = tdate_end_of_month (App::Chart::Download::iso_to_tdate_ceil ($m));
      } elsif ($f->{'hi_year'}) {
        $f->{'hi_tdate'}
          = App::Chart::ymd_to_tdate_floor($f->{'hi_year'}, 12, 31);
      } else {
        croak 'choose_files: missing hi date';
      }
    }
  }
  if (DEBUG >= 2) { require Data::Dumper;
                    print Data::Dumper::Dumper($files); }

  # restrict wanted range to what's available
  my $lo_available = min (map {$_->{'lo_tdate'}} @$files);
  my $hi_available = max (map {$_->{'hi_tdate'}} @$files);
  $lo_tdate = max ($lo_tdate, $lo_available);
  $hi_tdate = min ($hi_tdate, $hi_available);
  if (DEBUG) { print "  available $lo_available to $hi_available\n";
               print "  restricted range $lo_tdate to $hi_tdate\n"; }
  if ($lo_tdate > $hi_tdate) { return []; }

  # ignore file elements not covering any of the desired range
  $files = [ grep {App::Chart::overlap_inclusive_p ($lo_tdate, $hi_tdate,
                                                    $_->{'lo_tdate'},
                                                    $_->{'hi_tdate'})}
             @$files ];

  # Algorithm::ChooseSubsets would be another way to iterate, or
  # Math::Subset::List to get all combinations
  my $best_cost;
  my $best_files;
  foreach my $this_files (all_combinations ($files)) {
    if (! cover_p ($this_files, $lo_tdate, $hi_tdate)) { next; }
    my $cost = List::Util::sum (map {$_->{'cost'}||0} @$this_files);
    $cost += $App::Chart::option{'http_get_cost'} * scalar(@$this_files);
    if (! defined $best_cost || $cost < $best_cost) {
      $best_cost = $cost;
      $best_files = $this_files;
    }
  }
  return $best_files;
}

# return true if the set of file records in arrayref $files covers all of
# $lo_tdate through $hi_tdate inclusive
#
sub cover_p {
  my ($files, $lo_tdate, $hi_tdate) = @_;
  require Set::IntSpan::Fast;
  my $set = Set::IntSpan::Fast->new;
  foreach my $f (@$files) {
    $set->add_range ($f->{'lo_tdate'}, $f->{'hi_tdate'});
  }
  $set->contains_all_range ($lo_tdate, $hi_tdate);
}

# return a list which is all the combinations of elements of @$aref
# for example $aref == [ 10, 20 ] would return ([], [10], [20], [10,20])
# there's 2**N combinations for aref length N
#
sub all_combinations {
  my ($aref) = @_;
  my @ret = ([]);
  foreach my $i (0 .. $#$aref) {
    push @ret, map {[ @$_, $aref->[$i] ]} @ret;
  }
  return @ret;
}

# return the last tdate in the month containing the given $tdate
sub tdate_end_of_month {
  my ($tdate) = @_;
  my ($year, $month, $day) = App::Chart::tdate_to_ymd ($tdate);
  ($year, $month, $day) = Date::Calc::Add_Delta_YM ($year, $month, $day, 0,1);
  $day = 1;
  ($year, $month, $day) = Date::Calc::Add_Delta_Days ($year, $month, $day, -1);
  return App::Chart::ymd_to_tdate_floor ($year, $month, $day);
}

1;
__END__

=for stopwords url TTY LF whitespace undef YYYY-MM-DD GBP ISIN tdate

=head1 NAME

App::Chart::Download -- download functions

=cut

# =head1 HTTP FUNCTIONS
# 
# =over 4
# 
# =item C<< $resp = App::Chart::Download->get ($url, key=>value,...) >>
# 
# Download the given C<$url> and return a C<HTTP::Response> object.  The
# following key/value options are accepted.
# 
#     method          default 'GET'
#     data            body data for the request
#     etag            from previous get of this url
#     last_modified   from previous get of this url
# 
# A C<"POST"> can be done by setting C<method> accordingly and passing
# C<data>.  C<etag> and/or C<last_modified> can be given to avoid a
# re-download of url if unchanged (response status 304).
# 
# =item C<< App::Chart::Download::status ($str, $str, ...) >>
# 
# Join the argument strings together, with spaces between, and print them as
# the current download status.  Subsequent HTTP downloads through
# C<App::Chart::UserAgent> will append their progress to this status too.
# 
# =item C<< App::Chart::Download::download_message ($str, $str, ...) >>
# 
# Join the argument strings together, with spaces between, and print them and
# a newline as a download message.  This differs from an ordinary C<print> in
# that on a TTY it first erases anything from C<status> above (or checks the
# message itself is long enough to overwrite).
# 
# =back
# 
# =head1 PARSING FUNCTIONS
# 
# =over 4
# 
# =item App::Chart::Download::split_lines ($str)
# 
# Return a list of the lines in C<$str> separated by CR or LF, with trailing
# whitespace stripped, and blank lines (entirely whitespace) removed.
# 
# =item App::Chart::Download::trim_decimals ($str, $want_decimals)
# 
# Return C<$str> with trailing zero decimal places trimmed off to leave
# C<$want_decimals>.  If C<$str> doesn't look like a number, or is undef, then
# it's returned unchanged.
# 
# =item App::Chart::Download::str_is_zero ($str)
# 
# Return true if C<$str> is a zero number, like "0", "00", "0.00", ".000".
# 
# =item C<< App::Chart::Download::cents_to_dollars ($str) >>
# 
# C<$str> is a number like "12.5" in cents.  Return it with the decimal point
# shifted to be expressed in dollars like "0.125".
# 
# =back
# 
# =head1 DATE/TIME FUNCTIONS
# 
# =over 4
# 
# =item App::Chart::Download::month_to_nearest_year ($month)
# 
# C<$month> is in the range 1 to 12.  Return a year, as a number like 2007, to
# go with that month, so that the combination is within +/- 6 months of today.
# 
# =item C<< App::Chart::Download::Decode_Date_EU_to_iso ($str) >>
# 
# Decode a date in the form day/month/year using
# C<Date::Calc::Decode_Date_EU>, and return an ISO format date string like
# "2007-10-26".
# 
# =item App::Chart::Download::Decode_Date_YMD ($str)
# 
# Decode a date in the form year/month/day and return C<($year, $month,
# $day)>, similar to what C<Date::Calc> does.
# 
# The month given can be a number or a name in English and is always returned
# as a number.  Any separator can be used between the components and leading
# and trailing whitespace is ignored.  If the string is unrecognised the
# return is an empty list C<()>.
# 
# =item App::Chart::Download::Decode_Date_YMD_to_iso ($str)
# 
# Decode a date using C<App::Chart::Download::Decode_Date_YMD> above and return
# an ISO format string "YYYY-MM-DD".  An error is thrown if C<$str> is
# invalid.
# 
# =item App::Chart::Download::date_parse_to_iso ($str)
#
# unused?
# 
# Apply Date::Parse::strptime() to C<$str> and return an ISO format date
# string like "2007-10-26" for the result.  An error is thrown if C<$str> is
# unrecognisable.
# 
# =back
# 
# =item weekday_date_after_time ($hour,$min, $timezone, [$offset])
# 
# Return an an ISO format date string like C<"2008-08-20"> which is a weekday,
# giving today on a weekday after C<$hour>,C<$min>, or the previous weekday if
# before that time or any time on a weekend.
# 
# C<$offset> is a number of weekdays to step forward (or negative for back) on
# the return value.
# 
# For example if today's trading data is available after 5pm then a call like
# 
#     weekday_date_after_time (17,0, $my_zone)
# 
# would give yesterday until 5pm, and today after that, and give Friday all
# through the weekend.  If trading data is not available until 9am the
# following weekday then a call like
# 
#     weekday_date_after_time (9,0, $my_zone, -1)
# 
# would return the day before yesterday until 9am, and yesterday after that,
# including returning Thursday all through the weekend.

# =head1 DATABASE FUNCTIONS
# 
# =over 4
# 
# =item C<< App::Chart::Download::write_daily_group ($hashref) >>
# 
# C<$hashref> is daily share price data.  Write it to the database.  The
# fields of C<$hashref> are as follows.  They are variously crunched to
# normalize and validate before being written to the database.
#
# =over
#
# =item C<data>
#
# Arrayref containing hashref records with fields
#
#     symbol        string
#     open          price
#     high          price
#     low           price
#     close         price
#     volume        number
#     openint       number
#
# Any C<symbol> not already in the database is ignored.
# 
# =item C<dividends>
#
#     symbol        string
#
# Any C<symbol> not already in the database is ignored.
# 
# =item C<splits>
#
#     symbol        string
#
# Any C<symbol> not already in the database is ignored.
# 
# =item C<names>
#
# =item C<currencies>
#
# =back
#
#
#
# =item App::Chart::Download::write_latest_group ($hashref)
# 
# ...
# 

# =item App::Chart::Download::crunch_number ($str)
# 
# =item App::Chart::Download::crunch_price ($price, $prefer_decimals)
# 
# =item App::Chart::Download::crunch_change ($change, $prefer_decimals)
# 
# ...
# 

# =item App::Chart::Download::set_symbol_name ($symbol, $name)
# 
# Set the company or commodity name recorded in the database for C<$symbol>,
# if C<$symbol> is already in the database.
# 
# =item App::Chart::Download::set_currency ($symbol, $currency)
# 
# Set the currency recorded in the database for C<$symbol>, if C<$symbol> is
# already in the database.  C<$currency> should be a three-letter currency
# code, like "GBP" for British Pounds.
# 
# =item App::Chart::Download::set_isin ($symbol, $isin)
# 
# Set the ISIN recorded in the database for C<$symbol>, if C<$symbol> is
# already in the database.
# 
# =item App::Chart::Download::set_decimals ($symbol, $decimals)
# 
# Set the number of decimals to show for prices of C<$symbol>, if C<$symbol>
# is already in the database.
# 


# =item download (key=>value, ...)
# 
# ...
# 
# =cut

# =item C<< App::Chart::Download::start_tdate_for_update ($symbol, ...) >>
# 
# Return the tdate to start at for a data update of all the given symbols.
# This is the day after existing data of the oldest, or five years ago if any
# need an initial download.
# 
# =cut

