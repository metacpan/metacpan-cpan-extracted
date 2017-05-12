#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

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

use 5.006; # 3-arg open
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use List::Util qw(min max);
use POSIX;
use Scalar::Util;

use DBI;
use Lisp::Reader;
use File::Slurp;
use Date::Calc;

use App::Chart::Database;
use App::Chart::DBI;
use App::Chart::Download;
use App::Chart::Intraday;
use App::Chart::Gtk2::Symlist;


my $option_verbose = 1;

my $dbh = App::Chart::DBI->instance;
my $nbh = $dbh;
$Lisp::Reader::SYMBOLS_AS_STRINGS = 1;

sub directory_files {
  my ($dirname) = @_;
  return grep {/^[^.]/}
    map {File::Basename::basename($_)}
      glob "$dirname/*";
}

sub seconds_to_hmsstr {
  my ($seconds) = @_;
  return sprintf ('%02d:%02d:%02d', App::Chart::seconds_to_hms ($seconds));
}

sub insert_decimal {
  my ($str, $decimals) = @_;
  return $str if ($decimals == 0);
  my $sign = '';
  if ($str =~ /^(-)/) {
    $str = substr($str,1);
    $sign = '-';
  }
  $str = sprintf ("%0*s", $decimals+1, $str);
  substr($str,-$decimals,0, '.');

  return App::Chart::Download::trim_decimals ($sign . $str, 2);
}

sub convert_data {
  my @symbol_list = @_;
  print "database: ", scalar @symbol_list, " symbols\n";
  my $records = 0;

  foreach my $symbol (@symbol_list) {
    if ($option_verbose) {
      print "$symbol\n";
    }
    App::Chart::Database->add_symbol ($symbol);

    my @data;
    my @dividends;
    my @splits;
    my $h = { source => __FILE__,
              data => \@data,
              dividends => \@dividends,
              splits => \@splits,
              decimals => 2 };
    my $decimals = 0;

    my $filename = "$ENV{HOME}/Chart/data/$symbol";
    open IN, '<', $filename or die;

    foreach my $line (<IN>) {
      if ($line =~ /\(([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)( ([0-9]+))?/) {
        my ($date, $open, $high, $low, $close, $volume, $openint)
          = ($1,$2,$3,$4,$5,$6,$8);

        push @data, { symbol  => $symbol,
                      date    => App::Chart::tdate_to_iso ($1),
                      open    => insert_decimal ($2, $decimals),
                      high    => insert_decimal ($3, $decimals),
                      low     => insert_decimal ($4, $decimals),
                      close   => insert_decimal ($5, $decimals),
                      volume  => $6,
                      openint => $8 };
        $records++;
        next;
      }

      $line =~ s/\#f/\"\"/g;
      $line =~ s/\#t/1/g;
      my $arrayref = Lisp::Reader::lisp_read($line);
      my $form = $arrayref->[0];
      if ($option_verbose >= 2) { print Dumper(\$form); }
      next if ! defined $form; # blank or only comments

      if ($form->[0] eq 'decimals') {
        $decimals = $form->[1];
        if ($option_verbose) {
          print "decimals $decimals\n";
        }

      } elsif ($form->[0] eq 'currency') {
        my $currency = $form->[1];
        if ($option_verbose) { print "currency $currency\n"; }
        $h->{'currency'} = $currency;

      } elsif ($form->[0] eq 'name') {
        my $name = $form->[1];
        if ($option_verbose) { print "name $name\n"; }
        $h->{'name'} = $name;

      } elsif ($form->[0] eq 'dividend') {
        my $date = App::Chart::tdate_to_iso ($form->[1]);
        $form = $form->[2];

        if (! ref($form)) {
          # string dividend
          my $str = $form;
          if ($option_verbose) {
            print "dividend $date \"$str\"\n";
          }
          my $amount;
          my $imputation;
          my $qualifier;
          my $note;
          if (Scalar::Util::looks_like_number ($str)) {
            $amount = $str;
          } elsif ($amount eq 'unknown') {
            $qualifier = 'unknown';
          } elsif ($amount eq 'To be Advised') {
            $qualifier = 'TBA';
          } else {
            print "string dividend \"$str\"\n";
            $note = $str;
          }
          push @dividends, { symbol    => $symbol,
                             ex_date   => $date,
                             amount    => $amount,
                             qualifier => $qualifier,
                             note      => $note};

        } elsif ($form->[0] eq 'split') {
          my $new = $form->[1];
          my $old = $form->[2];
          if ($option_verbose) {
            print "split $date, $new, $old\n";
          }
          push @splits, { symbol => $symbol,
                          date => $date,
                          new  => $new,
                          old  => $old };

        } elsif ($form->[0] eq 'amount') {
          # structured value

          my $decimals = 0;
          my $amount = $form->[1];
          my $imputation;
          my $qualifier;

          my @array = @$form;
          foreach my $elem (@array[2..$#array]) {
            if ($elem->[0] eq 'decimals') {
              $decimals = $elem->[1];
            } elsif ($elem->[0] eq 'imputation') {
              $imputation = $elem->[1];
            } elsif ($elem->[0] eq 'estimated') {
              if ($elem->[1] != 0) {
                $qualifier = 'estimated';
              }
            } else {
              print "unrecognised dividend element: ",$elem->[0],"\n";
            }
          }

          $amount  = insert_decimal ($amount, $decimals);
          if ($imputation && ! ($imputation =~ /\./)) {
            $imputation  = insert_decimal ($imputation, $decimals);
          }

          if ($option_verbose) {
            print "dividend $date '",($amount||''),", '",($imputation||''),"'\n";
          }
          push @dividends, { symbol     => $symbol,
                             ex_date    => $date,
                             amount     => $amount,
                             imputation => $imputation,
                             qualifier  => $qualifier
                           };
        }
      }
    }
    close IN or die;

    App::Chart::Download::write_daily_group ($h);
  }
  print "database: $records daily records\n";
}

sub convert_latest {
  my @symbol_list = @_;
  print "latest: ", scalar @symbol_list, " symbols\n";

  foreach my $symbol (@symbol_list) {
    my $filename = "$ENV{HOME}/Chart/cache/latest/$symbol";
    my $content = File::Slurp::slurp ($filename);
    my %data = ();
    my $h = { 'data' => [\%data] };

    $content =~ s/\#f/""/g;
    my $form = Lisp::Reader::lisp_read($content);
    my $alist = $form->[0];
    foreach my $elem (@$alist) {
      $data{$elem->[0]} = $elem->[1];
    }
    $data{'source'} ||= 'convert-scm.pl';

    $h->{'source'} = $data{'source'};

    # empty strings are undef
    foreach my $field (keys %data) {
      if (exists $data{$field} && $data{$field} eq '') {
        delete $data{$field};
      }
    }

    my $decimals = $data{'decimals'};
    foreach my $field ('open', 'high', 'low', 'last', 'change',
                       'bid', 'offer') {
      if ($data{$field}) {
        $data{$field} = insert_decimal ($data{$field}, $decimals);
      }
    }

    foreach my $field (keys %data) {
      my $underscore = $field;
      $underscore =~ s/-/_/g;
      $data{$underscore} = $data{$field};
    }

    if (my $last_adate = $data{'last_adate'}) {
      $data{'last_date'} = App::Chart::adate_to_iso ($last_adate);
    }
    if (my $last_time = $data{'last_time'}) {
      $data{'last_time'} = seconds_to_hmsstr ($last_time);
    }

    if (my $quote_adate = $data{'quote_adate'}) {
      $data{'quote_date'} = App::Chart::adate_to_iso ($quote_adate);
    }
    if (my $quote_time = $data{'quote_time'}) {
      $data{'quote_time'} = seconds_to_hmsstr ($quote_time);
    }

    App::Chart::Download::write_latest_group ($h);
  }
}

sub convert_intraday {
  my @files = grep { /\.data$/ }
    directory_files ("$ENV{HOME}/Chart/cache/intraday");
  print "intraday: ", scalar @files, " images\n";

  foreach my $basename (@files) {
    my $fullname = "$ENV{HOME}/Chart/cache/intraday/$basename";

    $basename =~ /(.*)-(.*)\.data/;
    my $symbol = $1;
    my $mode = $2;
    my $image = File::Slurp::slurp ($fullname, { raw=>1 });

    if ($mode eq '1_Day') { $mode = '1d'; }
    elsif ($mode eq '5_Day') { $mode = '5d'; }

    App::Chart::Intraday::write_intraday_image (symbol => $symbol,
                                               mode => $mode,
                                               image => $image);
  }
}

sub data_decimals {
  my ($symbol) = @_;
  my $filename = "$ENV{HOME}/Chart/data/$symbol";
  my $decimals;
  if (! open IN, '<', $filename) {
    print "skip notes for defunct $symbol\n";
    return undef;
  }
  foreach my $line (<IN>) {
    if ($line =~ /\(decimals ([0-9]+)/) {
      $decimals = $1;
      last;
    }
  }
  close IN or die;
  if (! defined $decimals) {
    die "decimals not found for $symbol\n";
  }
  return $decimals;
}

sub convert_notes {
  my @symbol_list = @_;
  print "notes: ", scalar @symbol_list, " symbols\n";

  foreach my $symbol (@symbol_list) {
    my $decimals = data_decimals ($symbol);
    if (! defined $decimals) { next; }

    my $line_id = 1;
    my $alert_id = 1;
    my $annotation_id = 1;

    my $filename = "$ENV{HOME}/Chart/notes/$symbol";
    my $content = File::Slurp::slurp ($filename);

    $content =~ s/\#f/""/g;
    my $forms = Lisp::Reader::lisp_read($content);

    foreach my $form (@$forms) {
      my $key = $form->[0];
      if ($key eq 'annotation') {
        my ($key, $date, $str) = @$form;
        $date = App::Chart::tdate_to_iso ($date);
        my $id = $annotation_id++;
        my $sth = $nbh->prepare_cached
          ('INSERT INTO annotation (symbol, id, date, note) VALUES (?,?,?,?)');
        $sth->execute ($symbol, $id, $date, $str);
        $sth->finish();

      } elsif ($key eq 'line' || $key eq 'hline') {
        my ($key, $date1, $price1, $date2, $price2) = @$form;
        my $id = $line_id++;
        $date1 = App::Chart::tdate_to_iso ($date1);
        $date2 = App::Chart::tdate_to_iso ($date2);
        $price1  = insert_decimal ($price1, $decimals);
        $price2  = insert_decimal ($price2, $decimals);
        my $sth = $nbh->prepare_cached
          ('INSERT INTO line (symbol, id, date1, price1, date2, price2, horizontal)
            VALUES (?,?,?,?,?,?,?)');
        $sth->execute ($symbol, $id, $date1, $price1, $date2, $price2,
                       ($key eq 'hline' ? 1 : 0));
        $sth->finish();

      } elsif ($key eq 'alert-above' || $key eq 'alert-below') {
        my ($key, $price) = @$form;
        my $id = $alert_id++;
        $price  = insert_decimal ($price, $decimals);
        my $sth = $nbh->prepare_cached
          ('INSERT INTO alert (symbol, id, price, above) VALUES (?,?,?,?)');
        $sth->execute ($symbol, $id, $price, ($key eq 'alert-above' ? 1 : 0));
        $sth->finish();

      } else {
        print "unrecognised note: ", Dumper(\$form);
      }
    }
  }
}

sub convert_prefs {
  print "prefs\n";

  my $filename = "$ENV{HOME}/Chart/prefs.scm";
  my $content = File::Slurp::slurp ($filename);

  $content =~ s/\#f/""/g;
  my $forms = Lisp::Reader::lisp_read($content);

  foreach my $form (@$forms) {
    my $key = $form->[0];
    if ($key eq 'favourites') {
      my ($key, $list) = @$form;
      my $sth = $nbh->prepare_cached
        ('INSERT INTO symlist_content (key, pos, symbol) VALUES (?,?,?)');
      foreach my $pos (0 .. $#$list) {
        $sth->execute ('favourites', $pos, $list->[$pos]);
        $sth->finish();
      }

    } elsif ($key eq 'lme-username'
             || $key eq 'lme-password'
             || $key eq 'yahoo-quote-host'
             || $key eq 'yahoo-quote-timezone'
             || $key eq 'commsec-data-url'
             || $key eq 'commsec-enabled') {
      my ($key, $value) = @$form;
      if ($key eq 'commsec-enabled') {
        $key = 'commsec-enable';
        if ($value eq 'yes') { $value = 1; }
        if ($value eq 'no') { $value = 0; }
      }
      my $sth = $nbh->prepare_cached
        ('INSERT INTO preference (key, value) VALUES (?,?)');
      $sth->execute ($key, $value);
      $sth->finish();

    } else {
      print "(skip $key)\n";
    }
  }
}

sub convert_historical {
  require App::Chart::Gtk2::Symlist::Historical;
  require App::Chart::Gtk2::Symlist::All;
  my $historical_symlist = App::Chart::Gtk2::Symlist::Historical->instance;
  my $all_symlist = App::Chart::Gtk2::Symlist::All->instance;

  my $filename = "$ENV{HOME}/Chart/cache/historical-symbols";
  if (! -e $filename) { return; }
  my $content = File::Slurp::slurp ($filename);
  $content =~ s/\#f/""/g;
  my $forms = Lisp::Reader::lisp_read($content);

  my $sth = $dbh->prepare_cached
    ('UPDATE info SET historical=1 WHERE symbol=?');
  foreach my $symbol (@{$forms->[0]}) {
    if (App::Chart::Database->symbol_exists ($symbol)) {
      print "historical $symbol\n";
      $sth->execute ($symbol);
      $sth->finish;

      $historical_symlist->insert_symbol ($symbol);
    }
  }

  foreach my $symbol (App::Chart::Database->symbols_list()) {
    if (! App::Chart::Database->symbol_is_historical ($symbol)) {
      $all_symlist->insert_symbol ($symbol);
    }
  }
}

$dbh->begin_work;
$nbh->begin_work;
$dbh->do ('PRAGMA synchronous = OFF');
$dbh->do ('PRAGMA cache_size = 20000'); # of 1.5k pages, is 30Mb

convert_prefs();

#convert_notes ('BHP.AX','BBW.AX','ERA.AX','TEL.NZ');
convert_notes (directory_files ("$ENV{HOME}/Chart/notes"));

convert_intraday ();

#convert_data ('TEL.NZ','FPA.NZ','BHP.AX','IPG.AX');
convert_data (directory_files ("$ENV{HOME}/Chart/data"));

convert_historical;

#convert_latest ('BBW.AX','ERA.AX');
convert_latest (directory_files ("$ENV{HOME}/Chart/cache/latest"));

$dbh->commit;
$nbh->commit;
App::Chart::DBI->disconnect();

system 'ls -l ~/Chart/database.sqdb ~/Chart/notes.sqdb';
exit 0;



# Local variables:
# compile-command: "rm ~/Chart/database.sqdb ~/Chart/notes.sqdb; perl ~/pchart/devel/convert-scm.pl"
# End:
