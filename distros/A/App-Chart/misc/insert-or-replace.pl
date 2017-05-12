#!/usr/bin/perl -w

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

sub insert_or_replace {
  my ($dbh, $into, $into_args, $where, $where_args) = @_;
  my $n = App::Chart::DBI->read_single
    ("SELECT COUNT(*) $where", $where_args);
  my $sth = ($n == 0
             ? $dbh->prepare_cached ("INSERT $into", @$into_args);
             : $dbh->prepare_cached ("REPLACE $into $where", @$into_args, @$where_args));
  $sth->execute (@args);
  $sth->finish;
}

insert_or_replace ("INTO dividend (symbol, ex_date, pay_date, amount, imputation) VALUES (?,?,?,?,?)",
                   [$symbol, $ex_date, $pay_date, $amount, $imput],
                   "WHERE symbol=? AND ex_date =?",
                   [$symbol, $ex_date]);



sub insert_or_replace {
  my ($dbh, $into, $into_args, $where, $where_args) = @_;
  my $n = App::Chart::DBI->read_single
    ("SELECT COUNT(*) $where", $where_args);
  my $sth = ($n == 0
             ? $dbh->prepare_cached ("INSERT $into", @$into_args);
             : $dbh->prepare_cached ("REPLACE $into $where", @$into_args, @$where_args));
  $sth->execute (@args);
  $sth->finish;
}

insert_or_replace ("INTO dividend (symbol, ex_date, pay_date, amount, imputation) VALUES (?,?,?,?,?)",
                   [$symbol, $ex_date, $pay_date, $amount, $imput],
                   "WHERE symbol=? AND ex_date =?",
                   [$symbol, $ex_date]);
